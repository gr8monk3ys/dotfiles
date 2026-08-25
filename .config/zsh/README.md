# Zsh Configuration

Configuration for [Zsh](https://www.zsh.org/), the login shell on macOS and
the primary shell for these dotfiles. `ZDOTDIR` points here (set in the
repo-root `.zshenv`), so everything zsh loads lives in this directory.

## Files

- `.zshrc` — main interactive-shell config: prompt selection, zinit
  plugins, history, completion styling, tool integrations
- `.zprofile` — login-shell setup
- `aliases.zsh` — aliases (modern CLI replacements, macOS-only block,
  utility shortcuts); sourced by `.zshrc`
- `functions.zsh` — fzf-powered helper functions (`f`, `fv`, `cx`, …)
- `.inputrc` — readline behavior for non-zsh tools
- `zshrc.local.example` — template for machine-local overrides

## Prompt

[Starship](https://starship.rs) (config:
[`../starship/starship.toml`](../starship/starship.toml), OneDark). If the
`starship` binary is missing, `.zshrc` sets a plain two-line prompt until
`make brew-packages` installs it.

## Plugin manager

Plugins are managed by [zinit](https://github.com/zdharma-continuum/zinit)
(self-bootstraps on first shell start): zsh-syntax-highlighting (OneDark `ZSH_HIGHLIGHT_STYLES` palette),
zsh-completions, zsh-autosuggestions, fzf-tab, plus a few OMZ snippets
(git, sudo, command-not-found; aws/kubectl/archlinux only when the tool
exists). OMZ itself is **not** installed.

## Tool integrations

`.zshrc` initializes these when installed (all from the Brewfile):

- **fzf** — ctrl-r / ctrl-t, themed OneDark via `FZF_DEFAULT_OPTS`
- **zoxide** — frecency `cd` replacement (`--cmd cd`)
- **atuin** — searchable shell history UI (OneDark theme in
  [`../atuin/`](../atuin/))
- **direnv** — per-directory environments
- **mise** — runtime version manager

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
