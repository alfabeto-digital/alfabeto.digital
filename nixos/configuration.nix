###################################################################
#
# alfabeto.digital v = 0.0.1
# quipu v = 0.0.1
# nicolás malpic forero
# 21 de febrero, 2025
#
###################################################################
#
# Import nixos configurations:
#
# nixos
# ├── config.nix
# ├── configuration.nix
# ├── flake.nix
# ├── hardware-configuration.nix
# ├── home
# │   └── default.nix
# └── secrets
#     ├── secrets.plain --> delete after installation
#     └── secrets.yaml
#
###################################################################
#
# Run as root in /etc/nixos:
#
# --> Use nix-shell -p [age, sops]
# --> Generate the age key
#     mkdir /root/.config
#     mkdir /root/.config/sops
#     mkdir /root/.config/sops/age
#     nix-shell -p age --run "age-keygen -o /root/.config/sops/age/keys.txt"
# --> Get the public_key
#     nix-shell -p age --run "age-keygen -y /root/.config/sops/age/keys.txt"
# --> Encrypt using sops
#     nix-shell -p sops --run "sops --encrypt --age 'age1...' ./secrets/secrets.plain > ./secrets/secrets.yaml"
# --> Rebuild the system
#     nixos-rebuild switch --flake .#$(nix eval --raw 'import ./config.nix'.hostname)
#
###################################################################
{ config, lib, pkgs, ... }:

let
  cfg = import ./config.nix;
in {
  imports = [ ./hardware-configuration.nix ];

  # Enable flakes experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # hostName and timeZone
  networking.hostName = cfg.hostname;
  time.timeZone = cfg.timezone;

  # Garbage collector
  nix = {
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

  # Secrets management
  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    age.keyFile = "/root/.config/sops/age/keys.txt";
    secrets = {
      root_password.neededForUsers = true;
      admin_password.neededForUsers = true;
      db_password = {
        owner = "postgres";
        mode = "0600";
      };
    };
  };

  # System users definitions
  users.users = {
    root.hashedPasswordFile = config.sops.secrets.root_password.path;
    ${cfg.admin_username} = {
      isNormalUser = true;
      home = "/home/${cfg.admin_username}";
      extraGroups = [ "wheel" ];
      hashedPasswordFile = config.sops.secrets.admin_password.path;
    };
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;  # false to use SSH keys
      AllowUsers = [ cfg.admin_username ];
    };
  };

  # Enable PostgreSQL
  services.postgresql = {
    enable = true;
    ensureDatabases = [ cfg.db_name ];
    ensureUsers = [{
      name = cfg.db_username;
    }];
    initialScript = pkgs.writeText "init.sql" ''
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${cfg.db_username}') THEN
          CREATE USER ${cfg.db_username} WITH PASSWORD '${config.sops.secrets.db_password.path}';
        END IF;
      END $$;
      GRANT ALL PRIVILEGES ON DATABASE ${cfg.db_name} TO ${cfg.db_username};
    '';
    authentication = lib.mkForce ''
      local all postgres peer
      local all all md5
      host all all 127.0.0.1/32 md5
    '';
  };
  
  # Enable overlays
  nixpkgs.overlays = [
    (self: super: {
      # Import bashtop from source
      bashtop = super.stdenv.mkDerivation rec {
        pname = "bashtop";
        version = "0.9.25";
        src = super.fetchFromGitHub {
          owner = "aristocratos";
          repo = pname;
          rev = "v${version}";
          sha256 = "sha256-ewR1Z9z6GQfSFknTaqhsk8NKiSDXBdkVjP4sX7fJ1B4=";
        };
        dontBuild = true;
        installPhase = ''
          mkdir -p $out/bin
          install -m755 bashtop $out/bin/
        '';
        meta = with super.lib; {
          description = "Resource monitor for Linux/Unix systems";
          homepage = "https://github.com/aristocratos/bashtop";
          license = licenses.asl20;
          maintainers = with maintainers; [ ];
          platforms = platforms.all;
        };
      };
    })
  ];

  # Global packages installation
  environment.systemPackages = with pkgs; [
    vim
    wget 
    fzf
    kitty
    sops
    hostname
    bashtop
    postgresql
  ];
  
  # Firewall
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # System version
  system.stateVersion = "24.11";
}