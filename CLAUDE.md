# CLAUDE.md

Personal dotfiles for macOS and Arch (incl. Omarchy). GNU Stow links `.config/`
into `~/.config/`; `make` drives install, link and verification.

## Run / verify

- `make` — install + link for the platform `bin/platform detect` reports.
- `make link` / `make link-dry-run` / `make unlink` — `bin/link` apply /
  dry-run / undo. Links only; installs nothing but stow.
- `make verify` — the gate: `make lint` + `make test` + both Docker
  containers (`SKIP_DOCKER=1` skips those). `make test` is `bats test`.
  What each runs, and CI: `OPERATING.md` § Testing and verification.
- `bin/palette check` after any edit under `.config/`; `palette render`
  after editing a template or `danse.conf`.

## Where things live

- `.config/<app>/` — one dir per tool, each with a README. `.zshenv` at the root
  is the only file linked into `$HOME` directly.
- `.config/palette/` — `danse.conf` and the templates every themed file is
  rendered from. Rendered files and `palette:begin`/`end` regions are never
  hand-edited.
- `bin/` — `link`, `link-state`, `palette`, `wallpaper`, `manifest`,
  `install-kind`, `platform`, `dotfiles-*`, and the validators
  `check-alias-references`, `validate-doc-links`, `validate-config-live`;
  shared shell in `bin/lib/`. Index: `bin/README.md`; each answers `--help`.
- `install/` — manifests: `Brewfile`, `Caskfile[.extra]`, `npmfile`, `Rustfile`,
  `pacmanfile`, `Codefile`, plus `duti`. One package per line, its rationale
  and optional `cmd=`/`tier=` in the line's comment (`install/README.md`
  § Entry format).
- `test/` — BATS, one `test_<module>.bats` per module, helpers in
  `test_helper/`, conventions in `test/README.md`.
- `OPERATING.md` — the runbook. `CONTEXT.md` — the domain terms.

## Gotchas

- No identity or real hosts in tracked config. Git/jj identity and SSH hosts go in
  gitignored local files (`.config/git/config.local`, `.config/jj/conf.d/`,
  `.config/ssh/config.d/*.conf`); `test_dotfiles_init.bats` enforces it.
- Every unconditional alias must resolve to a manifest entry, builtin, or
  `test/allowlist/system-tools.txt` — `check-alias-references` fails otherwise.
- Portable shell only in anything sourced on macOS (no GNU-only flags).
- Conventional commits; one change per commit. A package is added with its
  rationale on the same manifest line (`test_packages.bats` fails without one);
  whether `dotfiles-doctor` probes it is `tier=` on that line.
- Tests never touch the real `$HOME`: fixture home via `setup_test_env`.
- Manifests under `install/` are read only through `bin/manifest`, never
  parsed inline.

## Agent skills

### Issue tracker

Issues live as GitHub issues in `gr8monk3ys/dotfiles`, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles, each label string equal to its name. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` and `docs/adr/` at the repo root, created lazily. See `docs/agents/domain.md`.
