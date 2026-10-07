# tailscale — the Tailscale node, and optionally a subnet router.
#
# Enrollment is interactive (`tailscale up`, then the browser link): there is
# no auth key in this tree, so no secret in the store or the repo. Advertised
# routes still need approval in the Tailscale admin console.
#
# Example (in a host record's `nixos`):
#   minerva.tailscale.advertiseRoutes = [ "192.0.2.10/32" ];
#   minerva.tailscale.operator = "admin";
{
  nixos =
    { config, lib, ... }:
    let
      cfg = config.minerva.tailscale;
      advertising = cfg.advertiseRoutes != [ ];
    in
    {
      options.minerva.tailscale = {
        advertiseRoutes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "192.0.2.10/32" ];
          description = ''
            Prefixes this node advertises as a subnet router. Keep them as
            narrow as the job needs (a single /32, never a whole LAN).
          '';
        };
        acceptRoutes = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Accept routes advertised by other nodes. Leave off on a node that is already on the advertised network.";
        };
        operator = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Local user allowed to run the tailscale CLI without sudo.";
        };
      };

      config = {
        services.tailscale = {
          enable = true;
          openFirewall = true;
          # "server" turns on IP forwarding for subnet routing; "client" only
          # the reverse-path settings for accepting routes; "both" does both.
          useRoutingFeatures =
            if advertising && cfg.acceptRoutes then
              "both"
            else if advertising then
              "server"
            else if cfg.acceptRoutes then
              "client"
            else
              "none";
          extraSetFlags =
            lib.optional (cfg.operator != null) "--operator=${cfg.operator}"
            ++ lib.optional advertising "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"
            ++ [ "--accept-routes=${lib.boolToString cfg.acceptRoutes}" ];
        };
      };
    };
}
