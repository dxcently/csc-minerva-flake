{ lib, ... }:
{
  # The host record names itself (networking.hostName) and its address.
  networking.firewall.enable = lib.mkDefault true;
  networking.useDHCP = lib.mkDefault true;
}
