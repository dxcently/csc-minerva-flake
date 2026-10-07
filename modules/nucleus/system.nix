{ lib, pkgs, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
    # Remote deploys (`nixos-rebuild --target-host`) copy closures as the admin
    # user; wheel already has passwordless sudo, so this grants nothing new.
    trusted-users = [ "@wheel" ];
  };

  time.timeZone = lib.mkDefault "America/New_York";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  environment.systemPackages = with pkgs; [
    curl
    git
    jq
    vim
  ];

  # system.stateVersion is deliberately NOT set here: it belongs to each
  # machine's first install and is stated in its host record.
}
