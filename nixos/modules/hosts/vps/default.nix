{ inputs, self, configDir, ... }:
let
  lib = inputs.nixpkgs.lib;
in {
  flake.nixosConfigurations = lib.optionalAttrs
    (builtins.pathExists "${configDir}/config-vps.nix")
    (let
      cfg           = import "${configDir}/config-vps.nix";
      _runtimeCheck = if lib.elem cfg.container_runtime [ "flake" "podman" "docker" ] then null
        else abort "config-vps.nix: container_runtime must be flake|podman|docker, got \"${cfg.container_runtime}\"";
    in {
      ${cfg.hostname} = inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit cfg; flakeDir = configDir; };
        modules = [
          inputs.sops-nix.nixosModules.sops
          "${configDir}/hardware-configuration-vps.nix"

          ({ config, lib, pkgs, flakeDir, ... }: {
            nix.settings.experimental-features = [ "nix-command" "flakes" ];
            nix.settings.auto-optimise-store   = true;
            nix.gc = {
              automatic = true;
              dates     = "weekly";
              options   = "--delete-older-than 7d";
            };

            boot.loader.grub.enable = true;

            networking.hostName = cfg.hostname;
            networking.firewall = {
              enable = true;
              allowedTCPPorts = [ 80 443 cfg.initrd_ssh_port ];
              allowedUDPPorts = [ 51820 ];
            };

            time.timeZone      = cfg.timezone;
            i18n.defaultLocale = cfg.locale_lang;
            console.keyMap              = cfg.keyboard_console;
            services.xserver.xkb.layout = cfg.keyboard_x11;

            sops = {
              defaultSopsFile = "${flakeDir}/secrets/secrets-vps.yaml";
              age.keyFile     = "/root/.config/sops/age/keys.txt";
              secrets = {
                vps_root_password.neededForUsers  = true;
                vps_admin_password.neededForUsers = true;
              };
            };

            users.users = {
              root.hashedPasswordFile = config.sops.secrets.vps_root_password.path;

              ${cfg.admin_username} = {
                isNormalUser = true;
                home         = "/home/${cfg.admin_username}";
                extraGroups  = [ "wheel" ];
                hashedPasswordFile = config.sops.secrets.vps_admin_password.path;
                openssh.authorizedKeys.keys = [ cfg.admin_ssh_key ];
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

            virtualisation.docker.enable = true;
            virtualisation.podman = {
              enable       = true;
              dockerCompat = false;
            };

            environment.systemPackages = with pkgs; [ vim git wget sops ];

            system.stateVersion = cfg.nixos_state_version;
          })

          self.nixosModules.pangolin-server
        ];
      };
    });
}