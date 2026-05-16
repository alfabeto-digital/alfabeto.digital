{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    arion = {
      url   = "github:hercules-ci/arion";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, arion }: let
    system   = "x86_64-linux";
    pkgs     = nixpkgs.legacyPackages.${system};
    # Generate arion-pkgs.nix pointing to the pinned nixpkgs from flake.lock.
    arionPkgs = pkgs.writeText "arion-pkgs.nix" "import ${nixpkgs} {}";
  in {
    packages.${system}.default = arion.packages.${system}.arion;

    apps.${system} = {
      up = {
        type    = "app";
        program = toString (pkgs.writeShellScript "vps-up" ''
          ${arion.packages.${system}.arion}/bin/arion \
            --pkgs ${arionPkgs} --file services.nix up -d
        '');
      };
      down = {
        type    = "app";
        program = toString (pkgs.writeShellScript "vps-down" ''
          ${arion.packages.${system}.arion}/bin/arion \
            --pkgs ${arionPkgs} --file services.nix down
        '');
      };
    };
  };
}
