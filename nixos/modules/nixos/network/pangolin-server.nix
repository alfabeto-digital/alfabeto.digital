{ inputs, ... }: {
  flake.nixosModules.pangolin-server = { config, lib, pkgs, cfg, flakeDir, ... }: {

    # ------------------------------------------------------------------ #
    # Sops secret + env file — needed by both native and container modes  #
    # ------------------------------------------------------------------ #

    sops.secrets.gerbil_pangolin_token = {};

    systemd.services.gerbil-env-setup = {
      description = "Write Gerbil API token environment file";
      wantedBy    = [ "multi-user.target"
                      "gerbil.service"
                      "docker-gerbil.service"
                      "podman-gerbil.service" ];
      before      = [ "gerbil.service"
                      "docker-gerbil.service"
                      "podman-gerbil.service" ];
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
        ExecStart       = "${pkgs.writeShellScript "gerbil-env-setup" ''
          umask 077
          printf 'GERBIL_PANGOLIN_TOKEN=' > /run/gerbil-env
          cat ${config.sops.secrets.gerbil_pangolin_token.path} >> /run/gerbil-env
          printf '\n' >> /run/gerbil-env
          chmod 600 /run/gerbil-env
        ''}";
      };
    };

    # ------------------------------------------------------------------ #
    # Config files for Pangolin and Gerbil (used by all modes)            #
    # ------------------------------------------------------------------ #

    environment.etc."pangolin/config.yaml".text = ''
      app:
        log_level: "info"
        save_logs: false
        base_domain: "${cfg.domain}"

      server:
        external_port: 443
        internal_port: ${toString cfg.pangolin_port}
        session_cookie_secure: true

      traefik:
        cert_resolver: ""

      gerbil:
        start_port: 51820
        base_endpoint: "${cfg.vps_ip}"

      database:
        path: "/app/data/pangolin.db"
    '';

    environment.etc."gerbil/config.yaml".text = ''
      wg_interface: "wg0"
      wg_port: 51820
      pangolin_endpoint: "http://127.0.0.1:${toString cfg.pangolin_port}"
    '';

    # Traefik TCP-passthrough routes (used by both modes).
    # Update cfg.newt_peer_ip and rebuild after first Newt connection.
    environment.etc."traefik/dynamic/routes.toml".text = ''
      [tcp.routers]
        [tcp.routers.alfabeto-https]
          rule        = "HostSNIRegexp(`^(.+\\.)?${cfg.domain}$`)"
          entryPoints = ["websecure"]
          service     = "pangolin-tunnel"
          [tcp.routers.alfabeto-https.tls]
            passthrough = true

        [tcp.routers.alfabeto-http]
          rule        = "HostSNI(`*`)"
          entryPoints = ["web"]
          service     = "pangolin-tunnel-http"

      [tcp.services]
        [tcp.services.pangolin-tunnel.loadBalancer]
          [[tcp.services.pangolin-tunnel.loadBalancer.servers]]
            address = "${cfg.newt_peer_ip}:443"

        [tcp.services.pangolin-tunnel-http.loadBalancer]
          [[tcp.services.pangolin-tunnel-http.loadBalancer.servers]]
            address = "${cfg.newt_peer_ip}:80"
    '';

    # ------------------------------------------------------------------ #
    # FLAKE MODE — native NixOS services                                  #
    # ------------------------------------------------------------------ #

    # CVE-2025-55182: fosrl-pangolin is marked insecure in nixpkgs.
    # Verify/update version with: nix search nixpkgs fosrl-pangolin
    nixpkgs.config.permittedInsecurePackages =
      if cfg.container_runtime == "flake" then [ "pangolin-1.10.3" ]
      else [];

    services.traefik = lib.mkIf (cfg.container_runtime == "flake") {
      enable = true;
      staticConfigOptions = {
        entryPoints.web.address       = ":80";
        entryPoints.websecure.address = ":443";
        log.level = "INFO";
        providers.file = {
          directory = "/etc/traefik/dynamic";
          watch     = true;
        };
      };
    };

    systemd.services.pangolin = lib.mkIf (cfg.container_runtime == "flake") {
      description = "Pangolin tunnel server";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "network-online.target" ];
      wants       = [ "network-online.target" ];
      serviceConfig = {
        Restart    = "always";
        RestartSec = "5s";
        ExecStart  = "${pkgs.fosrl-pangolin}/bin/pangolin --config /etc/pangolin/config.yaml";
        StateDirectory = "pangolin";
      };
    };

    systemd.services.gerbil = lib.mkIf (cfg.container_runtime == "flake") {
      description = "Gerbil WireGuard manager";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "network-online.target" "pangolin.service" "gerbil-env-setup.service" ];
      wants       = [ "network-online.target" ];
      requires    = [ "gerbil-env-setup.service" ];
      serviceConfig = {
        Restart    = "always";
        RestartSec = "5s";
        EnvironmentFile      = "/run/gerbil-env";
        ExecStart  = "${pkgs.fosrl-gerbil}/bin/gerbil --config /etc/gerbil/config.yaml";
        AmbientCapabilities  = "CAP_NET_ADMIN";
        CapabilityBoundingSet = "CAP_NET_ADMIN";
      };
    };

    # ------------------------------------------------------------------ #
    # CONTAINER MODE — virtualisation.oci-containers (podman or docker)  #
    # ------------------------------------------------------------------ #

    # Traefik static config file for container mode
    environment.etc."traefik/traefik.toml" =
      lib.mkIf (cfg.container_runtime != "flake") {
        text = ''
          [entryPoints]
            [entryPoints.web]
              address = ":80"
            [entryPoints.websecure]
              address = ":443"

          [log]
            level = "INFO"

          [providers]
            [providers.file]
              directory = "/etc/traefik/dynamic"
              watch = true
        '';
      };

    virtualisation.oci-containers = lib.mkIf (cfg.container_runtime != "flake") {
      backend = cfg.container_runtime;
      containers = {
        traefik = {
          image   = "docker.io/library/traefik:v3.0";
          ports   = [ "80:80" "443:443" ];
          volumes = [
            "/etc/traefik/traefik.toml:/etc/traefik/traefik.toml:ro"
            "/etc/traefik/dynamic:/etc/traefik/dynamic:ro"
          ];
        };

        pangolin = {
          image   = "docker.io/fosrl/pangolin:latest";
          ports   = [ "127.0.0.1:${toString cfg.pangolin_port}:${toString cfg.pangolin_port}" ];
          volumes = [
            "/etc/pangolin/config.yaml:/app/config/config.yaml:ro"
            "pangolin_data:/app/data"
          ];
          dependsOn        = [ "traefik" ];
        };

        gerbil = {
          image        = "docker.io/fosrl/gerbil:latest";
          volumes      = [ "/etc/gerbil/config.yaml:/app/config/config.yaml:ro" ];
          extraOptions = [ "--network=host" "--cap-add=NET_ADMIN" ];
          environmentFiles = [ "/run/gerbil-env" ];
          dependsOn        = [ "pangolin" ];
        };
      };
    };
  };
}
