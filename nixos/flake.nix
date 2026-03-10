{
  description = "alfabeto.digital: conspiratorios populares de las soberanías";

  # Flake inputs must be static — the version is hardcoded here and must be
  # kept in sync with nixos_channel_version in config.nix manually.
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }:
  let
    cfg = import ./config.nix;
  in {
    nixosConfigurations.${cfg.hostname} = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        sops-nix.nixosModules.sops
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs    = true;
            useUserPackages  = true;
            extraSpecialArgs = { admin_username = cfg.admin_username; };
            users.${cfg.admin_username} = import ./home/default.nix;
          };
        }
      ];
    };
  };
}