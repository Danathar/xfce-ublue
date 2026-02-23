# `uupd` Configuration Notes

This directory contains runtime configuration for Universal Blue's updater.

`config.json` is intentionally strict JSON because `uupd` reads it directly.
JSON does not support inline comments, so this file documents each setting.

## `checks.hardware`

- `enable`: Turn hardware checks on/off before running updates.
- `bat-min-percent`: Minimum battery percent required to proceed.
- `cpu-max-percent`: Maximum CPU usage percent allowed before deferring.
- `mem-max-percent`: Maximum memory usage percent allowed before deferring.
- `net-max-bytes`: Maximum recent network usage allowed before deferring.

## `modules`

Each module can be disabled independently:

- `brew.disable`: Skip Homebrew update/install actions.
- `distrobox.disable`: Skip distrobox update actions.
- `flatpak.disable`: Skip flatpak update actions.
- `system.disable`: Skip system image (`bootc`) update actions.
