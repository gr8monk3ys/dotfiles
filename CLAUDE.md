# CLAUDE.md

Personal dotfiles for macOS and Arch (incl. Omarchy). GNU Stow links `.config/`
into `~/.config/`; `make` drives install, link and verification.

## Run / verify

- `make` — detect platform (`bin/platform detect`) and install + link.
- `make link` / `make link-dry-run` / `make unlink` — Stow only.
- `make verify` — the gate: shell syntax, shell-surface tests, stale-ref grep,
  doc-link and tool-catalog validators, BATS, and a Docker fresh-install
  (`SKIP_DOCKER=1` to skip). `make test` is just BATS (`bats test`).
- CI (`.github/workflows/ci.yml`) runs the same checks plus the curl installer.

## Where things live

- `.config/<app>/` — one dir per tool, each with a README. `.zshenv` at the root
  is the only file linked into `$HOME` directly.
- `bin/` — `dotfiles-doctor/update/backup/restore/sync/why`, `platform`, and the
  validators `validate-doc-links`, `validate-tool-docs`, `check-alias-references`.
- `install/` — manifests: `Brewfile`, `Caskfile[.extra]`, `npmfile`, `Rustfile`,
  `pacmanfile`, `Codefile`, `duti`.
- `docs/TOOLS.md` — one rationale entry per package; `validate-tool-docs` fails
  when a manifest and the catalog disagree in either direction.
- `test/` — BATS (`test_*.bats`, helpers in `test_helper/`).
- `OPERATING.md` — the runbook (install paths, profiles, troubleshooting, conventions).

## Gotchas

- No identity or real hosts in tracked config. Git/jj identity and SSH hosts go in
  gitignored local files (`.config/git/config.local`, `.config/jj/conf.d/`,
  `.config/ssh/config.d/*.conf`); `test_regressions.bats` enforces it.
- Every unconditional alias must resolve to a manifest entry, builtin, or
  `test/allowlist/system-tools.txt` — `check-alias-references` fails otherwise.
- Portable shell only in anything sourced on macOS (no GNU-only flags).
- Conventional commits; one change per commit; update `docs/TOOLS.md` in the
  same commit that adds or removes a package.
