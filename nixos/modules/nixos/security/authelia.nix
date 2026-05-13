{ inputs, ... }: {
  flake.nixosModules.authelia = { config, lib, pkgs, cfg, storagePath, ... }: {

    systemd.tmpfiles.rules = [
      "d ${storagePath}/exchange/authelia              0750 authelia-main authelia-main - -"
      "d ${storagePath}/exchange/authelia/attachments  0750 authelia-main authelia-main - -"
    ];

    # Secrets must be added to secrets.yaml before deploying:
    #   authelia_jwt_secret, authelia_session_secret, authelia_storage_key
    sops.secrets = {
      authelia_jwt_secret     = { owner = "authelia-main"; mode = "0400"; };
      authelia_session_secret = { owner = "authelia-main"; mode = "0400"; };
      authelia_storage_key    = { owner = "authelia-main"; mode = "0400"; };
    };

    services.authelia.instances.main = {
      enable = true;
      secrets = {
        jwtSecretFile            = config.sops.secrets.authelia_jwt_secret.path;
        sessionSecretFile        = config.sops.secrets.authelia_session_secret.path;
        storageEncryptionKeyFile = config.sops.secrets.authelia_storage_key.path;
      };
      settings = {
        theme              = "dark";
        default_2fa_method = "totp";
        log.level          = "info";

        server.address = "tcp://127.0.0.1:${toString cfg.authelia_port}";

        storage.local.path = "${storagePath}/exchange/authelia/db.sqlite3";

        session = {
          name    = "authelia_session";
          cookies = [{
            domain       = cfg.domain;
            authelia_url = "https://auth.${cfg.domain}";
          }];
        };

        access_control = {
          default_policy = "two_factor";
          rules          = [];
        };

        authentication_backend.file = {
          path = "${storagePath}/exchange/authelia/users.yml";
        };

        notifier.filesystem = {
          filename = "${storagePath}/exchange/authelia/notifications.txt";
        };
      };
    };
  };
}
