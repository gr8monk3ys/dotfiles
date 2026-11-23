-- Field Notebook rice (lscaturchio.xyz at night).
--
-- Loaded from ~/.config/hypr/looknfeel.lua by a require() line that
-- omarchy/setup.sh appends once; this file is a symlink into the dotfiles.
-- Border colours come from the active Omarchy theme (field-notebook: the
-- forest-green pen), so they are not set here.

-- ── Look ──
-- Quiet and unhurried, like the site: generous gutters, hairline borders,
-- soft shadow, and the site's own easing curve, cubic-bezier(0.22, 1, 0.36, 1).
hl.config({
  general = {
    gaps_in = 6,
    gaps_out = { top = 8, right = 14, bottom = 14, left = 14 },
    border_size = 2,
    resize_on_border = true,
  },
  decoration = {
    rounding = 10,
    dim_inactive = true,
    dim_strength = 0.08,
    blur = { enabled = true, size = 6, passes = 3, vibrancy = 0.18, noise = 0.02 },
    shadow = { enabled = true, range = 18, render_power = 3, color = "rgba(0a0b0dcc)" },
  },
})
hl.curve("notebook", { type = "bezier", points = { {0.22, 1.0}, {0.36, 1.0} } })
hl.animation({ leaf = "windows",    enabled = true, speed = 4, bezier = "notebook", style = "popin 96%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "notebook", style = "popin 96%" })
hl.animation({ leaf = "border",     enabled = true, speed = 6, bezier = "notebook" })
hl.animation({ leaf = "fade",       enabled = true, speed = 4, bezier = "notebook" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "notebook", style = "slidefade 12%" })

-- ── Glass for every app, not just terminals ──
-- Everything gets the frosted look (opacity over the blur above), except
-- things where see-through would get in the way: games and game streaming,
-- video/image viewers, creative tools where colour accuracy matters, and
-- call/screen-share windows. Terminals keep Omarchy's own rule.
local no_glass = table.concat({
  -- games, launchers' game windows, emulators, streaming
  "steam_app_.*", "steam_proton", "gamescope", ".*\\.exe", "Minecraft.*", "org\\.vinegarhq\\.Sober",
  "[Rr]etro[Aa]rch", "com\\.libretro\\.RetroArch", "com\\.moonlight_stream\\.Moonlight", "[Gg]odot.*",
  -- video and images
  "mpv", "vlc", "io\\.github\\.celluloid_player\\.Celluloid", "org\\.gnome\\.Totem", "imv", "feh",
  "org\\.gnome\\.Loupe", ".*youtube\\.com.*",
  -- creative tools
  "[Gg]imp.*", "org\\.inkscape\\.Inkscape", "krita", "[Bb]lender", ".*[Rr]esolve.*",
  "com\\.obsproject\\.Studio", "org\\.kde\\.kdenlive", "darktable",
  -- calls and screen sharing
  "zoom", ".*zoom\\.us.*", "xdg-desktop-portal.*", "org\\.omarchy\\.screensaver",
  -- Field Notebook ghostty windows: ghostty already draws them see-through
  "org\\.fieldnotebook\\..*",
}, "|")
-- Browsers stay a touch more solid so pages stay readable.
o.window({ class = "negative:(" .. no_glass .. "|.*[Ff]irefox.*|zen|librewolf|.*[Cc]hrom(e|ium).*|[Bb]rave.*)", tag = "negative:terminal" },
  { opacity = "0.93 0.87", tag = "+transparent-window" })
o.window({ class = "(.*[Ff]irefox.*|zen|librewolf|.*[Cc]hrom(e|ium).*|[Bb]rave.*)" },
  { opacity = "0.97 0.93", tag = "+transparent-window" })
-- Anything fullscreen (a video, a game, a presentation) is fully solid.
o.window({ fullscreen = true }, { opacity = "1.0 override 1.0 override" })
-- Picture-in-picture players stay solid too.
o.window({ title = "Picture[- ]in[- ][Pp]icture" }, { opacity = "1.0 override 1.0 override" })

-- ── Login session ──
-- Workspace 1 uses the master layout so fn-session's panes land the same way
-- every login: Claude Desktop as the big left pane, then the dashboard, Spotify
-- and cava stacked on the right, top to bottom.
hl.workspace_rule({ workspace = "1", layout = "master" })
hl.config({ master = { mfact = 0.56, new_status = "slave", new_on_top = false } })

o.transparent_window("^org\\.fieldnotebook\\.(dash|music|gh)$", "0.94 0.9")

-- Give the shell and audio a moment, then open the panes. Re-run any time
-- with `fn-session`; it only opens what is missing.
o.exec_on_start("sleep 3 && " .. os.getenv("HOME") .. "/.local/bin/fn-session")

-- Night light: warm ink-on-paper evenings (schedule in hypr/hyprsunset.conf,
-- also linked from the dotfiles).
o.launch_on_start("hyprsunset")
