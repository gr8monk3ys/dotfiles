-- The shared colour palette, read from .config/palette/danse.conf.
--
-- Every other themed tool in this checkout draws from that file; before this
-- module nvim was the exception, inheriting whatever navarasu/onedark.nvim
-- shipped. That meant the editor kept OneDark's original red while the
-- terminal, the prompt, the bar and the desktop background had all moved to
-- the Matisse vermilion — the one window where "everything matches" was false.
--
-- Returns a name -> "#rrggbb" table. An unreadable palette file returns an
-- empty table rather than raising: a colour scheme is not worth a failed
-- startup, and onedark.nvim's own defaults are a reasonable fallback.

local M = {}

local function config_home()
  return os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
end

function M.load()
  local colors = {}
  local path = config_home() .. "/palette/danse.conf"
  local fh = io.open(path, "r")
  if not fh then
    return colors
  end
  for line in fh:lines() do
    -- name|#hex|role, skipping comments and blanks
    local name, hex = line:match("^([%w%-]+)|(#%x%x%x%x%x%x)|")
    if name then
      colors[name] = hex
    end
  end
  fh:close()
  return colors
end

return M
