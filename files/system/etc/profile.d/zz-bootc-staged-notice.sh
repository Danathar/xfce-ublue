#!/usr/bin/bash

# Show a terminal notice when bootc has a newer staged deployment.
_bootc_staged_notice_main() {
  local bootc_json staged_present booted_present
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

  command -v bootc >/dev/null 2>&1 || return 0
  command -v jq >/dev/null 2>&1 || return 0

  bootc_json="$(bootc status --json 2>/dev/null)" || return 0
  [ -n "$bootc_json" ] || return 0

  staged_present="$(printf '%s\n' "$bootc_json" | jq -r '.status.staged != null')"
  booted_present="$(printf '%s\n' "$bootc_json" | jq -r '.status.booted != null')"
  [ "$staged_present" = "true" ] || return 0
  [ "$booted_present" = "true" ] || return 0

  booted_ref="$(printf '%s\n' "$bootc_json" | jq -r '.status.booted.image.image // .status.booted.image["image-reference"] // .status.booted.imageReference // .status.booted["image-reference"] // ""')"
  staged_ref="$(printf '%s\n' "$bootc_json" | jq -r '.status.staged.image.image // .status.staged.image["image-reference"] // .status.staged.imageReference // .status.staged["image-reference"] // ""')"

  booted_digest="$(printf '%s\n' "$bootc_json" | jq -r '.status.booted.image.digest // .status.booted.digest // .status.booted.imageDigest // ""')"
  staged_digest="$(printf '%s\n' "$bootc_json" | jq -r '.status.staged.image.digest // .status.staged.digest // .status.staged.imageDigest // ""')"

  booted_version="$(printf '%s\n' "$bootc_json" | jq -r '.status.booted.version // ""')"
  staged_version="$(printf '%s\n' "$bootc_json" | jq -r '.status.staged.version // ""')"

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
