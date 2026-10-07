# base — what every Minerva host carries beyond the nucleus.
#
# An aggregation body is DATA: members named by CATALOGUE NAME, so the
# implementations stay in modules/dendrites/*.nix. `base` is the one aggregation
# every host selects. Capabilities only some hosts need (tailscale, caddy-edge)
# stay out of it and are selected per host.
{
  description = "A Minerva host: a hardened Proxmox guest with operator and network tools.";

  system.members = [
    "dev-tools"
    "hardening"
    "network-tools"
    "proxmox-guest"
  ];
}
