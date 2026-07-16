#!/usr/bin/env bash
set -exo pipefail

# Installs the Anaconda Web UI live installer, matching the pattern used by
# Bazzite/Aurora/Bluefin: a kickstart with the native `ostreecontainer`
# directive lays down the bootc image directly. anaconda-live provides its
# own "Install to Hard Drive" desktop icon to launch it (see Bazzite's
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

# ostreecontainer deploys from the local containers-storage copy embedded in
# the live image, which doesn't exist on the installed disk after first
# boot. Without switching the origin to the real registry ref, "bootc
# upgrade" (and uupd's system module) has nothing to pull from.
%post --erroronfail --log=/var/log/bootc-switch.log
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry ${imageref}:${imagetag}
%end
KSEOF
