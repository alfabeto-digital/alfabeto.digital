{ inputs, ... }: {
  flake.nixosModules.database = { config, lib, pkgs, cfg, dataPath, ... }:
  let
    dbMountUnit =
      builtins.replaceStrings ["/"] ["-"]
        (lib.removePrefix "/" "${cfg.data_mount_point}/${cfg.db_name}")
      + ".mount";
  in
  {
    systemd.services.postgresql = {
      after    = [ dbMountUnit ];
      requires = [ dbMountUnit ];
    };

    services.postgresql = {
      enable          = true;
      dataDir         = "${dataPath}/postgresql";
      ensureDatabases = [ cfg.db_name ];
      ensureUsers     = [{ name = cfg.db_username; }];
      authentication  = lib.mkForce ''
        local all      postgres       peer
        local dendrite dendrite       peer
        local authelia authelia-main  peer
        local stalwart stalwart-mail  peer
        local all      all            md5
        host  stalwart stalwart-mail  127.0.0.1/32 trust
        host  all      all            127.0.0.1/32 md5
      '';
    };

    systemd.services.postgresql-set-password = {
      description = "Set PostgreSQL user password from sops secret";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "postgresql.service" ];
      requires    = [ "postgresql.service" ];
      serviceConfig = {
        Type            = "oneshot";
        User            = "postgres";
        RemainAfterExit = true;
      };
      script = ''
        DB_PASSWORD=$(cat ${config.sops.secrets.db_password.path})
        for i in $(seq 1 30); do
          ROLE=$(${config.services.postgresql.package}/bin/psql -tAc \
            "SELECT 1 FROM pg_roles WHERE rolname='${cfg.db_username}'")
          if [ "$ROLE" = "1" ]; then break; fi
          echo "Waiting for role ${cfg.db_username} to be created... ($i/30)"
          sleep 2
        done
        ${config.services.postgresql.package}/bin/psql -c \
          "ALTER USER \"${cfg.db_username}\" WITH PASSWORD '$DB_PASSWORD';"
        ${config.services.postgresql.package}/bin/psql -c \
          "GRANT ALL PRIVILEGES ON DATABASE \"${cfg.db_name}\" TO \"${cfg.db_username}\";"
      '';
    };
  };
}
