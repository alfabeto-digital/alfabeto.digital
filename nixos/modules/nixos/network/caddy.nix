{ inputs, ... }: {
  flake.nixosModules.caddy = { config, lib, pkgs, cfg, ... }: {

    services.caddy = {
      enable = true;
      email  = cfg.email_acme;
      globalConfig = lib.optionalString (cfg.tunnel_type == "cloudflare") ''
        auto_https off
      '';

      virtualHosts = {
        "${cfg.domain}" = {
          extraConfig = ''
            root * /var/www/${cfg.domain}
            handle /assets/library/* {
              file_server browse
            }
            file_server
          '';
        };

        "warden.${cfg.domain}" = {
          extraConfig = ''
            reverse_proxy localhost:${toString cfg.vaultwarden_port}
          '';
        };

        "sync.${cfg.domain}" = {
          extraConfig = ''
            forward_auth 127.0.0.1:${toString cfg.authelia_port} {
              uri /api/authz/forward-auth
              copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
            }
            reverse_proxy localhost:${toString cfg.syncthing_port} {
              header_up -Authorization
            }
          '';
        };

        "auth.${cfg.domain}" = {
          extraConfig = ''
            reverse_proxy localhost:${toString cfg.authelia_port}
          '';
        };

        "matrix.${cfg.domain}" = {
          extraConfig = ''
            reverse_proxy localhost:${toString cfg.dendrite_port}
          '';
        };

        "ntfy.${cfg.domain}" = {
          extraConfig = ''
            forward_auth 127.0.0.1:${toString cfg.authelia_port} {
              uri /api/authz/forward-auth
              copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
            }
            reverse_proxy localhost:${toString cfg.ntfy_port}
          '';
        };

        "mail.${cfg.domain}" = {
          extraConfig = ''
            forward_auth 127.0.0.1:${toString cfg.authelia_port} {
              uri /api/authz/forward-auth
              copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
            }
            reverse_proxy localhost:${toString cfg.stalwart_port}
          '';
        };

        "adguard.${cfg.domain}" = {
          extraConfig = ''
            forward_auth 127.0.0.1:${toString cfg.authelia_port} {
              uri /api/authz/forward-auth
              copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
            }
            reverse_proxy localhost:${toString cfg.adguard_port}
          '';
        };
      };
    };
  };
}
