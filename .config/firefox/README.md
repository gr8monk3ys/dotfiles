# Firefox Configuration

[arkenfox](https://github.com/arkenfox/user.js)-based privacy hardening for
[Mozilla Firefox](https://www.mozilla.org/firefox/).

## Files

- `user.js` - the tracked preferences file (arkenfox v140, ~81KB)

## Stow links this somewhere Firefox never reads

`make link` stows this directory to `~/.config/firefox/`, the same as every
other tool here. Firefox does not read that path. `user.js` is a _per-profile_
file: Firefox reads it at startup from inside the profile directory, and
nowhere else.

So the stowed copy is the _source of truth_, not the _effective_ config. It
takes effect only once it is installed into a profile:

```bash
make firefox                 # into the profile Firefox actually opens
make firefox profiles=all    # into every profile in profiles.ini
bin/firefox-user-js status   # where it actually landed
```

See [bin/firefox-user-js](../../bin/firefox-user-js) for the full interface
(`--copy`, `--dry-run`, `--root`), and
[CONTEXT.md § Firefox profile state](../../CONTEXT.md) for the vocabulary its
`status` output uses.

## How installation works

- **Profiles come from `profiles.ini`**, never from globbing `Profiles/*/`. A
  glob picks up profiles Firefox has abandoned and cannot tell which one is
  live. An `[Install…]` section's `Default=` names the profile _this install_
  of Firefox opens and takes precedence over a `[Profile N]` section's
  `Default=1`, which is only the legacy fallback — on this machine the two
  disagree, and reading `Default=1` alone would harden a profile that has
  never been opened.
- **A symlink, not a copy.** Editing `user.js` here reaches Firefox at its
  next start with no reinstall step. Firefox follows a symlinked `user.js`
  (verified on 155.0.1 / macOS 15 by booting two throwaway profiles headless,
  one linked and one copied, and diffing the resulting `prefs.js`). Use
  `copy=1` for a sandboxed Firefox — Flatpak and Snap builds can only see
  paths their sandbox exports, so a link into this checkout resolves to
  nothing.
- **Nothing is clobbered.** A `user.js` this checkout did not write is moved
  to `user.js.bak.<timestamp>` first. Running twice changes nothing and takes
  no second backup.

## Firefox must be restarted

`user.js` is read once, at startup. `make firefox` warns when Firefox is
running rather than pretending the change is live.

## Verifying and undoing

Check a pref in `about:config`, or grep the profile's `prefs.js` after a
restart — Firefox copies every `user.js` pref that differs from the default
into it.

Removing `user.js` does _not_ revert the prefs it already wrote: they persist
in `prefs.js`. arkenfox ships
[prefsCleaner](https://github.com/arkenfox/user.js/wiki/5.1-Troubleshooting)
for that.

## Where the settings come from

`user.js` is an arkenfox release, so most of it should not be hand-edited —
arkenfox's own advice is to keep local changes in a `user-overrides.js` and
append them, so the base file stays diffable against the next release.

Sections worth reading before trusting it: 2800 (data erased on exit) and
anything tagged `[SETUP-WEB]`, which can break sites.

## Resources

- [arkenfox user.js](https://github.com/arkenfox/user.js) - the upstream project
- [arkenfox wiki](https://github.com/arkenfox/user.js/wiki) - what each section does
- [Firefox user.js documentation](https://kb.mozillazine.org/User.js_file)
- [about:config entries](https://kb.mozillazine.org/About:config_entries)
