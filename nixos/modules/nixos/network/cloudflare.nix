{ inputs, ... }: {
  flake.nixosModules.cloudflare = { config, lib, pkgs, cfg, ... }: {

    virtualisation.podman = {
      enable       = true;
      dockerCompat = true;
    };

    systemd.services.cloudflare-tunnel = {
      description = "Cloudflare Zero Trust tunnel";
      wantedBy    = [ "multi-user.target" ];
      after       = [ "network-online.target" ];
      wants       = [ "network-online.target" ];
      serviceConfig = {
        Restart    = "always";
        RestartSec = "5s";
        ExecStartPre = pkgs.writeShellScript "cloudflare-pull" ''
          ${pkgs.podman}/bin/podman pull cloudflare/cloudflared:latest
        '';
        ExecStart = pkgs.writeShellScript "cloudflare-start" ''
          TOKEN=$(cat ${config.sops.secrets.cloudflare_token.path})
          exec ${pkgs.podman}/bin/podman run --rm --name cloudflare \
            --network host \
            -e TUNNEL_TOKEN="$TOKEN" \
            cloudflare/cloudflared:latest \
            tunnel --no-autoupdate run
        '';
        ExecStop = pkgs.writeShellScript "cloudflare-stop" ''
          ${pkgs.podman}/bin/podman stop cloudflare || true
          ${pkgs.podman}/bin/podman rm   cloudflare || true
        '';
      };
    };
  };
}
