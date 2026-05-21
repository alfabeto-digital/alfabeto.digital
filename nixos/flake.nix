{
  description = "alfabeto.digital: conspiratorios populares de las soberanías";

  inputs = {
    nixpkgs.url          = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url      = "github:hercules-ci/flake-parts";
    import-tree.url      = "github:vic/import-tree";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [ (inputs.import-tree ./modules) ];
    _module.args.configDir =
      let e = builtins.getEnv "NIXOS_CONFIG_DIR"; in
      if e != "" then e else "/etc/nixos";
  };
}
