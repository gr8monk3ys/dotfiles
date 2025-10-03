# cURL Configuration

This directory contains the configuration for [cURL](https://curl.se/), a command-line tool for transferring data with URLs.

## Files

- `.curlrc` - Default configuration file for cURL commands

## What is cURL?

cURL is a command-line tool and library for transferring data using various network protocols. It's commonly used for:
- Making HTTP/HTTPS requests
- Downloading files from the internet
- Testing APIs
- Automating web interactions

## Configuration Purpose

The `.curlrc` file provides default options for all cURL commands, eliminating the need to specify common flags repeatedly. This makes cURL commands cleaner and ensures consistent behavior across all requests.

## Common Settings

Typical `.curlrc` configurations include:
- Setting default user agents
- Enabling automatic redirect following
- Configuring SSL/TLS verification behavior
- Setting default timeouts
- Enabling progress bars or silent mode
- Configuring authentication defaults

## Usage

Once this file is in place, any cURL command you run will automatically use these settings. For example:

```bash
# Instead of:
curl -L --user-agent "MyAgent" https://example.com

# You can just use:
curl https://example.com
```

The settings in `.curlrc` are applied automatically.

## Override Settings

You can override `.curlrc` settings for specific commands by explicitly providing different flags on the command line.

## Resources

- [cURL Documentation](https://curl.se/docs/)
- [cURL Manual](https://curl.se/docs/manual.html)
- [cURL Config File Format](https://curl.se/docs/manpage.html#-K)
