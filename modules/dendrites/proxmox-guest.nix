# proxmox-guest — what a NixOS VM needs to behave under Proxmox: the QEMU guest
# agent (shutdown, snapshots, IP reporting), a serial console for the Proxmox
# console view, and a root filesystem that follows a resized virtual disk.
{
  nixos =
    { lib, ... }:
    {
      services.qemuGuest.enable = true;
      boot.kernelParams = [
        "console=ttyS0,115200"
        "console=tty0"
      ];
      boot.growPartition = lib.mkDefault true;
    };
}
