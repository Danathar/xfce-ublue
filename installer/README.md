# Live ISO Installer Image

This directory builds the image that [`ublue-os/titanoboa`](https://github.com/ublue-os/titanoboa)
turns into a bootable live ISO. See [`docs/install-iso.md`](../docs/install-iso.md)
for end-user build/install instructions.

## What's here

Adapted from Titanoboa's own [bazzite](https://github.com/ublue-os/titanoboa/tree/main/examples/bazzite)
and [zirconium](https://github.com/ublue-os/titanoboa/tree/main/examples/zirconium)
examples, and from [`ublue-os/bazzite`](https://github.com/ublue-os/bazzite)'s
real `installer/` directory, trimmed down for a single-variant image with no
desktop-environment branching:

- `Containerfile` — layers this directory's `build.sh` onto `BASE_IMAGE`
  (defaults to `ghcr.io/danathar/xfce:latest`) and embeds
  `INSTALL_IMAGE_PAYLOAD` (same image by default) into local container
  storage as the install target.
- `build.sh` — regenerates the initramfs with `dracut-live`'s
  `dmsquash-live` modules, configures the `livesys-xfce` live session,
  stages GRUB2/EFI assets where `bootc-image-builder` expects them, and
  writes `/usr/lib/bootc-image-builder/iso.yaml` (the
  [container-native ISO contract](https://github.com/ondrejbudai/bootc-isos/blob/main/README.md#container-native-iso-contract-v010)).
- `iso.yaml` — ISO label and GRUB2 boot entries.
- `titanoboa_hook_preinitramfs.sh` — no-op (Bazzite uses this slot for a
  secureboot kernel swap this image doesn't need).
- `titanoboa_hook_postrootfs.sh` — installs `anaconda-live` and writes a
  kickstart using the native `ostreecontainer` directive, then adds an
  autostart entry that launches `liveinst` (Anaconda Web UI) on login.
- `flatpaks` — flatpaks to install into the *live session* (currently
  empty; unrelated to what ships in the installed image).

## Local build + test

```bash
sudo podman build \
  --cap-add sys_admin --security-opt label=disable \
  -t localhost/xfce-installer:latest installer/
```

Generate an ISO from that image with Titanoboa, then boot it in a VM with a
target disk of at least 64GB attached — see
[`docs/install-iso.md`](../docs/install-iso.md) for install steps.
