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

- Command hangs indefinitely (no return, must Ctrl+C or kill)
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

## Expected Behavior

1. Driver unbind should not NULL-deref — `isp_genpd_remove_device()` should handle
   partially initialized or corrupted ISP state gracefully.

2. Driver rebind should either succeed (creating DRM devices) or fail with an error.
   Silently hanging is unacceptable.

3. GPU reset should actually reset the DRM state, not just report "reset done" while
   leaving DRM in an unrecoverable state.

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
