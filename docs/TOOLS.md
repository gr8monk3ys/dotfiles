# Tool Catalog

Why every tool in this repo exists. One entry per package across the
install manifests (`install/Brewfile`, `Caskfile`, `Caskfile.extra`, `npmfile`, `Rustfile`,
`pacmanfile`), grouped roughly by the manifest sections.

- Browse interactively with **`dotfiles-why`** (fzf picker with preview) or
  query directly: `dotfiles-why ripgrep`.
- `bin/validate-tool-docs` (run by `make verify`) keeps this file honest:
  every package must have an entry here, and every entry must still be
  installed by a manifest.
- Per-app configuration rationale lives next to each config in
  `.config/<app>/README.md`; this catalog covers the *what and why* of the
  tools themselves.

## Core System Dependencies

### ca-certificates
- **Why:** SSL/TLS certificates.
- **Installed via:** Brewfile

### dbus
- **Why:** Message bus system.
- **Installed via:** Brewfile

### gnupg
- **Why:** PGP encryption.
- **Installed via:** Brewfile

## Graphics & UI Libraries

### freetype
- **Why:** Font rendering.
- **Installed via:** Brewfile

### glib
- **Why:** Core library.
- **Installed via:** Brewfile

### harfbuzz
- **Why:** Text shaping.
- **Installed via:** Brewfile

### librsvg
- **Why:** SVG rendering.
- **Installed via:** Brewfile

### adwaita-icon-theme
- **Why:** Icon theme.
- **Installed via:** Brewfile

### at-spi2-core
- **Why:** Accessibility toolkit.
- **Installed via:** Brewfile

### gsettings-desktop-schemas
- **Why:** Desktop settings.
- **Installed via:** Brewfile

## Development Tools

### gcc
- **Why:** GNU Compiler Collection.
- **Installed via:** Brewfile

### bear
- **Why:** Generate compilation database.
- **Installed via:** Brewfile

### meson
- **Why:** Build system.
- **Installed via:** Brewfile

### tbb
- **Why:** Threading Building Blocks.
- **Installed via:** Brewfile

### xcodegen
- **Why:** Xcode project generator.
- **Installed via:** Brewfile

### gh
- **Why:** Official GitHub CLI for PRs, issues, and API access from the terminal; used by helper scripts.
- **Alternatives:** hub (unmaintained)
- **Installed via:** Brewfile

### lazygit
- **Why:** Fast TUI for staging, rebasing, and browsing history when a full jj/git CLI round-trip is overkill.
- **Alternatives:** gitui, tig
- **Installed via:** Brewfile

### lazydocker
- **Why:** Same UX as lazygit for containers; quick logs/exec without memorizing docker flags.
- **Alternatives:** ctop, docker desktop dashboard
- **Installed via:** Brewfile

### rust-analyzer
- **Why:** Rust language server.
- **Installed via:** Brewfile

### lua-language-server
- **Why:** Lua language server.
- **Installed via:** Brewfile

### python-lsp-server
- **Why:** Python language server.
- **Installed via:** Brewfile

### typescript
- **Why:** TypeScript compiler (tsc) available globally for tooling.
- **Installed via:** Brewfile

## Programming Languages & Runtimes

### node
- **Why:** Node.js runtime required by npm global tooling and editors.
- **Installed via:** Brewfile

### deno
- **Why:** Secure-by-default TS runtime for one-off scripts.
- **Alternatives:** node, bun
- **Installed via:** Brewfile

### bun
- **Why:** Fast all-in-one JS runtime/bundler/test runner for scripts and tooling.
- **Alternatives:** node (kept), deno (kept)
- **Installed via:** Brewfile

### python@3.12
- **Why:** Python 3.12.
- **Installed via:** Brewfile

### python@3.13
- **Why:** Python 3.13 (latest).
- **Installed via:** Brewfile

### poetry
- **Why:** Python dependency management.
- **Installed via:** Brewfile

### pipx
- **Why:** Install Python apps in isolation.
- **Installed via:** Brewfile

### uv
- **Why:** Fast Python package/venv manager; gradually replacing pip/poetry workflows.
- **Alternatives:** pip, poetry (kept for legacy projects)
- **Installed via:** Brewfile

