# aerospace

[AeroSpace](https://nikitabobko.github.io/AeroSpace/guide), the tiling window
manager (macOS). It also starts the rest of the desktop chrome:
`after-startup-command` launches SketchyBar and JankyBorders, so the bar and
borders exist exactly when AeroSpace does.

## Why these choices

- **Workspaces by `Alt`:** `Alt+1…9` to go, `Alt+Shift+1…9` to send a
  window; letter workspaces `P` (PDFs), `K` (KeePassXC), `F` (Finder).
- **Apps land on fixed workspaces** (`on-window-detected`): Ghostty on 1,
  Firefox on 2, Spotify on 3, zathura on `P`, and so on.
- **Gaps of 8**, and 45 at the top to clear SketchyBar: without gaps a tiled
  screen reads as maximised windows.
- **`persistent-workspaces` lists 1–9, F, K and P.** Under config-version 2
  an undeclared workspace vanishes when its last window closes, and
  SketchyBar draws one indicator per workspace, so the list is what keeps
  the bar stable. `test_palette.bats` checks every workspace SketchyBar
  draws is declared.

## Gotchas

- zathura has no bundle id, so it is matched by a window title containing
  `Users` (the path of a document under `/Users`). A PDF opened from
  elsewhere stays where it opened.
- Messages, iMovie, Figma and Mail are routed to `G`, `M`, `D` and `Z`,
  which have no key bound and are not persistent; reach them with
  `aerospace workspace <name>`.
- No key moves focus or windows within a workspace: the `alt-m/n/e/i` set
  is commented out. Focus follows the mouse click.
- Spotify, routed to 3, is installed by no manifest.
- Needs Accessibility permission on first start.
