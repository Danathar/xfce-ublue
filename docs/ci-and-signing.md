# CI and Signing

## Workflows

- `.github/workflows/build.yml`: builds and pushes image on `main` push, schedule, or manual trigger.
- `.github/workflows/build-beta.yml`: builds and pushes branch-tagged beta images for non-`main` branches.
- `.github/workflows/build-pr.yml`: PR validation build (unsigned, non-push).

Docs/markdown-only changes are ignored by image build workflows (`README.md`, `**/README.md`, `docs/**`, and `**/*.md`).

## Required GitHub Secrets

- `SIGNING_SECRET`: contents of `cosign.key`
- `COSIGN_PASSWORD`: password used to generate `cosign.key` (empty only if key was created with empty password)

## Signing Notes

- Publish workflows use cosign signing with `SIGNING_SECRET`.
- PR validation builds run unsigned (`--no-sign`) and do not push.

## Update Path Configuration

- `uupd.timer` is enabled for ongoing updates.
- `rpm-ostreed-automatic.timer` is disabled to avoid duplicate auto-update paths.
- `uupd` config file: `files/system/etc/uupd/config.json`.
