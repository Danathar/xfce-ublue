# AGENTS.md

Canonical repo instructions for Codex/ChatGPT-style agents working in this
repository. This file is the agent-facing version of the guidance in
`CLAUDE.md`, adapted for this project and intended to be followed going
forward.

## Scope

- Apply these instructions to the whole repository unless a deeper `AGENTS.md`
  overrides them.
- Treat `CLAUDE.md` as background context; treat this file as the canonical
  working agreement for agent edits in this repo.

## Repo Summary

- Project type: BlueBuild recipe for a Fedora bootc / Universal Blue style
  XFCE image.
- Main build definition: `recipes/recipe.yml`.
- Overlay files land under `files/system`.
- Custom build scripts live under `files/scripts` and
  `files/system/usr/libexec/xfce-ublue`.
- CI lives in `.github/workflows/`.
- Default branch is `main`.

## Working Style

### 1. Think Before Coding

- State assumptions when they materially affect the change.
- If there are multiple reasonable interpretations, surface them instead of
  silently choosing the most convenient one.
- Push back on unnecessary complexity.
- Stop and ask only when a hidden-risk decision cannot be made safely from repo
  context.

### 2. Prefer the Simplest Change

- Solve the requested problem with the minimum code and minimum surface area.
- Do not add speculative flexibility, abstractions, or cleanup.
- Match existing patterns unless there is a clear defect.
- If a fix can live in build-time configuration instead of first-boot runtime
  logic, strongly prefer the build-time fix.

### 3. Keep Diffs Surgical

- Change only lines that trace directly to the task.
- Do not opportunistically refactor nearby code.
- Remove only dead code made obsolete by your own change.
- Do not stage or commit unrelated untracked files or local notes unless the
  user explicitly asks. Be especially careful with repo-root scratch files.

### 4. Verify What You Change

- Turn requests into concrete success criteria before editing.
- Prefer targeted validation over broad hand-waving.
- If you cannot run an important check, say so plainly.
- For bug fixes, try to validate the specific failure mode, not just syntax.

## Repo-Specific Guardrails

### BlueBuild Recipe Rules

- `recipes/recipe.yml` is the source of truth for the image definition.
- `image-version` is the base image tag, not the output branch tag. Do not
  rewrite it to create beta branch output tags.
- If branch-specific image tags are needed in CI, generate a temporary recipe
  with `alt-tags` instead of mutating the base image reference semantics.
- Keep `recipes/recipe.yml` readable; comment only where the behavior is
  non-obvious or easy to misinterpret later.

### Workflow Rules

- If a workflow edits or generates files before calling
  `blue-build/github-action`, preserve those edits by using `skip_checkout:
  true`.
- Keep branch-build logic compatible with the current beta flow in
  `.github/workflows/build-beta.yml`.
- Prefer non-destructive workflow changes and preserve concurrency protections
  when editing CI.

### bootc / Image Content Rules

- Prefer package-owned defaults over custom overrides when the package already
  creates the required path or config correctly.
- Avoid adding first-boot or runtime network dependencies when the needed data
  can be copied into the image at build time.
- Treat systemd units, tmpfiles, and first-boot scripts as user-facing boot
  paths: small mistakes there can break installs or create retry loops.

### Documentation Rules

- Keep docs aligned with actual behavior, especially around image build, first
  boot, and update flow.
- Do not rewrite docs for style alone.

## Recommended Validation

Run the smallest relevant subset for the change:

- `actionlint .github/workflows/build-beta.yml .github/workflows/build-pr.yml`
- `yamllint .github/workflows/*.yml recipes/recipe.yml`
- `bluebuild validate recipes/recipe.yml`
- `shellcheck files/scripts/install-starship.sh`
- `shellcheck files/system/usr/libexec/xfce-ublue/bluefin-brew-sync.sh`
- `systemd-analyze verify files/system/etc/systemd/system/bluefin-brew-sync.service`

When a change affects the built image or tag behavior, also consider:

- Local build: `bluebuild --log-out .state/logs build --archive oci recipes/recipe.yml`
- CI verification through GitHub Actions logs for the affected workflow

## Review Expectations

When asked for review, prioritize:

- real bugs
- regressions in build or first-boot behavior
- broken image-tag semantics
- package ownership conflicts
- missing or weak verification

Lead with findings, include file references, and keep summaries brief.

## Communication Defaults

- Be concise, direct, and collaborative.
- Explain why a change is needed when the reason is not obvious from the diff.
- Mention tradeoffs when choosing between runtime behavior, build-time behavior,
  and CI behavior.
- If something is safe but slightly odd, say so instead of silently normalizing
  it.
