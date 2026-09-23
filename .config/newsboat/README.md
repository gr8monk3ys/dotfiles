# newsboat

Terminal RSS/Atom reader. `config` is behaviour, `urls` the subscriptions;
newsboat reads both from `~/.config/newsboat/` as long as no `~/.newsboat/`
exists.

## Why these choices

- **Vim-style movement** (`h/j/k/l`, `g/G`, `d/u`): the stock bindings are
  unbound first so none of them shadow a remapped key. `h` and `Backspace`
  go back, `l` opens.
- **Query feeds at the top of `urls`** (`Blog Posts`, `Videos`) group entries
  by tag across feeds; `prepopulate-query-feeds` fills them at start-up
  instead of on first open.
- **`Space v` plays a link in mpv**: the macro swaps the browser for mpv,
  opens, and swaps back.
- **Colours are the terminal's named colours**, not hexes, so they follow the
  terminal theme and need nothing from the palette.

## Gotchas

- Only the pacmanfile installs newsboat; on macOS this config waits for a
  `brew install newsboat`.
- Links open in `$BROWSER` (`firefox`, from `.zshenv`).
- The `v` macro needs `mpv`, which no manifest installs.
- Feeds are not reloaded on a timer inside newsboat; the comment at the top of
  `config` suggests an hourly `newsboat -x reload` from cron.
