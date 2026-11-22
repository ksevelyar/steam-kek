# Orange Pi Zero 2w Hacks

## 1. UWE5622 Wi-Fi driver

* Current: Build the Armbian UWE5622 source into Linux and load `sprdwl_ng`.
* Code: [kernel source and configuration](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/hosts/steam-kek.nix), [UWE5622 source](https://github.com/armbian/uwe5622/tree/b64c5d6c36015049bdc34aad5f7b307545bfa29c)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 2. Wi-Fi device tree

* Current: Add the AW859A supplies, clock, reset and SDIO connection.
* Code: [Wi-Fi device tree patch](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/patches/orangepi-zero2w-wifi.patch)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 3. SDIO reset GPIO fallback

* Current: Treat `-ENOENT` as a missing reset controller and fall back to the reset GPIO.
* Code: [MMC power sequence patch](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/patches/mmc-pwrseq-simple-reset-gpio-fallback.patch)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 4. UWE5622 loopcheck null guard

* Current: Return an error if the WCN proc state is not initialized.
* Code: [loopcheck patch](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/patches/uwe5622-null-safe-loopcheck.patch), [UWE5622 source](https://github.com/armbian/uwe5622/tree/b64c5d6c36015049bdc34aad5f7b307545bfa29c)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 5. Wi-Fi firmware paths

* Current: Install uncompressed UWE5622 firmware and link `/lib/firmware` to `/run/current-system/firmware` in the SD image.
* Code: [firmware and image configuration](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/hosts/steam-kek.nix), [Armbian firmware](https://github.com/armbian/firmware/tree/f50a2a21bcdb77a562b3976930c5c6b521a1df08/uwe5622)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 6. H616 display engine and HDMI

* Current: Apply Armbian DRM patches and enable the board's HDMI connector and supply in the device tree.
* Code: [kernel and device tree configuration](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/hosts/steam-kek.nix), [HDMI device tree patch](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/patches/orangepi-zero2w-hdmi.patch), [Armbian DRM patches](https://github.com/armbian/build/tree/34e66c37211c70ef5cfad9c80dd76389720e19b7/patch/kernel/archive/sunxi-7.1/patches.drm)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 7. H616 video engine

* Current: Apply Armbian Cedrus and device tree patches, then select the H616 Cedrus variant.
* Code: [kernel and device tree configuration](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/hosts/steam-kek.nix), [variant patch](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/patches/cedrus-use-h616-variant.patch), [Armbian kernel patches](https://github.com/armbian/build/tree/34e66c37211c70ef5cfad9c80dd76389720e19b7/patch/kernel/archive/sunxi-7.1/patches.armbian)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 8. CPU frequency device tree

* Current: Apply Armbian's Zero 2W and Zero 3 CPU DVFS device tree patch.
* Code: [device tree configuration](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/hosts/steam-kek.nix), [Armbian DVFS patch](https://github.com/armbian/build/blob/34e66c37211c70ef5cfad9c80dd76389720e19b7/patch/kernel/archive/sunxi-7.1/patches.armbian/arm64-dts-sun50i-h618-orangepi-zero2w-zero3-cpu-dvfs.dtsi.patch)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 9. USB host rescan

* Current: Unbind and rebind the USB1 EHCI and OHCI controllers and disable their runtime autosuspend. The kernel command line also disables USB autosuspend.
* Code: [USB host service and kernel parameters](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/hosts/steam-kek.nix)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 10. Custom kernel and device tree build

* Current: Disable automatic kernel modules and built-in DTB compilation, ignore kernel configuration errors and compile the patched board DTB separately.
* Code: [kernel and device tree build](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/hosts/steam-kek.nix)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 11. nftables kernel options

* Current: Explicitly enable nftables, compatibility, connection tracking, logging, rejection and reverse-path filtering options.
* Code: [kernel configuration](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/hosts/steam-kek.nix)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 12. Avahi system call filter

* Current: Override the Avahi service's `SystemCallFilter` with an empty list.
* Code: [Avahi configuration](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/hosts/steam-kek.nix)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]

## 13. Cross-compilation overrides

* Current: Cross-compile for AArch64, disable fish documentation and build systemd without libbpf.
* Code: [flake cross-compilation configuration](https://github.com/ksevelyar/steam-kek/blob/95aadbdefd939bda7fd35bc926abf10ef7fe6b2a/flake.nix), [nixpkgs](https://github.com/NixOS/nixpkgs/tree/61b7c44c4073f0b827768aff0049561b5110ea5a)
* Why: [unknown]
* Remove and retest when: [unknown]
* Last tested: [unknown]
