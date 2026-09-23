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
  bg = "{{bg}}",
  bg_dark = "{{bg-dark}}",
  surface = "{{surface}}",
  fg = "{{fg}}",
  comment = "{{comment}}",
  blue = "{{blue}}",
  cyan = "{{cyan}}",
  green = "{{green}}",
  yellow = "{{yellow}}",
  magenta = "{{magenta}}",
  vermilion = "{{vermilion}}",
  terracotta = "{{terracotta}}",
  ultramarine = "{{ultramarine}}",
  viridian = "{{viridian}}",
  diff_add = "{{diff-add}}",
  diff_delete = "{{diff-delete}}",
}
