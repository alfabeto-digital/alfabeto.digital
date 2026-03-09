{
  description = "alfabeto.digital: conspiratorios populares de las soberanías";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, ... }@inputs:
  let
    cfg = import ./config.nix;
  in {
    nixosConfigurations.${cfg.hostname} = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        sops-nix.nixosModules.sops
        ./configuration.nix
        home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${cfg.admin_username} = import ./home/default.nix {
              admin_username = cfg.admin_username;
	     pkgs = nixpkgs.legacyPackages.x86_64-linux;
	   };
          };
        }
      ];
    };
  };
}