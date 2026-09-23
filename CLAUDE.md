# CLAUDE.md

Personal dotfiles for macOS and Arch (incl. Omarchy). GNU Stow links `.config/`
into `~/.config/`; `make` drives install, link and verification.

## Run / verify

- `make` — detect platform (`bin/platform detect`) and install + link.
- `make link` / `make link-dry-run` / `make unlink` — `bin/link` apply/dry-run/undo
  (stow, `.zshenv`, SSH Include, tool-owned dirs). Links only; installs nothing
  but stow.
- `make verify` — the gate: shellcheck, markdownlint, stale-ref grep, palette
  check, doc-link validator, BATS, and a Docker fresh-install (`SKIP_DOCKER=1`,
  `SKIP_LINTERS=1` to skip parts).
  It is a superset of CI. `make test` is just BATS (`bats test`).
- CI (`.github/workflows/ci.yml`) runs the same make targets, each once, plus
  the curl installer and a macOS fresh install; `Container (arch)` is the
  full `make arch` gate.

## Where things live

- `.config/<app>/` — one dir per tool, each with a README. `.zshenv` at the root
  is the only file linked into `$HOME` directly.
- `bin/` — `dotfiles-doctor/update/backup/restore/sync/why`, `platform`, and the
  validators `validate-doc-links`, `check-alias-references`; `manifest` reads `install/`.
- `install/` — manifests: `Brewfile`, `Caskfile[.extra]`, `npmfile`, `Rustfile`,
  `pacmanfile`, `Codefile`, `duti`. Each entry's rationale (and doctor tier) is
  the comment on its line — `install/README.md` § Entry format; `dotfiles-why`
  reads it.
- `test/` — BATS (`test_*.bats`, helpers in `test_helper/`).
- `OPERATING.md` — the runbook (install paths, profiles, troubleshooting, conventions).

## Gotchas

- No identity or real hosts in tracked config. Git/jj identity and SSH hosts go in
  gitignored local files (`.config/git/config.local`, `.config/jj/conf.d/`,
  `.config/ssh/config.d/*.conf`); `test_regressions.bats` enforces it.
- Every unconditional alias must resolve to a manifest entry, builtin, or
  `test/allowlist/system-tools.txt` — `check-alias-references` fails otherwise.
- Portable shell only in anything sourced on macOS (no GNU-only flags).
- Conventional commits; one change per commit. A package is added with its
  rationale on the same manifest line (`test_packages.bats` fails without one);
  whether `dotfiles-doctor` probes it is `tier=` on that line.
- Manifests under `install/` are read only through `bin/manifest`, never
  parsed inline.

## Agent skills

### Issue tracker

Issues live as GitHub issues in `gr8monk3ys/dotfiles`, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, each label string equal to its name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the repo root, created lazily. See `docs/agents/domain.md`.
