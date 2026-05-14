{ inputs, ... }: {
  flake.nixosModules.ntfy = { config, lib, pkgs, cfg, exchangePath, ... }: {

    users.users.ntfy-sh = { isSystemUser = true; group = "ntfy-sh"; };
    users.groups.ntfy-sh = {};

    systemd.tmpfiles.rules = [
      "d ${exchangePath}/ntfy             0750 ntfy-sh ntfy-sh - -"
      "d ${exchangePath}/ntfy/attachments 0750 ntfy-sh ntfy-sh - -"
    ];

    systemd.services.ntfy-sh = {
      serviceConfig = {
        DynamicUser    = lib.mkForce false;
        User           = lib.mkForce "ntfy-sh";
        Group          = lib.mkForce "ntfy-sh";
        ProtectHome    = lib.mkForce "no";
        ReadWritePaths = [ "${exchangePath}/ntfy" ];
      };
    };

    services.ntfy-sh = {
      enable = true;
      settings = {
        base-url             = "https://ntfy.${cfg.domain}";
        listen-http          = "127.0.0.1:${toString cfg.ntfy_port}";
        behind-proxy         = true;
        cache-file           = "${exchangePath}/ntfy/cache.db";
        cache-duration       = "24h";
        attachment-cache-dir = "${exchangePath}/ntfy/attachments";
        attachment-total-size = "2G";
        attachment-file-size  = "15M";
      };
    };
  };
}
