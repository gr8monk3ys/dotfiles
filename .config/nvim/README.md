# Neovim Configuration

Modern Neovim configuration using Lua and lazy.nvim plugin manager.

## Overview

This configuration provides a full-featured IDE-like experience with:
- **Plugin Management**: lazy.nvim for fast, lazy-loaded plugins
- **LSP Support**: Built-in language server protocol for multiple languages
- **Autocompletion**: nvim-cmp with multiple sources
- **Fuzzy Finding**: Telescope for files, grep, and more
- **Git Integration**: Gitsigns for inline blame and hunk navigation
- **Syntax Highlighting**: Tree-sitter for accurate highlighting
- **Auto-formatting**: Conform.nvim for format-on-save

## Structure

```
nvim/
├── init.lua                 # Entry point, loads all modules
├── lua/
│   ├── plugins.lua          # Plugin specifications for lazy.nvim
│   └── config/
│       ├── options.lua      # Vim options (tabs, search, UI)
│       ├── keymaps.lua      # Global key mappings
│       ├── autocmds.lua     # Autocommands
│       ├── filetypes.lua    # Filetype-specific settings
│       └── format.lua       # Auto-formatting configuration
└── lazy-lock.json           # Pinned plugin versions
```

## Key Bindings

### Leader Key
The leader key is `,` (comma).

### General Navigation

| Key | Mode | Action |
| --- | --- | --- |
| `<Space>` | Normal | Center screen on cursor |
| `<C-x>` | Normal | Next buffer |
| `<C-z>` | Normal | Previous buffer |
| `Y` | Normal | Yank to end of line |
| `n` | Normal | Next search result (centered) |
| `N` | Normal | Previous search result (centered) |
| `J` | Normal | Join lines without moving cursor |
| `jk` | Insert | Exit insert mode |

### File Explorer (nvim-tree)

| Key | Mode | Action |
| --- | --- | --- |
| `<C-a>` | Normal | Toggle file tree sidebar |
| `<C-r>` | Normal | Refresh file tree |

### Fuzzy Finding (Telescope)

| Key | Mode | Action |
| --- | --- | --- |
| `<C-p>` | Normal | Find files (including dotfiles) |
| `<C-g>` | Normal | Live grep across project |
| `<C-b>` | Normal | Search git branches |

### LSP (Language Server)

| Key | Mode | Action |
| --- | --- | --- |
| `gd` | Normal | Go to definition |
| `gD` | Normal | Go to declaration |
| `gr` | Normal | Go to references |
| `gi` | Normal | Go to implementation |
| `K` | Normal | Hover documentation |
| `<Leader>ca` | Normal | Code actions |
| `<Leader>rn` | Normal | Rename symbol |
| `<Leader>f` | Normal | Format file |

### Git (Gitsigns)

| Key | Mode | Action |
| --- | --- | --- |
| `]c` | Normal | Next hunk |
| `[c` | Normal | Previous hunk |
| `<Leader>hs` | Normal | Stage hunk |
| `<Leader>hu` | Normal | Undo stage hunk |
| `<Leader>hp` | Normal | Preview hunk |

### Terminal

| Key | Mode | Action |
| --- | --- | --- |
| `<C-t>` | Normal/Terminal | Toggle floating terminal |

### Quick Actions

| Key | Mode | Action |
| --- | --- | --- |
| `<Leader>w` | Normal | Save file |
| `<Leader>q` | Normal | Quit |

## Plugins

### Core

