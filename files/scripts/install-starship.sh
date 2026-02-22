#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

arch="$(uname -m)"
archive="starship-${arch}-unknown-linux-gnu.tar.gz"
url_base="https://github.com/starship/starship/releases/latest/download"

curl -fsSL --retry 3 "${url_base}/${archive}" -o "${tmpdir}/starship.tar.gz"
curl -fsSL --retry 3 "${url_base}/${archive}.sha256" -o "${tmpdir}/starship.tar.gz.sha256"

echo "$(cat "${tmpdir}/starship.tar.gz.sha256")  ${tmpdir}/starship.tar.gz" | sha256sum --check
tar -xzf "${tmpdir}/starship.tar.gz" -C "${tmpdir}"
install -c -m 0755 "${tmpdir}/starship" /usr/bin/starship
