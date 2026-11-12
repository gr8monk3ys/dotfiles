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

## Gotchas

- Needs Microphone permission for whatever terminal it runs in; macOS prompts
  on first run and cava draws a flat line until it is granted.
- `framerate = 60` is cheap here but it is a busy-loop on battery. Drop it to
  30 if that matters.

## Monochrome 43 (opt-in)

[`monochrome-43`](monochrome-43) is a grey-to-white gradient from
[`.config/palette/monochrome-43.conf`](../palette/monochrome-43.conf) with
[43PR/dotfiles](https://github.com/43PR/dotfiles) (MIT)'s fixed sensitivity. It leaves `[input] method` unset so each
platform's build picks its default backend (PipeWire on Arch/Omarchy).
`config` stays the default:

```bash
cava -p ~/.config/cava/monochrome-43
```

`shaders/` and `themes/` are cava's own upstream examples
([karlstav/cava](https://github.com/karlstav/cava), MIT); 43PR ships the same
files.
