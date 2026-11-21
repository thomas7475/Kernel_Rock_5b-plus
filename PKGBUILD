# Maintainer: Thomas <you@example.com>
# Contributor: 7Ji <pugokughin@gmail.com> (for the original PKGBUILD)
#
# Arch Linux ARM (aarch64) kernel for the Radxa ROCK 5B+ (RK3588), built from
# Collabora's hardware-enablement tree with the rocket NPU patch stack.
# Built automatically by GitHub Actions on an arm64 runner when a tag is
# pushed (release: v<version> on main; dev: <version>-dev, published as a
# pre-release) -- see .github/workflows/build-kernel.yml.

_desc="mainline kernel for Rockchip rk3588 with custom patches"

pkgbase=linux-aarch64-rockchip-collabora
pkgname=(
  "${pkgbase}"
  "${pkgbase}-headers"
)

# --- USER CONFIGURATION: START ---
#_commit='d0829c6423d74e7e20a8f547709671fdf355335a' # 6.19 collabora
#_commit='7c94261a67f7cbf1127e48bf3d2c2467e8b7a9de' # 7.2 collabora
#_commit='ecfd700eba45f9c1ad387a69275c8b39d7603809' # 7.3-rc7 collabora
#_commit='b43675945779c33b0fc93645152e62735774f3c2' # 7.3 collabora (rockchip-release)

# collabora "rockchip-devel" branch tip as of 2026-11-21, v7.4-rc3 based.
# The rocket patch series below was verified to apply to this exact commit
# under strict git am (18/18: 15 local patches + 3 downloaded originals).
_commit='6a63eca42acab19f062c5ad420f869c31effe47b'

_gittag='v7.4-rc3'
url="https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux.git"
# --- USER CONFIGURATION: END ---

_pkgver_sanitized=$(echo "${_gittag}" | sed -e 's/^v//' -e 's/-rc/rc/')
pkgver=${_pkgver_sanitized}.${_commit::7}

pkgrel=1
arch=('aarch64')
license=('GPL2')
# pahole is the current Arch/ALARM package name (renamed from 'dwarves');
# rust + rust-bindgen are needed because the config sets CONFIG_RUST=y.
makedepends=('git' 'kmod' 'bc' 'dtc' 'uboot-tools' 'pahole' 'python' 'rust' 'rust-bindgen')
options=(!strip)

_srcname="linux"

# Rocket NPU stack for the RK3588, 7.4-rc3 edition (18 patches, applied in
# the order listed in prepare()).
#
# Patches that needed NO modification for this tree are DOWNLOADED straight
# from their upstream home (github.com/gregordinary/patches, branch main);
# only patches that had to be adapted or reworked are kept in this
# repository (the 15 *.patch files in the patches/ subdirectory):
#
#  - 081-089 (local, unchanged): Igor Paunovic's DVFS series "[PATCH v2
#    00/11] accel/rocket: DVFS for the RK3588 NPU" (dri-devel, 2026-09-22),
#    minus 01/11 and 03/11 which kernel 7.3 already carries. These apply to
#    this tree as posted, but there is no URL makepkg could fetch them from:
#    lore.kernel.org answers curl/makepkg with 403 and patchwork with an
#    anti-bot challenge page, so they are carried on disk.
#  - 090, 091, 094, 095, 098 (local, adapted): gregordinary patches rebased
#    onto the DVFS series (same files as the 7.3 edition).
#  - 092 (local, reworked): gregordinary's extensible-uAPI patch, reworked
#    for 7.4-rc3's in-tree regcmd validation (ROCKET_MAX_REGCMDS /
#    ROCKET_REGCMD_ALIGN now live where its hunks used to land; both are
#    kept, and the validation still runs on every copied task).
#  - downloaded: batched-submit, irq-sync-before-reset and ppu-completion
#    apply to this tree exactly as upstream carries them, so no local copy
#    is kept. If raw.githubusercontent.com is unreachable, download the
#    three files from github.com/gregordinary/patches/tree/main/rocket and
#    replace the three https:// entries below with their file names.
source=(
  "${_srcname}::git+${url}#commit=${_commit}"
  'config'
  'patches/081-rocket-dvfs-number-cores-by-devicetree-position.patch'
  'patches/082-rocket-dvfs-keep-core-slots-stable-across-unbind.patch'
  'patches/083-rocket-dvfs-request-the-core-clocks-by-name.patch'
  'patches/084-rocket-dvfs-bindings-allow-dvfs-and-thermal.patch'
  'patches/085-rocket-dvfs-dts-add-an-opp-table-for-the-npu.patch'
  'patches/086-rocket-dvfs-restore-the-npu-clock-boot-rate.patch'
  'patches/087-rocket-dvfs-add-devfreq-support.patch'
  'patches/088-rocket-dvfs-register-a-devfreq-cooling-device.patch'
  'patches/089-rocket-dvfs-dts-add-passive-cooling.patch'
  'patches/090-rocket-drv-iommu-keepattach.patch'
  'patches/091-rocket-drv-fix-bo-mm-uaf.patch'
  'patches/092-rocket-drv-uapi-extensible-structs.patch'
  'patches/094-rocket-drv-reset-before-iommu-detach.patch'
  'patches/095-rocket-drv-irq-under-job-lock.patch'
  'patches/098-rocket-drv-suspend-after-reset.patch'
  'https://raw.githubusercontent.com/gregordinary/patches/main/rocket/086-rocket-drv-batched-submit.patch'
  'https://raw.githubusercontent.com/gregordinary/patches/main/rocket/091-rocket-drv-irq-sync-before-reset.patch'
  'https://raw.githubusercontent.com/gregordinary/patches/main/rocket/093-rocket-drv-ppu-completion.patch'
)

