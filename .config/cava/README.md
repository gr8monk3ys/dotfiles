# cava

Console audio visualiser.

## Theme

Colours come from [`.config/palette/danse.conf`](../palette/danse.conf). The
eight-stop gradient is the painting's own progression: the ultramarine sky at
the quiet end, up through the viridian ground, to the vermilion figures at the
peaks.

`bars = 0` lets cava fill whatever width the pane has, which is the right
answer under a tiling window manager where that width is not cava's to choose.

## It hears the microphone, not your music

This is the thing to know before wondering why it looks wrong. On macOS cava
captures an **input** device, and macOS has no built-in way to treat system
output as an input. Out of the box this visualises the room.

To visualise what is actually playing, route output through a loopback:

```bash
brew install blackhole-2ch
```

Then, in **Audio MIDI Setup**:

1. Create a Multi-Output Device containing both your real output and BlackHole
   2ch — so you still hear the audio.
2. Set that Multi-Output Device as the system output.
3. Set `source = BlackHole 2ch` in this config (replacing `auto`).

That is a system audio change with real consequences if you get it wrong —
notably, volume keys stop working on a Multi-Output Device — so it is left for
you to do deliberately rather than applied by `make`.

## Linked unfolded

cava writes default `shaders/` and `themes/` into its config directory on
every start when they are missing. With the directory folded into the
checkout, those files landed in the repo and were once committed, although this
config never loads them (`method = ncurses`). `.config/cava/` is a tool-owned
path in `bin/link`, so `make link` makes `~/.config/cava` a real directory
holding a link per tracked file; cava's own files stay outside the checkout.

## Gotchas

- Needs Microphone permission for whatever terminal it runs in; macOS prompts
  on first run and cava draws a flat line until it is granted.
- `framerate = 60` is cheap here but it is a busy-loop on battery. Drop it to
  30 if that matters.
