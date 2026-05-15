{ inputs, ... }: {
  flake.nixosModules.authelia = { config, lib, pkgs, cfg, exchangePath, ... }: {

    # services.authelia uses DynamicUser — declare explicitly so sops-nix resolves owner at eval time.
    users.users.authelia-main = { isSystemUser = true; group = "authelia-main"; };
    users.groups.authelia-main = {};

    systemd.tmpfiles.rules = [
      "d ${exchangePath}/authelia 0750 authelia-main authelia-main - -"
    ];

    # Secrets must be added to secrets.yaml before deploying:
    #   authelia_jwt_secret, authelia_session_secret, authelia_storage_key, authelia_users_file
    sops.secrets = {
      authelia_jwt_secret     = { owner = "authelia-main"; mode = "0400"; };
      authelia_session_secret = { owner = "authelia-main"; mode = "0400"; };
      authelia_storage_key    = { owner = "authelia-main"; mode = "0400"; };
      authelia_users_file     = { owner = "authelia-main"; mode = "0400"; };
      authelia_smtp_password  = { mode = "0444"; };
    };

    services.postgresql.ensureDatabases = [ "authelia" ];
    services.postgresql.ensureUsers     = [{ name = "authelia-main"; ensureClauses.login = true; }];

    systemd.services.postgresql-authelia-setup = {
      description = "Grant authelia-main privileges on authelia database";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "postgresql.service" ];
      requires    = [ "postgresql.service" ];
      serviceConfig = {
        Type            = "oneshot";
        User            = "postgres";
        RemainAfterExit = true;
      };
      script = ''
        set -e
        ${config.services.postgresql.package}/bin/psql -c \
          "GRANT ALL PRIVILEGES ON DATABASE authelia TO \"authelia-main\";"
        ${config.services.postgresql.package}/bin/psql -d authelia -c \
          "GRANT ALL ON SCHEMA public TO \"authelia-main\";"
      '';
    };

    systemd.services.authelia-main = {
      after    = [ "postgresql-authelia-setup.service" ];
      requires = [ "postgresql-authelia-setup.service" ];
      environment = {
        AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.sops.secrets.authelia_smtp_password.path;
      };
      serviceConfig = {
        ProtectHome    = lib.mkForce "no";
        ReadWritePaths = [ "${exchangePath}/authelia" ];
      };
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

        storage.postgres = {
          address  = "unix:///run/postgresql";
          database = "authelia";
          username = "authelia-main";
        };

        session = {
          name    = "authelia_session";
          cookies = [{
            domain       = cfg.domain;
            authelia_url = "https://auth.${cfg.domain}";
          }];
        };

        access_control = {
          default_policy = "two_factor";
          rules          = [
            { domain = "auth.${cfg.domain}"; policy = "bypass"; }
          ];
        };

        authentication_backend.file = {
          path = config.sops.secrets.authelia_users_file.path;
        };

        notifier.smtp = {
          address         = "smtp://127.0.0.1:587";
          sender          = "Authelia <${cfg.authelia_smtp_username}@${cfg.domain}>";
          username        = cfg.authelia_smtp_username;
          tls.skip_verify = true;
        };
      };
    };
  };
}
