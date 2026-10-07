# dev-tools — what an operator wants on the box when logged in over SSH:
# search, inspect, edit, and handle the repo's own secrets and formatting.
{
  nixos =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        age
        bat
        btop
        dig
        fd
        jq
        nixfmt
        ripgrep
        sops
        ssh-to-age
        tmux
        tree
      ];

      programs.git.enable = true;
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };
    };
}
