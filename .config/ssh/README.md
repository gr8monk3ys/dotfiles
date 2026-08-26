# SSH Config Snippets

This directory stores OpenSSH host snippets tracked by dotfiles.

## Layout

- `config.d/*.conf.example` — tracked templates
- `config.d/*.conf` — your real host entries (gitignored; copy from an `.example`)

## Activation

OpenSSH reads `~/.ssh/config`, not `~/.config/ssh/*` directly. The dotfiles
`make link` target ensures your `~/.ssh/config` contains:

```
Include ~/.config/ssh/config.d/*.conf
```

That makes snippets in this directory active on every machine where dotfiles
are linked.

## Safety

- Keep private keys out of this repo.
- Reference keys with `IdentityFile ~/.ssh/<keyname>`.
- Store secrets in local/private files if needed.
