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
    };
  };

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
  };

  security.acme = {
    acceptTerms = true;
    
    certs."alfabeto.digital".email = "services@alfabeto.digital";
    certs."warden.alfabeto.digital".email = "services@alfabeto.digital";
    certs."sync.alfabeto.digital".email = "services@alfabeto.digital";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 21 80 8080 443 8222 8384 ];
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