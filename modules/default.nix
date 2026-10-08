# modules/default.nix — the registry.
#
# NOT a module: plain data, read by habit's composition before any module graph
# exists. One catalogue line per capability, plus the aggregations and override
# records discovered beside it. A name with no line is unreachable, which is
# what shelving means.
{
  catalogue = {
    caddy-edge = ./dendrites/caddy-edge.nix;
    cloudflare-tunnel = ./dendrites/cloudflare-tunnel.nix;
    dev-tools = ./dendrites/dev-tools.nix;
    hardening = ./dendrites/hardening.nix;
    network-tools = ./dendrites/network-tools.nix;
    proxmox-guest = ./dendrites/proxmox-guest.nix;
    split-dns = ./dendrites/split-dns.nix;
    tailscale = ./dendrites/tailscale.nix;
  };

  overrides = import ./overrides;

  aggregations = import ./aggregations;
}
