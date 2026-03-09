{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "username";

  # Set your time zone.
  time.timeZone = "America/Bogota";

  # Define users groups
  users.groups.storage = {};
  users.groups.ftp = {};
  users.groups.syncthing = {};
  users.groups.nextcloud = {};

  # Define a maintenance account
  users.users.username = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "storage"];
    home = "/home/username";
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
  users.users.nginx.extraGroups = [ "acme" ];

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
    "d /mnt/storage/folder 0750 username storage"
    "d /mnt/storage/folder/data 0750 nextcloud storage"
    "d /mnt/storage/folder/config 0750 nextcloud storage"

    "d /mnt/storage/storage 0750 username storage"
    "d /mnt/storage/storage/exchange 0755 syncthing storage"

    "d /var/lib/acme/acme-challenge/.well-known/acme-challenge 0755 acme nginx"
  ];

  # Mount external hard drives
  fileSystems."/mnt/storage/folder" =
    { device = "/dev/disk/by-uuid/asdsa-03ba-490d-b748-wertwert";
      fsType = "ext4";
    };

  fileSystems."/mnt/storage/storage" =
    {
      device = "/dev/disk/by-uuid/asdfasdf-9700-4bdf-9924-ertert";
      fsType = "ext4";
    };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.vsftpd = {
    enable = true;
    localUsers = true;
    writeEnable = true;
    localRoot = "/mnt/storage/storage";
    userlist = [ "username" ];
  };

  # Enable docker virtualization
  virtualisation.docker.enable = true;

  # Start CloudFlare ZeroTrust tunnel
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      cloudflare = { 
        image = "cloudflare/cloudflared:latest tunnel --no-autoupdate run --token TOKEN_KEY";
      };
    };
  };

  # Configure web server with nginx
  services.nginx.package = pkgs.nginxStable.override { openssl = pkgs.libressl; };
  services.nginx.enable = true;

  # Main domain
  services.nginx.virtualHosts."primary.digital" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/primary.digital";
  };
  
  # Secondary domain
  services.nginx.virtualHosts."secondary.digital" = {
    forceSSL = true;
    enableACME = true;
    listen = [{port = 8443;  addr="0.0.0.0"; ssl = true;}];
    root = "/var/www/secondary.digital";
  };

  security.acme = {
    acceptTerms = true;
    
    certs."primary.digital".email = "services@primary.digital";
    certs."secondary.digital".email = "services@secondary.digital";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 21 80 8080 443 8222 8384 8443 8445 9980 22000];
    allowedUDPPorts = [ 22000 21027 ];
  }; 

  system.stateVersion = "23.11"; # Did you read the comment?
}