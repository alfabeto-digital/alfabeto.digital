{ inputs, ... }: {
  flake.nixosModules.stalwart = { config, lib, pkgs, cfg, storagePath, ... }: {

    systemd.tmpfiles.rules = [
      "d ${storagePath}/exchange/stalwart 0750 stalwart-mail stalwart-mail - -"
    ];

    services.stalwart-mail = {
      enable   = true;
      settings = {
        server = {
          hostname = "mail.${cfg.domain}";
          listeners = {
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
            http = {
              bind     = [ "127.0.0.1:${toString cfg.stalwart_port}" ];
              protocol = "http";
            };
          };
        };
        storage = {
          data      = "rocksdb";
          fts       = "rocksdb";
          blob      = "rocksdb";
          lookup    = "rocksdb";
          directory = "memory";
        };
        store.rocksdb = {
          type = "rocksdb";
          path = "${storagePath}/exchange/stalwart";
          compression = "lz4";
        };
        directory.memory = {
          type = "memory";
          principals = [];
        };
        tracer.stdout = {
          type   = "stdout";
          level  = "warn";
          enable = true;
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ 25 465 143 993 ];
  };
}
