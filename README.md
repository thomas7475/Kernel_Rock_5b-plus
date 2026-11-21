# Kernel Rock 5B+

Arch Linux ARM (aarch64) kernel packages for the **Radxa ROCK 5B+ (RK3588)**, built from [Collabora's rockchip hardware-enablement tree](https://gitlab.collabora.com/hardware-enablement/rockchip-3588/linux.git) with the **rocket NPU patch stack** (Gregory's [rocket series](https://github.com/gregordinary/patches) + Igor Paunović's [DVFS series](https://lore.kernel.org/r/20260922080114.44662-1-royalnet026@gmail.com)) on top.

The kernel is built automatically by GitHub Actions on a free arm64 runner whenever a tag is pushed; the resulting packages are attached to a GitHub Release.

## Packages

| package | contents |
|---|---|
| `linux-aarch64-rockchip-collabora` | `Image` (as `vmlinuz`), all Rockchip DTBs, modules |
| `linux-aarch64-rockchip-collabora-headers` | headers for out-of-tree module builds |

The NPU runs with devfreq at 200 MHz–1 GHz (OPP table + passive cooling included), and the driver carries the keep-attached IOMMU, batched-submit and IRQ/reset-path fixes from the rocket series. See the patch comments in the `PKGBUILD` for the full story.

## Repository layout

```
PKGBUILD                        the package recipe (pin, sources, packaging)
config                          kernel .config (CONFIG_RUST=y, aarch64)
08x-rocket-*.patch              the 15 patches that needed adaptation for this
                                tree (DVFS series + reworked gregordinary patches)
.github/workflows/build-kernel.yml   CI: tag -> arm64 build -> Release
```

Three more patches (batched-submit, irq-sync, ppu-completion) apply to this tree **unmodified** and are downloaded at build time straight from `github.com/gregordinary/patches` — that is why they are not in this repository.

## How the CI build works

1. A release tag (`v<version>` on `main`) or dev tag (`<version>-dev` on `dev`) is pushed (or the workflow is started manually from the Actions tab).
2. The job runs on GitHub's `ubuntu-24.04-arm` hosted runner (free for public repositories).
3. The official [Arch Linux ARM aarch64 rootfs](http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz) is imported into Docker on the runner — `makepkg` needs an Arch userland, the official `archlinux` images are amd64-only, and this way no third-party container images are involved.
4. `makepkg` applies the 18-patch series, builds the kernel (`-j$(nproc)`) and produces the two packages.
5. On tag builds, the packages plus a `SHA256SUMS` are attached to a GitHub Release for that tag — dev tags as pre-releases, release tags as normal releases.

A full build takes roughly 1–2 hours. Workflow artifacts are kept for 30 days; releases stay until deleted.

## Branches, tags and releases

Two lines of development, distinguished by tag suffix:

| line | branch | tag | result |
|---|---|---|---|
| release | `main` | `v<kernel-version>` (e.g. `v7.4rc3.6a63eca`) | full GitHub Release ("latest") |
| development | `dev` | `v<kernel-version>-dev` (e.g. `v7.5rc1.abc1234-dev`) | **pre-release** build |

**Dev build:** work on the `dev` branch, then:

```sh
git add -A
git commit -m "kernel 7.5-rc1 at <commit>"
git tag v7.5rc1.<shortsha>-dev
git push origin dev --tags
```

**Release:** once a dev build is validated on the board, fast-forward `main` to the same commit and tag it without the `-dev` suffix:

```sh
git checkout main && git merge --ff-only dev
git tag v7.5rc1.<shortsha>
git push origin main --tags
```

The release build re-runs and publishes the full release, which becomes "latest"; the dev pre-release stays available separately.

**What to edit when bumping the kernel version:** set `_commit` (the exact collabora tree commit) and `_gittag` (the upstream tag it is based on, e.g. `v7.5-rc1`) in `PKGBUILD`, and update the patch series if the new tree needs different patches.

The git source checksum is `SKIP` (the `#commit=` pin already fixes the exact tree). If you want pacman-grade content pinning for the kernel source too, run `updpkgsums` after changing `_commit` — but note it downloads the whole kernel history to compute the hash.

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
