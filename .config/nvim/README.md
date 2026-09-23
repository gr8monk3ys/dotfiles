# nvim

Neovim, the primary editor. Plain Lua on
[lazy.nvim](https://github.com/folke/lazy.nvim), no distribution:
`init.lua` sets the leader (`,`), loads `lua/config/*` (options, keymaps,
autocmds, filetypes), bootstraps lazy.nvim, loads `lua/plugins.lua`, then
`lua/config/format.lua`. `lazy-lock.json` pins every plugin. `,` then a pause
shows the mappings (which-key).

## Why these choices

- **Language servers through the built-in client** (`vim.lsp.enable`, the
  Neovim 0.11 API; the old `require("lspconfig").x.setup()` is deprecated).
  A server is enabled only when its binary is on PATH, so a machine without
  a toolchain starts silently instead of erroring. No Mason: servers come
  from the manifests or the toolchain.
- **Format on save through conform.nvim**, one formatter chain per filetype
  in `format.lua`, falling back to the language server. Like the servers,
  a formatter that is not installed is skipped.
- **Colours:** onedark.nvim supplies the highlight-group structure, and every
  shared colour is overridden from `lua/palette.lua`, which `bin/palette`
  renders from danse. `test_palette.bats` boots Neovim and checks the result.
- **Copilot** (`copilot.lua`) suggests inline; `<Tab>` accepts.

## Gotchas

- First start clones lazy.nvim and every plugin; it needs git and network.
  Nothing works offline until that has happened once.
- `<Tab>` in insert mode is Copilot's when a suggestion is showing.
- Most servers and formatters (gopls, pyright, stylua, ruff, taplo, …) are
  installed by no manifest: `rust-analyzer` and `biome` are in the Brewfile,
  the rest come with their toolchains or by hand. `:checkhealth` and
  `:ConformInfo` say what is missing.
