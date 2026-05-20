{
  ###############################################################
  # NixOS version
  ###############################################################

  nixos_state_version = "25.11";

  ###############################################################
  # System
  ###############################################################

  hostname = "vps";
  timezone = "America/Bogota";

  locale_lang = "en_US.UTF-8";

  keyboard_console = "es";
  keyboard_x11     = "es";

  ###############################################################
  # Users
  ###############################################################

  admin_username = "coyote";
  admin_ssh_key  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ/6wS3VY+sTtX7NEEZgwa1ojx+J2sg6TuY4Z3k60A17 coyote@alfabeto.digital";

  initrd_ssh_port = 2222;

  ###############################################################
  # Network / tunnel (Pangolin server)
  ###############################################################

  domain        = "alfabeto.digital";

  # Public IP of this VPS. Fill before first deploy.
  vps_ip        = "FILL_VPS_PUBLIC_IP";

  # Internal Pangolin API port (Gerbil connects here).
  pangolin_port = 3000;

  # WireGuard peer IP assigned by Pangolin to the Newt client on alfabeto.digital.
  # Fill after the first Newt connection (visible in Pangolin admin panel → Sites → peers).
  newt_peer_ip  = "FILL_AFTER_NEWT_CONNECTS";

  ###############################################################
  # Container runtime
  ###############################################################

  # "flake"  = native NixOS services (pkgs.fosrl-pangolin, pkgs.fosrl-gerbil, services.traefik)
  # "podman" = OCI containers via virtualisation.oci-containers + Podman backend
  # "docker" = OCI containers via virtualisation.oci-containers + Docker backend
  # Docker and Podman are ALWAYS installed on the VPS regardless of this value.
  container_runtime = "flake";
}
