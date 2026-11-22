{
  pkgs,
  modulesPath,
  config,
  lib,
  armbianBuild,
  uwe5622Source,
  ...
}:
let
  linuxSourceWithUwe5622 = pkgs.runCommand "linux-${pkgs.linux_7_1.version}-with-uwe5622-source" {
    nativeBuildInputs = [
      pkgs.gnutar
      pkgs.xz
    ];
  } ''
    mkdir -p $out
    tar -xf ${pkgs.linux_7_1.src} --strip-components=1 -C $out
    cp -R --no-preserve=mode,ownership ${uwe5622Source} $out/drivers/net/wireless/uwe5622
    printf '%s\n' 'obj-$(CONFIG_SPARD_WLAN_SUPPORT) += uwe5622/' >> $out/drivers/net/wireless/Makefile
    printf '%s\n' 'source "drivers/net/wireless/uwe5622/Kconfig"' >> $out/drivers/net/wireless/Kconfig
  '';

  h616DrmCodePatchNames = [
    "0025-dt-bindings-sram-Document-Allwinner-H616-VE-SRAM.patch"
    "0026-dt-bindings-sram-sunxi-sram-Add-H616-SRAM-regions.patch"
    "0027-soc-sunxi-sram-Const-ify-sunxi_sram_func-data-and-re.patch"
    "0028-soc-sunxi-sram-Allow-SRAM-to-be-claimed-multiple-tim.patch"
    "0029-soc-sunxi-sram-Support-claiming-multiple-regions-per.patch"
    "0030-soc-sunxi-sram-Add-H616-SRAM-regions.patch"
    "0032-clk-sunxi-ng-de2-Fix-Display-Engine-3.3-definitions.patch"
    "0033-drm-sun4i-Add-support-for-DE33-CSC.patch"
    "0034-drm-sun4i-vi_layer-Limit-formats-for-DE33.patch"
    "0035-clk-sunxi-ng-de2-Export-register-regmap-for-DE33.patch"
    "0036-dt-bindings-display-allwinner-Add-DE33-planes.patch"
    "0037-drm-sun4i-Add-planes-driver.patch"
    "0038-dt-bindings-display-allwinner-Split-H616-DE33-layer-.patch"
    "0039-drm-sun4i-switch-DE33-to-new-bindings.patch"
    "0040-dt-bindings-display-Add-H616-display-engine-compatib.patch"
    "0041-drm-sun4i-Add-support-for-H616-TCON-TOP.patch"
    "0042-drm-sun4i-tcon-Add-support-for-R40-LCD.patch"
    "0043-drm-sun4i-Add-H616-TCON-TV-support.patch"
    "0044-drm-sun4i-Add-support-for-H616-HDMI-PHY.patch"
    "0045-drm-sun4i-Add-compatible-for-H616-display-engine.patch"
  ];

  h616DrmCodePatches = map (patchName: {
    name = "armbian-${patchName}";
    patch = "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.drm/${patchName}";
  }) h616DrmCodePatchNames;

  orangePiKernel = pkgs.linux_7_1.override {
    autoModules = false;
    buildDTBs = false;
    ignoreConfigErrors = true;
    argsOverride.src = linuxSourceWithUwe5622;
    kernelPatches = h616DrmCodePatches ++ [
      {
        name = "mmc-pwrseq-simple-reset-gpio-fallback";
        patch = ../patches/mmc-pwrseq-simple-reset-gpio-fallback.patch;
      }
      {
        name = "uwe5622-null-safe-loopcheck";
        patch = ../patches/uwe5622-null-safe-loopcheck.patch;
      }
      {
        name = "cedrus-h616-variant";
        patch = "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.armbian/drv-staging-media-sunxi-cedrus-add-H616-variant.patch";
      }
      {
        name = "cedrus-use-h616-variant";
        patch = ../patches/cedrus-use-h616-variant.patch;
      }
    ];
    structuredExtraConfig = with lib.kernel; {
      DRM_SUN4I = yes;
      DRM_SUN8I_DW_HDMI = yes;
      DRM_SUN8I_MIXER = yes;
      IP6_NF_MATCH_RPFILTER = module;
      IP_NF_MATCH_RPFILTER = module;
      NETFILTER_XT_MATCH_PKTTYPE = module;
      NF_TABLES = module;
      NF_TABLES_INET = yes;
      NF_TABLES_IPV4 = yes;
      NF_TABLES_IPV6 = yes;
      NFT_COMPAT = module;
      NFT_CT = module;
      NFT_LOG = module;
      NFT_REJECT = module;
      NFT_REJECT_INET = module;
      NFT_REJECT_IPV4 = module;
      NFT_REJECT_IPV6 = module;
      SND_SUN4I_CODEC = module;
      SPARD_WLAN_SUPPORT = yes;
      SUN50I_H6_PRCM_PPU = yes;
      UNISOC_WIFI_PS = yes;
      VIDEO_SUNXI = yes;
      VIDEO_SUNXI_CEDRUS = module;
      WLAN_UWE5622 = module;
    };
  };

  orangePiKernelPackages = pkgs.linuxPackagesFor orangePiKernel;

  orangePiDeviceTreeSource = pkgs.applyPatches {
    name = "orangepi-zero2w-device-tree-source";
    src = pkgs.linux_7_1.src;
    patches = [
      "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.drm/0031-arm64-dts-allwinner-sun50i-h616-Add-SRAM-nodes.patch"
      "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.drm/0046-arm64-dts-allwinner-h616-Add-display-pipeline.patch"
      ../patches/orangepi-zero2w-hdmi.patch
      ../patches/orangepi-zero2w-wifi.patch
      "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.armbian/arm64-dts-sun50i-h618-orangepi-zero2w-zero3-cpu-dvfs.dtsi.patch"
      "${armbianBuild}/patch/kernel/archive/sunxi-7.1/patches.armbian/arm64-dts-sun50i-h616-add-vpu-node.patch"
    ];
  };

  orangePiCompiledDeviceTree = pkgs.deviceTree.compileDTS {
    name = "sun50i-h618-orangepi-zero2w.dtb";
    dtsFile = "${orangePiDeviceTreeSource}/arch/arm64/boot/dts/allwinner/sun50i-h618-orangepi-zero2w.dts";
    includePaths = [
      "${orangePiDeviceTreeSource}/arch/arm64/boot/dts"
      "${orangePiDeviceTreeSource}/arch/arm64/boot/dts/allwinner"
      "${orangePiDeviceTreeSource}/include"
    ];
  };

  orangePiDeviceTree = pkgs.runCommand "orangepi-zero2w-device-tree-${pkgs.linux_7_1.version}" { } ''
    install -Dm644 ${orangePiCompiledDeviceTree} $out/allwinner/sun50i-h618-orangepi-zero2w.dtb
  '';

  uwe5622Firmware = pkgs.runCommand "uwe5622-firmware" { } ''
    install -Dm644 ${pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/armbian/firmware/f50a2a21bcdb77a562b3976930c5c6b521a1df08/uwe5622/wcnmodem.bin";
      hash = "sha256-EZuHzjCHVzSmdGL3KT+4/oWs8ycP6LeMl4riS+dxWoA=";
    }} $out/lib/firmware/uwe5622/wcnmodem.bin
    install -Dm644 ${pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/armbian/firmware/f50a2a21bcdb77a562b3976930c5c6b521a1df08/uwe5622/wifi_2355b001_1ant.ini";
      hash = "sha256-HzxA7CRajQuZrRwjcGWX1t1QCKuAzvt7zBlW78TpOPc=";
    }} $out/lib/firmware/wifi_2355b001_1ant.ini
  '';
