# Install via ISO (Interactive Anaconda)

This is the recommended install path for most users.

## Prerequisites

- A published image, for example `ghcr.io/danathar/xfce:latest`
- `podman`
- `bluebuild` CLI

If `bluebuild` is not installed, install it with podman. Install instructions: [blue-build/cli#installation](https://github.com/blue-build/cli#installation)

```bash
podman run --pull always --rm ghcr.io/blue-build/cli:latest-installer | bash
bluebuild --version
```

## Build Installer ISO

Build from published image:

```bash
bluebuild generate-iso \
  --variant kinoite \
  --iso-name xfce-ublue.iso \
  -o output \
  image ghcr.io/danathar/xfce:latest
```

> [!NOTE]
> The current BlueBuild `generate-iso` path uses the community project [`JasonN3/build-container-installer`](https://github.com/JasonN3/build-container-installer). Fedora's official bootc image-builder path is documented here: <https://osbuild.org/docs/bootc/>.

Build from local recipe (builds image first, then ISO):

```bash
bluebuild generate-iso \
  --variant kinoite \
  --iso-name xfce-ublue.iso \
  -o output \
  recipe recipes/recipe.yml
```

Output ISO path:

- `output/xfce-ublue.iso`

## Variant Notes

`--variant` selects installer behavior, not your final image content.

- `kinoite` (recommended)
- `server`
- `silverblue`

## Installer Caveats

- Some systems can hit a known Anaconda UI issue where the Wi-Fi list is too long/cut off and selecting a network does not open the password dialog.
- If this occurs, continue install without network, then configure Wi-Fi after first boot.

## First Boot Behavior After ISO Install

- If wired network is already connected during first boot, reaching LightDM can take longer while initial system Flatpak setup completes.
- If no network is available on first boot and you connect Wi-Fi from the desktop later, you may see that Flatpak setup delay on second boot (occasional, not guaranteed).
