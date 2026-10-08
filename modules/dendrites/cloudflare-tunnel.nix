# cloudflare-tunnel — publish local HTTPS sites through a Cloudflare Tunnel.
#
# Outbound-only: cloudflared dials Cloudflare's edge (port 7844, QUIC or
# HTTP/2) and nothing listens on the internet side. Each hostname is handed to
# the local origin, normally caddy-edge on 127.0.0.1:443, with the hostname as
# the TLS server name, so Caddy keeps its own certificate and routing.
#
# The tunnel is locally managed: create it once with a browser login, then keep
# its credentials JSON in sops:
#   cloudflared tunnel login                 # pick the zone
#   cloudflared tunnel create <host>         # prints the id, writes <id>.json
#   sops set secrets/<host>.yaml '["cloudflared-credentials"]' "$(jq -Rs . <id>.json)"
# Public DNS for each hostname is a proxied CNAME to <id>.cfargotunnel.com.
#
# Example (in a host record's `nixos`):
#   minerva.tunnel = {
#     tunnelId = "00000000-0000-0000-0000-000000000000";
#     credentialsFile = config.sops.secrets."cloudflared-credentials".path;
#     hostnames = [ "auth.example.org" "pve.example.org" ];
#   };
{
  nixos =
    { config, lib, ... }:
    let
      cfg = config.minerva.tunnel;
    in
    {
      options.minerva.tunnel = {
        tunnelId = lib.mkOption {
          type = lib.types.str;
          description = "The tunnel's UUID, from `cloudflared tunnel create`.";
        };
        credentialsFile = lib.mkOption {
          type = lib.types.str;
          description = "Runtime path of the tunnel credentials JSON. Never a Nix store path.";
        };
        hostnames = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Public hostnames the tunnel serves; anything else gets a 404.";
        };
        origin = lib.mkOption {
          type = lib.types.str;
          default = "https://127.0.0.1:443";
          description = "Where cloudflared sends each request.";
        };
      };

      config = {
        services.cloudflared = {
          enable = true;
          tunnels.${cfg.tunnelId} = {
            inherit (cfg) credentialsFile;
            default = "http_status:404";
            ingress = lib.genAttrs cfg.hostnames (host: {
              service = cfg.origin;
              # The origin's certificate is for the hostname, not the address.
              originRequest.originServerName = host;
            });
          };
        };
      };
    };
}
