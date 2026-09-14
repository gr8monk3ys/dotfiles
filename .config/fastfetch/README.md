# fastfetch

System summary. `neofetch`'s replacement, and the thing that ends up in the
screenshot.

## The logo is the painting

Ghostty speaks the Kitty graphics protocol, so `logo.type = "kitty-direct"`
hands it the image file and lets the terminal draw it — no ASCII approximation.
The crop comes from `bin/wallpaper logo`, built from the same cached scan the
desktop background uses, so the two cannot disagree.

```bash
wallpaper logo        # build it; prints the path
```

If the file is missing — a fresh machine where `wallpaper` has not run — the
logo falls back to the built-in Apple ASCII art silently and fastfetch still
exits 0. Verified by moving the file away.

## Colours are named, not hex

`keys`, `title` and the rest use names (`blue`, `magenta`, `cyan`), which
resolve through the **terminal's** palette. Ghostty's palette is
[`.config/palette/danse.conf`](../palette/danse.conf), so fastfetch inherits
the retune automatically rather than carrying a copy that drifts. This is the
one themed config here that does not need a generated colour table, and it is
why there is no fastfetch entry in the generated-theme test.

## Gotchas

- `kitty-direct` renders nothing in a terminal without graphics support; the
  logo silently becomes ASCII. That includes piping fastfetch's output
  anywhere, which is expected.
- The `width`/`height` in the logo block are **cells**, not pixels. Changing
  the font size changes how large the painting appears.
