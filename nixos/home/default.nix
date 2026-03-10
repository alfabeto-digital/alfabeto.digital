{ pkgs, admin_username, ... }: {

  home.username      = admin_username;
  home.homeDirectory = "/home/${admin_username}";
  home.stateVersion  = (import ../config.nix).nixos_state_version;

  home.packages = with pkgs; [
    neovim
    git
  ];

  home.file = {
    ".config/nvim/init.vim".text = ''
      set number
      syntax enable
    '';
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ll           = "ls -la";
      update-nixos = "sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)";
      history      = "history | tac | fzf";
    };
  };
}