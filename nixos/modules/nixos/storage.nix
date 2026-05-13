{ inputs, ... }: {
  flake.nixosModules.storage = { config, lib, pkgs, cfg, storagePath, dataPath, ... }: {

    fileSystems."${storagePath}" = {
      device  = "/dev/disk/by-uuid/${cfg.storage_uuid}";
      fsType  = "ext4";
      options = [ "nofail" ];
    };

    systemd.services.unlock-data-disk = {
      description = "Unlock LUKS data disk (nvme1)";
      wantedBy    = [ "multi-user.target" ];
      before      = [ "postgresql.service" ];
      after       = [ "systemd-udev-settle.service" ];
      wants       = [ "systemd-udev-settle.service" ];
      unitConfig.ConditionPathExists = "!/dev/mapper/data-disk";
      serviceConfig = {
        Type            = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        ${pkgs.systemd}/bin/udevadm settle
        ${pkgs.cryptsetup}/bin/cryptsetup open \
          /dev/disk/by-uuid/${cfg.data_disk_uuid} \
          data-disk \
          --key-file ${config.sops.secrets.luks_data_key.path}
      '';
    };

    fileSystems."${dataPath}" = {
      device  = "/dev/mapper/data-disk";
      fsType  = "ext4";
      options = [ "x-systemd.requires=unlock-data-disk.service" ];
    };

    systemd.tmpfiles.rules = [
      "d ${storagePath}                                           0750 ${cfg.admin_username}       storage                     - -"
      "d ${storagePath}/exchange                                  0750 ${cfg.admin_username}       storage                     - -"
      "d ${storagePath}/exchange/vaultwarden                      0750 ${cfg.vaultwarden_username} ${cfg.vaultwarden_username}  - -"
      "d ${storagePath}/exchange/syncthing                        0750 ${cfg.syncthing_username}   storage                     - -"
      "d ${storagePath}/helios         0755 ${cfg.syncthing_username} storage - -"
      "d /var/www/${cfg.domain}       0755 caddy                   caddy   - -"
      "d ${dataPath}            0750 postgres postgres - -"
      "d ${dataPath}/postgresql 0750 postgres postgres - -"
    ];
  };
}
