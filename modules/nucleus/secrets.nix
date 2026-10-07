# secrets — sops-nix: encrypted secrets decrypted on the host at activation.
#
# The host decrypts with its own SSH ed25519 host key (converted to age by
# sops-nix), so there is no separate key to provision. To create a secrets file:
#   1. read the host's age recipient:  ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
#   2. add it (and your own) to a .sops.yaml creation rule
#   3. sops secrets/<host>.yaml        (keys below, one value each)
#
# Decrypted values appear under /run/secrets (a tmpfs), never in the Nix store.
# Wire them in the host record, e.g.
#   minerva.edge.cloudflareTokenFile = config.sops.secrets."cloudflare-dns-token".path;
#   minerva.tailscale.authKeyFile    = config.sops.secrets."tailscale-authkey".path;
{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.minerva.secrets;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.minerva.secrets = {
    file = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "The encrypted sops file for this host. Null means the host has no secrets.";
    };
    names = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "cloudflare-dns-token"
        "tailscale-authkey"
      ];
      description = "Keys in the file to expose under /run/secrets.";
    };
  };

  config = lib.mkIf (cfg.file != null) {
    sops = {
      defaultSopsFile = cfg.file;
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      secrets = lib.genAttrs cfg.names (_: { });
    };
  };
}
