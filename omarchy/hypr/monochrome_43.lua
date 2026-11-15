-- Monochrome 43 rice (inspired by github.com/43PR/dotfiles look.lua, MIT).
--
-- Loaded from ~/.config/hypr/looknfeel.lua by a require() line that
-- omarchy/setup.sh appends once; this file is a symlink into the dotfiles.
-- Border colours come from the active Omarchy theme (monochrome-43: white
-- active, grey inactive), so they are not set here.
hl.config({
  general = {
    gaps_in = 4,
    gaps_out = { top = 5, right = 8, bottom = 8, left = 8 },
    border_size = 1,
    resize_on_border = true,
  },
  decoration = {
    rounding = 8,
    blur = { enabled = true, size = 5, passes = 2, vibrancy = 0.2 },
    shadow = { enabled = true, range = 4, render_power = 3 },
  },
})
hl.curve("riceOut", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.0} } })
hl.animation({ leaf = "windows",    enabled = true, speed = 5, bezier = "riceOut" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 5, bezier = "riceOut" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default", style = "slidefadevert" })
