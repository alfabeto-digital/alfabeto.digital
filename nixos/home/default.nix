{ pkgs, admin_username, ... }: {
  home.username = admin_username;
  home.homeDirectory = "/home/${admin_username}";
  home.stateVersion = "24.11";

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
      ll = "ls -la";
      update-nixos = "sudo nixos-rebuild switch --flake .#$(hostname)";
      history = "history | tac | fzf";
    };
  };
}