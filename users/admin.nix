# admin — the one account every Minerva server carries. No password and no
# keys here: this tree is public. The host record (or a private overlay) adds
#   users.users.admin.openssh.authorizedKeys.keys = [ "ssh-ed25519 ..." ];
{
  nixos =
    { ... }:
    {
      users.users.admin = {
        isNormalUser = true;
        description = "Minerva administrator";
        extraGroups = [ "wheel" ];
        hashedPassword = "!"; # no password login; key-only over SSH
      };
      security.sudo.wheelNeedsPassword = false;
    };
}
