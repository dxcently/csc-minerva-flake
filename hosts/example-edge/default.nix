# example-edge — a template host record. Every value below is a documentation
# placeholder (RFC 5737 / example.org); copy it into a PRIVATE overlay flake and
# replace them there. Never put real addresses, keys or tokens in this tree.
{
  dendrites = {
    dev-tools.enable = true;
    proxmox-guest.enable = true;
    tailscale.enable = true;
    caddy-edge.enable = true;
  };

  users.admin = {
    definition = ../../users/admin.nix;
    homeManager.enable = false;
  };

  nixos =
    { config, ... }:
    {
      nixpkgs.hostPlatform = "x86_64-linux";
      proxmox.qemuConf.name = "example-edge";
      networking.hostName = "example-edge";
      system.stateVersion = "25.11";

      users.users.admin.openssh.authorizedKeys.keys = [
        # "ssh-ed25519 AAAA... you@example"
      ];

      minerva.secrets = {
        file = ../../secrets/example-edge.yaml;
        names = [
          "cloudflare-dns-token"
          "tailscale-authkey"
        ];
      };

      minerva.tailscale = {
        authKeyFile = config.sops.secrets."tailscale-authkey".path;
        operator = "admin";
        advertiseRoutes = [ "192.0.2.10/32" ];
      };

      minerva.edge = {
        domain = "example.org";
        cloudflareTokenFile = config.sops.secrets."cloudflare-dns-token".path;
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