# The git source supports pacman's content pinning (checksum of the
# deterministic git-archive export). After changing _commit, regenerate all
# sums with `updpkgsums` (the 'SKIP' below only spares the regeneration
# until then); everything else is pinned to the verified content.
sha256sums=('SKIP'
            '793121219855e49d310ddf54300ebdb6a927034b6b9a211069ae03512f503692'
            '7fbdeec39b16f73b635141f448090959f8efa5ebd2473be4b49555fffbdbc7b7'
            '4adc1be4f7f9d4bc8f56f1a270691732317fddb22517469df5e171086ea9b13d'
            'c3157c8afd01671e7ed241519d3b30c369f342e12b0237c64064868963d3dea6'
            '93f186153a88609116cf02b73e3f6555adc2e130d15078d0b8bebb7af2829a7c'
            'c81c9038a6d9aad1301b25fe1924008db7d9449054312c87e5758b552a69e8e9'
            'aae0fcfef6e7b7a4fe30344daee5a3de4e855a4759ba3370c6d2bf7ce7c7015d'
            '0b3a7b5e8396d3dd5cb27aa6096cdedc5ea5cbe577a9b02f0b33eb6d39260583'
            'a17a99af78a7ae00bf99cd00a2e61ad13370e5ea62df25bdc5c1cdf112f7ad6c'
            'd8eab548bade5317d23cc17a6778c2990c4417c80fbd86b6fa042b90c4a328d9'
            '1325fedadc75af79efa5a63d5a87f74a90f663f424ab3c8cc8ef24689074517d'
            'a1c056110ecd67604ba5fc4a0e0b260a374f30ddeaaeee87a008cc1473415424'
            '5d02599ef53b6f7dd33c3658662be65428a365bf3c0474a913f81884d5815edd'
            '4a5f59e13a80ba587b5555c90bbefbd110c9b0b5efd40f1375a60e33eb8a8645'
            'bdec11000dd9b1e76e25fe1ac8206cfc2d163da5cfd93bdca7191f922eaa0dde'
            '69c621cf678f5e6abe6ed7a73b31540bc0fe669efc2e381fdc838766c0af8b8b'
            'cd318ae62ed5c2f183df90e27cbdc2982a62e3f621a8c1fe66f48d33ad328f61'
            'f1d7178645b5104d9b9d6765e7d75febf1b2adb771478e43e3e41ecbb76e87a8'
            '14c331c05ff3eac4c97de479565e3de76a79c504cd46c3a666548935831e9851')

