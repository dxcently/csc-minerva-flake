# proxmox-guest — what a NixOS VM needs to behave under Proxmox: the QEMU guest
# agent (shutdown, snapshots, IP reporting), a serial console for the Proxmox
# console view, a root filesystem that follows a resized virtual disk, and the
# nixpkgs Proxmox image module, so `config.system.build.VMA` is a disk image
# restorable with `qmrestore`.
{
  nixos =
    { lib, modulesPath, ... }:
    {
      imports = [ (modulesPath + "/virtualisation/proxmox-image.nix") ];

      services.qemuGuest.enable = true;
      boot.growPartition = lib.mkDefault true;
    };
}
