#!/usr/bin/bash

# Show a simple terminal notice when bootc has a newer staged deployment.
_bootc_notice_exit() {
  return 0 2>/dev/null || exit 0
}

case "$-" in
  *i*) ;;
  *) _bootc_notice_exit ;;
esac

# Optional per-user opt-out, matching existing no-show MOTD behavior.
if [ -n "${HOME:-}" ] && [ -e "${HOME}/.config/no-show-staged-image-notice" ]; then
  _bootc_notice_exit
fi

command -v bootc >/dev/null 2>&1 || _bootc_notice_exit
command -v jq >/dev/null 2>&1 || _bootc_notice_exit

bootc_json="$(bootc status --json 2>/dev/null)" || _bootc_notice_exit
[ -n "$bootc_json" ] || _bootc_notice_exit

staged_present="$(printf '%s\n' "$bootc_json" | jq -r '.status.staged != null')"
booted_present="$(printf '%s\n' "$bootc_json" | jq -r '.status.booted != null')"
[ "$staged_present" = "true" ] || _bootc_notice_exit
[ "$booted_present" = "true" ] || _bootc_notice_exit

booted_ref="$(printf '%s\n' "$bootc_json" | jq -r '.status.booted.image.image // .status.booted.image["image-reference"] // .status.booted.imageReference // .status.booted["image-reference"] // ""')"
staged_ref="$(printf '%s\n' "$bootc_json" | jq -r '.status.staged.image.image // .status.staged.image["image-reference"] // .status.staged.imageReference // .status.staged["image-reference"] // ""')"

booted_digest="$(printf '%s\n' "$bootc_json" | jq -r '.status.booted.image.digest // .status.booted.digest // .status.booted.imageDigest // ""')"
staged_digest="$(printf '%s\n' "$bootc_json" | jq -r '.status.staged.image.digest // .status.staged.digest // .status.staged.imageDigest // ""')"

if [ -n "$staged_ref" ] && [ -n "$booted_ref" ] && [ "$staged_ref" = "$booted_ref" ]; then
  if [ -z "$staged_digest" ] || [ -z "$booted_digest" ] || [ "$staged_digest" = "$booted_digest" ]; then
    _bootc_notice_exit
  fi
fi

if [ -n "$staged_digest" ] && [ -n "$booted_digest" ] && [ "$staged_digest" = "$booted_digest" ]; then
  _bootc_notice_exit
fi

echo
echo "[bootc] A new image is staged and ready."
[ -n "$staged_ref" ] && echo "[bootc] Staged image: $staged_ref"
echo "[bootc] Reboot to apply it."

_bootc_notice_exit
