# example-edge — a template host record. Every value below is a documentation
# placeholder (RFC 5737 / example.org); copy it into a PRIVATE overlay flake and
# replace them there. Never put real addresses, keys or tokens in this tree.
{
  aggregation.server.enable = true;

  dendrites = {
    tailscale.enable = true;
    caddy-edge.enable = true;
  };

  users.admin = {
    definition = ../../users/admin.nix;
    homeManager.enable = false;
  };

  nixos =
    { lib, ... }:
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      networking.hostName = "example-edge";
      system.stateVersion = "25.11";

      # Stand-ins so the example evaluates; a real host imports its own
      # hardware scan or VM image module.
      boot.loader.grub.devices = [ "/dev/vda" ];
      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

      users.users.admin.openssh.authorizedKeys.keys = [
        # "ssh-ed25519 AAAA... you@example"
      ];

      minerva.tailscale = {
        operator = "admin";
        advertiseRoutes = [ "192.0.2.10/32" ];
      };

      minerva.edge = {
        domain = "example.org";
        cloudflareTokenFile = "/var/lib/minerva/cloudflare-dns-token";
        sites = {
          auth.upstream = "http://192.0.2.20:9000";
          quotient.upstream = "http://192.0.2.21:8080";
          git.upstream = "http://192.0.2.22:3000";
          pve = {
            upstream = "https://192.0.2.30:8006";
            tlsServerName = "pve.example.org";
          };
        };
      };
    };
}
