# amdgpu Kernel NULL Pointer Dereference in isp_genpd_remove_device During Driver Unbind

## Summary

After a severe OOM event on a system with AMD Ryzen AI Max+ 395 (Strix Halo, gfx1151),
the amdgpu driver enters a state where:

1. **DRM becomes permanently broken** — niri (Wayland compositor) loses DRM master and
   can never recover, even after process restart. All DRM operations return
   "Permission denied" or "DeviceMissing".

2. **Driver unbind crashes** — `echo PCI_ADDR > /sys/bus/pci/drivers/amdgpu/unbind`
   triggers a NULL pointer dereference in `isp_genpd_remove_device()`.

3. **Driver rebind hangs silently** — After the crashed unbind, rebind appears to
   succeed but creates no DRM devices (`/sys/class/drm/` is empty). The rebind
   command hangs indefinitely and must be killed.

The only recovery is a full system reboot.

## Hardware

- **CPU/APU:** AMD Ryzen AI Max+ 395 (Strix Halo, gfx1151)
- **GPU:** AMD [1002:1586] integrated GPU (same die)
- **PCI Address:** 0000:c5:00.0
- **RAM:** 128GB unified (CPU + GPU)
- **System:** GMKtec NucBox EVO-X2, BIOS EVO-X2 1.11

## Kernel

```
Linux evo-x2 7.0.1 #1-NixOS PREEMPT(lazy) x86_64
```

## Trigger Sequence

1. System runs AI workloads (llama-server with multimodal model using GPU compute via
   libhsa-runtime64, plus Python/ROCm processes).
2. All 128GB RAM + 42GB swap exhausted (OOM).
3. earlyoom kills processes, including dbus-broker and systemd-logind.
4. niri (Wayland compositor) loses DRM master status when logind dies.
5. niri enters zombie state — process alive, but DRM page flips fail with
   "Permission denied" on /dev/dri/card1.
6. Even after logind/dbus-broker restart (they have Restart=always), niri cannot
   recover DRM master. Killing and restarting niri produces the same DRM errors.
7. GPU reset via `/sys/class/drm/card1/device/reset` reports success ("resetting" /
   "reset done") but DRM remains broken.

## Bug 1: NULL Pointer Dereference on Unbind

Attempting to unbind the driver to recover:

```
$ systemctl --user stop niri
$ echo 0000:c5:00.0 > /sys/bus/pci/drivers/amdgpu/unbind
```

Kernel oops:

```
BUG: unable to handle page fault for address: ffffffffffffffb8
#PF: supervisor read access in kernel mode
#PF: error_code(0x0000) - not-present page
Oops: Oops: 0000 [#1] SMP NOPTI
CPU: 16 UID: 0 PID: 1700675 Comm: tee Tainted: G O 7.0.1 #1-NixOS

RIP: 0010:isp_genpd_remove_device+0x1c/0xc0 [amdgpu]
Code: 90 90 90 90 90 90 90 90 90 90 90 90 90 90 f3 0f 1e fa 0f 1f 44 00 00
      48 83 ff 10 0f 84 98 00 00 00 55 53 48 8b 47 58 48 89 fb <48> 8b 6e b8

Call Trace:
 isp_genpd_remove_device+0x1c/0xc0 [amdgpu]
 device_for_each_child+0x71/0xb0
 isp_v4_1_1_hw_fini+0x1e/0x60 [amdgpu]
 amdgpu_ip_block_hw_fini+0x39/0x7f [amdgpu]
 amdgpu_device_fini_hw+0x263/0x319 [amdgpu]
 amdgpu_pci_remove+0x4c/0x80 [amdgpu]
 pci_device_remove+0x4a/0xc0
 device_release_driver_internal+0x19e/0x200
 unbind_store+0xa4/0xb0
 kernfs_fop_write_iter+0x189/0x230
```

The crash dereferences `ffffffffffffffb8` which is `-72` — a NULL struct pointer with
field offset. RAX=0, RDI points to a device struct, suggesting the ISP genpd device
has a NULL parent or provider pointer after the OOM corruption.

Additionally, before the crash:

```
amdgpu 0000:c5:00.0: VM memory stats for proc (0) task (0) is non-zero when fini
amdgpu 0000:c5:00.0: finishing device.
kfd kfd: Sending SIGBUS to process 3550225
```

This indicates GPU VM (virtual memory) was in an inconsistent state — process/task
pointers were already zeroed out.

## Bug 2: Rebind Hangs, No DRM Devices Created

After the crashed unbind:

```
$ echo 0000:c5:00.0 > /sys/bus/pci/drivers/amdgpu/bind
```

- Command hangs indefinitely — not interruptible by Ctrl+C, SIGINT, or SIGTERM.
  Only closing the SSH terminal (killing the session) recovers. The process is
  stuck in uninterruptible sleep (D state) in kernel space.
