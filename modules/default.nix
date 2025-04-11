{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  inherit (config.image.repart.verityStore) partitionIds;
in
{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix" 
    "${modulesPath}/image/repart.nix"
  ];
  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "24.11";

  users.users.root.initialPassword = "nixos";

  environment.systemPackages = with pkgs; [
    neovim
    nano
    htop
    cryptsetup
  ];

  virtualisation.fileSystems = lib.mkVMOverride {
    "/" = {
      fsType = "tmpfs";
      options = [ "mode=0755" ];
    };

    "/usr" = {
      device = "/dev/mapper/usr";
      # explicitly mount it read-only otherwise systemd-remount-fs will fail
      options = [ "ro" ];
      fsType = config.image.repart.partitions.${partitionIds.store}.repartConfig.Format;
    };

    # bind-mount the store
    "/nix/store" = {
      device = "/usr/nix/store";
      options = [ "bind" ];
    };
  };

  image.repart = {
    verityStore = {
      enable = true;
      ukiPath = "/EFI/BOOT/BOOT${lib.toUpper config.nixpkgs.hostPlatform.efiArch}.EFI";
    };
    name = "test-image";
    partitions = {
      ${partitionIds.esp} = {
        # the UKI is injected into this partition by the verityStore module
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          SizeMinBytes = if config.nixpkgs.hostPlatform.isx86_64 then "64M" else "96M";
        };
      };
      ${partitionIds.store-verity}.repartConfig = {
        Minimize = "best";
      };
      ${partitionIds.store}.repartConfig = {
        Minimize = "best";
      };
    };
  };
  virtualisation = {
    directBoot.enable = false;
    mountHostNixStore = false;
    useEFIBoot = true;
  };

  boot = {
    loader.grub.enable = false;
    initrd.systemd.enable = true;
  };

  system.image = {
    id = "nixos-appliance";
    version = "1";
  };

  # don't create /usr/bin/env
  # this would require some extra work on read-only /usr
  # and it is not a strict necessity
  system.activationScripts.usrbinenv = lib.mkForce "";

}
