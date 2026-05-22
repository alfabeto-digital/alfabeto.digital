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

    systemd.services.stalwart-env-setup = {
      description = "Write Stalwart admin environment file";
      wantedBy    = [ "stalwart-mail.service" ];
      before      = [ "stalwart-mail.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = "${pkgs.writeShellScript "stalwart-env-setup" ''
          pw=$(tr -d '[:space:]' < ${config.sops.secrets.stalwart_admin_password.path})
          printf 'STALWART_RECOVERY_ADMIN=admin:%s\nSTALWART_ADMIN_PASSWORD=%s\n' "$pw" "$pw" > /run/stalwart-env
          chmod 600 /run/stalwart-env
        ''}";
      };
    };

    systemd.services.stalwart-mail = {
      after    = [ "postgresql-stalwart-setup.service" "stalwart-env-setup.service" ];
      requires = [ "postgresql-stalwart-setup.service" ];
      serviceConfig = {
        ProtectHome     = lib.mkForce "no";
        ReadWritePaths  = [ "${exchangePath}/stalwart" ];
        ReadOnlyPaths   = [ "/run/secrets" ];
        EnvironmentFile = "/run/stalwart-env";
      };
    };

    systemd.services.stalwart-bootstrap = {
      description = "Create initial Stalwart accounts";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "stalwart-mail.service" ];
      wants       = [ "stalwart-mail.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        EnvironmentFile = "/run/stalwart-env";
        ExecStart       = "${pkgs.writeShellScript "stalwart-bootstrap" ''
          url="http://127.0.0.1:${toString cfg.stalwart_port}"
          auth="admin:$STALWART_ADMIN_PASSWORD"

          for i in $(seq 1 30); do
            code=$(${pkgs.curl}/bin/curl -s -o /dev/null -w "%{http_code}" \
              -u "$auth" "$url/api/principal" 2>/dev/null)
            [ "$code" = "200" ] && break
            sleep 1
          done

          create_user() {
            local name=$1 email=$2 pw_file=$3
            local pw response
            pw=$(tr -d '[:space:]' < "$pw_file")
            response=$(${pkgs.curl}/bin/curl -s -u "$auth" "$url/api/principal/$name")
            if echo "$response" | grep -q '"error"'; then
              echo "Creating $name"
              ${pkgs.curl}/bin/curl -sf -X POST "$url/api/principal" \
                -u "$auth" \
                -H "Content-Type: application/json" \
                -d "{\"name\":\"$name\",\"class\":\"individual\",\"secrets\":[\"$pw\"],\"emails\":[\"$email\"]}"
            else
              echo "$name already exists, skipping"
            fi
          }

          create_user "${cfg.authelia_smtp_username}" \
            "${cfg.authelia_smtp_username}@${cfg.domain}" \
            "${config.sops.secrets.authelia_smtp_password.path}"

          create_user "${cfg.admin_username}" \
            "${cfg.admin_username}@${cfg.domain}" \
            "${config.sops.secrets.admin_mail_password.path}"
        ''}";
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
          directory = "internal";
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
        directory.internal = {
          type  = "internal";
          store = "db";
        };
        authentication.fallback-admin = {
          user   = "admin";
          secret = "%{env:STALWART_ADMIN_PASSWORD}%";
        };

        management.secret = "%{env:STALWART_ADMIN_PASSWORD}%";

        tracer.stdout = {
          type   = "stdout";
          level  = "warn";
          enable = true;
        };
      };
    };

    sops.secrets.authelia_smtp_password  = { mode = "0444"; };
    sops.secrets.stalwart_admin_password = { owner = "stalwart-mail"; mode = "0400"; };
    sops.secrets.admin_mail_password     = {};

    networking.firewall.allowedTCPPorts = [ 25 465 143 993 ];
  };
}
