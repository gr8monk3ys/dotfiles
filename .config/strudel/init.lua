-- A Neovim profile just for live coding with Strudel.
-- Start it with:  strudel-live [file.str]   (or NVIM_APPNAME=strudel nvim file.str)
-- The main Neovim config (~/.config/nvim) is untouched; this one lives in
-- ~/.config/strudel, with its own plugins under ~/.local/share/strudel.

vim.g.mapleader = " "
vim.opt.number = true
vim.opt.termguicolors = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.signcolumn = "yes"
-- Pick up edits made outside Neovim (e.g. by Claude) when the window is focused
vim.opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, { command = "checktime" })

-- The colours are the active Rice's, from the main config's palette module
-- (ADR 0003), so this profile matches the desktop and the main editor.
-- Only that module is borrowed: its directory goes on package.path, not on
-- the runtimepath, so none of the main config's other modules load here.
local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
package.path = config_home .. "/nvim/lua/?.lua;" .. package.path

-- lazy.nvim, bootstrapped into this profile's own data dir
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Chromium where the OS ships it at this path (Arch); elsewhere strudel.nvim
-- uses the browser its puppeteer installs.
local chromium = "/usr/bin/chromium"

require("lazy").setup({
  {
    "gruvw/strudel.nvim",
    build = "npm ci",
    lazy = false, -- lazy-loading breaks .str file type support (upstream issue #5)
    config = function()
      local strudel = require("strudel")
      strudel.setup({
        browser_exec_path = vim.fn.executable(chromium) == 1 and chromium or nil,
        update_on_save = true, -- :w re-evaluates while playing
        ui = {
          -- The browser window shows only the visuals; the code lives in Neovim.
          hide_menu_panel = true,
          hide_code_editor = true,
          hide_top_bar = false,
          hide_error_display = false,
        },
      })
      local map = function(lhs, fn, desc) vim.keymap.set("n", lhs, fn, { desc = desc }) end
      map("<leader>sl", strudel.launch, "Strudel: launch")
      map("<leader>sq", strudel.quit, "Strudel: quit")
      map("<leader>st", strudel.toggle, "Strudel: play/stop")
      map("<leader>su", strudel.update, "Strudel: update (evaluate)")
      map("<leader>ss", strudel.stop, "Strudel: stop")
      map("<leader>sx", strudel.execute, "Strudel: use this buffer and update")
      -- strudel-live sets STRUDEL_AUTOLAUNCH: open the browser and start playing at once
      if vim.env.STRUDEL_AUTOLAUNCH == "1" then
        vim.api.nvim_create_autocmd("VimEnter", {
          once = true,
          callback = function() vim.defer_fn(strudel.launch, 300) end,
        })
      end
      -- Ctrl+Enter evaluates, like in the web editor
      vim.keymap.set({ "n", "i" }, "<C-CR>", function() strudel.update() end, { desc = "Strudel: update" })
    end,
  },
  { "navarasu/onedark.nvim", lazy = false, priority = 1000,
    config = function() require("palette").apply() end },
}, { rocks = { enabled = false } })
