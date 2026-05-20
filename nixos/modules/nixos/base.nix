{ inputs, ... }: {
  flake.nixosModules.base = { config, lib, pkgs, cfg, flakeDir, ... }: {

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    nix.settings.auto-optimise-store   = true;
    nix.gc = {
      automatic = true;
      dates     = "weekly";
      options   = "--delete-older-than 7d";
    };

    boot.loader.systemd-boot.enable      = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelParams = [ "ip=dhcp" ];
    boot.initrd.availableKernelModules = [ "r8169" ];
    boot.initrd.network = {
      enable = true;
      ssh = {
        enable          = true;
        port            = cfg.initrd_ssh_port;
        authorizedKeys  = [ cfg.admin_ssh_key ];
        hostKeys        = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
      };
    };

    networking.hostName = cfg.hostname;
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
        cfg.initrd_ssh_port
        cfg.vaultwarden_port
      ];
    };

    time.timeZone = cfg.timezone;

    i18n.defaultLocale = cfg.locale_lang;
    i18n.extraLocaleSettings = {
      LC_MESSAGES       = cfg.locale_lang;
      LC_TIME           = cfg.locale_time;
      LC_NUMERIC        = cfg.locale_numeric;
      LC_MONETARY       = cfg.locale_monetary;
      LC_MEASUREMENT    = cfg.locale_measurement;
      LC_PAPER          = cfg.locale_paper;
      LC_ADDRESS        = cfg.locale_address;
      LC_TELEPHONE      = cfg.locale_telephone;
      LC_NAME           = cfg.locale_name;
      LC_IDENTIFICATION = cfg.locale_identification;
    };

    console.keyMap               = cfg.keyboard_console;
    services.xserver.xkb.layout = cfg.keyboard_x11;

    sops = {
      defaultSopsFile = "${flakeDir}/secrets/secrets.yaml";
      age.keyFile     = "/root/.config/sops/age/keys.txt";
      secrets = {
        root_password.neededForUsers  = true;
        admin_password.neededForUsers = true;
        db_password = {
          owner = "postgres";
          mode  = "0600";
        };
        luks_data_key = {
          mode = "0400";
        };
      };
    };

    users.groups = {
      storage     = {};
      syncthing   = {};
      vaultwarden = {};
    };

    users.users = {
      root.hashedPasswordFile = config.sops.secrets.root_password.path;

      ${cfg.admin_username} = {
        isNormalUser       = true;
        home               = "/home/${cfg.admin_username}";
        homeMode           = "0751";
        extraGroups        = [ "wheel" "storage" ];
        hashedPasswordFile = config.sops.secrets.admin_password.path;
        openssh.authorizedKeys.keys = [ cfg.admin_ssh_key ];
      };

      ${cfg.syncthing_username} = {
        isSystemUser = true;
        group        = lib.mkForce cfg.syncthing_username;
        extraGroups  = [ "storage" ];
      };

      ${cfg.vaultwarden_username} = {
        isSystemUser = true;
        group        = lib.mkForce cfg.vaultwarden_username;
        extraGroups  = [ "storage" ];
      };
    };

    security.sudo.wheelNeedsPassword = false;

    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin        = "no";
        PasswordAuthentication = false;
        AllowUsers             = [ cfg.admin_username ];
      };
    };

    nixpkgs.overlays = [
      (self: super: {
        bashtop = super.stdenv.mkDerivation rec {
          pname   = "bashtop";
          version = "0.9.25";
          src = super.fetchFromGitHub {
            owner  = "aristocratos";
            repo   = pname;
            rev    = "v${version}";
            sha256 = "sha256-ewR1Z9z6GQfSFknTaqhsk8NKiSDXBdkVjP4sX7fJ1B4=";
          };
          dontBuild = true;
          installPhase = ''
            mkdir -p $out/bin
            install -m755 bashtop $out/bin/
          '';
          meta = with super.lib; {
            description = "Resource monitor for Linux/Unix systems";
            homepage    = "https://github.com/aristocratos/bashtop";
            license     = licenses.asl20;
            platforms   = platforms.all;
          };
        };
      })
    ];

    environment.systemPackages = with pkgs; [
      vim neovim git wget fzf kitty sops hostname bashtop gtop postgresql cryptsetup
      pciutils ethtool iproute2 net-tools
    ];

    systemd.tmpfiles.rules = [
      "d /home/${cfg.admin_username}/exchange 0755 ${cfg.admin_username} users - -"
    ];

    system.stateVersion = cfg.nixos_state_version;
  };
}
