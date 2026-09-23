# git

Global git config, read from `$XDG_CONFIG_HOME/git/config` (git has read the
XDG path natively since 1.7.12). `ignore` is the global excludes file.

## Identity

The tracked `config` carries no name, email or signing key; they live in the
gitignored `config.local`, which `config` `[include]`s at the bottom.
Write it with `make init` rather than by hand:

```bash
make init                                              # prompts
make init GIT_USER_NAME="Your Name" GIT_USER_EMAIL=you@example.com
make init check=1                                      # report only
```

`make init` copies `config.local.example` and appends the `[user]` block, so
the template's menu of machine-local options survives into the file you edit
next. It never rewrites a `config.local` that already exists. Without a signing
key it also writes `commit.gpgsign = false`, because the tracked config turns
commit signing on and a machine with no GPG key would otherwise fail every
commit.

## Why these choices

- **Signed commits** (`commit.gpgsign`), identity supplied per machine as
  above.
- **`pull.rebase`** and **`push.autoSetupRemote`**: no merge bubbles on pull,
  and a first `git push` of a new branch just works.
- **`merge.conflictstyle = diff3`**, so a conflict shows the common ancestor
  as well as both sides.
- **delta as the pager**, side by side with line numbers, highlighting with
  the `danse` bat theme; its diff colours are a region rendered by
  `bin/palette`.
- **Aliases** (`git config --get-regexp '^alias\.'` lists them) are the
  shell-era ones: `l` graph log, `s` short status, `d` diff with stat.

## Gotchas

- The `github:` and `gist:` shorthands expand to `git://` URLs, a protocol
  GitHub turned off in 2022, so fetching through them fails. Use full
  `https://` URLs.
- `https://github.com/github/...` is rewritten to SSH, which needs a key
  registered with GitHub. The broader HTTPS-to-SSH push rewrite is commented
  out for that reason; the comment above it explains.
- git also reads `~/.gitconfig`, after this file, so anything set there
  wins. A leftover `~/.gitconfig` is the usual reason a setting here seems
  ignored.
