# Claude Code

Claude Code keeps its own state in `~/.claude/`, and almost none of it is
tracked here. The CLI is installed by its own installer into
`~/.local/bin/claude` (`.zshrc` puts that on `PATH`), and `aliases.zsh` defines
`cc='claude'`. Per-repo instructions go in that repo's `CLAUDE.md`; this
repo's is at the root.

## Themes

`themes/` holds custom Claude Code themes:

| File | Base | Matches |
| --- | --- | --- |
| `lscaturchio.json` | `dark` | lscaturchio.xyz, dark mode |
| `lscaturchio-light.json` | `light` | lscaturchio.xyz, light mode |

Stow links this directory to `~/.config/claude/`, which Claude Code never
opens: it reads custom themes from `~/.claude/themes/` (or
`$CLAUDE_CONFIG_DIR/themes/`). Put them there with:

```bash
make claude-themes            # or: bin/claude-themes install
bin/claude-themes status      # where they landed
```

On Windows, `windows\setup.ps1 -Apply` copies them instead. See
[bin/claude-themes](../../bin/claude-themes) for the full interface.

Then pick one with `/theme` in Claude Code; that stores
`"theme": "custom:lscaturchio"` in Claude Code's own `settings.json`, which is
not tracked. If `~/.claude/themes/` did not exist when Claude Code started,
restart it once.

A theme sets Claude Code's own colours only. The terminal background and font
come from the terminal.

### Not from the palette

Every other themed tool here draws from
[`palette/danse.conf`](../palette/README.md). These two files do not, on
purpose: they follow the website (accent `#42a979` on `#111317`), not the
desktop. The site defines no warning, plan-mode or diff colours, so those
tokens are chosen to sit beside its green. Each file has three fields —
`name`, `base`, and `overrides` (a map of colour token to `#rrggbb`); a token
left out falls through to the base preset.
