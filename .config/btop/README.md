# btop

Resource monitor. Replaces `top` for anything interactive.

## Theme

`themes/danse.theme` is rendered by `bin/palette` from
[`.config/palette/danse.conf`](../palette/danse.conf) and its template. The gradients are where
the Matisse colours earn their place: load and temperature run viridian →
ochre → vermilion, which is the painting's own ground-to-figures progression.

`theme[main_bg]` is deliberately **empty** and `theme_background = false` is
set. That is how btop leaves its background transparent, so it inherits
Ghostty's blur and the painting behind it instead of punching an opaque
rectangle through the middle of the rice.

## btop rewrites this config

`btop.conf` is tracked in **btop's own canonical form**, not as hand-written
prose, because btop rewrites the file on exit — comments and ordering included.
An earlier hand-commented version was replaced the first time btop ran, with
every setting preserved but every comment gone.

The rewrite is idempotent: running btop again leaves the file byte-identical
(verified by hash). So a diff here means a real change — a setting you altered
in the TUI, or a schema change in a new btop — and is worth committing, not
reverting.

The rationale that used to live in the file:

| Setting | Why |
| --- | --- |
| `graph_symbol = "braille"` | densest graph per cell, which matters in a tiled pane |
| `vim_keys = true` | consistent with everything else here |
| `theme_background = false` | inherit Ghostty's transparency |
| `proc_gradient = true` | the palette gradient on the process list |

## Gotchas

- btop needs a real terminal. It exits immediately under a pipe or a
  non-interactive shell with `Couldn't determine terminal size`, which is why
  there is no `validate-config-live` probe for it. The theme is rendered, so
  `bin/palette check` guards it instead; that is a text check, not a
  liveness one.