in
{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];

  boot = {
    kernelPackages = orangePiKernelPackages;
    kernelParams = [
      "console=tty1"
      "console=ttyS0,115200n8"
      "usbcore.autosuspend=-1"
    ];
    kernelModules = [ "sprdwl_ng" ];
    initrd = {
      availableKernelModules = lib.mkForce [ "mmc_block" ];
      includeDefaultModules = false;
    };
    loader = {
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        configurationLimit = 1;
      };
    };
    supportedFilesystems = lib.mkForce [
      "vfat"
      "ext4"
    ];
  };

  hardware = {
    deviceTree = {
      enable = true;
      dtbSource = orangePiDeviceTree;
      name = "allwinner/sun50i-h618-orangepi-zero2w.dtb";
    };
    firmware = [ uwe5622Firmware ];
    firmwareCompression = "none";
    graphics.enable = true;
  };

  system.build.uboot = pkgs.ubootOrangePiZero3.override {
    defconfig = "orangepi_zero2w_defconfig";
  };

  sdImage = {
    compressImage = false;
    firmwareSize = 8;
    populateFirmwareCommands = "";
    populateRootCommands = ''
      mkdir -p ./files/boot ./files/lib
      ln -s /run/current-system/firmware ./files/lib/firmware
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
    retroarch
    libretro.mesen
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
    dtc
    usbutils
    stress-ng
  ];

  environment.defaultPackages = [ ];

  nix = {
    daemonCPUSchedPolicy = "idle";
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      extra-substituters = [ "https://idempotent-desktop.cachix.org" ];
      extra-trusted-public-keys = [
        "idempotent-desktop.cachix.org-1:21i2Mb/mrJ9XcfmksWpaYMr78ZPbwxhX/BwSS1X+PRw="
      ];
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  system.stateVersion = "25.11";

  security.rtkit.enable = true;

  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
    openssh = {
      enable = true;
      startWhenNeeded = false;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
      };
    };
    avahi = {
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
    getty.autologinUser = "root";
  };

  systemd.services.avahi-daemon.serviceConfig.SystemCallFilter = lib.mkForce [ ];

  systemd.services.usb-host-rescan = {
    description = "Rescan USB1 host devices after PHY initialization";
    wantedBy = [ "multi-user.target" ];
    after = [
      "local-fs.target"
      "systemd-modules-load.service"
    ];
    path = [ pkgs.coreutils ];
    unitConfig.ConditionPathExists = "/sys/bus/platform/devices/5200000.usb";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "usb-host-rescan" ''
        set -eu

        if [ -L /sys/bus/platform/devices/5200000.usb/driver ]; then
          printf '5200000.usb' > /sys/bus/platform/drivers/ehci-platform/unbind
        fi
        if [ -L /sys/bus/platform/devices/5200400.usb/driver ]; then
          printf '5200400.usb' > /sys/bus/platform/drivers/ohci-platform/unbind
        fi

        sleep 1
        printf '5200400.usb' > /sys/bus/platform/drivers/ohci-platform/bind
        sleep 1
        printf '5200000.usb' > /sys/bus/platform/drivers/ehci-platform/bind

        for powerControlPath in /sys/bus/platform/devices/5200*.usb/usb*/power/control; do
          [ -e "$powerControlPath" ] || continue
          printf 'on' > "$powerControlPath"
        done
      '';
    };
  };

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.fish;
    users = {
      root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrgLo+NfYI06fdY1BamC5o2tNeRlw1ZuPAkyy41w0Ir ksevelyar@gmail.com"
      ];
      ksevelyar = {
        isNormalUser = true;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOrgLo+NfYI06fdY1BamC5o2tNeRlw1ZuPAkyy41w0Ir ksevelyar@gmail.com"
        ];
        extraGroups = [
          "wheel"
          "dialout"
        ];
      };
    };
  };

  programs.fish = {
    enable = true;
    generateCompletions = false;
    interactiveShellInit = ''
      set fish_greeting
      set temperature (cat /sys/devices/virtual/thermal/thermal_zone0/temp 2>/dev/null)
      test -n "$temperature"; and echo "🌡️ "(math -s 0 "$temperature / 1000")"C"
    '';
  };

  networking = {
    networkmanager.wifi.powersave = false;
    usePredictableInterfaceNames = false;
    hostName = "steam-kek";
    useDHCP = true;
    firewall.enable = true;
  };

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  security.polkit.enable = true;
  time.timeZone = "Europe/Moscow";
}
