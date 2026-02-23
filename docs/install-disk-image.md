# Install via Disk Image (qcow2/raw)

Use this path when you want direct disk images (VM or bare metal) instead of an interactive installer ISO.

## Generate `qcow2` from Published Image

1. Prepare directories:

```bash
mkdir -p output
```

2. Download `config.toml` from this repository:

```bash
curl -fsSLO https://raw.githubusercontent.com/Danathar/xfce-ublue/refs/heads/main/config.toml
```

3. Pull published image:

```bash
sudo podman pull ghcr.io/danathar/xfce:latest
```

4. Build `qcow2` image:

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

Output:

- `output/qcow2/disk.qcow2`

## Create VM with `virt-install`

```bash
virt-install \
  --name xfce-ublue-test \
  --memory 4096 \
  --vcpus 4 \
  --cpu host-passthrough \
  --import \
  --disk path=/home/$USER/disk.qcow2,format=qcow2,bus=virtio \
  --os-variant fedora-unknown \
  --network user,model=virtio \
  --graphics spice \
  --video virtio \
  --channel spicevmc \
  --boot uefi
```

If you use `qemu:///session`, `--network user,model=virtio` is the safe default.

## Change Disk Type

Adjust the image type argument:

- `--type qcow2` for KVM/libvirt/virt-manager
- `--type raw` for raw disk workflows
- `--type ami` for AWS-style outputs (when supported)

## Bare Metal (raw image)

Status: this flow has not been tested yet in this project.

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

3. Write image to disk (example `/dev/nvme0n1`):

```bash
sudo lsblk
sudo dd if=output/raw/disk.raw of=/dev/nvme0n1 bs=16M status=progress oflag=direct conv=fsync
sync
```

4. Reboot into installed disk.

Notes:

- `dd` erases the target disk completely. Double-check path with `lsblk`.
- If output filename differs, inspect `output/raw/` and adjust `if=` path.
- User setup comes from `config.toml` (currently user `xfc`, password `changeme`).

## Customize Disk Size

Set in `config.toml`:

```toml
[customizations]
disk = { minsize = "40 GiB" }
```

Default in this repository: `40 GiB`.

## Add or Change Users in `config.toml`

Current block:

```toml
[[customizations.user]]
name = "xfc"
password = "changeme"
groups = ["wheel"]
```

Add users with additional `[[customizations.user]]` blocks:

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

## First Boot Note for Disk Images

For non-Anaconda install paths (like raw/qcow2), time is set to UTC by default. Set timezone/geographic area after first boot from XFCE date/time settings.
