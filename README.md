# Kernel Rock 5B+

Arch Linux ARM (aarch64) kernel packages for the **Radxa ROCK 5B+ (RK3588)**, built in two tracks that share one repository, one workflow and one rocket NPU patch stack (Gregory's [rocket series](https://github.com/gregordinary/patches) + Igor Paunović's [DVFS series](https://lore.kernel.org/r/20260922080114.44662-1-royalnet026@gmail.com)):

| track | branch | kernel source | package |
|---|---|---|---|
| **release** | `main` | [Collabora rockchip-**release** tree](https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux.git), 7.3-based (commit `b436759`) | `linux-aarch64-rockchip` |
| **development** | `dev` | [Collabora rockchip-**devel** tree](https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux.git), v7.4-rc3-based (commit `6a63eca`) | `linux-aarch64-rockchip-collabora` |

Both tracks build from the same Collabora hardware-enablement repository — the release track follows the validated `rockchip-release` line, the development track the fast-moving `rockchip-devel` line — and both carry the identical rocket NPU patch stack, with the pinning and packaging machinery shared between them.

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
| release | `main` | `v<kernel-version>` (e.g. `v7.3.b436759`) | full GitHub Release ("latest") |
| development | `dev` | `v<kernel-version>-dev` (e.g. `v7.4rc3.6a63eca-dev`) | **pre-release** build |

**Dev build:** work on the `dev` branch (its PKGBUILD pins the Collabora rockchip-**devel** tree), then:

```sh
git checkout dev
# ... edit PKGBUILD _commit/_gittag if bumping the development kernel ...
git add -A && git commit -m "kernel 7.4-rc3 at <commit>"
git tag v7.4rc3.<shortsha>-dev
git push origin dev --tags
```

**Release build:** the `main` PKGBUILD follows the Collabora rockchip-**release** tree. When Collabora publishes a new release state (e.g. a 7.4-based `rockchip-release`), change `_commit` (and `_gittag`) on `main`, commit, and tag:

```sh
git checkout main
# edit PKGBUILD: _commit='<new rockchip-release sha>' / _gittag='v7.4'
git add PKGBUILD && git commit -m "kernel 7.4 at <commit>"
git tag v7.4.<shortsha>
git push origin main --tags
```

The two PKGBUILDs intentionally differ (release line vs. devel line), so promotion from dev to release is a **version bump on `main`**, not a branch merge: a development kernel reaches the release track when Collabora ships the corresponding `rockchip-release` state to pin. If you cherry-pick from `dev` to `main`, expect conflicts in the PKGBUILD's user-configuration block and keep main's release-tree pin.

**What to edit when bumping the kernel version:**
- release track (`main`): `_commit` (exact rockchip-release tree commit) and `_gittag` (the mainline version it is based on, e.g. `v7.3`);
- dev track (`dev`): `_commit` (exact rockchip-devel tree commit) and `_gittag` (e.g. `v7.5-rc1`), plus the patch series if the new tree needs different patches.

The git source checksum is `SKIP` (the `#commit=` pin already fixes the exact tree). If you want pacman-grade content pinning for the kernel source too, run `updpkgsums` after changing `_commit` — but note it downloads the whole kernel history to compute the hash.

## Building locally

On any aarch64 Arch userland (e.g. Arch Linux ARM):

```sh
sudo pacman -Syu --needed base-devel git kmod bc dtc uboot-tools pahole python rust rust-src rust-bindgen perl openssl libelf zstd
MAKEFLAGS="-j$(nproc)" makepkg -f
```

`make olddefconfig` in `build()` picks up new Kconfig defaults automatically, so the `config` file only needs manual attention when you want to change options.

**`rust-src` is load-bearing:** ALARM splits the Rust standard-library sources into a separate `rust-src` package. Without it, `scripts/rust_is_available.sh` fails its core-library-source check and `olddefconfig` *silently* drops `CONFIG_RUST=y` — the build stays green but produces no Rust code and a headers package without `libmacros.so`/`target.json`/`rust/*.o`, breaking DKMS builds of Rust modules (exactly what happened to the pkgrel=1 packages). The CI therefore verifies after every build that the headers package contains `rust/libmacros.so` and `CONFIG_RUST=y`.

## Caveats

- The CI build verifies that the packages **compile**; it does not boot-test them. Install on a board you can recover (serial console or removable eMMC/SD).
- The kernel is unsigned; module signing keys are generated per-build if enabled in the config.
- CI runs on GitHub's `ubuntu-24.04-arm` hosted runners — **native aarch64** (image family `ubuntu24-arm64`), asserted at the start of every run. Building Rust modules out of tree additionally needs `rust` on the board itself.
- If a future kernel rejects Arch Linux ARM's `rustc` as too new (the kernel supports a bounded rustc range; 7.3/7.4-rc3 want ≥ 1.85.0 and ALARM currently ships 1.100.0), the build fails at the Rust availability check with a clear message — pin an older rust via rustup in the workflow in that case.

## Licenses and attribution

- The kernel is GPL-2.0 (see `LICENSE`).
- Patches: Gregory's rocket series (GPL-2.0, `github.com/gregordinary/patches`) and Igor Paunović's DVFS series (GPL-2.0, dri-devel).
- `PKGBUILD` structure originally based on 7Ji's `linux-aarch64-rockchip` PKGBUILD.