### uvicorn
- **Why:** ASGI server.
- **Installed via:** Brewfile

### ghc
- **Why:** Glasgow Haskell Compiler.
- **Installed via:** Brewfile

### ghcup
- **Why:** Haskell toolchain installer.
- **Installed via:** Brewfile

### haskell-stack
- **Why:** Haskell build tool.
- **Installed via:** Brewfile

### ruby
- **Why:** Ruby programming language.
- **Installed via:** Brewfile

### r
- **Why:** R statistical language.
- **Installed via:** Brewfile

### zig
- **Why:** Zig programming language.
- **Installed via:** Brewfile

### luarocks
- **Why:** Lua package manager.
- **Installed via:** Brewfile

## Mobile Development

### cocoapods
- **Why:** iOS dependency manager.
- **Installed via:** Brewfile

### ios-deploy
- **Why:** Deploy iOS apps.
- **Installed via:** Brewfile

### libimobiledevice
- **Why:** iOS device communication.
- **Installed via:** Brewfile

## Containerization

### colima
- **Why:** Container runtime on macOS.
- **Installed via:** Brewfile

### docker
- **Why:** Container platform.
- **Installed via:** Brewfile

### docker-compose
- **Why:** Multi-container Docker apps.
- **Installed via:** Brewfile

## Text Editors & IDEs

### neovim
- **Why:** Primary editor. Lua config with lazy.nvim, LSP, treesitter, conform formatting.
- **Alternatives:** vim, helix, vscodium (GUI fallback)
- **Installed via:** Brewfile
- **Config:** [`.config/nvim/`](../.config/nvim/)

## Shell & Terminal Tools

### tmux
- **Why:** Backup multiplexer kept for SSH/remote boxes and muscle-memory compatibility; zellij is primary locally.
- **Alternatives:** zellij (primary), screen
- **Installed via:** Brewfile
- **Config:** [`.config/tmux/`](../.config/tmux/)

### zsh-syntax-highlighting
- **Why:** Zsh syntax highlighting (also loaded via zinit); styled with an OneDark `ZSH_HIGHLIGHT_STYLES` palette in `.zshrc`.
- **Installed via:** Brewfile

### starship
- **Why:** Shell prompt: fast single binary, one TOML config, actively developed (Powerlevel10k, the previous prompt, is in maintenance mode).
- **Alternatives:** powerlevel10k, oh-my-posh, pure
- **Installed via:** Brewfile
- **Config:** [`.config/starship/`](../.config/starship/)

### fzf
- **Why:** Fuzzy finder powering ctrl-r/ctrl-t, fzf-tab completion menus, and the f/fv helper functions; OneDark-themed via FZF_DEFAULT_OPTS.
- **Alternatives:** skim, peco
- **Installed via:** Brewfile, pacmanfile

### dockutil
- **Why:** Rebuilds the Dock from a script (`.config/macos/dock.sh`) instead of dragging icons on every new machine.
- **Installed via:** Brewfile

### duti
- **Why:** Applies the file-type → app associations in `install/duti` (`make duti`) so a fresh machine opens code, markdown and media in the intended apps without clicking through Finder.
- **Installed via:** Brewfile

## File & Text Search

### fd
- **Why:** Fast, gitignore-aware find with sane syntax; used directly (find is not shadowed).
- **Alternatives:** find, fselect
- **Installed via:** Brewfile, pacmanfile

### ripgrep
- **Why:** Fast recursive grep used by editor pickers and scripts; grep itself is not shadowed.
- **Alternatives:** grep, ag, ack
- **Installed via:** Brewfile

### jq
- **Why:** The standard JSON processor; scripted everywhere, so kept canonical (jnv adds interactivity).
- **Alternatives:** jaq, gojq, dasel
- **Installed via:** Brewfile

### tree
- **Why:** Directory tree viewer.
- **Installed via:** Brewfile

## Modern CLI Replacements (Rust-powered)

