{ pkgs, cfg, admin_username, ... }: {

  home.username      = admin_username;
  home.homeDirectory = "/home/${admin_username}";
  home.stateVersion  = cfg.nixos_state_version;

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
      rebuild-nixos = "nixos-rebuild build  --flake /etc/nixos#$(hostname) --impure";
      switch-nixos  = "nixos-rebuild switch --flake /etc/nixos#$(hostname) --impure";
      history      = "history | tac | fzf";
    };
  };
}
