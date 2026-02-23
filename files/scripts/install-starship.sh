#!/usr/bin/env bash
# Install Starship from upstream release artifacts.
# We use this path because a `starship` RPM is not consistently available
# in the Fedora/COPR repo mix used by image builds.
set -euo pipefail

# Isolate temporary download/extract work.
tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

# Match binary architecture to the build host architecture.
arch="$(uname -m)"
archive="starship-${arch}-unknown-linux-gnu.tar.gz"
url_base="https://github.com/starship/starship/releases/latest/download"

# Download release tarball + published checksum.
curl -fsSL --retry 3 "${url_base}/${archive}" -o "${tmpdir}/starship.tar.gz"
curl -fsSL --retry 3 "${url_base}/${archive}.sha256" -o "${tmpdir}/starship.tar.gz.sha256"

# Verify integrity before installing.
echo "$(cat "${tmpdir}/starship.tar.gz.sha256")  ${tmpdir}/starship.tar.gz" | sha256sum --check
tar -xzf "${tmpdir}/starship.tar.gz" -C "${tmpdir}"
# Install prompt binary globally in the image.
install -c -m 0755 "${tmpdir}/starship" /usr/bin/starship