prepare() {
  cd "${srcdir}/${_srcname}"

  # NOTE: .scmversion is dead (setlocalversion no longer reads it), so
  # nothing is needed to keep '+' out of the release string: the tree stays
  # clean because git am commits the patches, and the '-g<sha>' suffix is
  # governed by CONFIG_LOCALVERSION_AUTO in the config.

  # Stage the local patches into srcdir at a known path: makepkg stages
  # "patches/xxx.patch" source entries either flattened to the basename
  # or under the subdirectory depending on the pacman version, so do not
  # rely on its staging here.
  mkdir -p "${srcdir}/patches"
  cp -a "${startdir}/patches/." "${srcdir}/patches/"

  # --- APPLY ROCKET PATCHES (mbox; verified to apply at the pinned commit) ---
  # Slot order for the 7.4-rc3 stack; the three marked "downloaded" are the
  # unmodified upstream files fetched via the https:// source entries.
  local _rocket_patches=(
    '081-rocket-dvfs-number-cores-by-devicetree-position.patch'
    '082-rocket-dvfs-keep-core-slots-stable-across-unbind.patch'
    '083-rocket-dvfs-request-the-core-clocks-by-name.patch'
    '084-rocket-dvfs-bindings-allow-dvfs-and-thermal.patch'
    '085-rocket-dvfs-dts-add-an-opp-table-for-the-npu.patch'
    '086-rocket-dvfs-restore-the-npu-clock-boot-rate.patch'
    '087-rocket-dvfs-add-devfreq-support.patch'
    '088-rocket-dvfs-register-a-devfreq-cooling-device.patch'
    '089-rocket-dvfs-dts-add-passive-cooling.patch'
    '090-rocket-drv-iommu-keepattach.patch'
    '091-rocket-drv-fix-bo-mm-uaf.patch'
    '092-rocket-drv-uapi-extensible-structs.patch'
    '086-rocket-drv-batched-submit.patch'            # 093 slot (downloaded)
    '094-rocket-drv-reset-before-iommu-detach.patch'
    '095-rocket-drv-irq-under-job-lock.patch'
    '091-rocket-drv-irq-sync-before-reset.patch'    # 096 slot (downloaded)
    '093-rocket-drv-ppu-completion.patch'           # 097 slot (downloaded)
    '098-rocket-drv-suspend-after-reset.patch'
  )
  echo "Applying rocket NPU patch series (${#_rocket_patches[@]} patches)..."
  for _patch in "${_rocket_patches[@]}"; do
    echo "Applying ${_patch}..."
    git -c user.name='PKGBUILD' -c user.email='pkgbuild@localhost' am --3way "${srcdir}/${_patch}"
  done

  # --- SET KERNEL VERSION ---
  echo "-${pkgrel}" >localversion.10-pkgrel
  echo "-${pkgbase#linux-}" >localversion.20-pkgname

  # Prepare the configuration file.
  cp "${srcdir}/config" ./.config
}

build() {
  cd "${srcdir}/${_srcname}"

  # Update the .config file with default values for new options
  # (picks up the rocket driver's PM_DEVFREQ / governor selects).
  make olddefconfig prepare

  # Get the kernel version string
  make -s kernelrelease >version

  unset LDFLAGS
  make ${MAKEFLAGS} DTC_FLAGS="-@" Image modules dtbs
}

_package() {
  pkgdesc="The Linux Kernel and modules - ${_desc}"
  depends=('coreutils' 'initramfs' 'kmod')
  optdepends=(
    'uboot-legacy-initrd-hooks: to generate uboot legacy initrd images'
    'linux-firmware: firmware images needed for some devices'
    'wireless-regdb: to set the correct wireless channels of your country'
  )

  cd "${srcdir}/${_srcname}"

  local _kernver
  _kernver="$(<version)"
  local _dir_module="${pkgdir}/usr/lib/modules/${_kernver}"

  make INSTALL_MOD_PATH="${pkgdir}/usr" INSTALL_MOD_STRIP=1 modules_install
  make INSTALL_DTBS_PATH="${srcdir}/dtbs" dtbs_install

  install -D -m 644 /dev/stdin "${_dir_module}/pkgbase" <<<"${pkgbase}"
  install -Dm644 arch/arm64/boot/Image "${_dir_module}/vmlinuz"
  rm -f "${_dir_module}/"{build,source}

  # Install DTBs for Rockchip SoCs
  install -d -m 755 "${pkgdir}/boot/dtbs/${pkgbase}"
  cp -a "${srcdir}/dtbs/rockchip" "${pkgdir}/boot/dtbs/${pkgbase}/"
}

