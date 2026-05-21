{ inputs, self, configDir, ... }:
let
  lib = inputs.nixpkgs.lib;
in {
  flake.nixosConfigurations = lib.optionalAttrs
    (builtins.pathExists "${configDir}/config.nix")
    (let
      cfg          = import "${configDir}/config.nix";
      _tunnelTypeCheck = if lib.elem cfg.tunnel_type [ "cloudflare" "newt" ] then null
        else abort "config.nix: tunnel_type must be \"cloudflare\" or \"newt\", got \"${cfg.tunnel_type}\"";
      storagePath  = "${cfg.storage_mount_point}/${cfg.storage_name}";
      dataPath     = "${cfg.data_mount_point}/${cfg.db_name}";
      pkgsUnstable = import inputs.nixpkgs-unstable { system = "x86_64-linux"; config.allowUnfree = true; };
    in {
      ${cfg.hostname} = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit cfg storagePath dataPath pkgsUnstable;
          flakeDir     = self.outPath;
          exchangePath = "/home/${cfg.admin_username}/exchange";
        };
        modules = [
          inputs.sops-nix.nixosModules.sops
          inputs.home-manager.nixosModules.home-manager
          "${configDir}/hardware-configuration.nix"

          # Core system
          self.nixosModules.base
          self.nixosModules.storage
          self.nixosModules.database

          # Network
          self.nixosModules.caddy
        ] ++ lib.optional (cfg.tunnel_type == "cloudflare") self.nixosModules.cloudflare
          ++ lib.optional (cfg.tunnel_type == "newt")        self.nixosModules.newt
          ++ [
          # Services
          self.nixosModules.vaultwarden
          self.nixosModules.syncthing

          # Admin user (home-manager)
          self.nixosModules.admin

          # Security
          self.nixosModules.adguard
          self.nixosModules.authelia

          # Communications
          self.nixosModules.dendrite
          self.nixosModules.stalwart
          self.nixosModules.ntfy
        ];
      };
    });
}