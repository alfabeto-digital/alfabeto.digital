# Placeholder — replace with the output of:
#   nixos-generate-config --show-hardware-config
# Run on the VPS after installing NixOS. Most KVM/QEMU VPS use virtio drivers.
{ modulesPath, ... }: {
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_blk" ];
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };
  boot.loader.grub.device = "/dev/vda";
}
