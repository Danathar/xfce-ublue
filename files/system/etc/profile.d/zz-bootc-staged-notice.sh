#!/usr/bin/bash

# Show a terminal notice when a reboot is needed for a newly staged deployment.
_bootc_staged_notice_main() {
  local pending_ec status_json staged_ref

  case "$-" in
    *i*) ;;
    *) return 0 ;;
  esac

  # Optional per-user opt-out.
  if [ -n "${HOME:-}" ] && [ -e "${HOME}/.config/no-show-staged-image-notice" ]; then
    return 0
  fi

  command -v rpm-ostree >/dev/null 2>&1 || return 0

  if rpm-ostree status --pending-exit-77 >/dev/null 2>&1; then
    pending_ec=0
  else
    pending_ec=$?
  fi

  # 77 means a pending deployment is available (reboot needed).
  [ "$pending_ec" -eq 77 ] || return 0

  # Best-effort staged ref for context; message should still show without this.
  staged_ref=""
  if command -v jq >/dev/null 2>&1; then
    status_json="$(rpm-ostree status --json 2>/dev/null)"
    if [ -n "$status_json" ]; then
      staged_ref="$(printf '%s\n' "$status_json" | jq -r '.deployments[]? | select(.staged == true) | .["container-image-reference"] // .origin // .id // ""' | head -n 1)"
    fi
  fi

  echo
  echo "[bootc] A new image is staged and ready."
  [ -n "$staged_ref" ] && echo "[bootc] Staged image: $staged_ref"
  echo "[bootc] Reboot to apply it."
}

_bootc_staged_notice_main
unset -f _bootc_staged_notice_main
