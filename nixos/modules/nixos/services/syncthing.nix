{ inputs, ... }: {
  flake.nixosModules.syncthing = { config, lib, pkgs, cfg, storagePath, ... }: {

    services.syncthing = {
      enable     = true;
      user       = cfg.syncthing_username;
      group      = "storage";
      dataDir    = "${storagePath}/helios";
      configDir  = "${storagePath}/exchange/syncthing";
      guiAddress = "0.0.0.0:${toString cfg.syncthing_port}";
    };
  };
}
