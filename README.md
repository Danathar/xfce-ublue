# xfce-ublue

Fedora bootc/Universal Blue style image using XFCE, built with BlueBuild.

> This is **not** an official Universal Blue image.
> It is a personal experimental project.

## Included

- Base image: `ghcr.io/ublue-os/base-main`
- Desktop: `xfce-desktop-environment` group + `lightdm` + `lightdm-gtk-greeter`
- `distrobox`
- Homebrew via BlueBuild `brew` module
- Flatpaks via BlueBuild `default-flatpaks` module (system scope, Flathub)
  - XFCE-focused curated subset; avoids replacing core XFCE tools with GNOME app Flatpaks
- Automatic ongoing updates handled by `uupd.timer` (brew, flatpak, distrobox, and system)
- GitHub Actions build workflows in `.github/workflows/`

## First Boot Notes

- On first boot, it can take a bit for initial system Flatpak state to fully settle.
- Time is set to UTC by default. Set your timezone and geographic area after first boot.

## Build Locally

Requirements:

- `bluebuild`
- `podman`

Build OCI archive:

```bash
bluebuild --log-out .state/logs build --archive oci recipes/recipe.yml
```

Load and tag for local bootc-image-builder:

```bash
sudo podman load -i oci/xfce.tar.gz
sudo podman images
sudo podman tag <NEW_IMAGE_ID> localhost/xfce:latest
```

## Generate Disk Image From GitHub-Built Image

After GitHub Actions publishes your image to GHCR, generate a disk image directly from it with `bootc-image-builder`.

1. Prepare directories:

```bash
mkdir -p output
```

2. Download `config.toml` from this repository:

```bash
curl -fsSLO https://raw.githubusercontent.com/Danathar/xfce-ublue/refs/heads/main/config.toml
```

3. Pull your published image:

```bash
sudo podman pull ghcr.io/danathar/xfce:latest
```

4. Build a `qcow2` image:

`output/` must exist before this command (`mkdir -p output`).

```bash
sudo podman run --rm -it --privileged \
  --security-opt label=type:unconfined_t \
  -v "$(pwd)/config.toml:/config.toml:ro" \
  -v "$(pwd)/output:/output" \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type qcow2 \
  --rootfs ext4 \
  --config /config.toml \
  ghcr.io/danathar/xfce:latest
```

Output is in `output/qcow2/disk.qcow2`.

### Create a VM with `virt-install`

After copying `disk.qcow2` to your host system:

```bash
virt-install \
  --name xfce-ublue-test \
  --memory 4096 \
  --vcpus 4 \
  --cpu host-passthrough \
  --import \
  --disk path=/var/home/$USER/disk.qcow2,format=qcow2,bus=virtio \
  --os-variant fedora-unknown \
  --network user,model=virtio \
  --graphics spice \
  --video virtio \
  --channel spicevmc \
  --boot uefi
```

If you use `qemu:///session`, `--network user,model=virtio` is the safe default.

### Change Disk Type

Change `--type`:

- `--type qcow2` for KVM/libvirt/virt-manager
- `--type raw` for raw disk image workflows
- `--type ami` for AWS-style image outputs (when supported by your build setup)

## Run on Bare Metal

For physical hardware, generate a `raw` disk image and write it to the target disk.

Status: this bare-metal flow has not been tested yet in this project.

1. Prepare files:

```bash
mkdir -p output
curl -fsSLO https://raw.githubusercontent.com/Danathar/xfce-ublue/main/config.toml
sudo podman pull ghcr.io/danathar/xfce:latest
```

2. Build raw image:

```bash
sudo podman run --rm -it --privileged \
  --security-opt label=type:unconfined_t \
  -v "$(pwd)/config.toml:/config.toml:ro" \
  -v "$(pwd)/output:/output" \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  quay.io/centos-bootc/bootc-image-builder:latest \
  --type raw \
  --rootfs ext4 \
  --config /config.toml \
  ghcr.io/danathar/xfce:latest
```

3. Write image to target disk (example: `/dev/nvme0n1`):

```bash
sudo lsblk
sudo dd if=output/raw/disk.raw of=/dev/nvme0n1 bs=16M status=progress oflag=direct conv=fsync
sync
```

4. Reboot into the installed disk.

Notes:

- `dd` will erase the target disk completely. Double-check device path with `lsblk`.
- If your output filename differs, check `output/raw/` and adjust the `dd if=` path.
- User setup comes from `config.toml` (currently user `xfc` with password `changeme`).

