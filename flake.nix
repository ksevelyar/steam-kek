{
  description = "NixOS sdImage for Orange Pi Zero 2W";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    nixpkgs,
    agenix,
    ...
  }: let
    buildSystem = "x86_64-linux";
    lib = nixpkgs.lib;
  in {
    nixosConfigurations.steam-kek = lib.nixosSystem {
      system = buildSystem;
      modules = [
        agenix.nixosModules.default
        ({
          pkgs,
          modulesPath,
          config,
          ...
        }: let
          hostAgenixKey = pkgs.writeText "host-agenix-key" (builtins.readFile /home/ksevelyar/.ssh/guest_ed25519_key);
        in {
          imports = [
            (modulesPath + "/installer/sd-card/sd-image.nix")
            (modulesPath + "/profiles/minimal.nix")
          ];

          environment.etc."ssh/host-agenix-key" = {
            source = /home/ksevelyar/.ssh/guest_ed25519_key;
            mode = "0600";
          };

          age = {
            identityPaths = ["/etc/ssh/host-agenix-key"];
            secrets.wifi.file = ./secrets/wifi.age;
            secrets.root-password.file = ./secrets/root-password.age;
          };

          boot = {
            consoleLogLevel = 1;
            kernelParams = [
              "console=ttyS0,115200n8"
              "console=tty0"
            ];
            loader = {
              grub.enable = false;
              generic-extlinux-compatible.enable = true;
              generic-extlinux-compatible.configurationLimit = 1;
            };
            initrd.availableKernelModules = [
              "xhci_pci"
              "usbhid"
              "usb_storage"
            ];
            supportedFilesystems = lib.mkForce ["vfat" "ext4"];
          };

          hardware.deviceTree = {
            enable = true;
            name = "allwinner/sun50i-h618-orangepi-zero2w.dtb";
          };

          system.build.uboot = pkgs.buildUBoot {
            defconfig = "orangepi_zero2w_defconfig";
            extraMeta.platforms = ["aarch64-linux"];
            env.BL31 = "${pkgs.armTrustedFirmwareAllwinnerH616}/bl31.bin";
            filesToInstall = ["u-boot-sunxi-with-spl.bin"];
          };

          documentation.enable = false;
          documentation.man.cache.enable = false;
          services.lvm.enable = false;

          environment.systemPackages = with pkgs; [
            rsync
            lm_sensors
            powertop
            vim
            zoxide
            bat
            fd
            fzf
            ripgrep
            tealdeer
            bottom
            macchina

            # debug
            dtc
            usbutils
            stress-ng
          ];

          environment.defaultPackages = [];

          nix = {
            daemonCPUSchedPolicy = "idle";
            extraOptions = ''
              experimental-features = nix-command flakes
            '';
          };
          nixpkgs = {
            config.allowUnsupportedSystem = true;
            crossSystem.system = "aarch64-linux";
          };

          zramSwap = {
            enable = true;
            algorithm = "zstd";
          };

          system.stateVersion = "25.11";

          services.openssh = {
            enable = true;
            startWhenNeeded = false;
            settings = {
              PermitRootLogin = "prohibit-password";
              PasswordAuthentication = false;
            };
          };

          # NOTE: fix setgroups crash on arm
          systemd.services.avahi-daemon.serviceConfig.SystemCallFilter = lib.mkForce [];
          services.avahi = {
            enable = true;
            ipv6 = false;
            nssmdns4 = true;
            publish = {
              enable = true;
              addresses = true;
              domain = true;
              workstation = true;
            };
          };

          services.getty.autologinUser = "root";
          users.defaultUserShell = pkgs.fish;
          programs.fish.enable = true;
          programs.fish.interactiveShellInit = ''
            set fish_greeting

            set temp (cat /sys/devices/virtual/thermal/thermal_zone0/temp 2>/dev/null)
            test -n "$temp"; and echo "🌡️ "(math -s 0 "$temp / 1000")"C"
          '';

          users.mutableUsers = false;
          users.users = {
            root = {
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrgLo+NfYI06fdY1BamC5o2tNeRlw1ZuPAkyy41w0Ir ksevelyar@gmail.com"
              ];
              hashedPasswordFile = config.age.secrets.root-password.path;
            };

            ksevelyar = {
              isNormalUser = true;
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrgLo+NfYI06fdY1BamC5o2tNeRlw1ZuPAkyy41w0Ir ksevelyar@gmail.com"
              ];
              hashedPasswordFile = config.age.secrets.root-password.path;

              extraGroups = ["wheel" "dialout"];
            };
          };

          networking = {
            networkmanager.wifi.powersave = false;
            usePredictableInterfaceNames = false;
            hostName = "steam-kek";

            useDHCP = true;
            # interfaces.wlan0.useDHCP = true;

            wireless = {
              enable = true;
              secretsFile = config.age.secrets.wifi.path;
              networks.fellowship-of-the-ring-2 = {
                pskRaw = "ext:fellowship-of-the-ring";
              };
            };
          };

          powerManagement = {
            enable = true;
            cpuFreqGovernor = "powersave";
          };

          networking.firewall = {
            enable = true;
          };

          security.polkit.enable = true;

          time.timeZone = "Europe/Moscow";
        })
      ];
    };
  };
}
