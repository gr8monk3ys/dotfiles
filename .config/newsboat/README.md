# Newsboat Configuration

This directory contains the configuration for [Newsboat](https://newsboat.org/), a text-based RSS/Atom feed reader for the terminal.

## Files

- `config` - Main configuration file for Newsboat behavior and appearance
- `urls` - List of RSS/Atom feeds to subscribe to

## What is Newsboat?

Newsboat is a fork of Newsbeuter, providing:
- Fast, keyboard-driven RSS feed reading
- Offline reading support
- Podcast support
- Customizable keybindings
- Filtering and tagging
- Scriptable with external programs
- Multiple format support (RSS, Atom, JSON Feed)

## Configuration Overview

### config

The `config` file controls Newsboat's behavior using key-value pairs.

#### Common Settings

**Appearance**
```
color background white black
color listnormal white black
color listfocus black yellow bold
color info yellow black bold
```

**Behavior**
```
auto-reload yes
reload-time 60
browser "firefox %u"
download-path "~/Downloads"
max-items 100
```

**Keybindings**
```
bind-key j down
bind-key k up
bind-key J next-feed
bind-key K prev-feed
bind-key o open-in-browser
```

**Macros**
- Define custom actions
- Pipe articles to external programs
- Integration with read-it-later services

### urls

The `urls` file contains your RSS/Atom feed subscriptions, one per line:

```
https://example.com/feed.xml
https://blog.example.com/rss "Blog" "Tech"
https://news.example.com/atom.xml "News"
```

Format: `URL ["Title"] ["Tags"]`

#### Organizing Feeds

Use tags to organize feeds:
```
https://feed1.com/rss "~Tech News"
https://feed2.com/rss "~Tech News"
https://feed3.com/rss "~Programming"
```

Tags starting with `~` create collapsible categories.

## Usage

Launch Newsboat with:
```bash
newsboat
```

### Basic Navigation

- `j/k` - Move down/up through articles
- `Enter` - Open article
- `o` - Open in browser
- `r` - Reload current feed
- `R` - Reload all feeds
- `q` - Quit current view
- `Q` - Quit Newsboat

### Feed Management

- `A` - Mark all articles as read
- `n` - Mark current article as unread
- `s` - Save article
- `e` - Enqueue podcast (if applicable)

### Filtering

- `/` - Search articles
- `F` - Filter articles

## Features

### Podcast Support

Newsboat can handle podcast feeds:
- Download episodes
- Queue management
- Integration with media players

### Tagging System

Organize feeds with tags for better management:
```
https://feed.com/rss "Site Name" "tag1" "tag2"
```

### Macros

Create custom actions:
```
macro y set browser "mpv %u"; open-in-browser ; set browser "firefox %u"
```

### External Integration

Pipe articles to external programs:
- Save to read-it-later services (Pocket, Instapaper)
- Share on social media
- Process with custom scripts

## Tips

1. **Performance**: Use `max-items` to limit memory usage
2. **Offline Reading**: Enable `download-full-page` for complete articles
3. **Filtering**: Use `ignore-article` to skip unwanted content
4. **Bookmarks**: Use `:bookmark` to save URLs
5. **Import OPML**: `newsboat -i subscriptions.opml`

## Resources

- [Newsboat Documentation](https://newsboat.org/releases/2.31/docs/newsboat.html)
- [Newsboat GitHub](https://github.com/newsboat/newsboat)
- [Example Configurations](https://github.com/newsboat/newsboat/wiki/Example-configurations)
- [RSS/Atom Feed Discovery](https://validator.w3.org/feed/)
