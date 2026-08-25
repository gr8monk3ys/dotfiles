# MPD Configuration

[Music Player Daemon](https://www.musicpd.org/) config, linked to
`~/.config/mpd/mpd.conf` by `make link`.

## What is configured

- **Library:** `~/Music`, auto-updated when files change (`auto_update`).
- **Playlists:** `~/.config/mpd/playlists` (create the directory before
  first run; it is not in this repo).
- **Network:** binds to `127.0.0.1` only — no LAN exposure.
- **Startup:** resumes paused rather than playing (`restore_paused`).

## Outputs

Two `audio_output` blocks:

- **PipeWire** — the actual sound output. This assumes a PipeWire host
  (Linux); on macOS, `brew install mpd` needs a different output type
  (e.g. `osx`), so edit this block there.
- **FIFO at `/tmp/mpd.fifo`** (`44100:16:2`) — a raw PCM feed for
  terminal visualizers such as `cava`. Harmless if nothing reads it.

## Usage

```bash
mpd                      # start the daemon (reads this file)
mpc update && mpc play   # or use a client such as ncmpcpp / rmpc
```

Upstream reference: <https://mpd.readthedocs.io/en/latest/user.html>
