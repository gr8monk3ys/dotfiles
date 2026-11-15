# strudel

A separate Neovim profile for live coding music with
[Strudel](https://strudel.cc) through
[strudel.nvim](https://github.com/gruvw/strudel.nvim). It is its own
`NVIM_APPNAME`, so the main editor config (`.config/nvim/`) is untouched and
this one keeps its plugins in `~/.local/share/strudel/`.

## Use

```bash
NVIM_APPNAME=strudel nvim file.str
```

| Key | Action |
| --- | --- |
| `<Space>sl` | launch the Strudel browser window |
| `<Space>st` | play / stop |
| `<Space>su`, `Ctrl+Enter` | evaluate the buffer |
| `<Space>ss` | stop |
| `<Space>sq` | quit |

`:w` re-evaluates while playing. With `STRUDEL_AUTOLAUNCH=1` in the
environment the browser opens and playback starts as soon as the profile
does.

## Colours

The active Rice's, like every other themed tool (ADR 0003): the profile
loads `.config/nvim/lua/palette.lua` and lets onedark.nvim paint with it,
so on Field Notebook it is night paper and the forest-green pen, the same as
the main editor and Ghostty.

## Notes

- Chromium is used when it is at `/usr/bin/chromium` (Arch); otherwise
  strudel.nvim's own browser.
- Only `init.lua` is tracked (and linked); `lazy-lock.json` stays a local
  file beside it, written by lazy.nvim, so this profile's plugins are not
  pinned.