- No DRM devices appear in `/sys/class/drm/` (only `version` file remains)
- No PCI device listed under `/sys/bus/pci/drivers/amdgpu/`
- No kernel log output from amdgpu during bind attempt

## Bug 3: DRM State Permanently Corrupted After OOM

After the OOM event kills dbus-broker and logind:

- GPU reset (`/sys/class/drm/card1/device/reset`) reports success but DRM remains broken
- New niri process gets `Error::DeviceMissing` on DRM operations
- GPU hardware is functional (amdgpu driver is loaded, card1 exists)
- But the DRM/KMS subsystem cannot initialize any outputs or do page flips
- The ISP (Image Signal Processor) block appears to be part of the corruption,
  as the crash is in ISP genpd cleanup code

## Bug 4: CPU Power Management Broken After Driver Crash

After the `isp_genpd_remove_device` kernel oops, CPU frequency becomes stuck at
the minimum base clock (600 MHz) even at 100% load across all 16 cores:

- All cores at 98-100% utilization
- All cores locked to ~600 MHz (max capable: 5.1 GHz)
- `scaling_governor` = schedutil, `scaling_max_freq` = 5187500 — governor looks correct
- Temperature: 89°C, Power: 144W — NOT thermal throttling
- `amd_pstate` = guided mode

On AMD Strix Halo (Ryzen AI Max+ 395), the CPU and GPU share the same die. The
SMU (System Management Unit) manages power and frequency for both. The crashed
amdgpu driver appears to have corrupted or locked the SMU state, preventing the
CPU from boosting above minimum frequency even under full load.

This confirms the amdgpu crash has side effects beyond just the GPU — it corrupts
shared silicon infrastructure (SMU, ISP power domains) that affects the entire SoC.

### Diagnostic data collected while bug was active:

```
# CPU frequency stuck BELOW configured minimum
scaling_driver:          amd-pstate
amd_pstate status:       guided
amd_pstate prefcore:     enabled
boost:                   1 (enabled)
scaling_min_freq:        2000000 (2.0 GHz)
scaling_max_freq:        5187500 (5.1 GHz)
scaling_cur_freq:        ~603000 (600 MHz)   ← BELOW scaling_min_freq!
cpuinfo_cur_freq:        (empty)              ← kernel cannot read HW freq
energy_performance_preference: (empty)        ← not set at all
scaling_available_frequencies: (empty)        ← no frequencies listed

# All cores identical
cpu0-cpu3: all at ~603 MHz

# GPU driver state after crashed unbind
/sys/class/drm/:         only "version" file (no card0/card1/renderD128)
/sys/bus/pci/drivers/amdgpu/: no PCI device bound
amdgpu module:           still loaded but no hardware attached

# Kernel timing anomalies (after oops)
perf: interrupt took too long (2508 > 2500), lowering kernel.perf_event_max_sample_rate to 79000
perf: interrupt took too long (3344 > 3135), lowering kernel.perf_event_max_sample_rate to 59000
hrtimer: interrupt took 307571 ns   ← 307us hrtimer latency, normally <10us
```

The kernel oops at 04:46:29 left `irqs disabled` (noted in the oops: `note: tee[1700675] exited with irqs disabled`).
This may have left a CPU core with interrupts disabled, causing cascading timing issues.
However, the CPU frequency stuck at 600 MHz appeared significantly later (user reports ~30+ minutes),
suggesting it's not just an immediate oops side-effect but rather a gradual SMU state corruption.

## Expected Behavior

1. Driver unbind should not NULL-deref — `isp_genpd_remove_device()` should handle
   partially initialized or corrupted ISP state gracefully.

2. Driver rebind should either succeed (creating DRM devices) or fail with an error.
   Silently hanging is unacceptable.

3. GPU reset should actually reset the DRM state, not just report "reset done" while
   leaving DRM in an unrecoverable state.

4. Driver crash should not corrupt shared SoC infrastructure (SMU). CPU frequency
   management must remain independent of GPU driver state.

## Additional Context

Multiple `python3.13` processes segfaulted in `libhsa-runtime64.so` during the OOM
event, suggesting the AMD HSA runtime (used for GPU compute) was actively using the
GPU when memory exhaustion hit. The segfaults are in the same code path:

```
python3.13[pid]: segfault at 34 ip 00007ffeeb048930 sp 00007fffffff82e0 error 4
  in libhsa-runtime64.so[48930,7ffeeb01d000+11c000]
Code: ... 4c 8b 66 68 4d 39 e5 74 30 <41> 83 7c 24 34 03 49 8b 44 24 20 74 43
```

This likely left the GPU's compute queues and VM state in an inconsistent state that
the amdgpu driver's cleanup paths don't handle.

## Reproduction

1. Run GPU compute workloads (llama-server multimodal, ROCm/PyTorch) on Strix Halo
2. Exhaust all system RAM + swap
3. Kill critical session services (logind, dbus-broker) during OOM
4. Observe DRM state corruption
5. Attempt driver unbind/rebind for recovery
