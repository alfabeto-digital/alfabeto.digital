{ inputs, ... }: {
  flake.nixosModules.dendrite = { config, lib, pkgs, cfg, storagePath, ... }: {

    systemd.tmpfiles.rules = [
      "d ${storagePath}/exchange/dendrite        0750 dendrite dendrite - -"
      "d ${storagePath}/exchange/dendrite/media  0750 dendrite dendrite - -"
    ];

    # dendrite_private_key must be added to secrets.yaml before deploying.
    # Generate: nix shell nixpkgs#dendrite -c generate-keys --private-key /tmp/matrix_key.pem
    sops.secrets.dendrite_private_key = {
      owner = "dendrite";
      mode  = "0400";
    };

    # Declare the dendrite PostgreSQL user and database — merged with database.nix.
    services.postgresql.ensureDatabases = [ "dendrite" ];
    services.postgresql.ensureUsers     = [{ name = "dendrite"; }];

    services.dendrite = {
      enable   = true;
      httpPort = cfg.dendrite_port;
      settings = {
        global = {
          server_name              = "matrix.${cfg.domain}";
          private_key              = config.sops.secrets.dendrite_private_key.path;
          presence.enable_inbound  = true;
          presence.enable_outbound = true;
        };
        client_api = {
          registration_disabled = true;
          guests_disabled       = true;
        };
        media_api = {
          base_path           = "${storagePath}/exchange/dendrite/media";
          max_file_size_bytes = 104857600;
        };
        sync_api.search.enabled = true;
        # Uses peer auth over Unix socket — no password needed in Nix store.
        database.connection_string = "postgresql:///dendrite?host=/run/postgresql";
        jetstream.storage_path     = "${storagePath}/exchange/dendrite/nats";
        logging = [{ type = "std"; level = "warn"; }];
      };
    };
  };
}
