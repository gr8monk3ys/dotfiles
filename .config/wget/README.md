# Wget Configuration

This directory contains the configuration for [GNU Wget](https://www.gnu.org/software/wget/), a command-line utility for downloading files from the web.

## Files

- `.wgetrc` - Configuration file for wget default options

## What is Wget?

Wget is a free utility for non-interactive download of files from the web. It supports:
- HTTP, HTTPS, and FTP protocols
- Recursive downloads
- Background operation
- Resume broken downloads
- Bandwidth limiting
- Proxy support
- Cookie handling

## Configuration Overview

The `.wgetrc` file sets default options for all wget commands, making downloads more convenient and consistent.

### Common Settings

#### Behavior
```
# Continue partially downloaded files
continue = on

# Timeout settings
timeout = 60
dns-timeout = 60
connect-timeout = 60
read-timeout = 60

# Number of retries
tries = 3

# Wait time between retries
wait = 2
```

#### User Agent
```
# Set custom user agent
user_agent = Mozilla/5.0 (compatible; Wget)
```

#### Download Options
```
# Timestamping (only download if newer)
timestamping = on

# No clobber (don't overwrite existing files)
noclobber = on

# Follow FTP links
follow_ftp = on
```

#### Output
```
# Progress bar style
progress = bar:force:noscroll

# Save logs
logfile = ~/.wget-log
```

#### Security
```
# Check server certificates
check_certificate = on

# Use secure protocols when available
prefer_family = IPv4
```

## Usage

After configuration, wget automatically applies these settings:

```bash
# Simple download
wget https://example.com/file.zip

# Recursive download
wget -r -np https://example.com/directory/

# Download with custom name
wget -O custom-name.zip https://example.com/file.zip

# Background download
wget -b https://example.com/large-file.iso

# Limit bandwidth
wget --limit-rate=500k https://example.com/file.zip

# Resume broken download
wget -c https://example.com/large-file.zip
```

### Override Configuration

Command-line options override `.wgetrc` settings:

```bash
# Disable timestamping for this download
wget --no-timestamping https://example.com/file.txt
```

## Common Use Cases

### Mirror Website
```bash
wget --mirror --convert-links --page-requisites --no-parent https://example.com
```

### Download File List
```bash
wget -i urls.txt
```

### Download with Authentication
```bash
wget --user=username --password=password https://example.com/file.zip
```

### Background Download with Email Notification
```bash
wget -b https://example.com/file.zip && mail -s "Download Complete" user@example.com
```

## Tips

1. **Resume Downloads**: Always use `-c` for large files
2. **Rate Limiting**: Use `--limit-rate` on shared connections
3. **Quiet Mode**: Use `-q` in scripts
4. **Accept/Reject**: Use `-A` and `-R` to filter file types
5. **Robots.txt**: Wget respects robots.txt by default

## Configuration Locations

Wget reads configuration from:
1. `/etc/wgetrc` - System-wide configuration
2. `~/.wgetrc` or `~/.config/wget/.wgetrc` - User configuration
3. Command-line options - Highest priority

## Security Considerations

- Always verify downloads with checksums
- Be cautious with `--no-check-certificate`
- Use HTTPS when available
- Be mindful of bandwidth usage on shared networks

## Resources

- [Wget Manual](https://www.gnu.org/software/wget/manual/)
- [Wget Examples](https://www.gnu.org/software/wget/manual/html_node/Examples.html)
- [Wget FAQ](https://www.gnu.org/software/wget/faq.html)
- [wgetrc Sample](https://www.gnu.org/software/wget/manual/html_node/Wgetrc-Syntax.html)