### eza
- **Why:** Modern ls with icons, git status, and tree view; aliased to ls and used in fzf-tab previews.
- **Alternatives:** lsd, plain ls
- **Installed via:** Brewfile
- **Config:** [`.config/eza/`](../.config/eza/)

### bat
- **Why:** cat with syntax highlighting and paging; OneDark theme, used as fzf/dotfiles-why previewer.
- **Alternatives:** cat, moar
- **Installed via:** Brewfile
- **Config:** [`.config/bat/`](../.config/bat/)

### zoxide
- **Why:** Frecency-based cd (aliased to cd) replacing the old z.lua setup.
- **Alternatives:** z.lua (removed), autojump
- **Installed via:** Brewfile, pacmanfile

### git-delta
- **Why:** Syntax-highlighting pager for git/jj diffs, OneDark-matched.
- **Alternatives:** difftastic (kept for structural diffs), diff-so-fancy
- **Installed via:** Brewfile, pacmanfile

### dust
- **Why:** Readable du with a usage graph; du itself is not shadowed.
- **Alternatives:** du, ncdu, gdu
- **Installed via:** Brewfile

### bottom
- **Why:** Graphical process/system monitor (btm); top is not shadowed.
- **Alternatives:** htop, btop, glances
- **Installed via:** Brewfile

### procs
- **Why:** Readable, searchable ps; ps itself is not shadowed.
- **Alternatives:** ps
- **Installed via:** Brewfile

### sd
- **Why:** Intuitive find-and-replace; sed stays unshadowed because scripts depend on it.
- **Alternatives:** sed
- **Installed via:** Brewfile

### hyperfine
- **Why:** Statistical CLI benchmarking; used to measure shell startup alongside dotfiles-bench-shell.
- **Alternatives:** time, bench
- **Installed via:** Brewfile

### tokei
- **Why:** Code statistics tool.
- **Installed via:** Brewfile

### watchexec
- **Why:** File watcher for development.
- **Installed via:** Brewfile

## Next-Gen Modern Tools (2024+)

### yazi
- **Why:** Primary terminal file manager: async, image previews, OneDark theme.
- **Alternatives:** ranger, lf, nnn, broot (kept for tree-jumps)
- **Installed via:** Brewfile
- **Config:** [`.config/yazi/`](../.config/yazi/)

### jj
- **Why:** Jujutsu: Git-compatible VCS with first-class undo, anonymous branches, and automatic rebases; primary local workflow, git remains the wire format.
- **Alternatives:** git alone
- **Installed via:** Brewfile
- **Config:** [`.config/jj/`](../.config/jj/)

### zellij
- **Why:** Primary terminal multiplexer: sane defaults, discoverable keybindings, floating panes, OneDark theme.
- **Alternatives:** tmux (kept as backup)
- **Installed via:** Brewfile
- **Config:** [`.config/zellij/`](../.config/zellij/)

### navi
- **Why:** Interactive cheatsheets at the prompt (ctrl-g) for rarely-used commands.
- **Alternatives:** tldr/tealdeer (kept)
- **Installed via:** Brewfile

### broot
- **Why:** Tree navigation with fuzzy search for jumping deep into big repos.
- **Alternatives:** yazi (primary file manager)
- **Installed via:** Brewfile

### tealdeer
- **Why:** Fast Rust tldr client for example-first help; man stays canonical.
- **Alternatives:** tldr (node)
- **Installed via:** Brewfile

### gping
- **Why:** Graphical ping with history.
- **Installed via:** Brewfile

### ouch
- **Why:** Universal archive compress/decompress.
- **Installed via:** Brewfile

## Modern CLI Tools (2025+ additions)

### jnv
- **Why:** Interactive JSON navigator with jq.
- **Installed via:** Brewfile

### glow
- **Why:** Renders markdown in the terminal; used for README/doc reading.
- **Alternatives:** bat (plain highlight)
- **Installed via:** Brewfile

### csvlens
- **Why:** Interactive CSV viewer.
- **Installed via:** Brewfile

### xsv
- **Why:** Fast CSV toolkit (Rust).
- **Installed via:** Brewfile

### duf
- **Why:** Readable df with colored table output; df itself is not shadowed.
- **Alternatives:** df
- **Installed via:** Brewfile

