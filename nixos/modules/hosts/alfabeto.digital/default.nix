{ inputs, self, ... }:
let
  cfg         = import ../../../config.nix;
  storagePath = "${cfg.storage_mount_point}/${cfg.storage_name}";
  dataPath    = "${cfg.data_mount_point}/${cfg.db_name}";
  pkgsUnstable = import inputs.nixpkgs-unstable { system = "x86_64-linux"; config.allowUnfree = true; };
in {
  flake.nixosConfigurations.${cfg.hostname} = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit cfg storagePath dataPath pkgsUnstable;
      flakeDir     = self.outPath;
      exchangePath = "/home/${cfg.admin_username}/exchange";
    };
    modules = [
      inputs.sops-nix.nixosModules.sops
      inputs.home-manager.nixosModules.home-manager
      ../../../hardware-configuration.nix

      # Core system
      self.nixosModules.base
      self.nixosModules.storage
      self.nixosModules.database

      # Network
      self.nixosModules.caddy
      self.nixosModules.cloudflare

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
}
