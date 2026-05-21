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

  programs.bash.enable = true;
}
