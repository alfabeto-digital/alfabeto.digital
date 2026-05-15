{ inputs, ... }: {
  flake.nixosModules.stalwart = { config, lib, pkgs, cfg, exchangePath, ... }: {

    systemd.tmpfiles.rules = [
      "d ${exchangePath}/stalwart       0750 stalwart-mail stalwart-mail - -"
      "d ${exchangePath}/stalwart/blobs 0750 stalwart-mail stalwart-mail - -"
    ];

    services.postgresql.ensureDatabases = [ "stalwart" ];
    services.postgresql.ensureUsers     = [{ name = "stalwart-mail"; ensureClauses.login = true; }];

    systemd.services.postgresql-stalwart-setup = {
      description = "Grant stalwart-mail privileges on stalwart database";
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
          "GRANT ALL PRIVILEGES ON DATABASE stalwart TO \"stalwart-mail\";"
        ${config.services.postgresql.package}/bin/psql -d stalwart -c \
          "GRANT ALL ON SCHEMA public TO \"stalwart-mail\";"
      '';
    };

    systemd.services.stalwart-mail = {
      after    = [ "postgresql-stalwart-setup.service" ];
      requires = [ "postgresql-stalwart-setup.service" ];
      serviceConfig = {
        ProtectHome    = lib.mkForce "no";
        ReadWritePaths = [ "${exchangePath}/stalwart" ];
      };
    };

    services.stalwart-mail = {
      enable   = true;
      settings = {
        server = {
          hostname = "mail.${cfg.domain}";
          listener = {
            smtp = {
              bind    = [ "0.0.0.0:25" ];
              protocol = "smtp";
            };
            smtps = {
              bind    = [ "0.0.0.0:465" ];
              protocol = "smtp";
              tls.implicit = true;
            };
            imap = {
              bind    = [ "0.0.0.0:143" ];
              protocol = "imap";
            };
            imaps = {
              bind    = [ "0.0.0.0:993" ];
              protocol = "imap";
              tls.implicit = true;
            };
            submission = {
              bind     = [ "127.0.0.1:587" ];
              protocol = "smtp";
            };
            http = {
              bind     = [ "127.0.0.1:${toString cfg.stalwart_port}" ];
              protocol = "http";
            };
          };
        };
        "session.auth.allow-plain-text" = true;
        storage = {
          data      = "db";
          fts       = "db";
          blob      = "blobs";
          lookup    = "db";
          directory = "memory";
        };
        store.db = {
          type     = "postgresql";
          host     = "127.0.0.1";
          port     = 5432;
          database = "stalwart";
          user     = "stalwart-mail";
        };
        store.blobs = {
          type = "fs";
          path = "${exchangePath}/stalwart/blobs";
        };
        directory.memory = {
          type       = "memory";
          principals = [{
            name   = "authelia";
            type   = "individual";
            secret = "%{file:${config.sops.secrets.authelia_smtp_password.path}}%";
            email  = [ "authelia@alfabeto.digital" ];
          }];
        };
        management.secret = "%{file:${config.sops.secrets.stalwart_admin_password.path}}%";

        tracer.stdout = {
          type   = "stdout";
          level  = "warn";
          enable = true;
        };
      };
    };

    sops.secrets.authelia_smtp_password  = { mode = "0444"; };
    sops.secrets.stalwart_admin_password = { owner = "stalwart-mail"; mode = "0400"; };

    networking.firewall.allowedTCPPorts = [ 25 465 143 993 ];
  };
}
