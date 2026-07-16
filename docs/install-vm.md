# Try the ISO in a VM (libvirt / virt-manager)

This walks through booting the [live ISO](install-iso.md) in a local VM with
libvirt. The ISO has a couple of requirements (UEFI firmware, enough disk)
that the virt-manager "New VM" wizard doesn't set up correctly by default, so
the most reliable path is a single `virt-install` command.

> [!IMPORTANT]
> The ISO is **UEFI-only** and needs **Secure Boot off** (its kernel is not
> signed) and a target disk of **at least 64GB**. The command below sets all
> three. See [install-iso.md](install-iso.md) for the underlying reasons.

## One-shot `virt-install` command

Replace `/path/to/xfce-live.iso` with your extracted ISO (the download is a
`.zip` — extract it first), then run:

```bash
virt-install \
  --name xfce-ublue-live \
  --memory 6144 \
  --vcpus 4 \
  --machine q35 \
  --boot cdrom,hd,loader=/usr/share/edk2/ovmf/OVMF_CODE_4M.qcow2,loader.readonly=yes,loader.type=pflash,nvram.template=/usr/share/edk2/ovmf/OVMF_VARS_4M.qcow2 \
  --disk path="$HOME/.local/share/libvirt/images/xfce-ublue-live.qcow2",size=64,format=qcow2,bus=virtio \
  --disk path=/path/to/xfce-live.iso,device=cdrom \
  --network user,model=virtio \
  --sound default \
  --graphics spice \
  --video virtio \
  --osinfo detect=on,require=off \
  --noautoconsole
```

The VM appears in virt-manager as `xfce-ublue-live` — open it there to watch
it boot. It boots to a live XFCE desktop; double-click **Install to Hard
Drive** and follow the Anaconda wizard.

### After installing: remove the ISO so it boots from disk

UEFI firmware remembers "boot from CD-ROM" in the VM's NVRAM, so after the
install finishes the VM will keep booting back into the live ISO instead of
your new system. Fix it once:

1. Shut the VM down.
2. In virt-manager, open the VM's hardware details, select the **SATA CDROM**
   device, and click **Remove** (or, from the CLI while shut off:
   `virsh detach-disk xfce-ublue-live sda --config`).
3. Boot the VM — it now starts from the installed disk.

## Why the flags are what they are

Each of these addresses something the default wizard gets wrong for this ISO:

- **`--boot ...loader=.../OVMF_CODE_4M.qcow2 ...`** — forces UEFI with the
  *non*-Secure-Boot firmware. `--boot uefi` (the simple form) often auto-picks
  the Secure Boot variant, which refuses this image's unsigned kernel.
- **`nvram.template=.../OVMF_VARS_4M.qcow2`** — the writable UEFI variable
  store; libvirt creates the VM's own copy from this template.
- **`--boot cdrom,hd`** — boot the ISO first, the disk second.
- **`--disk ...size=64...`** — the 64GB minimum (smaller fails mid-install on
  ostree's free-space check).
- **`--network user,model=virtio`** — QEMU user-mode networking. Works without
  a pre-defined libvirt network, so it's fine under both `qemu:///session` and
  `qemu:///system`. If you use system libvirt and prefer its NAT network, swap
  in `--network network=default`.
- **`--sound default`** — without a sound device you'll see harmless
  `spice-vdagent: can't get default alsa mixer` warnings in the log.
- **`--osinfo detect=on,require=off`** — lets detection fail gracefully; the
  ISO isn't in libvirt's OS database, and the resulting "generic" fallback
  warning is harmless.

### If the OVMF firmware paths don't exist

The `/usr/share/edk2/ovmf/OVMF_CODE_4M.qcow2` paths above are Fedora's. On
other distros the files live elsewhere and may be `.fd` instead of `.qcow2`
(drop the `format=`/`templateFormat=` bits for raw `.fd` firmware). Find yours:

```bash
ls /usr/share/edk2/ovmf/ /usr/share/OVMF/ /usr/share/qemu/ 2>/dev/null | grep -i code
```

Pick the plain (non-`secboot`/`secure`) `*CODE*` file and its matching
`*VARS*` template.
