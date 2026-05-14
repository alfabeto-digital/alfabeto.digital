{ inputs, ... }: {
  flake.nixosModules.syncthing = { config, lib, pkgs, cfg, storagePath, exchangePath, ... }: {

    systemd.tmpfiles.rules = [
      "d ${exchangePath}/syncthing 0750 syncthing syncthing - -"
    ];

    services.syncthing = {
      enable     = true;
      user       = cfg.syncthing_username;
      group      = "storage";
      dataDir    = "${storagePath}/helios";
      configDir  = "${exchangePath}/syncthing";
      guiAddress = "0.0.0.0:${toString cfg.syncthing_port}";
    };
  };
}
