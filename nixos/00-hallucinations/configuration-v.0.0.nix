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
  # time.timeZone = "Europe/Amsterdam";

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

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.coyote = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" ]; # Enable ‘sudo’ for the user.
    home = "/home/coyote";
    packages = with pkgs; [
      gtop
    ];
  };

  users.groups.bitwarden = {};

  users.users.bitwarden = {
    isNormalUser = true;
    extraGroups = [ "bitwarden" "docker" ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
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

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

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

  systemd.services.bitwarden = {
      serviceConfig = {
        User = "bitwarden";
        ExecStart = "/opt/bitwarden/./bitwarden.sh start";
    };
    wantedBy = [ "multi-user.target" ]; # Ensure the service starts in the multi-user runlevel
  };

  # Configure web server with nginx
  services.nginx.package = pkgs.nginxStable.override { openssl = pkgs.libressl; };
  services.nginx.enable = true;

  services.nginx.virtualHosts."alfabeto.digital" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/alfabeto.digital";
  };

  services.nginx.virtualHosts."boycott.digital" = {
    forceSSL = true;
    enableACME = true;
    listen = [{port = 8443;  addr="0.0.0.0"; ssl = true;}];
    root = "/var/www/boycott.digital";
  };
  
  security.acme = {
    acceptTerms = true;
    certs."alfabeto.digital".email = "services@alfabeto.digital";
    certs."boycott.digital".email = "services@boycott.digital";
  };
  
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 8443 8444];
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

}