### doggo
- **Why:** Modern DNS client with readable output; dig is not shadowed since scripts parse it.
- **Alternatives:** dig, dog
- **Installed via:** Brewfile

### bandwhich
- **Why:** Network utilization by process.
- **Installed via:** Brewfile

### viddy
- **Why:** Modern watch command with diffs.
- **Installed via:** Brewfile

### trippy
- **Why:** mtr-style network diagnostic TUI (aliased via sudo trip).
- **Alternatives:** mtr, traceroute
- **Installed via:** Brewfile

### just
- **Why:** Ergonomic command runner for project-local recipes; make stays for this repo itself.
- **Alternatives:** make, task
- **Installed via:** Brewfile

### difftastic
- **Why:** Structural, syntax-aware diffs for review; delta covers day-to-day paging.
- **Alternatives:** git-delta (pager)
- **Installed via:** Brewfile

### grex
- **Why:** Generate regex from examples.
- **Installed via:** Brewfile

### topgrade
- **Why:** One command to update brew/npm/cargo/etc.; complements dotfiles-update.
- **Alternatives:** dotfiles-update (repo script)
- **Installed via:** Brewfile

### gum
- **Why:** Styled headers, prompts, and spinners for shell scripts; `bin/lib/ui.sh` upgrades script output with it when present (plain ANSI fallback keeps tests/CI stable).
- **Alternatives:** hand-rolled ANSI escapes (the fallback)
- **Installed via:** Brewfile

### fastfetch
- **Why:** Fast, maintained neofetch successor for a system-info splash; run on demand via the `ff` alias rather than on shell start to protect startup time.
- **Alternatives:** neofetch (unmaintained), macchina
- **Installed via:** Brewfile
- **Config:** [`.config/fastfetch/`](../.config/fastfetch/)

## Shell History & Environment

### atuin
- **Why:** SQLite-backed shell history with fuzzy search and optional sync; replaces plain ctrl-r. OneDark-themed via a custom theme file.
- **Alternatives:** mcfly, plain HISTFILE (still kept as fallback)
- **Installed via:** Brewfile
- **Config:** [`.config/atuin/`](../.config/atuin/)

### direnv
- **Why:** Per-directory env vars; loads per-project dev environments from `.envrc`.
- **Alternatives:** shadowenv
- **Installed via:** Brewfile

## Version Management

### mise
- **Why:** Single version manager for node/python/etc.; replaces asdf/pyenv/nvm sprawl (n is kept only for the Makefile bootstrap).
- **Alternatives:** asdf, nvm+pyenv+rbenv
- **Installed via:** Brewfile

## File Transfer & Download

### aria2
- **Why:** Download utility.
- **Installed via:** Brewfile

### transmission-cli
- **Why:** Torrent client CLI.
- **Installed via:** Brewfile

### yt-dlp
- **Why:** YouTube downloader.
- **Installed via:** Brewfile

## Media Processing

### ffmpeg
- **Why:** Video/audio processing.
- **Installed via:** Brewfile

### imagemagick
- **Why:** Image processing.
- **Installed via:** Brewfile

## Document Tools

### mupdf
- **Why:** Lightweight PDF viewer.
- **Installed via:** Brewfile

### zathura
- **Why:** Vim-keybinding document viewer for PDFs.
- **Alternatives:** mupdf (kept as backend/light viewer), Preview.app
- **Installed via:** Brewfile
- **Config:** [`.config/zathura/`](../.config/zathura/)

### zathura-pdf-mupdf
- **Why:** MuPDF backend for Zathura.
- **Installed via:** Brewfile

### pandoc
- **Why:** Universal document converter.
- **Installed via:** Brewfile

### sphinx-doc
- **Why:** Documentation generator.
- **Installed via:** Brewfile

### typst
- **Why:** Modern typesetting system.
- **Installed via:** Brewfile

### typstyle
- **Why:** Typst formatter.
- **Installed via:** Brewfile

### manim
- **Why:** Math animation engine.
- **Installed via:** Brewfile

## Data Science & Jupyter

### jupyterlab
- **Why:** Interactive notebooks.
- **Installed via:** Brewfile

