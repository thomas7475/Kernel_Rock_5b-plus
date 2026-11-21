# Kernel Rock 5B+

Arch Linux ARM (aarch64) kernel packages for the **Radxa ROCK 5B+ (RK3588)**, built in two tracks that share one repository, one workflow and one rocket NPU patch stack (Gregory's [rocket series](https://github.com/gregordinary/patches) + Igor Paunović's [DVFS series](https://lore.kernel.org/r/20260922080114.44662-1-royalnet026@gmail.com)):

| track | branch | kernel source | package |
|---|---|---|---|
| **release** | `main` | mainline **stable** from kernel.org (e.g. `v7.3.5`) | `linux-aarch64-rockchip` |
| **development** | `dev` | [Collabora's rockchip-devel tree](https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux.git) (e.g. `v7.4-rc3` based) | `linux-aarch64-rockchip-collabora` |

The rocket NPU base driver has been part of mainline since 7.3 (`drivers/accel/rocket`), and mainline 7.3 ships the `rk3588-rock-5b-plus.dts` board description — so the stable track carries the same NPU stack as the development track, on a kernel that only contains released, reviewed code.

The kernel is built automatically by GitHub Actions on a free arm64 runner whenever a tag is pushed; the resulting packages are attached to a GitHub Release.

## Packages

| package | contents |
|---|---|
| `linux-aarch64-rockchip` (release track) | `Image` (as `vmlinuz`), all Rockchip DTBs, modules |
| `linux-aarch64-rockchip-headers` | headers for out-of-tree module builds |
| `linux-aarch64-rockchip-collabora` (dev track) | same contents, experimental tree |
| `linux-aarch64-rockchip-collabora-headers` | headers for out-of-tree module builds |

The two package names differ on purpose, so the stable and the development kernel can be installed side by side on one board (they use different `/usr/lib/modules/<kernver>` directories and `/boot/dtbs/<pkgbase>`).

The NPU runs with devfreq at 200 MHz–1 GHz (OPP table + passive cooling included), and the driver carries the keep-attached IOMMU, batched-submit and IRQ/reset-path fixes from the rocket series. See the patch comments in the `PKGBUILD` for the full story.

## Repository layout

```
PKGBUILD                        the package recipe (pin, sources, packaging)
config                          kernel .config (CONFIG_RUST=y, aarch64)
patches/                        the 15 patches that needed adaptation for this
                                tree (DVFS series + reworked gregordinary patches)
.github/workflows/build-kernel.yml   CI: tag -> arm64 build -> Release
```

Three more patches (batched-submit, irq-sync, ppu-completion) apply to this tree **unmodified** and are downloaded at build time straight from `github.com/gregordinary/patches` — that is why they are not in the `patches/` directory.

## How the CI build works

1. A release tag (`v<version>` on `main`) or dev tag (`<version>-dev` on `dev`) is pushed (or the workflow is started manually from the Actions tab).
2. The job runs on GitHub's `ubuntu-24.04-arm` hosted runner (free for public repositories).
3. The official [Arch Linux ARM aarch64 rootfs](http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz) is imported into Docker on the runner — `makepkg` needs an Arch userland, the official `archlinux` images are amd64-only, and this way no third-party container images are involved.
4. `makepkg` applies the 18-patch series, builds the kernel (`-j$(nproc)`) and produces the two packages.
5. On tag builds, the packages plus a `SHA256SUMS` are attached to a GitHub Release for that tag — dev tags as pre-releases, release tags as normal releases.

A full build takes roughly 1–2 hours. Workflow artifacts are kept for 30 days; releases stay until deleted.

## Branches, tags and releases

Two tracks, distinguished by branch and tag suffix:

| track | branch | tag | result |
|---|---|---|---|
| release | `main` | `v<kernel-version>` (e.g. `v7.3.5`) | full GitHub Release ("latest") |
| development | `dev` | `v<kernel-version>-dev` (e.g. `v7.4rc3.6a63eca-dev`) | **pre-release** build |

**Dev build:** work on the `dev` branch (its PKGBUILD pins the Collabora tree), then:

```sh
git checkout dev
# ... edit PKGBUILD _commit/_gittag if bumping the development kernel ...
git add -A && git commit -m "kernel 7.4-rc3 at <commit>"
git tag v7.4rc3.<shortsha>-dev
git push origin dev --tags
```

**Release build:** the `main` PKGBUILD follows the kernel.org **stable** series. To follow a new stable release, change `_gittag` only (e.g. `v7.3.6`), commit on `main`, and tag:

```sh
git checkout main
# edit PKGBUILD: _gittag='v7.3.6'
git add PKGBUILD && git commit -m "kernel 7.3.6"
git tag v7.3.6
git push origin main --tags
```

The two PKGBUILDs intentionally differ (stable tarball vs. Collabora tree), so promotion from dev to release is a **version bump on `main`**, not a branch merge: a development kernel reaches the release track when its features have landed in a mainline stable release (the NPU stack did exactly that in 7.3). If you cherry-pick from `dev` to `main`, expect conflicts in `PKGBUILD` and keep main's stable-source block.

**What to edit when bumping the kernel version:**
- release track (`main`): `_gittag` in `PKGBUILD` — that is all, the rocket stack follows automatically;
- dev track (`dev`): `_commit` (exact Collabora tree commit) and `_gittag` (upstream tag it is based on), plus the patch series if the new tree needs different patches.

The git source checksum is `SKIP` (the `#tag=`/`#commit=` pin already fixes the exact tree). If you want pacman-grade content pinning for the kernel source too, run `updpkgsums` after changing the pin — but note it downloads the whole kernel history to compute the hash.

## Building locally

On any aarch64 Arch userland (e.g. Arch Linux ARM):

```sh
sudo pacman -Syu --needed base-devel git kmod bc dtc uboot-tools pahole python rust rust-bindgen perl openssl libelf zstd
MAKEFLAGS="-j$(nproc)" makepkg -f
```

`make olddefconfig` in `build()` picks up new Kconfig defaults automatically, so the `config` file only needs manual attention when you want to change options.

## Caveats

- The CI build verifies that the packages **compile**; it does not boot-test them. Install on a board you can recover (serial console or removable eMMC/SD).
- The kernel is unsigned; module signing keys are generated per-build if enabled in the config.
- If a future kernel rejects Arch Linux ARM's `rustc` as too new (the kernel supports a bounded rustc range; 7.4-rc3 wants ≥ 1.85.0 and ALARM currently ships 1.100.0), the build fails at the Rust availability check with a clear message — pin an older rust via rustup in the workflow in that case.

## Licenses and attribution

- The kernel is GPL-2.0 (see `LICENSE`).
- Patches: Gregory's rocket series (GPL-2.0, `github.com/gregordinary/patches`) and Igor Paunović's DVFS series (GPL-2.0, dri-devel).
- `PKGBUILD` structure originally based on 7Ji's `linux-aarch64-rockchip` PKGBUILD.
