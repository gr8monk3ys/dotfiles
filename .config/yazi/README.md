# yazi

[Yazi](https://yazi-rs.github.io/docs), the primary terminal file manager.
`yazi.toml` is behaviour, `keymap.toml` the Vim-style bindings (press `~` in
yazi for the live list), `theme.toml` the colours.

## Why these choices

- **Hidden files shown, directories first, natural sort** (`file2` before
  `file10`), with sizes in the line mode.
- **Openers per platform:** `open` / `open -R` on macOS, `xdg-open` /
  `nautilus` on Linux; archives go through `ouch`, so one tool handles every
  format for both extract and compress.
- **Previews** use yazi's built-in previewers for code, images, video, PDF
  and archives; SVG, HEIC, AVIF and JXL go through ImageMagick (`magick`).
  Ghostty draws images natively.

## Shell integration

`y` (and `fm`), defined in `.config/zsh/aliases.zsh`, runs yazi and `cd`s to
wherever you quit it. Plain `yazi` does not.

## Gotchas

- yazi renames config sections between releases, and a config it cannot
  parse is silently replaced by stock defaults. 25.4 renamed `[manager]` to
  `[mgr]` and the `[open]` rules' `name` key to `url`;
  `test/test_tool_configs.bats` checks `yazi.toml` for both.
- `theme.toml` is rendered from the danse palette by `bin/palette`; edit its
  template under `.config/palette/templates/`, not the file here.
