# windows-terminal

A Windows Terminal [settings
fragment](https://learn.microsoft.com/windows/terminal/json-fragment-extensions)
that adds the `danse` colour scheme and applies it, with JetBrainsMono Nerd
Font, to the `Arch` WSL profile.

## Why a fragment

Terminal's own `settings.json` holds machine-specific state (profile order, the
default profile, window sizes) that does not belong in this repo. A fragment
layers on top of it, so the theme can be tracked without owning the file.

## The template

[`danse.json.tpl`](danse.json.tpl) carries `{{ARCH_PROFILE_GUID}}` where the
profile's GUID goes. `windows/setup.ps1` reads the GUID of the visible profile
named `Arch` from `settings.json` and writes the filled-in fragment to
`%LOCALAPPDATA%\Microsoft\Windows Terminal\Fragments\dotfiles\danse.json`.
Terminal picks it up on its next start.

## Colours

The ANSI mapping is the same as
[`.config/ghostty/themes/danse`](../../.config/ghostty/themes/danse); every hex
must be a palette colour, which `test_palette.bats` checks.
