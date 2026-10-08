# split-dns — answer the edge's own names locally, so private clients skip the
# public path.
#
# A CoreDNS server for one zone. Every name in the zone (apex and any label
# under it) answers with the address that suits the asking client: each
# `views` entry matches client CIDRs and names the address to hand back, so a
# tailnet client gets the edge's tailnet IP while a LAN client gets its LAN IP.
# A client matching no view gets no answer (REFUSED) and keeps using public
# DNS. AAAA is answered empty, so clients never fall back to a public IPv6
# path. Nothing outside the zone is served: this is not a resolver.
#
# Point clients at it with the tailnet's split DNS (zone -> this host's
# tailnet IP), or a LAN DHCP option. `extraRecords` adds names that exist only
# here, e.g. SSH jump targets that must never be public.
#
# Example (in a host record's `nixos`):
#   minerva.splitDns = {
#     zone = "example.org";
#     interfaces = [ "tailscale0" ];
#     views.tailnet = { cidrs = [ "100.64.0.0/10" ]; address = "100.64.0.10"; };
#   };
{
  nixos =
    { config, lib, ... }:
    let
      cfg = config.minerva.splitDns;
      zoneRe = lib.replaceStrings [ "." ] [ "\\." ] cfg.zone;

      # One server block per view: CoreDNS picks the first whose `view`
      # expression matches the client.
      viewBlock = name: v: ''
        ${cfg.zone}:53 {
          bind ${lib.concatStringsSep " " cfg.interfaces}
          view ${name} {
            expr ${lib.concatMapStringsSep " || " (c: "incidr(client_ip(), '${c}')") v.cidrs}
          }
          ${lib.optionalString (cfg.extraRecords != { }) ''
            hosts {
              ${lib.concatStrings (lib.mapAttrsToList (n: a: "${a} ${n}.${cfg.zone}\n") cfg.extraRecords)}
              fallthrough
            }
          ''}
          template IN A ${cfg.zone} {
            match "^(.+\.)?${zoneRe}\.$"
            answer "{{ .Name }} 60 IN A ${v.address}"
          }
          template IN AAAA ${cfg.zone} {
            match "^(.+\.)?${zoneRe}\.$"
            rcode NOERROR
          }
          errors
        }
      '';
    in
    {
      options.minerva.splitDns = {
        zone = lib.mkOption {
          type = lib.types.str;
          description = "The zone answered locally.";
        };
        interfaces = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          example = [ "tailscale0" ];
          description = "Interfaces CoreDNS listens on; port 53 is opened on exactly these.";
        };
        views = lib.mkOption {
          description = "Client networks and the address each one is given.";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                cidrs = lib.mkOption { type = lib.types.listOf lib.types.str; };
                address = lib.mkOption { type = lib.types.str; };
              };
            }
          );
        };
        extraRecords = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          example = {
            jump = "100.64.0.10";
          };
          description = "Local-only names (label -> address), answered the same in every view.";
        };
      };

      config = {
        services.coredns = {
          enable = true;
          config = ''
            ${lib.concatStrings (lib.mapAttrsToList viewBlock cfg.views)}
            ${cfg.zone}:53 {
              bind ${lib.concatStringsSep " " cfg.interfaces}
              acl {
                block
              }
            }
          '';
        };

        # An interface address (e.g. tailscale0's) may appear after boot.
        systemd.services.coredns = {
          after = [ "tailscaled.service" ];
          wants = [ "tailscaled.service" ];
          serviceConfig = {
            Restart = lib.mkForce "always";
            RestartSec = 5;
          };
        };

        networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: {
          allowedUDPPorts = [ 53 ];
          allowedTCPPorts = [ 53 ];
        });
      };
    };
}
