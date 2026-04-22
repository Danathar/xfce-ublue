#!/usr/bin/env bash

# Synchronize Bluefin's curated Homebrew bundles once on first boot.
# This keeps the XFCE image close to the "starter tools" experience from
# other uBlue desktops without turning the process into a recurring service.
set -euo pipefail

# Marker written after a successful (or intentionally skipped) run so the
# corresponding systemd unit does not execute every boot.
STATE_FILE="/var/lib/bluefin-brew-sync/done"
# User to receive brew packages; default is UID 1000 (first local user).
TARGET_USER="${TARGET_USER:-1000}"

# Allow TARGET_USER to be either a numeric UID or a literal username.
if [[ "${TARGET_USER}" =~ ^[0-9]+$ ]]; then
  TARGET_NAME="$(getent passwd "${TARGET_USER}" | cut -d: -f1 || true)"
else
  TARGET_NAME="${TARGET_USER}"
fi

# Exit successfully if the user is not created yet (common on very first boot
# before account provisioning finishes). The unit will retry next boot.
if [[ -z "${TARGET_NAME}" ]] || ! id "${TARGET_NAME}" >/dev/null 2>&1; then
  echo "Target user '${TARGET_USER}' does not exist yet; skipping for now."
  exit 0
fi

# Resolve and validate the target home, since brew bundle runs in user context.
TARGET_HOME="$(getent passwd "${TARGET_NAME}" | cut -d: -f6)"
if [[ -z "${TARGET_HOME}" ]] || [[ ! -d "${TARGET_HOME}" ]]; then
  echo "Target home '${TARGET_HOME}' does not exist yet; skipping for now."
  exit 0
fi

# From here on, any exit (success or failure) counts as "attempted" — mark done
# so the unit does not retry forever on a failed brew bundle. The retry-later
# exits above intentionally do NOT reach this trap.
trap 'touch "${STATE_FILE}"' EXIT

brew_dir=""

# Curated Brewfiles are copied into the image at build time (recipe.yml).
if [[ -d "/usr/share/ublue-os/homebrew" ]]; then
  brew_dir="/usr/share/ublue-os/homebrew"
fi

# Resolve the "regular user tools" Brewfile from known Bluefin names first.
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

# Resolve the "developer/IDE tools" Brewfile from known Bluefin names first.
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

# If canonical names were not found, fall back to first matching filenames.
if [[ -z "${regular_brewfile}" ]]; then
  regular_brewfile="$(find "${brew_dir}" -maxdepth 2 -type f -name '*Brewfile*' | grep -Ev '(dev|devel|developer|dx)' | head -n1 || true)"
fi
if [[ -z "${developer_brewfile}" ]]; then
  developer_brewfile="$(find "${brew_dir}" -maxdepth 2 -type f -name '*Brewfile*' | grep -Ei '(dev|devel|developer|dx)' | head -n1 || true)"
fi

# If either bundle is missing, mark done and stop to avoid boot-loop retries.
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

# Locate the brew executable across common install paths.
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

# No brew means nothing to do; mark done so boot remains clean.
if [[ -z "${brew_bin}" ]]; then
  echo "Homebrew binary not found; skipping curated brew sync."
  touch "${STATE_FILE}"
  exit 0
fi

# Minimal environment for deterministic non-interactive brew bundle runs.
common_env=(
  "HOME=${TARGET_HOME}"
  "USER=${TARGET_NAME}"
  "LOGNAME=${TARGET_NAME}"
  "PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:/usr/bin:/usr/sbin"
  "HOMEBREW_NO_ANALYTICS=1"
)

# Apply both curated bundles as the target user.
runuser -u "${TARGET_NAME}" -- env "${common_env[@]}" "${brew_bin}" bundle --file "${regular_brewfile}"
runuser -u "${TARGET_NAME}" -- env "${common_env[@]}" "${brew_bin}" bundle --file "${developer_brewfile}"

# Mark completion for systemd ConditionPathExists gate.
touch "${STATE_FILE}"
echo "Bluefin curated brew packages installed for ${TARGET_NAME}."
