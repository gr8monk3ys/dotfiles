# curl

Defaults for every [curl](https://curl.se/docs/manpage.html) run from a shell
that read `.zshenv`: a browser user agent, an automatic `Referer` when
following redirects, and a 60-second connect timeout.

## Gotchas

- curl reads `~/.curlrc` or `$CURL_HOME/.curlrc`, never an XDG path, so this
  file is found only because `.zshenv` exports `CURL_HOME`.
  `make verify-config-live` checks it.
- It applies to scripts too, not only to typing `curl`. A script that needs
  curl's stock behaviour should pass `-q` (`--disable`) as the first argument.
