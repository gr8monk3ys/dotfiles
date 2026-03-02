#!/usr/bin/env zsh

# Easier navigation: .., ..., ...., ....., ~ and -
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~" # `cd` is probably faster to type though
alias -- -="cd -"

# Shortcuts
alias d="cd ~/Documents/Dropbox"
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias p="cd ~/projects"
alias g="git"

# Detect which `ls` flavor is in use
if ls --color > /dev/null 2>&1; then # GNU `ls`
	colorflag="--color"
	export LS_COLORS='no=00:fi=00:di=01;31:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:'
else # macOS `ls`
	colorflag="-G"
	export LSCOLORS='BxBxhxDxfxhxhxhxhxcxcx'
fi

# List all files colorized in long format
alias l="ls -lF ${colorflag}"

# List all files colorized in long format, excluding . and ..
alias la="ls -lAF ${colorflag}"

# List only directories
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"

# Always use color output for `ls`
alias ls="command ls ${colorflag}"

# Always enable colored `grep` output
# Note: `GREP_OPTIONS="--color=auto"` is deprecated, hence the alias usage.
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Enable aliases to be sudo’ed
alias sudo='sudo '

# Get week number
alias week='date +%V'

# System updates — use `make update` or `dotsup` (line 336) for full dotfiles update
alias update='sudo softwareupdate -i -a'

# Google Chrome
alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
alias canary='/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary'

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"

# Show active network interfaces
alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"

# Flush Directory Service cache
alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"

# Clean up LaunchServices to remove duplicates in the “Open With” menu
alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"

# Canonical hex dump; some systems have this symlinked
command -v hd > /dev/null || alias hd="hexdump -C"

# macOS has no `md5sum`, so use `md5` as a fallback
command -v md5sum > /dev/null || alias md5sum="md5"

# macOS has no `sha1sum`, so use `shasum` as a fallback
command -v sha1sum > /dev/null || alias sha1sum="shasum"

# JavaScriptCore REPL
jscbin="/System/Library/Frameworks/JavaScriptCore.framework/Versions/A/Resources/jsc";
[ -e "${jscbin}" ] && alias jsc="${jscbin}";
unset jscbin;

# Trim new lines and copy to clipboard
alias copy="tr -d '\n' | pbcopy"

# Recursively delete `.DS_Store` files
alias cleanup="find . -type f -name '*.DS_Store' -ls -delete"

# Empty the Trash on all mounted volumes and the main HDD.
# Also, clear Apple’s System Logs to improve shell startup speed.
# Finally, clear download history from quarantine. https://mths.be/bum
alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'"

# Show/hide hidden files in Finder
alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

# Hide/show all desktop icons (useful when presenting)
alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

# URL-encode strings (Python 3 compatible)
alias urlencode='python3 -c "import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))"'

# Merge PDF files, preserving hyperlinks
# Usage: `mergepdf input{1,2,3}.pdf`
alias mergepdf='gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=_merged.pdf'

# Disable Spotlight
alias spotoff="sudo mdutil -a -i off"
# Enable Spotlight
alias spoton="sudo mdutil -a -i on"

# PlistBuddy alias, because sometimes `defaults` just doesn’t cut it
alias plistbuddy="/usr/libexec/PlistBuddy"

# Airport CLI alias
alias airport='/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport'

# Intuitive map function
# For example, to list all directories that contain a certain file:
# find . -name .gitattributes | map dirname
alias map="xargs -n1"

# One of @janmoesen’s ProTip™s
for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
	alias "${method}"="lwp-request -m '${method}'"
done

# Stuff I never really use but cannot delete either because of http://xkcd.com/530/
alias stfu="osascript -e 'set volume output muted true'"
alias pumpitup="osascript -e 'set volume output volume 100'"

# Kill all the tabs in Chrome to free up memory
# [C] explained: http://www.commandlinefu.com/commands/view/402/exclude-grep-from-your-grepped-output-of-ps-alias-included-in-description
alias chromekill="ps ux | grep '[C]hrome Helper --type=renderer' | grep -v extension-process | tr -s ' ' | cut -d ' ' -f2 | xargs kill"

# Lock the screen (when going AFK)
alias afk="/System/Library/CoreServices/Menu\ Extras/User.menu/Contents/Resources/CGSession -suspend"

# Reload the shell (i.e. invoke as a login shell)
alias reload="exec ${SHELL} -l"

# Print each PATH entry on a separate line
alias path='echo -e ${PATH//:/\\n}'

# ============================================================================
# Modern CLI Replacements (Rust-powered tools)
# These override traditional Unix commands with faster, more feature-rich alternatives
# ============================================================================

# eza - Modern ls replacement with icons and git integration
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias l='eza -l --icons --git --group-directories-first'
    alias la='eza -la --icons --git --group-directories-first'
    alias ll='eza -la --icons --git --group-directories-first'
    alias lt='eza --tree --icons --git -L 2'
    alias lta='eza --tree --icons --git -L 2 -a'
    alias tree='eza --tree --icons'
fi

# bat - Cat with syntax highlighting (use bat directly, don't shadow cat)
# cat is used idiomatically in pipes to strip colors — bat reverses that
if command -v bat &> /dev/null; then
    alias catp='bat'  # cat with pager
    alias catl='bat --plain'  # cat without line numbers
