#!/usr/bin/env bash

set -euo pipefail

STATE_FILE="/var/lib/bluefin-brew-sync/done"
WORK_DIR="/var/tmp/bluefin-brew-sync"
TARGET_USER="${TARGET_USER:-1000}"
BLUEFIN_IMAGE="${BLUEFIN_IMAGE:-ghcr.io/ublue-os/bluefin:latest}"

if [[ "${TARGET_USER}" =~ ^[0-9]+$ ]]; then
  TARGET_NAME="$(getent passwd "${TARGET_USER}" | cut -d: -f1 || true)"
else
  TARGET_NAME="${TARGET_USER}"
fi

if [[ -z "${TARGET_NAME}" ]] || ! id "${TARGET_NAME}" >/dev/null 2>&1; then
  echo "Target user '${TARGET_USER}' does not exist yet; skipping for now."
  exit 0
fi

TARGET_HOME="$(getent passwd "${TARGET_NAME}" | cut -d: -f6)"
if [[ -z "${TARGET_HOME}" ]] || [[ ! -d "${TARGET_HOME}" ]]; then
  echo "Target home '${TARGET_HOME}' does not exist yet; skipping for now."
  exit 0
fi

mkdir -p "${WORK_DIR}"
brew_dir=""

# Preferred source: already present inside the image.
if [[ -d "/usr/share/ublue-os/homebrew" ]]; then
  brew_dir="/usr/share/ublue-os/homebrew"
fi

# Fallback source: extract curated Brewfiles from latest Bluefin image.
if [[ -z "${brew_dir}" ]]; then
  if ! command -v podman >/dev/null 2>&1; then
    echo "podman not available and /usr/share/ublue-os/homebrew missing; skipping curated brew sync."
    touch "${STATE_FILE}"
    exit 0
  fi

  rm -rf "${WORK_DIR:?}/bluefin-homebrew"
  mkdir -p "${WORK_DIR}/bluefin-homebrew"

  if ! podman pull --quiet "${BLUEFIN_IMAGE}" >/dev/null; then
    echo "Failed to pull ${BLUEFIN_IMAGE}; skipping curated brew sync."
    touch "${STATE_FILE}"
    exit 0
  fi

  container_id="$(podman create "${BLUEFIN_IMAGE}" true)"
  cleanup() {
    podman rm -f "${container_id}" >/dev/null 2>&1 || true
  }
  trap cleanup EXIT

  if podman cp "${container_id}:/usr/share/ublue-os/homebrew/." "${WORK_DIR}/bluefin-homebrew/" >/dev/null 2>&1; then
    brew_dir="${WORK_DIR}/bluefin-homebrew"
  else
    echo "Could not extract /usr/share/ublue-os/homebrew from ${BLUEFIN_IMAGE}; skipping curated brew sync."
    touch "${STATE_FILE}"
    exit 0
  fi
fi

regular_brewfile=""
for candidate in \
  "${brew_dir}/cli.Brewfile" \
  "${brew_dir}/regular.Brewfile" \
  "${brew_dir}/base.Brewfile" \
  "${brew_dir}/Brewfile"
do
  if [[ -f "${candidate}" ]]; then
    regular_brewfile="${candidate}"
    break
  fi
done

developer_brewfile=""
for candidate in \
  "${brew_dir}/ide.Brewfile" \
  "${brew_dir}/developer.Brewfile" \
  "${brew_dir}/Brewfile-developer" \
  "${brew_dir}/dx.Brewfile" \
  "${brew_dir}/experimental-ide.Brewfile"
do
  if [[ -f "${candidate}" ]]; then
    developer_brewfile="${candidate}"
    break
  fi
done

if [[ -z "${regular_brewfile}" ]]; then
  regular_brewfile="$(find "${brew_dir}" -maxdepth 2 -type f -name '*Brewfile*' | grep -Ev '(dev|devel|developer|dx)' | head -n1 || true)"
fi
if [[ -z "${developer_brewfile}" ]]; then
  developer_brewfile="$(find "${brew_dir}" -maxdepth 2 -type f -name '*Brewfile*' | grep -Ei '(dev|devel|developer|dx)' | head -n1 || true)"
fi

if [[ -z "${regular_brewfile}" ]]; then
  echo "Could not resolve Bluefin regular Brewfile; skipping curated brew sync."
  touch "${STATE_FILE}"
  exit 0
fi
if [[ -z "${developer_brewfile}" ]]; then
  echo "Could not resolve Bluefin developer Brewfile; skipping curated brew sync."
  touch "${STATE_FILE}"
  exit 0
fi

brew_bin=""
for candidate in \
  "/home/linuxbrew/.linuxbrew/bin/brew" \
  "/var/home/linuxbrew/.linuxbrew/bin/brew" \
  "/usr/bin/brew"
do
  if [[ -x "${candidate}" ]]; then
    brew_bin="${candidate}"
    break
  fi
done

if [[ -z "${brew_bin}" ]]; then
  echo "Homebrew binary not found; skipping curated brew sync."
  touch "${STATE_FILE}"
  exit 0
fi

common_env=(
  "HOME=${TARGET_HOME}"
  "USER=${TARGET_NAME}"
  "LOGNAME=${TARGET_NAME}"
  "PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/usr/bin:/usr/sbin"
  "HOMEBREW_NO_ANALYTICS=1"
)

runuser -u "${TARGET_NAME}" -- env "${common_env[@]}" "${brew_bin}" bundle --file "${regular_brewfile}"
runuser -u "${TARGET_NAME}" -- env "${common_env[@]}" "${brew_bin}" bundle --file "${developer_brewfile}"

touch "${STATE_FILE}"
echo "Bluefin curated brew packages installed for ${TARGET_NAME}."
