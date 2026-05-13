{ inputs, ... }: {
  flake.nixosModules.vaultwarden = { config, lib, pkgs, cfg, storagePath, ... }: {

    systemd.services.vaultwarden = {
      after    = [ "mnt-storage-virgilio.mount" ];
      requires = [ "mnt-storage-virgilio.mount" ];
      serviceConfig.ReadWritePaths = [ "${storagePath}/exchange/vaultwarden" ];
    };

    services.vaultwarden = {
      enable = true;
      config = {
        DOMAIN         = "https://warden.${cfg.domain}";
        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_PORT    = cfg.vaultwarden_port;
        DATA_FOLDER    = "${storagePath}/exchange/vaultwarden";
      };
    };
  };
}
