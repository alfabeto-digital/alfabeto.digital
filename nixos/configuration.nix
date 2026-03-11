###################################################################
#
# alfabeto.digital
# nicolás malpic forero
#
###################################################################
#
# nixos
# ├── config.nix
# ├── configuration.nix
# ├── flake.nix
# ├── hardware-configuration.nix  ← generated during installation
# ├── home
# │   └── default.nix
# └── secrets
#     ├── secrets.plain           ← delete after encrypting
#     └── secrets.yaml
#
###################################################################
#
# PRE-INSTALLATION CHECKLIST
#
# 1. Partition nvme0 (OS disk) with LUKS during the NixOS installer.
#    The installer writes hardware-configuration.nix automatically.
#
# 2. Partition and encrypt nvme1 (data disk):
#
#    a) Format and create the filesystem:
#         cryptsetup luksFormat /dev/nvme1n1    # choose an emergency passphrase
#         cryptsetup luksOpen /dev/nvme1n1 data-disk
#         mkfs.ext4 /dev/mapper/data-disk
#         cryptsetup luksClose data-disk
#
#    b) Fill data_disk_uuid in config.nix:
#         blkid /dev/nvme1n1
#
#    c) After filling and encrypting secrets (step 4), enroll the
#       luks_data_key as a second key slot in the LUKS header.
#       This lets the system unlock the disk automatically at boot
#       while the emergency passphrase from step (a) remains as backup:
#
#         LUKS_KEY=$(sops --decrypt ./secrets/secrets.yaml \
#           | grep 'luks_data_key' | awk -F': ' '{print $2}' | tr -d '"')
#         echo -n "$LUKS_KEY" > /tmp/luks.key
#         truncate -s -1 /tmp/luks.key
#         cryptsetup luksAddKey /dev/nvme1n1 /tmp/luks.key
#         rm /tmp/luks.key
#         unset LUKS_KEY
#
#       To verify both key slots are enrolled:
#         cryptsetup luksDump /dev/nvme1n1 | grep "Key Slot"
#
# 3. Generate the initrd SSH host key (for remote LUKS unlock of nvme0):
#      mkdir -p /etc/secrets/initrd
#      ssh-keygen -t ed25519 -N "" \
#        -f /etc/secrets/initrd/ssh_host_ed25519_key
#      echo "ssh-ed25519 AAAA... user@host" > /etc/secrets/initrd/authorized_keys
#      chmod 600 /etc/secrets/initrd/authorized_keys
#    This file must exist before the first nixos-rebuild.
#
# 4. Generate the age key and encrypt secrets:
#      nix-shell -p age sops
#      mkdir -p /root/.config/sops/age
#      age-keygen -o /root/.config/sops/age/keys.txt
#      age-keygen -y /root/.config/sops/age/keys.txt   # → copy this public key
#    Fill secrets/secrets.plain (see that file for instructions), then:
#      sops --encrypt --age 'age1...' ./secrets/secrets.plain \
#        > ./secrets/secrets.yaml
#      rm ./secrets/secrets.plain
#
# 5. Build:
#      nixos-rebuild switch --flake /etc/nixos#alfabetodigital
#
# REMOTE LUKS UNLOCK (after reboot):
#   Connect from your authorized machine:
#      ssh -p <initrd_ssh_port> root@<server-ip>
#   Type the nvme0 passphrase at the prompt.
#
###################################################################

{ config, lib, pkgs, ... }:

let
  cfg = import ./config.nix;

  # Derived paths — computed once, used throughout.
  dataPath    = "${cfg.data_mount_point}/${cfg.db_name}";          # /mnt/data/quipu
  storagePath = "${cfg.storage_mount_point}/${cfg.storage_name}";  # /mnt/storage/virgilio
