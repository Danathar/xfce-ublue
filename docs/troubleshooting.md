# Troubleshooting

## Common Behaviors

### First Boot Delay Before LightDM

- The image gates first graphical login on initial system Flatpak setup.
- If network is available, first boot can take longer before LightDM appears.

### Delay on Second Boot After Wi-Fi Setup

- If first boot happened without network and Wi-Fi is configured afterward, Flatpak setup can run on a later boot.
- This may be noticed on second boot and is occasional, not guaranteed.

### Installer Wi-Fi List UI Issue

- Some systems can hit a known Anaconda UI issue where the wireless list is too long/cut off and selecting an SSID does not open a password dialog.
- Workaround: complete install without network, then configure Wi-Fi after first boot.

### Harmless warnings in the boot log (VM only)

Inside a VM you may see a few warnings in `journalctl -b` that don't appear on
real hardware and don't affect anything:

- `spice-vdagent: vdagent-audio: can't get default alsa mixer` — the VM has no
  sound device. Add one (virt-manager: Add Hardware → Sound; `virt-install`:
  `--sound default`) if you want audio and to silence this.
- `wireplumber: spa.bluez5: BlueZ system service is not available` — no
  Bluetooth in the VM.
- `udev-worker ... sr0: Process '/usr/sbin/pktsetup ...'` — the empty virtual
  CD-ROM drive.

The previously-noisy `mcelog.service`, `systemd-remount-fs.service`, and
`rsyslog.service` failures are now masked in the image (see "Issues Fixed"
below), so `systemctl --failed` should be clean.

## Issues Fixed in This Repository

1. Fedora release identity conflict
Removed `fedora-release-xfce` and `fedora-release-identity-xfce` from recipe installs because they conflict with `fedora-release-identity-basic` in `base-main`.

2. LightDM failed on boot (`/var/cache/lightdm` + `/var/lib/lightdm-data` errors)
Added tmpfiles overlay at `files/system/usr/lib/tmpfiles.d/zz-lightdm-local.conf` to create required LightDM directories with correct ownership.

3. DNFDragora updater hanging on ostree image
Removed `dnfdragora` and `dnfdragora-updater` from the image since system updates are handled via ostree/bootc workflows.

4. New fixes not appearing in qcow2
Root cause was stale tag usage (`localhost/xfce:latest` still pointing to an older image). The fix was to retag the newest loaded image ID before generating qcow2.

5. `bootc-image-builder` manifest error for `/boot`
Required setting a supported root filesystem (`--rootfs ext4`) when generating qcow2.

6. Staged-update terminal notice did not behave like Aurora/Bluefin
`starship` is not available as a normal DNF package in this build context, so the prompt notice failed when installed that way. We now install `starship` from the upstream release tarball at build time and use a Starship custom module to show `New deployment staged` when an update is pending.

7. `systemctl --failed` showing broken services on every boot
Three services failed on each boot and were masked in `recipes/recipe.yml` (confirmed via `journalctl -u <name> -b`, not guessed):
   - `rsyslog.service` — redundant with systemd-journald and misconfigured for ostree; its `imjournal` module repeatedly failed to write its state file to the read-only `/`, spamming `open() failed ... Read-only file system`.
   - `systemd-remount-fs.service` — fails on any ostree/bootc system because `/` is an overlayfs that rejects the remount (`overlay: No changes allowed in reconfigure`).
   - `mcelog.service` — `mcelog` doesn't support AMD Zen (family 17h+) and exits with `does not support this processor`. Masking also disables it on Intel hosts where it would work; `systemctl unmask mcelog.service` to restore it there.
