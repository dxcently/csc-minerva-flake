# modules/nucleus/default.nix — every unconditional core file, one line each.
{
  imports = [
    ./networking.nix
    ./openssh.nix
    ./system.nix
  ];
}
