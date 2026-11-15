# Zsh Configuration

Configuration for [Zsh](https://www.zsh.org/), the login shell on macOS and
the primary shell for these dotfiles. `ZDOTDIR` points here (set in the
repo-root `.zshenv`), so everything zsh loads lives in this directory.

## Files

- `.zshrc` — main interactive-shell config: prompt selection, zinit
  plugins, history, completion styling, tool integrations
- `lib.zsh` — helpers both of the files below need, sourced first
- `aliases.zsh` — aliases (modern CLI replacements, macOS-only block,
  utility shortcuts); sourced by `.zshrc`
- `functions.zsh` — fzf-powered helper functions (`f`, `fv`, `cx`, …)
- `rice.zsh` — asks the Rice module (`palette/rice.sh`) for the active rice
  and points every themed CLI tool at that rice's file (ADR 0003)
- `rices/<rice>.zsh` — the shell's own colours per rice (highlight styles,
  autosuggestions, fzf, `EZA_COLORS`), rendered by `bin/rice-themes`
- `zshrc.local.example` — template for machine-local overrides

### Load order

`.zshrc` sources `lib.zsh`, then `aliases.zsh`, then `functions.zsh`, and the
order is load-bearing rather than incidental:

1. `aliases.zsh` builds the `copy` alias out of `lib.zsh`'s
   `_dotfiles_clipboard`.
2. zsh expands aliases when a function body is _parsed_, so `functions.zsh`
   must come after `aliases.zsh` for `cx` to pick up `l`.

`test_shell_boot.bats` asserts the helper is live in a booted shell, which is
what makes this a checked constraint instead of a comment.

## Prompt

[Starship](https://starship.rs) (config:
[`../starship/starship.toml`](../starship/starship.toml), a Monochrome 43
powerline prompt in a Nerd Font) on Monochrome 43. On another rice
`rice.zsh` switches it to that rice's lean prompt,
[`../starship/field-notebook.toml`](../starship/field-notebook.toml) or
[`../starship/danse.toml`](../starship/danse.toml), and on danse also points
`fastfetch` and `cava` at their danse files. If the `starship` binary is missing, `.zshrc` sets a plain two-line
prompt until `make brew-packages` installs it.

## Plugin manager

Plugins are managed by [zinit](https://github.com/zdharma-continuum/zinit)
(self-bootstraps on first shell start): zsh-syntax-highlighting (the rice's `ZSH_HIGHLIGHT_STYLES`),
zsh-completions, zsh-autosuggestions, fzf-tab, plus a few OMZ snippets
(git, sudo, command-not-found; aws/kubectl/archlinux only when the tool
exists). OMZ itself is **not** installed.

## Tool integrations

`.zshrc` initializes these when installed (all from the Brewfile):

- **fzf** — ctrl-r / ctrl-t, in the rice's colours via `FZF_DEFAULT_OPTS`
- **zoxide** — frecency `cd` replacement (`--cmd cd`)
- **atuin** — searchable shell history UI (the rice's theme in
  [`../atuin/`](../atuin/))
- **direnv** — per-directory environments
- **mise** — runtime version manager
- **gh** — `GITHUB_PERSONAL_ACCESS_TOKEN` is exported from `gh auth token`
  (gh's keyring login) when it is not already set, for the github Claude Code
  plugin's MCP server. Nothing is written to disk; log in once with
  `gh auth login`. Costs one `gh` call (~70ms) per shell start.

## Local overrides & machine types

- `~/.config/zsh/zshrc.local` — machine-specific settings (gitignored),
  sourced last; copy from `zshrc.local.example`
- `~/.machine_type` (`personal`/`work`/`server`) selects an optional
  `zshrc.<type>` overlay

## Usage

```bash
exec zsh          # reload configuration
dotfiles-bench-shell   # measure startup time
```

## Resources

- [Zsh Documentation](https://zsh.sourceforge.io/Doc/)
- [zinit](https://github.com/zdharma-continuum/zinit)
- [Starship](https://starship.rs)
