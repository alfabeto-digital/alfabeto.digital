{ inputs, self, ... }: {
  flake.nixosModules.admin = { config, lib, pkgs, cfg, ... }: {
    home-manager = {
      useGlobalPkgs    = true;
      useUserPackages  = true;
      extraSpecialArgs = { inherit cfg; admin_username = cfg.admin_username; };
      users.${cfg.admin_username} = import ../../home;
    };
  };
}
