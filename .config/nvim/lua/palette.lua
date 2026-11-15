-- The active Rice's colours, for the editor (ADR 0003).
--
-- Every themed tool in this checkout follows the Rice (palette/rice.sh): the
-- desktop, the prompt, the CLI tools, and here the editor, so Neovim inside
-- a Field Notebook Ghostty is night paper and the forest-green pen, not
-- OneDark. The Rice module is asked directly (one `sh` at start-up) rather
-- than trusting an environment variable, so an editor started from anywhere
-- agrees with the desktop.
--
-- onedark.nvim stays the engine: it already themes treesitter, LSP,
-- telescope, gitsigns and the rest from one small table of colours, and
-- danse *is* onedark's "dark" style with two accents retuned. For any other
-- rice every one of those colours comes from the rice's palette, through its
-- role map (palette/<rice>.roles, the same one bin/rice-themes uses), with
-- the in-between surfaces blended from two palette colours.
--
-- Also loaded by the Strudel profile (~/.config/strudel/init.lua), which
-- puts this config on its runtimepath.
--
-- An unreadable palette returns an empty table rather than raising: a colour
-- scheme is not worth a failed start-up, and onedark's defaults are a
-- reasonable fallback.

local M = {}

local function config_home()
  return os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
end

local function palette_dir()
  return config_home() .. "/palette"
end

-- Lines of `a|b|...` in a file, as a -> b. Comments and blanks skipped.
local function read_pairs(path)
  local pairs_ = {}
  local fh = io.open(path, "r")
  if not fh then
    return pairs_
  end
  for line in fh:lines() do
    local a, b = line:match("^([%w%-]+)|([^|]+)")
    if a then
      pairs_[a] = b
    end
  end
  fh:close()
  return pairs_
end

-- The active rice, as the Rice module answers it; "danse" if it cannot.
function M.rice()
  local rice_sh = palette_dir() .. "/rice.sh"
  if vim.fn.filereadable(rice_sh) == 0 then
    return "danse"
  end
  local out = vim.fn.system({ "sh", "-c", '. "$1" && rice_select && printf %s "$RICE"', "sh", rice_sh })
  if vim.v.shell_error ~= 0 or not out:match("^[%w%-]+$") then
    return "danse"
  end
  return out
end

-- name -> "#rrggbb" for a rice's palette (default: the active rice).
function M.load(rice)
  local colors = {}
  for name, hex in pairs(read_pairs(palette_dir() .. "/" .. (rice or M.rice()) .. ".conf")) do
    if hex:match("^#%x%x%x%x%x%x$") then
      colors[name] = hex
    end
  end
  return colors
end

-- role -> "#rrggbb": each danse-named role filled by the rice's own colour.
function M.roles(rice)
  rice = rice or M.rice()
  local colors = M.load(rice)
  local roles = {}
  for role, name in pairs(read_pairs(palette_dir() .. "/" .. rice .. ".roles")) do
    roles[role] = colors[name]
  end
  return roles
end

-- a blended toward b by t (0..1), for surfaces between two palette colours.
local function mix(a, b, t)
  local function ch(hex, i)
    return tonumber(hex:sub(i, i + 1), 16)
  end
  local out = "#"
  for _, i in ipairs({ 2, 4, 6 }) do
    out = out .. string.format("%02x", math.floor(ch(a, i) + (ch(b, i) - ch(a, i)) * t + 0.5))
  end
  return out
end

-- The onedark.nvim setup table for a rice (default: the active one).
function M.onedark(rice)
  rice = rice or M.rice()
  local r = M.roles(rice)
  if rice == "danse" or not (r.bg and r.fg and r.surface and r.comment) then
    -- onedark's "dark" style already is danse's ground and accents, except
    -- the red and orange, retuned to Matisse vermilion and terracotta.
    return { style = "dark", colors = { red = r.vermilion, orange = r.terracotta } }
  end
  return {
    style = "dark",
    colors = {
      black = r["bg-dark"],
      bg0 = r.bg,
      bg1 = mix(r.bg, r.surface, 0.4),
      bg2 = mix(r.bg, r.surface, 0.7),
      bg3 = r.surface,
      bg_d = r["bg-dark"],
      bg_blue = r.blue,
      bg_yellow = r.yellow,
      fg = r.fg,
      purple = r.magenta,
      green = r.green,
      orange = r.terracotta,
      blue = r.blue,
      yellow = r.yellow,
      cyan = r.cyan,
      red = r.vermilion,
      grey = r.comment,
      light_grey = mix(r.comment, r.fg, 0.4),
      dark_cyan = mix(r.cyan, r.bg, 0.4),
      dark_red = mix(r.vermilion, r.bg, 0.4),
      dark_yellow = mix(r.yellow, r.bg, 0.4),
      dark_purple = mix(r.magenta, r.bg, 0.4),
      diff_add = r["diff-add"],
      diff_delete = r["diff-del"],
      diff_change = mix(r.bg, r.blue, 0.2),
      diff_text = mix(r.bg, r.blue, 0.4),
    },
    -- Selected text in the rice's selection fill (Field Notebook: the pen at
    -- 22% over night, as on the site and in Ghostty).
    highlights = { Visual = { bg = r.ultramarine } },
  }
end

-- Set onedark up for the active rice and load it.
function M.apply()
  local onedark = require("onedark")
  onedark.setup(M.onedark())
  onedark.load()
end

return M
