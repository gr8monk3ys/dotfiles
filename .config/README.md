# .config/

One directory per tool. `make link` stows this directory into
`~/.config/`; tools that write their own files into their config directory
are linked unfolded instead (`bin/link tool-owned` lists them; see
CONTEXT.md § Link). Each directory's README says why the tool is here and
what is not obvious from its config.

Themed files are rendered from [palette/](palette/README.md): edit the
template there, never the rendered file.

| Directory | Tool |
| --- | --- |
| [aerospace/](aerospace/) | AeroSpace, the tiling window manager (macOS) |
| [atuin/](atuin/) | Shell history search |
| [bat/](bat/) | `cat` with highlighting; also the pager theme |
| [borders/](borders/) | JankyBorders, the focused-window border (macOS) |
| [btop/](btop/) | Resource monitor |
| [cava/](cava/) | Console audio visualiser |
| [claude/](claude/) | Nothing tracked; Claude Code keeps its state in `~/.claude/` |
| [curl/](curl/) | curl defaults |
| [eza/](eza/) | `ls` replacement |
| [fastfetch/](fastfetch/) | System summary |
| [firefox/](firefox/) | arkenfox `user.js`, installed per profile by `make firefox` |
| [ghostty/](ghostty/) | Ghostty, the primary terminal |
| [git/](git/) | Global git config and ignore |
| [jj/](jj/) | Jujutsu |
| [karabiner/](karabiner/) | Karabiner-Elements key remapping (macOS) |
| [latexmk/](latexmk/) | LaTeX build defaults |
| [macos/](macos/) | macOS defaults scripts and the sync LaunchAgent |
| [mpd/](mpd/) | Music Player Daemon |
| [newsboat/](newsboat/) | RSS reader |
| [npm/](npm/) | npm global prefix |
| [nvim/](nvim/) | Neovim |
| [palette/](palette/) | The `danse` palette and the templates rendered from it |
| [sketchybar/](sketchybar/) | SketchyBar, the status bar (macOS) |
| [ssh/](ssh/) | OpenSSH host snippets, `Include`d from `~/.ssh/config` |
| [starship/](starship/) | Prompt |
| [tmux/](tmux/) | tmux, the backup multiplexer |
| [wget/](wget/) | wget defaults |
| [yazi/](yazi/) | Terminal file manager |
| [zathura/](zathura/) | PDF viewer |
| [zellij/](zellij/) | Zellij, the primary multiplexer |
| [zsh/](zsh/) | zsh: `.zshrc`, aliases, functions |

`.zshenv`, the one file linked into `$HOME` directly, lives at the repo root.
