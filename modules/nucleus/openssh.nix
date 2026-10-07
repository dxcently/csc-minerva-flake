{ ... }:
{
  # Key-only, no root. Authorized keys belong to the user definition or the
  # host record, never to this public tree.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
