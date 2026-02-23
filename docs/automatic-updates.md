# Automatic Updates

This repo has multiple automated update/build paths in GitHub Actions:

- `Build and Push Image` (`.github/workflows/build.yml`):
  - Runs automatically on non-doc pushes to `main`.
  - Runs on a weekly schedule: Sunday at `05:30 UTC`.
  - Can also be run manually from the Actions tab (`workflow_dispatch`).
  - Rebuilds and publishes signed `ghcr.io/danathar/xfce:latest`.

- `Dependabot` (`.github/dependabot.yml`):
  - Checks GitHub Actions dependencies daily.
  - Opens PRs when workflow/action versions can be updated.

- `Build PR Image` (`.github/workflows/build-pr.yml`):
  - Runs automatically on non-doc pull requests.
  - Validates image buildability without pushing or signing.

- `Build and Push Beta Branch Image` (`.github/workflows/build-beta.yml`):
  - Runs automatically on non-doc pushes to non-`main` branches.
  - Publishes beta branch-tagged images.

## Non-Doc Trigger Rules

Build workflows skip docs-only changes via `paths-ignore`:

- `README.md`
- `**/README.md`
- `docs/**`
- `**/*.md`
