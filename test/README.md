# test/

The BATS suite. `make test-setup` installs its prerequisites (bats,
bats-support, bats-assert, zsh, stow); `make test` runs it; `bats
test/test_link.bats -f "dry-run"` runs part of it. How it fits into `make
verify` and CI is in [OPERATING.md](../OPERATING.md#testing-and-verification).

## Conventions

- **One file per module.** `test_<module>.bats` tests `bin/<module>` (or the
  Makefile, install.sh, the shell surface) through its interface. A test
  that guards a past bug says so in a `# Regression:` comment and lives with
  the module it guards, not in a file of its own.
- **Never the real home.** A test that runs a script gives it
  `HOME="$TEST_HOME"` (and, where the script reads it, an `XDG_CONFIG_HOME`
  under that), from `setup_test_env` in `test_helper/common.bash`;
  `cleanup_test_env` removes it. Nothing may write into `~` or into the
  checkout: the shell-boot tests boot zsh from a copied fixture home and
  fail if the boot leaves anything in the checkout.
- **Fixtures, not the live repo.** Modules that take `DOTFILES_DIR` run
  against a throwaway checkout under `$TEST_TEMP_DIR` (`FAKE_REPO` in the
  link tests, `make_fixture` in the palette tests). Real manifests and
  configs are read only by the tests that assert on them.
- **Stubs log their argv.** Package managers are never run: a stub in a
  `STUB_BIN` directory first on `PATH` records its arguments, and the test
  asserts on what was asked for. PATH is otherwise cut to the system
  directories, so a tool on the developer's machine cannot make a test pass.
- **Observe, don't grep.** Anything with a runtime observable is asserted
  against the running thing (a booted zsh, `git config`, the script's
  output). A text check stays only where there is no cheap observable, and
  its comment says why.
- **No signing.** `common.bash` turns off commit and tag signing for the
  fixture repos through `GIT_CONFIG_COUNT`, so a linked git config cannot
  make them ask for a key.