### python-matplotlib
- **Why:** Plotting library.
- **Installed via:** Brewfile

## Communication & Email

### neomutt
- **Why:** Terminal email client (paired with isync/msmtp).
- **Alternatives:** himalaya (kept, modern alternative)
- **Installed via:** Brewfile

### msmtp
- **Why:** SMTP client.
- **Installed via:** Brewfile

### isync
- **Why:** Mailbox synchronization.
- **Installed via:** Brewfile

### himalaya
- **Why:** Modern terminal email client.
- **Installed via:** Brewfile

## Security & Privacy

### pass
- **Why:** GPG-backed CLI password store for scripts and git-credential use.
- **Alternatives:** keepassxc (GUI vault)
- **Installed via:** Brewfile

## Productivity & Utilities

### timetrace
- **Why:** Time tracking.
- **Installed via:** Brewfile

### timewarrior
- **Why:** Time tracking.
- **Installed via:** Brewfile

### spotify_player
- **Why:** Spotify TUI player.
- **Installed via:** Brewfile

### sl
- **Why:** Steam Locomotive (fun).
- **Installed via:** Brewfile

### telnet
- **Why:** Telnet client.
- **Installed via:** Brewfile

### xh
- **Why:** Friendly HTTP client for API poking.
- **Alternatives:** curl (kept canonical), httpie
- **Installed via:** Brewfile

### typos-cli
- **Why:** Source code spell checker.
- **Installed via:** Brewfile

### biome
- **Why:** Single fast formatter/linter for JS/TS; wired into nvim conform.
- **Alternatives:** prettier+eslint
- **Installed via:** Brewfile

### cabin
- **Why:** C++ package manager / build system (formerly poac). _Rationale unclear — candidate for removal if no active C++ projects use it._
- **Installed via:** Brewfile

## Databases

### mysql@8.4
- **Why:** MySQL 8.4.
- **Installed via:** Brewfile

## Status Bar

### sketchybar
- **Why:** Customizable status bar showing AeroSpace workspaces; themed with the repo-wide OneDark palette.
- **Alternatives:** stock menu bar, übersicht
- **Installed via:** Brewfile
- **Config:** [`.config/sketchybar/`](../.config/sketchybar/)

## AI & Machine Learning

### ollama
- **Why:** Local LLM runner for offline/private inference.
- **Alternatives:** llama.cpp, lm-studio
- **Installed via:** Brewfile

## Window Management & System Utilities (GUI)

### aerospace
- **Why:** i3-style tiling window manager for macOS without disabling SIP; integrates with SketchyBar workspaces.
- **Alternatives:** yabai (needs SIP changes), Rectangle
- **Installed via:** Caskfile
- **Config:** [`.config/aerospace/`](../.config/aerospace/)

### karabiner-elements
- **Why:** Low-level keyboard remapping (hyper key, hjkl arrows).
- **Alternatives:** BetterTouchTool
- **Installed via:** Caskfile
- **Config:** [`.config/karabiner/`](../.config/karabiner/)

### raycast
- **Why:** Spotlight replacement: launcher, clipboard history, window commands, extensions.
- **Alternatives:** Alfred, Spotlight
- **Installed via:** Caskfile

### keycastr
- **Why:** Keystroke visualizer for presentations.
- **Installed via:** Caskfile.extra

## Terminals & Terminal Tools (GUI)

### ghostty
- **Why:** Primary terminal: GPU-accelerated, Zig-based, native macOS feel; adaptive Horizon Bright/Broadcast theme with frosted glass.
- **Alternatives:** kitty, wezterm, alacritty
- **Installed via:** Caskfile
- **Config:** [`.config/ghostty/`](../.config/ghostty/)

## Web Browsers (GUI)

### firefox
- **Why:** Primary browser, hardened with an arkenfox-based user.js.
- **Alternatives:** brave-browser, zen (both installed as alternates)
- **Installed via:** Caskfile
- **Config:** [`.config/firefox/`](../.config/firefox/)

### brave-browser
- **Why:** Privacy-focused Chromium browser.
- **Installed via:** Caskfile

