{ inputs, ... }: {
  flake.nixosModules.caddy = { config, lib, pkgs, cfg, ... }: {

    services.caddy = {
      enable = true;
      email  = cfg.email_acme;

      virtualHosts = {
        "${cfg.domain}" = {
          extraConfig = ''
            root * /var/www/${cfg.domain}
            file_server
          '';
        };

        # Localhost-only HTTP endpoint for the Cloudflare tunnel.
        # cloudflared uses --network host and connects to 127.0.0.1:domain_tunnel_port.
        # Caddy's public vhost redirects HTTP→HTTPS, causing a TLS mismatch inside
        # cloudflared; this plain-HTTP block on a separate port avoids that.
        "http://:${toString cfg.domain_tunnel_port}" = {
          extraConfig = ''
            bind 127.0.0.1
            root * /var/www/${cfg.domain}
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
            reverse_proxy localhost:${toString cfg.syncthing_port}
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
            forward_auth localhost:${toString cfg.authelia_port} {
              uri /api/authz/forward-auth
              copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
            }
            reverse_proxy localhost:${toString cfg.ntfy_port}
          '';
        };

        "mail.${cfg.domain}" = {
          extraConfig = ''
            forward_auth localhost:${toString cfg.authelia_port} {
              uri /api/authz/forward-auth
              copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
            }
            reverse_proxy localhost:${toString cfg.stalwart_port}
          '';
        };

        "adguard.${cfg.domain}" = {
          extraConfig = ''
            forward_auth localhost:${toString cfg.authelia_port} {
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
