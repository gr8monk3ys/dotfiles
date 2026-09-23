-- The shared colour palette, as a name -> "#rrggbb" table.
--
-- Rendered by bin/palette from .config/palette/templates/.config/nvim/lua/palette.lua.
-- Edit the template, then run `palette render`; `palette check` fails on hand edits.
--
-- A rendered table rather than a parser: before this module nvim was the one
-- window where "everything matches" was false, inheriting whatever
-- navarasu/onedark.nvim shipped, and a runtime read of danse.conf would be one
-- more parser of it that could drift from bin/palette's.

return {
  bg = "#282c34",
  bg_dark = "#21252b",
  surface = "#3e4451",
  fg = "#abb2bf",
  comment = "#5c6370",
  blue = "#61afef",
  cyan = "#56b6c2",
  green = "#98c379",
  yellow = "#e5c07b",
  magenta = "#c678dd",
  vermilion = "#e06a51",
  terracotta = "#d98c5c",
  ultramarine = "#2b4468",
  viridian = "#476a62",
  diff_add = "#2d3b2d",
  diff_delete = "#3b2d2d",
}
