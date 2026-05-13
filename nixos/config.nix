{
  ###############################################################
  # NixOS versions
  ###############################################################

  # Used in flake.nix to set the channel URLs for nixpkgs and home-manager.
  nixos_channel_version = "25.11";

  # Reflects the NixOS version at initial installation.
  # Used for system.stateVersion and home.stateVersion.
  # Must NEVER be changed after the first build.
  nixos_state_version = "25.11";

  ###############################################################
  # System
  ###############################################################

  hostname = "alfabeto-digital";
  timezone = "America/Bogota";

  # Locale — each LC category is configurable independently.
  locale_lang           = "en_US.UTF-8";  # LANG and LC_MESSAGES
  locale_collate        = "C";
  locale_time           = "es_CO.UTF-8";
  locale_numeric        = "es_CO.UTF-8";
  locale_monetary       = "es_CO.UTF-8";
  locale_measurement    = "es_CO.UTF-8";
  locale_paper          = "es_CO.UTF-8";
  locale_address        = "es_CO.UTF-8";
  locale_telephone      = "es_CO.UTF-8";
  locale_name           = "es_CO.UTF-8";
  locale_identification = "es_CO.UTF-8";

  # Keyboard
  keyboard_console = "es";  # console keymap  (loadkeys)
  keyboard_x11     = "es";  # X11 keymap      (localectl set-x11-keymap)

  ###############################################################
  # Users
  ###############################################################

  admin_username     = "coyote";
  # SSH public key for the admin user and initrd unlock.
  # Not a secret — paste the full contents of ~/.ssh/id_ed25519.pub here.
  admin_ssh_key      = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFDzt0xpIooI9TG2oITP+p23Ju8IBbn5YPnsiaw2YnnV services@alfabeto.digital"; # <-- REPLACE
  syncthing_username = "syncthing";
  vaultwarden_username = "vaultwarden";
  ftp_username       = "ftp";

  ###############################################################
  # Database
  ###############################################################

  db_name     = "quipu";
  db_username = "quipucamayoc";

  # nvme1 (data disk) is mounted at:
  #   <data_mount_point>/<db_name>  →  /mnt/data/quipu
  data_mount_point = "/mnt/data";

  # nvme1 LUKS UUID — fill after partitioning nvme1:
  #   blkid /dev/nvme1n1
  data_disk_uuid = ""; # <-- FILL AFTER INSTALLATION

  ###############################################################
  # Storage (external disk — not yet encrypted)
  ###############################################################

  # Mounted at:
  #   <storage_mount_point>/<storage_name>  →  /mnt/storage/virgilio
  storage_mount_point = "/mnt/storage";
  storage_name        = "virgilio";

  # External disk UUID
  storage_uuid = "6b668f05-9700-4bdf-9924-341bac87eed6";

  ###############################################################
  # Domain & ACME
  ###############################################################

  domain     = "alfabeto.digital";
  email_acme = "services@alfabeto.digital";

  ###############################################################
  # Service ports
  ###############################################################

  vaultwarden_port   = 8222;
  syncthing_port     = 8384;
  domain_tunnel_port = 8081;  # localhost-only HTTP for Cloudflare tunnel
  ftp_port           = 21;
  initrd_ssh_port    = 2222;

  # Paso 3 — communications & security services (all internal; exposed via Caddy in Paso 4)
  adguard_port  = 3000;    # AdGuard Home admin UI
  authelia_port = 9091;    # Authelia SSO / 2FA
  dendrite_port = 8008;    # Dendrite Matrix homeserver HTTP
  stalwart_port = 8080;    # Stalwart Mail management
  ntfy_port     = 2586;    # ntfy push notifications
}