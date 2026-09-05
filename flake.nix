{
  description = "nixos-config — laptop system config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      system = "x86_64-linux";
      username = "scooke";
      fullName = "Sean Cooke";
      specialArgs = { inherit username fullName; };
    in {
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          ./nixos/configuration.nix
          ./nixos/hardware-configuration.nix
          { networking.hostName = "laptop"; }
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit username; };
            # GNOME rewrites ~/.config/monitors.xml, replacing the symlink
            # Home Manager owns. Move it aside instead of failing activation.
            home-manager.backupFileExtension = "hm-bak";
            home-manager.users.${username} = import ./home-manager/home.nix;
          }
        ];
      };
    };
}