| Plugin | Purpose |
| --- | --- |
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager with lazy-loading |
| [onedark.nvim](https://github.com/navarasu/onedark.nvim) | Color scheme (OneDark) |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Keybinding hints and discovery |

### File Navigation

| Plugin | Purpose |
| --- | --- |
| [nvim-tree.lua](https://github.com/kyazdani42/nvim-tree.lua) | File explorer sidebar |
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) | Fuzzy finder for files, grep, branches |
| [dashboard-nvim](https://github.com/nvimdev/dashboard-nvim) | Start screen with quick actions |

### UI Enhancements

| Plugin | Purpose |
| --- | --- |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | Status line |
| [bufferline.nvim](https://github.com/akinsho/bufferline.nvim) | Buffer tabs |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | Indentation guides |
| [dressing.nvim](https://github.com/stevearc/dressing.nvim) | Better UI dialogs |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | File icons |

### LSP & Completion

| Plugin | Purpose |
| --- | --- |
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP configuration |
| [lspsaga.nvim](https://github.com/nvimdev/lspsaga.nvim) | LSP UI enhancements |
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Autocompletion engine |
| [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) | LSP completion source |
| [cmp-buffer](https://github.com/hrsh7th/cmp-buffer) | Buffer words completion |
| [cmp-path](https://github.com/hrsh7th/cmp-path) | File path completion |
| [cmp-git](https://github.com/petertriho/cmp-git) | Git completion in commit messages |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | Snippet engine |
| [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) | Snippet collection |

### Git

| Plugin | Purpose |
| --- | --- |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Git decorations, blame, hunks |

### Syntax & Formatting

| Plugin | Purpose |
| --- | --- |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax highlighting and parsing |
| [conform.nvim](https://github.com/stevearc/conform.nvim) | Format on save |

### Editing

| Plugin | Purpose |
| --- | --- |
| [nvim-surround](https://github.com/kylechui/nvim-surround) | Surround text objects |
| [vim-visual-multi](https://github.com/mg979/vim-visual-multi) | Multiple cursors (`<C-n>`) |
| [vim-endwise](https://github.com/tpope/vim-endwise) | Auto-add `end` in Ruby, Lua, etc. |
| [copilot.lua](https://github.com/zbirenbaum/copilot.lua) | GitHub Copilot integration |

## Language Server Support

The following language servers are auto-configured when available:

| Language | Server | Install Command |
| --- | --- | --- |
| Go | gopls | `go install golang.org/x/tools/gopls@latest` |
| Python | pyright | `npm install -g pyright` |
| Rust | rust-analyzer | `rustup component add rust-analyzer` |
| TypeScript/JavaScript | ts_ls | `npm install -g typescript-language-server typescript` |
| C/C++ | clangd | `brew install llvm` or system package |
| Nix | nixd | `nix-env -iA nixpkgs.nixd` |
| KCL | kcl-language-server | See KittyCAD docs |

## Auto-Formatting

Format-on-save is configured via Conform.nvim for these languages:

| Language | Formatter(s) |
| --- | --- |
| Go | goimports, gofumpt |
| JavaScript/TypeScript | biome |
| JSON | jq |
| Lua | stylua |
| Python | ruff |
| Nix | alejandra |
| Markdown | mdformat |
| Rust | rustfmt |
| TOML | taplo |
| YAML | yamlfmt |
| All files | trim_whitespace |

## Options

Key settings from `config/options.lua`:

- **Line numbers**: Enabled (not relative)
- **Indentation**: 4 spaces, smart indent
- **Search**: Case-insensitive unless uppercase used
- **Clipboard**: System clipboard integration
- **Mouse**: Enabled in all modes
- **Undo**: Persistent undo enabled
- **Splits**: Open right and below

## Installation

1. Ensure Neovim 0.9+ is installed
2. Clone/symlink this config to `~/.config/nvim`
3. Launch Neovim - lazy.nvim will auto-install plugins
4. Run `:checkhealth` to verify setup

### Installing Formatters

```bash
# Go
go install golang.org/x/tools/goimports@latest
go install mvdan.cc/gofumpt@latest

# JavaScript/TypeScript
npm install -g @biomejs/biome

# Lua
cargo install stylua

# Python
pip install ruff

# Nix
nix-env -iA nixpkgs.alejandra

# YAML
go install github.com/google/yamlfmt/cmd/yamlfmt@latest
```

## Troubleshooting

### Plugins not loading
Run `:Lazy` to open the plugin manager UI and check for errors.

### LSP not working
1. Ensure the language server is installed and in PATH
2. Run `:LspInfo` to check server status
3. Check `:LspLog` for error messages

### Formatting not working
1. Ensure the formatter is installed
2. Check `:ConformInfo` for status
3. Try manual format with `:lua require("conform").format()`

### Tree-sitter errors
Run `:TSUpdate` to update parsers, or `:TSInstall <language>` for specific languages.

## Resources

- [Neovim Documentation](https://neovim.io/doc/)
- [lazy.nvim](https://github.com/folke/lazy.nvim)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [Telescope](https://github.com/nvim-telescope/telescope.nvim)
