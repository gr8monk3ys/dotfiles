# wget

Defaults for [GNU Wget](https://www.gnu.org/software/wget/manual/), the
non-interactive downloader. They matter most for recursive fetches.

## Why these choices

- **Fail fast:** `timeout = 60` and `tries = 3`, against wget's 15-minute read
  timeout and 20 retries, which make a dead host look like a hang.
  `retry_connrefused` retries a server that is still coming up.
- **Recursive fetches stay put:** `no_parent` never climbs above the starting
  directory; `timestamping` skips files that have not changed, so a re-run of
  a mirror only fetches what is new.
- **Saved files are usable:** `trust_server_names` names a file after the
  final redirect target rather than the redirecting URL, and
  `adjust_extension` adds `.html`/`.css` so a mirrored page opens locally.
- **`robots = off` and a browser `user_agent`:** this is for fetching things
  on purpose, not crawling. Pass `-e robots=on` when that matters.

## Gotchas

- wget has no XDG support. It finds `.wgetrc` here only because `.zshenv`
  exports `WGETRC`; from a shell that did not read `.zshenv` (cron, launchd)
  it uses `~/.wgetrc` or nothing. `make verify-config-live` checks it.
- `local_encoding` is left commented out: builds without IDN support refuse
  to start with it set.
