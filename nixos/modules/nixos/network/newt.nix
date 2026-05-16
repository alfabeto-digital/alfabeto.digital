{ inputs, ... }: {
  flake.nixosModules.newt = { config, lib, pkgs, cfg, ... }: {

    systemd.services.newt-env-setup = {
      description = "Write Newt tunnel environment file";
      wantedBy    = [ "newt.service" ];
      before      = [ "newt.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = "${pkgs.writeShellScript "newt-env-setup" ''
          umask 077
          printf 'NEWT_ID=' > /run/newt-env
          cat ${config.sops.secrets.newt_client_id.path} >> /run/newt-env
          printf '\nNEWT_SECRET=' >> /run/newt-env
          cat ${config.sops.secrets.newt_client_secret.path} >> /run/newt-env
          printf '\nNEWT_SERVER=' >> /run/newt-env
          cat ${config.sops.secrets.newt_server_url.path} >> /run/newt-env
          printf '\n' >> /run/newt-env
          chmod 600 /run/newt-env
        ''}";
      };
    };

    systemd.services.newt = {
      description = "Newt tunnel client";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "network-online.target" "newt-env-setup.service" ];
      wants       = [ "network-online.target" ];
      requires    = [ "newt-env-setup.service" ];
      serviceConfig = {
        Restart        = "always";
        RestartSec     = "5s";
        EnvironmentFile = "/run/newt-env";
        ExecStart      = "${pkgs.fosrl-newt}/bin/newt";
      };
    };

    sops.secrets.newt_client_id     = {};
    sops.secrets.newt_client_secret = {};
    sops.secrets.newt_server_url    = {};
  };
}
