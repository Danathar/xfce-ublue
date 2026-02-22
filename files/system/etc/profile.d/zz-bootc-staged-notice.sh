#!/usr/bin/bash

# Show a terminal notice when bootc has a newer staged deployment.
_bootc_staged_notice_main() {
  local status_json status_source staged_present booted_present
  local booted_ref staged_ref booted_digest staged_digest
  local booted_version staged_version

  case "$-" in
    *i*) ;;
    *) return 0 ;;
  esac

  # Optional per-user opt-out.
  if [ -n "${HOME:-}" ] && [ -e "${HOME}/.config/no-show-staged-image-notice" ]; then
    return 0
  fi

  command -v jq >/dev/null 2>&1 || return 0

  if command -v bootc >/dev/null 2>&1; then
    status_json="$(bootc status --json 2>/dev/null)" && [ -n "$status_json" ] && status_source="bootc"
  fi

  # Some systems restrict `bootc status` to root; use rpm-ostree JSON when available.
  if [ -z "$status_source" ] && command -v rpm-ostree >/dev/null 2>&1; then
    status_json="$(rpm-ostree status --json 2>/dev/null)" && [ -n "$status_json" ] && status_source="rpm-ostree"
  fi

  [ -n "$status_source" ] || return 0

  if [ "$status_source" = "bootc" ]; then
    staged_present="$(printf '%s\n' "$status_json" | jq -r '.status.staged != null')"
    booted_present="$(printf '%s\n' "$status_json" | jq -r '.status.booted != null')"
    [ "$staged_present" = "true" ] || return 0
    [ "$booted_present" = "true" ] || return 0

    booted_ref="$(printf '%s\n' "$status_json" | jq -r '.status.booted.image.image // .status.booted.image["image-reference"] // .status.booted.imageReference // .status.booted["image-reference"] // ""')"
    staged_ref="$(printf '%s\n' "$status_json" | jq -r '.status.staged.image.image // .status.staged.image["image-reference"] // .status.staged.imageReference // .status.staged["image-reference"] // ""')"

    booted_digest="$(printf '%s\n' "$status_json" | jq -r '.status.booted.image.digest // .status.booted.digest // .status.booted.imageDigest // ""')"
    staged_digest="$(printf '%s\n' "$status_json" | jq -r '.status.staged.image.digest // .status.staged.digest // .status.staged.imageDigest // ""')"

    booted_version="$(printf '%s\n' "$status_json" | jq -r '.status.booted.version // ""')"
    staged_version="$(printf '%s\n' "$status_json" | jq -r '.status.staged.version // ""')"
  else
    staged_present="$(printf '%s\n' "$status_json" | jq -r '[.deployments[]? | select(.staged == true)] | length > 0')"
    booted_present="$(printf '%s\n' "$status_json" | jq -r '[.deployments[]? | select(.booted == true)] | length > 0')"
    [ "$staged_present" = "true" ] || return 0
    [ "$booted_present" = "true" ] || return 0

    booted_ref="$(printf '%s\n' "$status_json" | jq -r '.deployments[]? | select(.booted == true) | .["container-image-reference"] // .origin // .id // ""' | head -n 1)"
    staged_ref="$(printf '%s\n' "$status_json" | jq -r '.deployments[]? | select(.staged == true) | .["container-image-reference"] // .origin // .id // ""' | head -n 1)"

    booted_digest="$(printf '%s\n' "$status_json" | jq -r '.deployments[]? | select(.booted == true) | .digest // .checksum // ""' | head -n 1)"
    staged_digest="$(printf '%s\n' "$status_json" | jq -r '.deployments[]? | select(.staged == true) | .digest // .checksum // ""' | head -n 1)"

    booted_version="$(printf '%s\n' "$status_json" | jq -r '.deployments[]? | select(.booted == true) | .version // ""' | head -n 1)"
    staged_version="$(printf '%s\n' "$status_json" | jq -r '.deployments[]? | select(.staged == true) | .version // ""' | head -n 1)"
  fi

  # If bootc cannot provide enough identifying data, stay silent.
  [ -n "${staged_ref}${staged_digest}${staged_version}" ] || return 0
  [ -n "${booted_ref}${booted_digest}${booted_version}" ] || return 0

  # Prefer digest comparison when both digests are available.
  if [ -n "$staged_digest" ] && [ -n "$booted_digest" ]; then
    [ "$staged_digest" != "$booted_digest" ] || return 0
  elif [ -n "$staged_ref" ] && [ -n "$booted_ref" ]; then
    [ "$staged_ref" != "$booted_ref" ] || return 0
  elif [ -n "$staged_version" ] && [ -n "$booted_version" ]; then
    [ "$staged_version" != "$booted_version" ] || return 0
  else
    # Missing comparable values: avoid false positives.
    return 0
  fi

  echo
  echo "[bootc] A new image is staged and ready."
  [ -n "$staged_ref" ] && echo "[bootc] Staged image: $staged_ref"
  echo "[bootc] Reboot to apply it."
}

_bootc_staged_notice_main
unset -f _bootc_staged_notice_main
