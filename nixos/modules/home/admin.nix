{ inputs, ... }: {
  flake.nixosModules.admin = { config, lib, pkgs, cfg, ... }:
  let
    # Shared home-manager config applied to both root and the admin user.
    # Admin inherits everything root has; extend admin's section for user-only additions.
    commonHome = { pkgs, ... }: {
      home.packages = with pkgs; [ neovim git ];

      home.file.".config/nvim/init.vim".text = ''
        set number
        syntax enable
      '';

      programs.bash = {
        enable = true;
        shellAliases = {
          ll           = "ls -la";
          update-nixos = "sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)";
          history      = "history | tac | fzf";
        };
      };
    };
  in {
    home-manager = {
      useGlobalPkgs   = true;
      useUserPackages = true;

      users.root = { ... }: {
        imports = [ commonHome ];
        home.username      = "root";
        home.homeDirectory = "/root";
        home.stateVersion  = cfg.nixos_state_version;
      };

      users.${cfg.admin_username} = { ... }: {
        imports = [ commonHome ];
        home.username      = cfg.admin_username;
        home.homeDirectory = "/home/${cfg.admin_username}";
        home.stateVersion  = cfg.nixos_state_version;
      };
    };
  };
}
