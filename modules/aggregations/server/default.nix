# server — what every Minerva server carries beyond the nucleus.
#
# An aggregation body is DATA: members named by catalogue name. A server is a
# Proxmox guest; the edge capabilities (tailscale, caddy-edge) are selected
# per host, because not every server is the edge.
{
  description = "A Minerva server running as a Proxmox guest.";

  system.members = [ "proxmox-guest" ];
}
