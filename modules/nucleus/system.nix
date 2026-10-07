{ lib, pkgs, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
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
