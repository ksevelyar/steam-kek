{
  description = "NixOS SD image for Orange Pi Zero 2W";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/61b7c44c4073";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    armbian-build = {
      url = "github:armbian/build/34e66c37211c70ef5cfad9c80dd76389720e19b7";
      flake = false;
    };
    uwe5622-source = {
      url = "github:armbian/uwe5622/b64c5d6c36015049bdc34aad5f7b307545bfa29c";
      flake = false;
    };
  };

  outputs =
    { nixpkgs, agenix, armbian-build, uwe5622-source, ... }:
    let
      steamKekConfiguration = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          armbianBuild = armbian-build;
          uwe5622Source = uwe5622-source;
        };
        modules = [
          agenix.nixosModules.default
          ./hosts/steam-kek.nix
          ({ config, ... }: {
            environment.etc."ssh/host-agenix-key" = {
              source = /home/ksevelyar/.ssh/guest_ed25519_key;
              mode = "0600";
            };

            age = {
              identityPaths = [ "/etc/ssh/host-agenix-key" ];
              secrets.wifi.file = ./secrets/wifi.age;
              secrets.root-password.file = ./secrets/root-password.age;
            };

            users.users = {
              root.hashedPasswordFile = config.age.secrets.root-password.path;
              ksevelyar.hashedPasswordFile = config.age.secrets.root-password.path;
            };

            networking.wireless = {
              enable = true;
              secretsFile = config.age.secrets.wifi.path;
              networks.fellowship-of-the-ring-2.pskRaw = "ext:fellowship-of-the-ring";
            };

            nixpkgs = {
              config.allowUnsupportedSystem = true;
              crossSystem.system = "aarch64-linux";
              overlays = [
                (final: previous: {
                  fish = previous.fish.overrideAttrs (previousAttributes: {
                    cmakeFlags = previousAttributes.cmakeFlags ++ [ "-DWITH_DOCS=OFF" ];
                  });
                  systemd = previous.systemd.override { withLibBPF = false; };
                })
              ];
            };
          })
        ];
      };
    in
    {
      nixosConfigurations = {
        steam-kek = steamKekConfiguration;
        steam-kek-ci = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          specialArgs = {
            armbianBuild = armbian-build;
            uwe5622Source = uwe5622-source;
          };
          modules = [ ./hosts/steam-kek.nix ];
        };
      };
    };
}
