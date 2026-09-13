# npm Configuration

npm reads this file because `.zshenv` points `NPM_CONFIG_USERCONFIG` at it;
npm has no XDG support of its own.

## Why this exists

npm's default global prefix is the directory node is installed in. On a
Homebrew mac that is `/opt/homebrew/Cellar/node/<version>`, which Homebrew
deletes on every node upgrade — taking every `npm install -g` package with
it, including everything in `install/npmfile`.

Setting `prefix=${HOME}/.local` puts global packages somewhere stable.
Binaries land in `~/.local/bin`, which `.zshenv` already adds to `PATH`, so
nothing else needs to change.

## Verifying

```bash
npm config get prefix        # should print <home>/.local
npm ls -g --depth=0          # should resolve under ~/.local/lib
```

If `npm config get prefix` still points into the Cellar, `NPM_CONFIG_USERCONFIG`
is not exported — start a new shell, or check `.zshenv`.
