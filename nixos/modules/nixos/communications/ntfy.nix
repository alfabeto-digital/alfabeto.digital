{ inputs, ... }: {
  flake.nixosModules.ntfy = { config, lib, pkgs, cfg, exchangePath, ... }: {

    systemd.tmpfiles.rules = [
      "d ${exchangePath}/ntfy             0750 ntfy-sh ntfy-sh - -"
      "d ${exchangePath}/ntfy/attachments 0750 ntfy-sh ntfy-sh - -"
    ];

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
