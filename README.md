# xfce-ublue

Fedora bootc/Universal Blue style image using XFCE, built with BlueBuild.

> [!NOTE]
> This is **not** an official Universal Blue image.
> It is built from official and trusted upstream sources (the Universal Blue base image, Fedora/RPM Fusion packages, Flathub, and Homebrew).
> Currently, this image builds and runs successfully. The installer is not as smooth or quick as I would like (please be patient if it seems slow; it is not hung), but this is a known upstream Anaconda issue. Please review the "First Boot Summary" regarding potential startup delays during the initial boots.
>
> This repository was developed using some directed AI assistance, although its contents have been manually tested and inspected. I believe it's important for anyone using open-source tools on GitHub to have this context before relying on them.

## What You Get

- Base image: `ghcr.io/ublue-os/base-main`
- XFCE desktop (`xfce-desktop-environment` + `lightdm` + `lightdm-gtk-greeter`)
- Broadcom legacy Wi-Fi support tooling (`rpmfusion-nonfree-release` + `b43-fwcutter`)
- Firmware updates via `fwupd` and the GNOME Firmware Flatpak
- Homebrew via Universal Blue `brew` OCI image
- Flatpaks via BlueBuild `default-flatpaks` module (system scope, Flathub)
- Automatic updates via `uupd.timer` (system, brew, flatpak, distrobox)
- Signed image publishing workflows in `.github/workflows/`

## Quick Start (Installer ISO)

**[Get the latest ISO](https://github.com/Danathar/xfce-ublue/releases/tag/iso-latest)**
— no forking or building required. That page always links to the current
build's workflow run; open it and download the `xfce-live-iso` artifact
from its Summary. Requires a GitHub login (GitHub Releases can't host a
file this large, so it's an Actions artifact instead — see
[`docs/install-iso.md`](docs/install-iso.md#download) for why).

The ISO boots into a live XFCE desktop; double-click **Install to Hard
Drive** to run the Anaconda Web UI installer (the same mechanism Bazzite,
Aurora, and Bluefin use) and deploy `ghcr.io/danathar/xfce:latest` directly
to disk.

> [!IMPORTANT]
> Use a target disk of **at least 64GB**.

Detailed instructions, caveats, and how to build your own ISO:
[`docs/install-iso.md`](docs/install-iso.md).

## First Boot Summary

- First graphical login is gated on one-time system Flatpak setup, so reaching LightDM can take longer when network is available.
- If first boot had no network, that setup delay may occur on a later boot after network is configured (occasional).
- For non-Anaconda install paths (raw/qcow2 disk image), time defaults to UTC; set timezone after first boot.

More details and known quirks: [`docs/troubleshooting.md`](docs/troubleshooting.md).

## Documentation

- Local builds: [`docs/build-locally.md`](docs/build-locally.md)
- Installer ISO install: [`docs/install-iso.md`](docs/install-iso.md)
- Try the ISO in a VM (libvirt/virt-manager): [`docs/install-vm.md`](docs/install-vm.md)
- Disk image install (qcow2/raw): [`docs/install-disk-image.md`](docs/install-disk-image.md)
- Troubleshooting and known behaviors: [`docs/troubleshooting.md`](docs/troubleshooting.md)
- Automatic update/build cadence: [`docs/automatic-updates.md`](docs/automatic-updates.md)
- CI, signing, and update-path config: [`docs/ci-and-signing.md`](docs/ci-and-signing.md)
- Using this repo as template or fork: [`docs/repo-template-or-fork.md`](docs/repo-template-or-fork.md)