in {

  imports = [ ./hardware-configuration.nix ];

  ###############################################################
  # Nix
  ###############################################################

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store   = true;
  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 7d";
  };

  ###############################################################
  # Boot
  ###############################################################

  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Request DHCP during initrd so the SSH unlock endpoint is reachable.
  boot.kernelParams = [ "ip=dhcp" ];

  # Remote SSH in initrd for unlocking nvme0 (LUKS OS disk).
  # See PRE-INSTALLATION CHECKLIST step 3 for key generation.
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable             = true;
      port               = cfg.initrd_ssh_port;
      authorizedKeyFiles = [ "/etc/secrets/initrd/authorized_keys" ];
      hostKeys           = [ "/etc/secrets/initrd/ssh_host_ed25519_key" ];
    };
  };

  ###############################################################
  # Networking
  ###############################################################

  networking.hostName = cfg.hostname;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      80                    # HTTP / ACME challenge
      443                   # HTTPS
      cfg.initrd_ssh_port   # initrd SSH (LUKS unlock)
      cfg.vaultwarden_port
      cfg.syncthing_port
      # cfg.ftp_port        # uncomment when vsftpd is re-enabled
    ];
  };

  ###############################################################
  # Time, locale & keyboard
  ###############################################################

  time.timeZone = cfg.timezone;

  i18n.defaultLocale = cfg.locale_lang;
  i18n.extraLocaleSettings = {
    LC_MESSAGES       = cfg.locale_lang;
    # LC_COLLATE = cfg.locale_collate is intentionally omitted:
    # "C" is a built-in glibc locale that cannot be compiled and does
    # not need to appear in extraLocaleSettings.
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

  ###############################################################
  # Secrets (sops-nix)
  ###############################################################

  sops = {
    defaultSopsFile = ./secrets/secrets.yaml;
    age.keyFile     = "/root/.config/sops/age/keys.txt";
    secrets = {
      root_password.neededForUsers  = true;
      admin_password.neededForUsers = true;
      db_password = {
        owner = "postgres";
        mode  = "0600";
      };
      cloudflare_token = {};
      luks_data_key = {
        mode = "0400";
      };
    };
  };

  ###############################################################
  # Users & groups
  ###############################################################

  users.groups = {
    storage   = {};
    syncthing = {};
  };

  users.users = {
    root.hashedPasswordFile = config.sops.secrets.root_password.path;

    ${cfg.admin_username} = {
      isNormalUser       = true;
      home               = "/home/${cfg.admin_username}";
      extraGroups        = [ "wheel" "docker" "storage" ];
      hashedPasswordFile = config.sops.secrets.admin_password.path;
      openssh.authorizedKeys.keys = [ cfg.admin_ssh_key ];
    };

    ${cfg.syncthing_username} = {
      isSystemUser = true;
      group        = lib.mkForce cfg.syncthing_username;
      extraGroups  = [ "storage" ];
    };
  };

  security.sudo.wheelNeedsPassword = false;

  ###############################################################
  # SSH
  ###############################################################

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin        = "no";
      PasswordAuthentication = false;
      AllowUsers             = [ cfg.admin_username ];
    };
  };

  ###############################################################
  # Disks & filesystems
  ###############################################################

  # External storage disk — not yet encrypted.
  # nofail prevents boot failures if the disk is absent.
  fileSystems."${storagePath}" = {
    device  = "/dev/disk/by-uuid/${cfg.storage_uuid}";
    fsType  = "ext4";
    options = [ "nofail" ];
  };

  # Unlock nvme1 (data disk) with the sops-managed LUKS key.
  # ConditionPathExists prevents re-running if the mapper already exists.
  systemd.services.unlock-data-disk = {
    description = "Unlock LUKS data disk (nvme1)";
    wantedBy    = [ "multi-user.target" ];
    before      = [ "postgresql.service" ];
    unitConfig.ConditionPathExists = "!/dev/mapper/data-disk";
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.cryptsetup}/bin/cryptsetup open \
        /dev/disk/by-uuid/${cfg.data_disk_uuid} \
        data-disk \
        --key-file ${config.sops.secrets.luks_data_key.path}
    '';
  };

  # Mount decrypted nvme1 — PostgreSQL data lives here.
  fileSystems."${dataPath}" = {
    device  = "/dev/mapper/data-disk";
    fsType  = "ext4";
    options = [ "x-systemd.requires=unlock-data-disk.service" ];
  };

  # Directory structure — 'd' directive is idempotent: creates only if absent.
  systemd.tmpfiles.rules = [
    "d ${storagePath}                                           0750 ${cfg.admin_username}     storage - -"
    "d ${storagePath}/helios                                    0755 ${cfg.syncthing_username} storage - -"
    "d /var/www/${cfg.domain}                                  0755 nginx                     nginx   - -"
    "d /var/lib/acme/acme-challenge                            0755 acme                      nginx   - -"
    "d /var/lib/acme/acme-challenge/.well-known                0755 acme                      nginx   - -"
    "d /var/lib/acme/acme-challenge/.well-known/acme-challenge 0755 acme                      nginx   - -"
  ];

  ###############################################################
  # PostgreSQL
  ###############################################################

  services.postgresql = {
    enable          = true;
    dataDir         = "${dataPath}/postgresql";
    ensureDatabases = [ cfg.db_name ];
    ensureUsers     = [{ name = cfg.db_username; }];
    authentication  = lib.mkForce ''
      local all postgres peer
      local all all    md5
      host  all all    127.0.0.1/32 md5
    '';
  };

  # Sets DB user password and grants from sops secret.
  # Runs after every boot — both statements are idempotent.
  systemd.services.postgresql-set-password = {
    description = "Set PostgreSQL user password from sops secret";
    wantedBy    = [ "multi-user.target" ];
    after       = [ "postgresql.service" ];
    requires    = [ "postgresql.service" ];
    serviceConfig = {
      Type            = "oneshot";
      User            = "postgres";
      RemainAfterExit = true;
    };
    script = ''
      DB_PASSWORD=$(cat ${config.sops.secrets.db_password.path})
      ${config.services.postgresql.package}/bin/psql -c \
        "ALTER USER \"${cfg.db_username}\" WITH PASSWORD '$DB_PASSWORD';"
      ${config.services.postgresql.package}/bin/psql -c \
        "GRANT ALL PRIVILEGES ON DATABASE \"${cfg.db_name}\" TO \"${cfg.db_username}\";"
    '';
  };

  ###############################################################
  # Docker & Cloudflare Zero Trust tunnel
  ###############################################################

  virtualisation.docker.enable = true;

  # Creates /run/cloudflare.env from the sops secret at boot.
  # Written to /run (tmpfs) so it never touches disk unencrypted.
  systemd.services.cloudflare-env = {
    description     = "Write Cloudflare tunnel env file from sops secret";
    wantedBy        = [ "multi-user.target" ];
    before          = [ "docker-cloudflare.service" ];
    unitConfig.ConditionPathExists = "!/run/cloudflare.env";
    serviceConfig = {
      Type            = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      TOKEN=$(cat ${config.sops.secrets.cloudflare_token.path})
      printf 'TUNNEL_TOKEN=%s' "$TOKEN" > /run/cloudflare.env
      chmod 400 /run/cloudflare.env
    '';
  };

  # Ensure docker-cloudflare waits for the env file to exist.
  systemd.services.docker-cloudflare = {
    after    = [ "cloudflare-env.service" ];
    requires = [ "cloudflare-env.service" ];
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.cloudflare = {
      image            = "cloudflare/cloudflared:latest";
      cmd              = [ "tunnel" "--no-autoupdate" "run" ];
      environmentFiles = [ "/run/cloudflare.env" ];
    };
  };


  ###############################################################
  # Vaultwarden
  ###############################################################

  services.vaultwarden = {
    enable = true;
    config = {
      DOMAIN         = "https://warden.${cfg.domain}";
      ROCKET_ADDRESS = "0.0.0.0";
      ROCKET_PORT    = cfg.vaultwarden_port;
    };
  };

  ###############################################################
  # Syncthing
  ###############################################################

  services.syncthing = {
    enable     = true;
    user       = cfg.syncthing_username;
    group      = "storage";
    dataDir    = "${storagePath}/helios";
    configDir  = "${storagePath}/helios/syncthing";
    guiAddress = "0.0.0.0:${toString cfg.syncthing_port}";
  };

  ###############################################################
  # vsftpd — disabled; re-enable when needed
  ###############################################################

  # services.vsftpd = {
  #   enable      = true;
  #   localUsers  = true;
  #   writeEnable = true;
  #   localRoot   = storagePath;
  #   userlist    = [ cfg.admin_username ];
  # };
  # users.users.${cfg.ftp_username} = {
  #   isSystemUser = true;
  #   group        = "ftp";
  #   extraGroups  = [ "storage" ];
  # };
  # users.groups.ftp = {};
  # Also uncomment cfg.ftp_port in networking.firewall.allowedTCPPorts.

  ###############################################################
  # Nginx & ACME
  ###############################################################

  services.nginx = {
    enable  = true;
    package = pkgs.nginxStable.override { openssl = pkgs.libressl; };
    virtualHosts = {
      "${cfg.domain}" = {
        forceSSL   = true;
        enableACME = true;
        locations."/.well-known/acme-challenge".root = "/var/lib/acme/acme-challenge";
        root = "/var/www/${cfg.domain}";
      };
      "warden.${cfg.domain}" = {
        forceSSL   = true;
        enableACME = true;
        locations."/.well-known/acme-challenge".root = "/var/lib/acme/acme-challenge";
        locations."/".proxyPass = "https://0.0.0.0:${toString cfg.vaultwarden_port}";
      };
      "sync.${cfg.domain}" = {
        forceSSL   = true;
        enableACME = true;
        locations."/.well-known/acme-challenge".root = "/var/lib/acme/acme-challenge";
        locations."/".proxyPass = "http://0.0.0.0:${toString cfg.syncthing_port}";
      };
    };
  };

  # defaults.group = "nginx" grants nginx read access to certificates —
  # the clean fix for the manual nginx/acme workaround from V1.
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = cfg.email_acme;
      group = "nginx";
    };
    certs."${cfg.domain}"        = {};
    certs."warden.${cfg.domain}" = {};
    certs."sync.${cfg.domain}"   = {};
  };

  ###############################################################
  # Packages & overlays
  ###############################################################

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
    vim
    wget
    fzf
    kitty
    sops
    hostname
    bashtop
    gtop
    postgresql
    cryptsetup
  ];

  ###############################################################
  # System version
  ###############################################################

  # Sourced from config.nix — must match the NixOS version used during
  # installation and must never be changed afterwards.
  system.stateVersion = cfg.nixos_state_version;
}