# Use This Repository as Template or Fork

If you want your own image in your own GitHub account, you have two options:

- Use Template: best for starting fresh without upstream git history.
- Fork: best if you want easy upstream syncing/cherry-picking from this repo.

## Option A: Use Template (Recommended)

1. On GitHub, open this repository and click `Use this template`.
2. Create a new repository under your account (for example `my-xfce-ublue`).
3. Clone your new repository locally.
4. Update image identity in `recipes/recipe.yml`:
   - `name:` (image name)
   - `base-image:` (leave as-is unless intentionally changing base)
   - `image-version:` (keep `latest` for main)
5. In GitHub repo settings, add Actions secrets:
   - `SIGNING_SECRET`: full contents of your `cosign.key`
   - `COSIGN_PASSWORD`: password used when that key was created
6. Ensure `cosign.pub` is committed at repo root.
7. Push to `main` and wait for `Build and Push Image` workflow to complete.
8. Verify image exists in GHCR:
   - `ghcr.io/<your-github-username>/<image-name>:latest`

## Option B: Fork

1. On GitHub, click `Fork`.
2. In fork settings, add the same secrets:
   - `SIGNING_SECRET`
   - `COSIGN_PASSWORD`
3. Confirm `Actions` are enabled for the fork.
4. Push a commit to your fork `main` and confirm build success.
5. Your image is published under your account namespace in GHCR.

## Template vs Fork Decision

- Use Template when:
  - You want a clean independent project.
  - You do not want inherited commit history/noise.
- Use Fork when:
  - You plan to regularly pull updates from this repository.
  - You want easy upstream diff visibility.

## Branch Build Behavior

- `main` pushes publish stable image tag `:latest`.
- Non-`main` branch pushes publish beta branch images via `build-beta.yml`.
- Dependabot branches are excluded from beta image publishing.