### Change Disk Size

Set size in `config.toml`:

```toml
[customizations]
disk = { minsize = "40 GiB" }
```

This repository defaults to `40 GiB` in `config.toml`.

### Add or Change Users in `config.toml`

Current user block:

```toml
[[customizations.user]]
name = "xfc"
password = "changeme"
groups = ["wheel"]
```

Add more users by adding additional `[[customizations.user]]` blocks:

```toml
[[customizations.user]]
name = "alice"
password = "changeme"
groups = ["wheel"]

[[customizations.user]]
name = "bob"
password = "changeme"
groups = []
```

## Issues We Fixed

1. Fedora release identity conflict
Removed `fedora-release-xfce` and `fedora-release-identity-xfce` from recipe installs because they conflict with `fedora-release-identity-basic` in `base-main`.

2. LightDM failed on boot (`/var/cache/lightdm` + `/var/lib/lightdm-data` errors)
Added tmpfiles overlay at `files/system/usr/lib/tmpfiles.d/zz-lightdm-local.conf` to create required LightDM directories with correct ownership.

3. New fixes not appearing in qcow2
Root cause was stale tag usage (`localhost/xfce:latest` still pointing to an older image). The fix was to retag the newest loaded image ID before generating qcow2.

4. bootc-image-builder manifest error for `/boot`
Required setting a supported root filesystem (`--rootfs ext4`) when generating qcow2.

## GitHub Actions Notes

- `build.yml`: builds/pushes image on push/schedule/manual.
- `build-pr.yml`: PR validation build.
- Add secret `SIGNING_SECRET` with contents of `cosign.key`.
- Add secret `COSIGN_PASSWORD` with the password used to generate `cosign.key` (use empty string only if your key was created with empty password).
- `build.yml` ignores README-only pushes.

## Update Behavior

- `uupd.timer` is enabled for automatic updates.
- `rpm-ostreed-automatic.timer` is disabled to avoid duplicate system auto-update paths.
- `uupd` configuration is managed at `files/system/etc/uupd/config.json`.

## Use as Template or Fork

If you want your own image in your own GitHub account, you have two options:

- Use Template: best for starting fresh without upstream git history.
- Fork: best if you want easy upstream syncing/cherry-picking from this repo later.

### Option A: Use Template (recommended for most users)

1. On GitHub, open this repository and click `Use this template`.
2. Create a new repository under your account (for example `my-xfce-ublue`).
3. Clone your new repository locally.
4. Update image identity in `recipes/recipe.yml`:
   - `name:` (image name)
   - `base-image:` (leave as-is unless you intentionally change base)
   - `image-version:` (keep `latest` for main)
5. In GitHub repo settings, add Actions secrets:
   - `SIGNING_SECRET`: full contents of your `cosign.key`
   - `COSIGN_PASSWORD`: password used when that key was created
6. Ensure `cosign.pub` is committed at repo root.
7. Push to `main` and wait for `Build and Push Image` workflow to complete.
8. Verify image exists in GHCR:
   - `ghcr.io/<your-github-username>/<image-name>:latest`

### Option B: Fork

1. On GitHub, click `Fork`.
2. In your fork settings, add the same secrets:
   - `SIGNING_SECRET`
   - `COSIGN_PASSWORD`
3. Confirm `Actions` are enabled for the fork.
4. Push a commit to your fork `main` and confirm build success.
5. Your image is published under your account namespace in GHCR.

### Template vs Fork Decision

- Use Template when:
  - You want a clean independent project.
  - You do not want inherited commit history/noise.
- Use Fork when:
  - You plan to regularly pull updates from this repository.
  - You want easy upstream diff visibility.

### Branch Build Behavior

- `main` pushes publish your stable image (`:latest`).
- Non-`main` branch pushes publish beta branch images via `build-beta.yml`.
- Dependabot branches are excluded from beta image publishing.

### First-Time Validation Checklist

After your first successful build:

1. Check `Actions` tab shows successful `Build and Push Image`.
2. Pull the image:
   - `podman pull ghcr.io/<your-user>/<image-name>:latest`
3. Rebase/install and verify:
   - `rpm-ostree status`
   - `sudo bootc status`
4. Verify update services:
   - `systemctl status uupd.timer`
   - `systemctl status rpm-ostreed-automatic.timer` (should be disabled)
