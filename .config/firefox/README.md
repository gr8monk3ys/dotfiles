# Firefox Configuration

This directory contains user preferences for [Mozilla Firefox](https://www.mozilla.org/firefox/).

## Files

- `user.js` - User preferences file for Firefox customization

## What is user.js?

The `user.js` file is a configuration file that allows you to customize Firefox settings that aren't easily accessible through the standard preferences interface. It's particularly useful for:
- Privacy and security hardening
- Performance optimization
- UI/UX customization
- Developer-specific settings

## How It Works

When Firefox starts, it reads the `user.js` file from your profile directory and applies all the preferences defined in it. These settings override any existing preferences in `prefs.js`.

### Installation

To use this configuration:

1. Locate your Firefox profile directory:
   - macOS: `~/Library/Application Support/Firefox/Profiles/xxxxxxxx.default/`
   - Linux: `~/.mozilla/firefox/xxxxxxxx.default/`
   - Windows: `%APPDATA%\Mozilla\Firefox\Profiles\xxxxxxxx.default\`

2. Copy `user.js` to your profile directory

3. Restart Firefox for changes to take effect

## Common Customizations

Typical `user.js` configurations include:
- **Privacy**: Disable telemetry, tracking, and data collection
- **Security**: Enhanced security settings and HTTPS-only mode
- **Performance**: Hardware acceleration, cache settings
- **UI/UX**: Disable animations, compact mode, custom homepage
- **Developer Tools**: Enable debugging features

## Managing Settings

- Settings in `user.js` are permanent and override GUI changes
- To change settings, edit `user.js` and restart Firefox
- To remove a setting, delete the line from `user.js` and restart Firefox
- Use `about:config` in Firefox to verify applied settings

## Backup

Always backup your `user.js` before making significant changes. This dotfiles repository serves as version control for your Firefox preferences.

## Resources

- [Firefox user.js Documentation](https://kb.mozillazine.org/User.js_file)
- [about:config Entries](https://kb.mozillazine.org/About:config_entries)
- [arkenfox user.js](https://github.com/arkenfox/user.js) - Privacy-focused template
