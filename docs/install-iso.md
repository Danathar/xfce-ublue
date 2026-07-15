# Install via ISO (Live Desktop + Anaconda Web UI)

This is the recommended install path for most users.

The ISO boots into a full live XFCE desktop (so you can try the system before
installing), then an **Install to Hard Drive** icon on the desktop launches
the same Anaconda Web UI installer used by Bazzite, Aurora, and Bluefin. The
installer deploys the actual published container image directly via
`ostree container image deploy` — there's no separate "build the OS" step;
the live session and the installed system both trace back to
`ghcr.io/danathar/xfce:latest`.

This replaces the earlier `bluebuild generate-iso` (JasonN3/build-container-installer)
path documented previously in this file. If you need that older boot-only
installer ISO for some reason, `bluebuild generate-iso` still works against
this repo's recipe; it's just no longer the recommended path.

## How It Works

The ISO is built with [`ublue-os/titanoboa`](https://github.com/ublue-os/titanoboa),
which implements the [Container-native ISO contract v0.1.0](https://github.com/ondrejbudai/bootc-isos/blob/main/README.md#container-native-iso-contract-v010).
The [`installer/`](../installer/) directory in this repo contains the
Containerfile and build script that layer the live-boot tooling (dracut-live,
livesys-scripts, GRUB2/EFI staging, Anaconda) on top of the published xfce
image; Titanoboa itself then converts that layered image into a bootable ISO.

## Prerequisites

- `podman`
- `sudo` (the installer image build needs `--cap-add sys_admin --security-opt label=disable`)
- A published image, for example `ghcr.io/danathar/xfce:latest`
- A target disk of **at least 64GB**

## Build Installer ISO

### Via GitHub Actions (recommended)

The [`Titanoboa ISO Experiment`](../.github/workflows/build-iso-experiment.yml)
workflow builds the installer image and generates the ISO on a GitHub-hosted
runner — this avoids needing the privileged local `podman build` and the
large scratch disk space on your own machine. Trigger it and download the
`xfce-live-iso` artifact from the run (artifacts expire after 3 days).

### Locally

Build the installer image (layers live-boot tooling onto the published xfce image):

```bash
sudo podman build \
  --cap-add sys_admin --security-opt label=disable \
  -t localhost/xfce-installer:latest installer/
```

Then generate the ISO with Titanoboa (see [ublue-os/titanoboa](https://github.com/ublue-os/titanoboa)
for the current invocation — either its GitHub Action or `main.sh` locally,
pointed at `localhost/xfce-installer:latest`).

Output ISO path: wherever you point `TITANOBOA_OUTPUT_DIR` / `iso-dest`
(defaults to `output.iso` in the current directory).

## Installing

1. Boot the ISO. It reaches a live XFCE desktop automatically.
2. Double-click **Install to Hard Drive** on the desktop.
3. Follow the Anaconda Web UI wizard (opens in Firefox): language, date/time,
   installation method, storage, account creation, then **Erase data and install**.
4. When it finishes, reboot and remove the installation media.

## Installer Caveats

- Use a target disk of **at least 64GB**. Smaller disks can fail partway
  through installation with an ostree free-space error.
- The installer needs enough RAM to run Anaconda, Firefox, and the live XFCE
  session concurrently; 6GB or more is recommended.
- If you hit Wi-Fi network-selection trouble during install, continue
  without network and configure Wi-Fi after first boot.

## First Boot Behavior After ISO Install

- If wired network is already connected during first boot, reaching LightDM
  can take longer while initial system Flatpak setup completes.
- If no network is available on first boot and you connect Wi-Fi from the
  desktop later, you may see that Flatpak setup delay on second boot
  (occasional, not guaranteed).
