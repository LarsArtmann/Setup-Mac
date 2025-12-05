# Installing NixOS on Evo-X2 (AMD Ryzen AI Max+)

## 1. Prepare the Installation Media
1. Download the latest **NixOS Minimal ISO** (64-bit AMD/Intel) from [nixos.org](https://nixos.org/download.html).
2. Flash it to a USB stick (use Etcher or `dd`).
3. Boot your GMKtec PC from the USB stick.

## 2. Connect to WiFi (if needed)
```bash
# If using Ethernet, skip this.
sudo systemctl start wpa_supplicant
wpa_cli
> add_network
> 0
> set_network 0 ssid "YOUR_WIFI_NAME"
> set_network 0 psk "YOUR_WIFI_PASSWORD"
> enable_network 0
> quit
```

## 3. Partition & Format
(Recommended: Wipe everything and use standard layout)
```bash
# Check your disk name (likely /dev/nvme0n1)
lsblk

# Run the partition tool (interactive)
sudo cfdisk /dev/nvme0n1
# Create:
# 1. 512MB EFI Partition (Type: EFI System)
# 2. Rest of disk Linux Filesystem (Type: Linux filesystem)

# Format
sudo mkfs.fat -F 32 -n boot /dev/nvme0n1p1
sudo mkfs.ext4 -L nixos /dev/nvme0n1p2

# Mount
sudo mount /dev/disk/by-label/nixos /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/boot /mnt/boot
```

## 4. Get the Configuration
```bash
# Install git provided by the installer
nix-shell -p git

# Clone your dotfiles
git clone https://github.com/YOUR_USERNAME/Setup-Mac.git /mnt/etc/nixos
cd /mnt/etc/nixos
```

## 5. Generate Hardware Config
Your PC has specific hardware ID/drives. We need to generate the real hardware config and overwrite the template I made.
```bash
nixos-generate-config --show-hardware-config > dotfiles/nixos/hardware-configuration.nix
```

## 6. Install
```bash
# Install using the 'evo-x2' flake output we created
nixos-install --flake .#evo-x2
```

## 7. Reboot
```bash
reboot
```

---

## Post-Install
- Login as `lars` (password is set during install or needs setting via root)
- Hyprland should start automatically or via `Hyprland` command (if not using login manager)
- Run `just switch` to apply updates in the future!
