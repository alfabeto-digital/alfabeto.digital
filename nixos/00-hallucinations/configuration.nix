# alfabeto.digital

# author: Nicolás Malpic Forero
# nmalpicf@alfabeto.digital

# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "coyote"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Bogota";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define users groups
  users.groups.storage = {};
  users.groups.ftp = {};
  users.groups.syncthing = {};
  users.groups.nextcloud = {};

  # Define a maintenance account
  users.users.coyote = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "storage"];
    home = "/home/coyote";
    packages = with pkgs; [
      gtop
    ];
  };

  # Define a ftp account
  users.users.ftp = {
    isSystemUser = true;
    group = "ftp";
    extraGroups = [ "storage" ];
  };

  # Disable sudo password request for wheel group
  security.sudo.wheelNeedsPassword = false;

  # Define system accounts
  users.users.syncthing = {
    isSystemUser = true;
    group = lib.mkForce "syncthing";
    extraGroups = [ "storage" ];
  };

  users.users.nextcloud = {
    isSystemUser = true;
    group = "nextcloud";
    extraGroups = [ "storage" ];
  };

  # Add acme user to create Letsencrypt certificates
  #users.users.nginx.extraGroups = [ "acme" ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # The Nano editor is also installed by default.
    wget
    vsftpd
  ];

  # Prevent the laptop to suspend when lid is closed
  services.logind.lidSwitch = "ignore";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Add permissions to storage folder
  systemd.tmpfiles.rules = [
    "d /mnt/storage/dante 0750 coyote storage"
    "d /mnt/storage/dante/data 0750 nextcloud storage"
    "d /mnt/storage/dante/config 0750 nextcloud storage"

    "d /mnt/storage/virgilio 0750 coyote storage"
    "d /mnt/storage/virgilio/helios 0755 syncthing storage"

    #"d /var/lib/acme/acme-challenge/.well-known/acme-challenge 0755 acme nginx"
  ];

  # Mount external hard drives
  fileSystems."/mnt/storage/dante" =
  #  { device = "/dev/disk/by-uuid/46b21863-03ba-490d-b748-51802e17fc99";
    { 
      device = "/dev/disk/by-uuid/2681-2288";
      fsType = "exfat";
    };

  fileSystems."/mnt/storage/virgilio" =
    {
      device = "/dev/disk/by-uuid/6b668f05-9700-4bdf-9924-341bac87eed6";
      fsType = "ext4";
    };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.vsftpd = {
    enable = true;
    localUsers = true;
    writeEnable = true;
    localRoot = "/mnt/storage/virgilio";
    userlist = [ "coyote" ];
  };

  # Enable docker virtualization
  virtualisation.docker.enable = true;

  # Start CloudFlare ZeroTrust tunnel
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      cloudflare = { 
        image = "cloudflare/cloudflared:latest tunnel --no-autoupdate run --token eyJhIjoiZGI4YmY1NTgwNTM3YjRkYmYwNGE2YzZjZDI3NGQwNGUiLCJ0IjoiZjNkMDQ1MDgtMDU2NS00MmUxLWI3NTktYzdlYjJiMzQ1NTRmIiwicyI6IlpUUm1OMkZqTkRrdE9UVXdNUzAwWTJOaUxXSmhOamd0Tm1FMllUazVOV0kwTTJGayJ9";
      };
    };
  };

  # Enable vaultwarden
  services.vaultwarden.enable = true;

  services.vaultwarden.config = {
    DOMAIN = "https://warden.alfabeto.digital";
    ROCKET_ADDRESS = "0.0.0.0";
    ROCKET_PORT = 8222;
  };

  # Enable syncthing
  services = {
    syncthing = {
        enable = true;
        user = "syncthing";
        group = "storage";
        dataDir = "/mnt/storage/virgilio/helios";    # Default folder for new synced folders
        configDir = "/mnt/storage/virgilio/helios/syncthing";   # Folder for Syncthing's settings and keys
        guiAddress = "0.0.0.0:8384";
  #      settings = {
  #        gui = {
  #          user = "coyote";
  #          password = "tmp";
  #        };
  #      };
    };
  };

  # Enable nextcloud
  #nixpkgs.overlays = [ (import ./overlays/nextcloud29.nix) ];

  #environment.etc."nextcloud-admin-pass".text = "tmp";
  #services.nextcloud = {
  #  enable = true;      
  #  hostName = "cloud.alfabeto.digital";
  #  https = true;
  #  database.createLocally = true;
  #  package = pkgs.nextcloud29;
  #  config = {
  #    dbtype = "mysql";
  #    dbname = "nextcloud";
  #    dbuser = "nextcloud";
  #    adminpassFile = "/etc/nextcloud-admin-pass";
  #  };
  
  #  datadir = "/mnt/storage/dante";
   
  #  appstoreEnable = true; 
  #  autoUpdateApps.enable = true;
  #  extraAppsEnable = true;
  #  extraApps = {
      # List of apps we want to install and are already packaged in
      # https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/nextcloud/packages/nextcloud-apps.json
  #    inherit (config.services.nextcloud.package.packages.apps) calendar previewgenerator;
  #    richdocuments = pkgs.fetchNextcloudApp {
  #      sha256 = "sha256-zdUX04k6FLM/fiI7pkWMFmQzuJy75ZcTbBlmxNsiXKY=";
  #      url = "https://github.com/nextcloud-releases/richdocuments/releases/download/v6.3.10/richdocuments-v6.3.10.tar.gz";
  #      license = "agpl3Only";
  #    };
  #  };
  #};

  # Enable nextcloud office
  #virtualisation.oci-containers.containers.collabora = {
  #  image = "docker.io/collabora/code:latest";
  #  ports = [ "9980:9980/tcp" ];
  #  environment = {
  #    server_name = "office.alfabeto.digital";
  #    aliasgroup1 = "cloud.alfabeto.digital";
  #  };
  #  extraOptions = [
  #    "--cap-add" "MKNOD"
  #  ];
    #restart = "always";
  #};

  # Enable cron jobs to run maintenance tasks
  #services.cron = {
  #  enable = true;
  #  systemCronJobs = [
  #    "0 0 * * * coyote nextcloud-occ preview:pre-generate"
  #    "0 * * * * coyote nextcloud-occ files:scan --all"
  #  ];
  #};

  # Configure web server with nginx
  services.nginx.package = pkgs.nginxStable.override { openssl = pkgs.libressl; };
  services.nginx.enable = true;

  # Main domain
  services.nginx.virtualHosts."alfabeto.digital" = {
    forceSSL = true;
    enableACME = true;
    locations."/.well-known/acme-challenge" = {
      root = "/var/lib/acme/acme-challenge";
    };
    root = "/var/www/alfabeto.digital";
  };
  
  # Vaultwarden
  services.nginx.virtualHosts."warden.alfabeto.digital" = {
    forceSSL = true;
    enableACME = true;
    locations."/.well-known/acme-challenge" = {
      root = "/var/lib/acme/acme-challenge"; 
    };
    locations."/" = {
      proxyPass = "https://0.0.0.0:${toString config.services.vaultwarden.config.ROCKET_PORT}";
    };
    #listen = [{port = 8222; addr="0.0.0.0"; ssl = true;}];
  };

  # Syncthing
  services.nginx.virtualHosts."sync.alfabeto.digital" = {
    forceSSL = true;
    enableACME = true;
    locations."/.well-known/acme-challenge" = {
      root = "/var/lib/acme/acme-challenge"; 
    };
    locations."/" = {
      proxyPass = "http://0.0.0.0:8384";
    };
    #listen = [{port = 8384; addr="0.0.0.0"; ssl = true;}];
  };

  # Nextcloud
  #services.nginx.virtualHosts."cloud.alfabeto.digital" = {
  #  forceSSL = true;
  #  enableACME = true;
  #  listen = [{port = 8445; addr="0.0.0.0"; ssl = true;}];
  #};

  # Nextcloud office (Collabora)
  #services.nginx.virtualHosts.${config.virtualisation.oci-containers.containers.collabora.environment.server_name} = {
  #  enableACME = true;
  #  forceSSL = true;

  #  extraConfig = ''
      # static files
  #    location ^~ /browser {
  #      proxy_pass http://127.0.0.1:9980;
  #      proxy_set_header Host $host;
  #    }

      # WOPI discovery URL
  #    location ^~ /hosting/discovery {
  #      proxy_pass http://127.0.0.1:9980;
  #      proxy_set_header Host $host;
  #    }

      # Capabilities
  #    location ^~ /hosting/capabilities {
  #      proxy_pass http://127.0.0.1:9980;
  #      proxy_set_header Host $host;
  #   }

     # main websocket
  #   location ~ ^/cool/(.*)/ws$ {
  #     proxy_pass http://127.0.0.1:9980;
  #     proxy_set_header Upgrade $http_upgrade;
  #     proxy_set_header Connection "Upgrade";
  #     proxy_set_header Host $host;
  #     proxy_read_timeout 36000s;
  #   }

     # download, presentation and image upload
  #   location ~ ^/(c|l)ool {
  #     proxy_pass http://127.0.0.1:9980;
  #     proxy_set_header Host $host;
  #   }

     # Admin Console websocket
  #   location ^~ /cool/adminws {
  #     proxy_pass http://127.0.0.1:9980;
  #     proxy_set_header Upgrade $http_upgrade;
  #     proxy_set_header Connection "Upgrade";
  #     proxy_set_header Host $host;
  #     proxy_read_timeout 36000s;
  #   }
  #  '';
  #};

  # Secondary domain
  # services.nginx.virtualHosts."boycott.digital" = {
  #  forceSSL = true;
  #  enableACME = true;
  #  listen = [{port = 8443;  addr="0.0.0.0"; ssl = true;}];
  #  root = "/var/www/boycott.digital";
  #};

  security.acme = {
    acceptTerms = true;
    
    certs."alfabeto.digital".email = "services@alfabeto.digital";
    certs."warden.alfabeto.digital".email = "services@alfabeto.digital";
    certs."sync.alfabeto.digital".email = "services@alfabeto.digital";
  #  certs."cloud.alfabeto.digital".email = "services@alfabeto.digital";
  #  certs."office.alfabeto.digital".email = "services@alfabeto.digital";
    
  #  certs."boycott.digital".email = "services@boycott.digital";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 21 80 8080 443 8222 8384 8445 9980 22000];
    allowedUDPPorts = [ 22000 21027 ];
  }; 

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?
}