fi

# ripgrep (use rg directly, don't shadow grep)
if command -v rg &> /dev/null; then
    alias rgi='rg -i'  # case insensitive
fi

# fd (use fd directly, don't shadow find)
# fd is not a drop-in replacement — different flags, ignores hidden files by default

# sd (use sd directly, don't shadow sed)
# sd uses Rust regex syntax, no address ranges — not a sed replacement

# dust - Modern du (use dust/dus directly, don't shadow du)
if command -v dust &> /dev/null; then
    alias dus='dust -s'  # summary only
fi

# procs - Modern ps (use procs directly, don't shadow ps)
if command -v procs &> /dev/null; then
    alias psa='procs -a'  # all processes
    alias pst='procs --tree'  # process tree
fi

# bottom - Modern system monitor (use btm directly, don't shadow top)
if command -v btm &> /dev/null; then
    alias htop='btm'
fi

# delta (configured in git; use delta directly, don't shadow diff)
# delta is a pager/formatter — not a diff replacement (no -u, -q, wrong exit codes)

# zoxide - Smart cd (already initialized in zshrc, adding convenience aliases)
if command -v zoxide &> /dev/null; then
    alias zi='zoxide query -i'  # interactive selection
fi

# Atuin - Shell history (convenience aliases)
if command -v atuin &> /dev/null; then
    alias hs='atuin search'  # history search
    alias hsi='atuin search -i'  # interactive history search
fi

# mise - Version manager aliases
if command -v mise &> /dev/null; then
    alias mi='mise install'
    alias mu='mise use'
    alias ml='mise list'
    alias mls='mise ls'
fi

# Quick benchmarking with hyperfine
if command -v hyperfine &> /dev/null; then
    alias bench='hyperfine'
fi

# Code statistics with tokei
if command -v tokei &> /dev/null; then
    alias loc='tokei'
    alias sloc='tokei -s lines'
fi

# watchexec (use watchexec directly, don't shadow watch)
# watchexec watches files for changes; watch repeats a command on interval — different tools

# ============================================================================
# Next-Gen Modern Tools (2024+)
# ============================================================================

# Yazi - Terminal file manager (replaces lf/ranger)
if command -v yazi &> /dev/null; then
    # Shell wrapper to cd on exit
    function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
    }
    alias fm='y'  # file manager shortcut
fi

# Jujutsu (jj) - Modern Git alternative
if command -v jj &> /dev/null; then
    alias j='jj'
    alias js='jj status'
    alias jl='jj log'
    alias jll='jj log -r "trunk()..@"'
    alias jd='jj diff'
    alias jds='jj diff --summary'
    alias jn='jj new'
    alias jdesc='jj describe'
    alias jam='jj amend'
    alias jsq='jj squash'
    alias jgf='jj git fetch'
    alias jgp='jj git push'
fi

# Zellij - Modern terminal multiplexer (tmux alternative)
if command -v zellij &> /dev/null; then
    alias zj='zellij'
    alias zja='zellij attach'
    alias zjl='zellij list-sessions'
    alias zjk='zellij kill-session'
    alias zjka='zellij kill-all-sessions'
fi

# Navi - Interactive cheatsheet
if command -v navi &> /dev/null; then
    alias cheat='navi'
    alias nq='navi query'
fi

# Broot - Tree navigation with fuzzy search
if command -v broot &> /dev/null; then
    alias br='broot'
    alias brs='broot --sizes'  # show sizes
    alias brd='broot --dates'  # show dates
fi

# Tealdeer - Fast tldr client (don't shadow builtin help)
if command -v tldr &> /dev/null; then
    alias tldru='tldr --update'
fi

# Gping - Graphical ping (use gping directly, don't shadow ping)
# gping is a TUI graph tool, not flag-compatible with ping

# Ouch - Universal archive tool
if command -v ouch &> /dev/null; then
    alias compress='ouch compress'
    alias decompress='ouch decompress'
    alias extract='ouch decompress'
    alias arc='ouch'
fi

# ============================================================================
# Utility Aliases
# ============================================================================

# Quick edit configs
alias zshrc='${EDITOR:-nvim} ~/.config/zsh/.zshrc'
alias aliases='${EDITOR:-nvim} ~/.config/zsh/aliases.zsh'
alias gitconfig='${EDITOR:-nvim} ~/.config/git/.gitconfig'
alias ghosttyconf='${EDITOR:-nvim} ~/.config/ghostty/config'
alias yaziconf='${EDITOR:-nvim} ~/.config/yazi/yazi.toml'
alias jjconf='${EDITOR:-nvim} ~/.config/jj/config.toml'

# Dotfiles management
alias dots='cd ~/.dotfiles'
alias dotsup='cd ~/.dotfiles && git pull && make link'

# Nix shortcuts (when using Nix)
if command -v darwin-rebuild &> /dev/null; then
    alias nrs='darwin-rebuild switch --flake ~/.dotfiles'
fi
if command -v home-manager &> /dev/null; then
    alias nhs='home-manager switch --flake ~/.dotfiles'
fi
alias nfu='nix flake update'
alias nfc='nix flake check'
alias ndev='nix develop'

# Claude Code (AI assistant)
alias cc='claude'
