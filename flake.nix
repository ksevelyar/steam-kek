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
          armbianBuild = pkgs.fetchFromGitHub {
            owner = "armbian";
            repo = "build";
            rev = "259c7b157f9cc7968f077f5483ff0537f691c712";
            hash = "sha256-xHYF4aenAwqPDWW7UdrkE+gOnN/dvUMFyzVoBB4R3fg=";
          };
          armbianFirmware = pkgs.fetchFromGitHub {
            owner = "armbian";
            repo = "firmware";
            rev = "4050e02da2dce2b74c97101f7964ecfb962f5aec";
            hash = "sha256-wc4xyNtUlONntofWJm8/w0KErJzXKHijOyh9hAYTCoU=";
          };
          uwe5622 = pkgs.fetchFromGitHub {
            owner = "armbian";
            repo = "uwe5622";
            rev = "ce59d2aafbdad2cd740ee203053ccfba058a20bc";
            hash = "sha256-QruvPN21BoYxSj6KQWkguytZjv08fsubrTFDE/W4XGw=";
          };
          linuxSource = pkgs.runCommand "linux-6.18.44-uwe5622-source" {nativeBuildInputs = [pkgs.xz];} ''
            mkdir $out
            tar -xf ${pkgs.linux_6_18.src} -C $out --strip-components=1
            cd $out
            mkdir -p drivers/net/wireless/uwe5622
            cp -R ${uwe5622}/{tty-sdio,unisocwcn,unisocwifi,Kconfig,Makefile} drivers/net/wireless/uwe5622/
            echo 'obj-$(CONFIG_SPARD_WLAN_SUPPORT) += uwe5622/' >> drivers/net/wireless/Makefile
            sed -i '/source "drivers\/net\/wireless\/ti\/Kconfig"/a source "drivers/net/wireless/uwe5622/Kconfig"' drivers/net/wireless/Kconfig
          '';
          linux_6_18 = pkgs.linux_6_18.override {
            src = linuxSource;
            argsOverride = {
              src = linuxSource;
            };
          };
          linuxPackages = pkgs.linuxPackagesFor linux_6_18;
          uwe5622Firmware = pkgs.runCommand "uwe5622-firmware" {} ''
            mkdir -p $out/lib/firmware
            cp -R ${armbianFirmware}/uwe5622 $out/lib/firmware/
          '';
          drmPatch = name: {
            inherit name;
            patch = "${armbianBuild}/patch/kernel/archive/sunxi-6.18/patches.drm/${name}.patch";
          };
          drmPatches = map drmPatch [
            "0001-drm-sun4i-mixer-Fix-up-DE33-channel-macros"
            "0002-drm-sun4i-mixer-Remove-ccsc-cfg-for-DE3"
            "0003-drm-sun4i-de2-Initialize-layer-fields-earlier"
            "0004-drm-sun4i-ui_layer-Move-check-from-update-to-check-c"
            "0005-drm-sun4i-vi_layer-Move-check-from-update-to-check-c"
            "0006-drm-sun4i-layers-Make-atomic-commit-functions-void"
            "0007-drm-sun4i-Move-blender-config-from-layers-to-mixer"
            "0008-drm-sun4i-ui-layer-Write-attributes-in-one-go"
            "0009-drm-sun4i-vi-layer-Write-attributes-in-one-go"
            "0010-drm-sun4i-mixer-Move-layer-enabling-to-atomic_update"
            "0011-drm-sun4i-de2-de3-Simplify-CSC-config-interface"
            "0012-drm-sun4i-csc-Simplify-arguments-with-taking-plane-s"
            "0013-drm-sun4i-de2-de3-Move-plane-type-determination-to-m"
            "0014-drm-sun4i-ui_layer-Change-index-meaning"
            "0015-drm-sun4i-layer-move-num-of-planes-calc-out-of-layer"
            "0016-drm-sun4i-ui_layer-use-layer-struct-instead-of-multi"
            "0017-drm-sun4i-vi_layer-use-layer-struct-instead-of-multi"
            "0018-drm-sun4i-ui_scaler-use-layer-instead-of-mixer-for-a"
            "0019-drm-sun4i-vi_scaler-use-layer-instead-of-mixer-for-a"
            "0020-drm-sun4i-layers-Make-regmap-for-layers-configurable"
            "0021-drm-sun4i-csc-use-layer-arg-instead-of-mixer"
            "0022-drm-sun4i-layers-add-physical-index-arg"
            "0023-drm-sun4i-vi_scaler-Update-DE33-base-calculation"
            "0024-drm-sun4i-mixer-Convert-heuristics-to-quirk"
            "0025-drm-sun4i-ui_scaler-drop-sanity-checks"
            "0026-drm-sun4i-mixer-Add-quirk-for-number-of-VI-scalers"
            "0027-drm-sun4i-mixer-split-out-layer-config"
            "0028-drm-sun4i-layer-replace-mixer-with-layer-struct"
            "0029-drm-sun4i-vi_scaler-Find-mixer-from-crtc"
            "0030-drm-sun4i-Nuke-mixer-pointer-from-layer-code"
            "0031-drm-sun4i-Add-support-for-DE33-CSC"
            "0032-drm-sun4i-vi_layer-Limit-formats-for-DE33"
            "0033-clk-sunxi-ng-de2-Export-register-regmap-for-DE33"
            "0034-dt-bindings-display-allwinner-Add-DE33-planes"
            "0035-drm-sun4i-Add-planes-driver"
            "0036-dt-bindings-display-allwinner-Update-H616-DE33-bindi"
            "0037-drm-sun4i-switch-DE33-to-new-bindings"
            "0038-drm-sun4i-Add-H616-TCON-TV-support"
            "0039-srm-sun4i-Add-support-for-H616-HDMI-PHY"
            "0040-drm-sun4i-Add-compatible-for-H616-display-engine"
            "0041-arm64-dts-allwinner-h616-Add-display-pipeline"
          ];
          # Fish's documentation generator cannot run while cross-compiling.
          fish = pkgs.fish.overrideAttrs (old: {
            cmakeFlags = (old.cmakeFlags or []) ++ ["-DWITH_DOCS=OFF"];
          });
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
            kernelPackages = linuxPackages;
            kernelPatches = drmPatches ++ [
              {
                name = "orangepi-zero2w-wifi-hdmi";
                patch = ./patches/orangepi-zero2w-wifi-hdmi.patch;
                structuredExtraConfig = with lib.kernel; {
                  SPARD_WLAN_SUPPORT = yes;
                  WLAN_UWE5622 = module;
                  TTY_OVERY_SDIO = module;
                  CFG80211 = module;
                  PWRSEQ_SIMPLE = yes;
                  DRM_SUN4I = yes;
                  DRM_SUN8I_MIXER = yes;
                };
              }
            ];
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

          hardware.firmware = [uwe5622Firmware];
          hardware.firmwareCompression = "none";
          boot.kernelModules = ["sprdwl_ng"];

          system.build.uboot = pkgs.buildUBoot {
            defconfig = "orangepi_zero2w_defconfig";
            extraMeta.platforms = ["aarch64-linux"];
            env.BL31 = "${pkgs.armTrustedFirmwareAllwinnerH616}/bl31.bin";
            filesToInstall = ["u-boot-sunxi-with-spl.bin"];
          };

          sdImage = {
            populateFirmwareCommands = "";
            populateRootCommands = ''
              mkdir -p ./files/boot
              ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
            '';
            postBuildCommands = ''
              dd if=${config.system.build.uboot}/u-boot-sunxi-with-spl.bin of=$img bs=1024 seek=8 conv=notrunc
            '';
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
          users.defaultUserShell = fish;
          programs.fish.enable = true;
          programs.fish.package = fish;
          programs.fish.generateCompletions = false;
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