### zen
- **Why:** Zen browser (privacy-focused).
- **Installed via:** Caskfile

### tor-browser
- **Why:** Anonymous web browser.
- **Installed via:** Caskfile.extra

## Development Tools & IDEs (GUI)

### vscodium
- **Why:** Telemetry-free VS Code build as the GUI editor fallback; extensions pinned in install/Codefile.
- **Alternatives:** vscode
- **Installed via:** Caskfile

### docker-desktop
- **Why:** Docker Desktop — the container runtime plus Docker CLI; used for local services and the fleet's containerised projects.
- **Installed via:** Caskfile

### db-browser-for-sqlite
- **Why:** SQLite database browser.
- **Installed via:** Caskfile.extra

## Design & Creative Tools (GUI)

### figma
- **Why:** Interface design and prototyping.
- **Installed via:** Caskfile.extra

### godot
- **Why:** Open-source game engine.
- **Installed via:** Caskfile.extra

## Media Creation & Editing (GUI)

### audacity
- **Why:** Audio editing software.
- **Installed via:** Caskfile.extra

### obs
- **Why:** Open Broadcaster Software (streaming/recording).
- **Installed via:** Caskfile.extra

### rode-central
- **Why:** Rode microphone control software.
- **Installed via:** Caskfile.extra

## Media Players & Music (GUI)

### tidal
- **Why:** Music streaming service.
- **Installed via:** Caskfile

## Note-Taking & Knowledge Management (GUI)

### obsidian
- **Why:** Markdown knowledge base on plain files — survives app churn.
- **Alternatives:** logseq, notion
- **Installed via:** Caskfile

## Productivity & Organization (GUI)

### spacedrive
- **Why:** Cross-platform file manager.
- **Installed via:** Caskfile.extra

## Security & Privacy (GUI)

### keepassxc
- **Why:** Offline, open-source password vault; pass covers CLI secrets.
- **Alternatives:** 1password, bitwarden
- **Installed via:** Caskfile

### proton-drive
- **Why:** End-to-end encrypted cloud storage.
- **Installed via:** Caskfile

### monero-wallet
- **Why:** Cryptocurrency wallet.
- **Installed via:** Caskfile.extra

## Communication (GUI)

### dorion
- **Why:** Discord client alternative.
- **Installed via:** Caskfile.extra

## System Utilities & Tools (GUI)

### balenaetcher
- **Why:** USB/SD card imaging tool.
- **Installed via:** Caskfile.extra

### cameracontroller
- **Why:** Webcam control software.
- **Installed via:** Caskfile.extra

## Gaming & Entertainment (GUI)

### lunar-client
- **Why:** Minecraft client with mods.
- **Installed via:** Caskfile.extra

### love
- **Why:** LÖVE 2D game framework.
- **Installed via:** Caskfile.extra

## npm globals

### npm
- **Why:** Node's package manager itself, kept current globally (ships with node but updated independently).
- **Installed via:** npmfile

### pnpm
- **Why:** Disk-efficient npm alternative (content-addressed store); preferred for JS monorepos.
- **Installed via:** npmfile

### yarn
- **Why:** Legacy JS package manager kept for projects that pin it.
- **Installed via:** npmfile

### @antfu/ni
- **Why:** `ni`/`nr` shims that auto-detect npm/pnpm/yarn/bun per project — one muscle memory for all of them.
- **Installed via:** npmfile

### npm-check-updates
- **Why:** Bumps package.json ranges to latest (`ncu`).
- **Installed via:** npmfile

### tsx
- **Why:** Run TypeScript files directly without a build step.
- **Installed via:** npmfile

### prettier
- **Why:** Default formatter for web-adjacent files where biome isn't configured.
- **Installed via:** npmfile

### release-it
- **Why:** Automates version bump + changelog + tag + publish for npm packages.
- **Installed via:** npmfile

### remark-cli
- **Why:** Markdown linting/processing pipeline.
- **Installed via:** npmfile

### remark-preset-webpro
- **Why:** Shared remark ruleset for the markdown pipeline.
- **Installed via:** npmfile

### fkill-cli
- **Why:** Fuzzy, cross-platform process killer (`fkill`).
- **Installed via:** npmfile

