{ inputs, ... }: {
  flake.nixosModules.adguard = { config, lib, pkgs, cfg, exchangePath, ... }: {

    systemd.tmpfiles.rules = [
      "d ${exchangePath}/adguard 0750 adguardhome adguardhome - -"
    ];

    services.adguardhome = {
      enable          = true;
      mutableSettings = true;
      host            = "127.0.0.1";
      port            = cfg.adguard_port;
      settings = {
        dns = {
          bind_hosts      = [ "0.0.0.0" ];
          port            = 53;
          upstream_dns    = [
            "https://dns.quad9.net/dns-query"
            "https://cloudflare-dns.com/dns-query"
          ];
          bootstrap_dns   = [ "9.9.9.9" "1.1.1.1" ];
          cache_size      = 4194304;
        };
      };
    };

    systemd.services.adguardhome.serviceConfig.ExecStart = lib.mkForce
      "${pkgs.adguardhome}/bin/AdGuardHome --no-check-update -w ${exchangePath}/adguard";

    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];
  };
}
