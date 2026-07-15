#!/usr/bin/env bash
set -exo pipefail

# No-op: xfce-ublue does not need a kernel swap before initramfs
# regeneration (that hook exists upstream for secureboot-signed
# kernel requirements bazzite has that this image doesn't).