### get-port-cli
- **Why:** Prints a free TCP port; handy in scripts.
- **Installed via:** npmfile

### underscore-cli
- **Why:** JS-flavored JSON manipulation when jq syntax is overkill.
- **Installed via:** npmfile

### fast-cli
- **Why:** Quick bandwidth test from the terminal (fast.com).
- **Installed via:** npmfile

### gtop
- **Why:** Graphical system dashboard in the terminal (node-based; bottom is the daily driver).
- **Installed via:** npmfile

### local-web-server
- **Why:** Instant static file server with SPA/HTTPS options (`ws`).
- **Installed via:** npmfile

### svgo
- **Why:** SVG optimizer for asset pipelines.
- **Installed via:** npmfile

## Cargo

### cargo-cache
- **Why:** Inspect and prune the global cargo cache.
- **Installed via:** Rustfile

### cargo-update
- **Why:** `cargo install-update -a` — updates cargo-installed binaries; used by dotfiles-update.
- **Installed via:** Rustfile

### jless
- **Why:** Pager for huge JSON files (jq/jnv handle querying; jless handles reading).
- **Installed via:** Rustfile

## Arch (pacman)

### base-devel
- **Why:** Arch meta-package: compilers and build tooling required for AUR builds.
- **Installed via:** pacmanfile

### bash-completion
- **Why:** Completions for bash sessions on Arch boxes.
- **Installed via:** pacmanfile

### nano
- **Why:** Tiny fallback editor for root/rescue shells where nvim isn't set up.
- **Installed via:** pacmanfile

## Fonts (GUI)

Nerd-Font patched monospace fonts (`font-*` casks). Day-one, from the
Caskfile: JetBrains Mono (primary, used by Ghostty/SketchyBar) and Fira Code
(ligatures). Optional, from Caskfile.extra: 0xProto, IBM 3270, Agave, Hack,
plus Font Awesome icons. The validator treats `font-*` casks as covered by
this section.

## Not installed by manifests

Tools that have configs or are assumed present but are not installed by the
package manifests. Documented here so the gap is visible.

### git
- **Why:** Core VCS; jj wraps it locally. Comes from Xcode CLT on macOS and `pacmanfile` on Arch; delta/difftastic provide diff UX.
- **Installed via:** system (macOS CLT), pacmanfile
- **Config:** [`.config/git/`](../.config/git/)

### zsh
- **Why:** Login shell (macOS default); config split across `.zshenv` / `.config/zsh/`.
- **Installed via:** system
- **Config:** [`.config/zsh/`](../.config/zsh/)

### zinit
- **Why:** Zsh plugin manager (turbo-capable, lighter than oh-my-zsh); self-bootstraps from `.zshrc` on first run.
- **Alternatives:** oh-my-zsh (removed), antidote, zsh4humans
- **Installed via:** self-bootstrap in `.zshrc`

### stow
- **Why:** GNU Stow creates the symlink farm for all configs; installed on demand by `make stow-macos` / `stow-arch`.
- **Installed via:** Makefile

### bats
- **Why:** Test runner for the repo's test suite; installed by `make test-setup`.
- **Installed via:** Makefile

### claude
- **Why:** Claude Code CLI for agentic coding; installed via its own installer, pinned to `~/.local/bin/claude` by `.zshrc`.
- **Installed via:** vendor installer
- **Config:** [`.config/claude/`](../.config/claude/)

### newsboat
- **Why:** Terminal RSS reader. _Config exists but no manifest installs it — add to Brewfile or drop the config._
- **Installed via:** none (gap)
- **Config:** [`.config/newsboat/`](../.config/newsboat/)

### mpd
- **Why:** Music Player Daemon. _Config exists but no manifest installs it — add to Brewfile or drop the config._
- **Installed via:** none (gap)
- **Config:** [`.config/mpd/`](../.config/mpd/)

### latexmk
- **Why:** LaTeX build orchestration; ships with TeX distributions (not separately installed).
- **Installed via:** TeX distribution
- **Config:** [`.config/latexmk/`](../.config/latexmk/)
