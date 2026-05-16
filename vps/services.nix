{ pkgs, ... }: {
  project.name = "pangolin-vps";

  docker-compose.volumes.pangolin_data = {};

  services = {

    traefik.service = {
      image   = "traefik:v3.0";
      ports   = [ "80:80" "443:443" ];
      volumes = [
        "./config/traefik.toml:/etc/traefik/traefik.toml:ro"
        "./config/dynamic:/etc/traefik/dynamic:ro"
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      restart = "always";
    };

    pangolin.service = {
      useHostStore = true;
      command      = [ "${pkgs.fosrl-pangolin}/bin/pangolin" ];
      ports        = [ "127.0.0.1:3000:3000" ];  # loopback only — Gerbil uses network_mode: host
      volumes      = [
        "./config/pangolin.yaml:/app/config/config.yaml:ro"
        "pangolin_data:/app/data"
      ];
      env_file     = [ "./secrets.env" ];
      depends_on   = [ "traefik" ];
      restart      = "always";
    };

    gerbil.service = {
      useHostStore = true;
      command      = [ "${pkgs.fosrl-gerbil}/bin/gerbil" ];
      volumes      = [
        "./config/gerbil.yaml:/app/config/config.yaml:ro"
      ];
      env_file          = [ "./secrets.env" ];  # provides GERBIL_PANGOLIN_TOKEN
      capabilities.NET_ADMIN = true;
      network_mode      = "host";
      depends_on        = [ "pangolin" ];
      restart           = "always";
    };

  };
}
