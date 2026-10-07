# caddy-edge — the TLS reverse proxy in front of the private apps.
#
# One wildcard certificate (*.<domain> plus the apex) is obtained by DNS-01
# through Cloudflare, so nothing needs to be reachable from the internet to
# issue or renew it. Each site is one subdomain, each on its OWN browser
# origin: apps never share an origin by path.
#
# The Cloudflare token is read at runtime from a file outside the Nix store and
# handed to Caddy as a systemd credential. It needs only Zone:DNS:Edit and
# Zone:Zone:Read on the one zone.
#
# Example (in a host record's `nixos`):
#   minerva.edge = {
#     domain = "example.org";
#     cloudflareTokenFile = "/var/lib/minerva/cloudflare-dns-token";
#     sites.auth.upstream = "http://192.0.2.20:9000";
#     sites.pve = { upstream = "https://192.0.2.30:8006"; tlsCaFile = ./pve-ca.pem; };
#   };
{
  nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.minerva.edge;
      credential = "/run/credentials/caddy.service/cloudflare-dns-token";

      siteBlock = name: site: ''
        @${name} host ${name}.${cfg.domain}
        handle @${name} {
          reverse_proxy ${site.upstream}${
            lib.optionalString (site.tlsCaFile != null || site.tlsServerName != null) ''
               {
                transport http {
                  ${lib.optionalString (site.tlsCaFile != null) "tls_trust_pool file ${site.tlsCaFile}"}
                  ${lib.optionalString (site.tlsServerName != null) "tls_server_name ${site.tlsServerName}"}
                }
              }''
          }
          ${site.extraConfig}
        }
      '';
    in
    {
      options.minerva.edge = {
        domain = lib.mkOption {
          type = lib.types.str;
          example = "example.org";
          description = "The zone the wildcard certificate and every site live under.";
        };
        acmeEmail = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Contact address for the ACME account.";
        };
        cloudflareTokenFile = lib.mkOption {
          type = lib.types.str;
          example = "/var/lib/minerva/cloudflare-dns-token";
          description = "Runtime path of a file holding only the scoped Cloudflare API token. Never a Nix store path.";
        };
        apexResponse = lib.mkOption {
          type = lib.types.lines;
          default = "respond 404";
          description = "Caddyfile directives for the bare domain.";
        };
        sites = lib.mkOption {
          default = { };
          description = "Subdomain sites, keyed by the label in front of the domain.";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                upstream = lib.mkOption {
                  type = lib.types.str;
                  description = "Where to proxy, e.g. http://192.0.2.20:9000 or https://192.0.2.30:8006.";
                };
                tlsCaFile = lib.mkOption {
                  type = lib.types.nullOr lib.types.path;
                  default = null;
                  description = "CA bundle that signs the upstream's certificate (for an https upstream with a private CA).";
                };
                tlsServerName = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Name to validate the upstream certificate against, when it differs from the address.";
                };
                extraConfig = lib.mkOption {
                  type = lib.types.lines;
                  default = "";
                  description = "Extra directives inside this site's handle block.";
                };
              };
            }
          );
        };
      };

      config = {
        services.caddy = {
          enable = true;
          email = cfg.acmeEmail;
          # Caddy with the Cloudflare DNS provider, built from a hash-pinned
          # source. Refresh the hash with `nix build` after changing the version.
          package = pkgs.caddy.withPlugins {
            plugins = [ "github.com/caddy-dns/cloudflare@v0.2.1" ];
            hash = "sha256-ijDzBvNhN6kVRNkjbLMHRh1K8qP7kLCiirQJLwkzrCc=";
          };
          # Access logs go to the journal: the module's default file name would
          # be derived from the wildcard address.
          virtualHosts."*.${cfg.domain}, ${cfg.domain}" = {
            logFormat = "output stderr";
            extraConfig = ''
              tls {
                dns cloudflare {file.${credential}}
              }
              ${lib.concatStrings (lib.mapAttrsToList siteBlock cfg.sites)}
              @apex host ${cfg.domain}
              handle @apex {
                ${cfg.apexResponse}
              }
              handle {
                respond 404
              }
            '';
          };
        };

        systemd.services.caddy.serviceConfig.LoadCredential =
          "cloudflare-dns-token:${cfg.cloudflareTokenFile}";

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
      };
    };
}
