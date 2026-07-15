#!/usr/bin/env bash
set -exo pipefail

# Installs the Anaconda Web UI live installer, matching the pattern used by
# Bazzite/Aurora/Bluefin: a kickstart with the native `ostreecontainer`
# directive lays down the bootc image directly, launched via an autostart
# entry when the live XFCE session starts (see Bazzite's
# installer/titanoboa_hook_postrootfs.sh and installer/system_files/shared
# for the full-featured reference this is trimmed down from).

INSTALL_IMAGE_PAYLOAD=${INSTALL_IMAGE_PAYLOAD:?}

dnf install -y anaconda-live libblockdev-btrfs libblockdev-lvm libblockdev-dm firefox

# Needed for Anaconda Web UI
mkdir -p /var/lib/rpm-state

imageref="${INSTALL_IMAGE_PAYLOAD%%:*}"
imagetag="${INSTALL_IMAGE_PAYLOAD##*:}"

cat <<KSEOF >>/usr/share/anaconda/interactive-defaults.ks
ostreecontainer --url=${imageref}:${imagetag} --transport=containers-storage --no-signature-verification
KSEOF

cat <<'SCRIPTEOF' >/usr/bin/xfce-live-installer.sh
#!/usr/bin/bash
liveinst &
disown $!
SCRIPTEOF
chmod +x /usr/bin/xfce-live-installer.sh

mkdir -p /etc/skel/.config/autostart
cat <<'DESKTOPEOF' >/etc/skel/.config/autostart/xfce-live-installer.desktop
[Desktop Entry]
Exec=/usr/bin/xfce-live-installer.sh
Icon=application-x-shellscript
Type=Application
DESKTOPEOF