_package-headers() {
  pkgdesc="Header files and scripts for building modules for linux kernel - ${_desc}"
  depends=('pahole')

  cd "${srcdir}/${_srcname}"

  local _kernver
  _kernver="$(<version)"
  local _builddir="${pkgdir}/usr/lib/modules/${_kernver}/build"

  echo "Installing build files..."
  install -Dt "${_builddir}" -m644 .config Makefile Module.symvers System.map \
    localversion.* version vmlinux
  install -Dt "${_builddir}/kernel" -m644 kernel/Makefile
  install -Dt "${_builddir}/arch/arm64" -m644 arch/arm64/Makefile
  cp -t "${_builddir}" -a scripts

  echo "Installing headers..."
  cp -t "${_builddir}" -a include
  cp -t "${_builddir}/arch/arm64" -a arch/arm64/include
  install -Dt "${_builddir}/arch/arm64/kernel" -m644 arch/arm64/kernel/asm-offsets.s
  if [ -d rust ]; then
    echo "Installing Rust artifacts..."
    cp -t "${_builddir}" -a rust
  fi

  # Add headers for out-of-tree modules
  install -Dt "${_builddir}/drivers/md" -m644 drivers/md/*.h
  install -Dt "${_builddir}/net/mac80211" -m644 net/mac80211/*.h
  # Check if these files exist before installing to prevent failure if they move in future kernels
  for f in drivers/media/i2c/msp3400-driver.h \
           drivers/media/usb/dvb-usb/*.h \
           drivers/media/dvb-frontends/*.h \
           drivers/media/tuners/*.h \
           drivers/iio/common/hid-sensors/*.h; do
    if ls $f >/dev/null 2>&1; then
       install -Dt "${_builddir}/$(dirname $f)" -m644 $f
    fi
  done

  echo "Installing KConfig files..."
  find . -name 'Kconfig*' -exec install -Dm644 {} "${_builddir}/{}" \;

  echo "Cleaning up..."
  # Remove unneeded architectures
  for _arch in "${_builddir}"/arch/*/; do
    [[ ${_arch} = */arm64/ ]] && continue
    rm -r "${_arch}"
  done

  # -f: Documentation/ is only present because the Kconfig find above copied
  # Documentation/Kconfig* into it; guard against a tree without those files.
  rm -rf "${_builddir}/Documentation"
  find -L "${_builddir}" -type l -delete
  find "${_builddir}" -type f -name '*.o' -delete

  echo "Stripping build tools..."
  local file
  while read -rd '' file; do
    case "$(file -Sib "$file")" in
      application/x-sharedlib\;*) strip -v ${STRIP_SHARED} "$file" ;;
      application/x-archive\;*) strip -v ${STRIP_STATIC} "$file" ;;
      application/x-executable\;*) strip -v ${STRIP_BINARIES} "$file" ;;
      application/x-pie-executable\;*) strip -v ${STRIP_SHARED} "$file" ;;
    esac
  done < <(find "${_builddir}" -type f -perm -u+x ! -name vmlinux -print0)

  strip -v $STRIP_STATIC "${_builddir}/vmlinux"

  mkdir -p "${pkgdir}/usr/src"
  ln -sr "${_builddir}" "${pkgdir}/usr/src/${pkgbase}"
}

for _p in "${pkgname[@]}"; do
  eval "
    package_${_p}() {
      $(declare -f "_package${_p#$pkgbase}")
      _package${_p#$pkgbase}
    }
  "
done
