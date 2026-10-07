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

      # Hostname and network come from the host record, not from PVE's
      # cloud-init (which would force the hostname empty).
      proxmox.cloudInit.enable = lib.mkDefault false;

      services.qemuGuest.enable = true;
      boot.growPartition = lib.mkDefault true;
    };
}
