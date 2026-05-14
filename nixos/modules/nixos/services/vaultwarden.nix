{ inputs, ... }: {
  flake.nixosModules.vaultwarden = { config, lib, pkgs, cfg, exchangePath, ... }: {

    systemd.tmpfiles.rules = [
      "d ${exchangePath}/vaultwarden 0750 vaultwarden vaultwarden - -"
    ];

    systemd.services.vaultwarden = {
      serviceConfig = {
        ReadWritePaths = [ "${exchangePath}/vaultwarden" ];
        ProtectHome    = "no";
      };
    };

    services.vaultwarden = {
      enable = true;
      config = {
        DOMAIN         = "https://warden.${cfg.domain}";
        ROCKET_ADDRESS = "0.0.0.0";
        ROCKET_PORT    = cfg.vaultwarden_port;
        DATA_FOLDER    = "${exchangePath}/vaultwarden";
      };
    };
  };
}
