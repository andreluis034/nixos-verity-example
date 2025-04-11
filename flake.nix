{
  description = "NixOS system image with repart, pinned to 24.11";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };

  outputs = { self, ... }:
    {
      nixosConfigurations.image = self.inputs.nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
      
        modules = [ 
           ./modules
        ];
      };

      packages.x86_64-linux.default = self.nixosConfigurations.image.config.system.build.image;
    };
}
