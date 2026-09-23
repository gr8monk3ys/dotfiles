typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg={{green}}'
ZSH_HIGHLIGHT_STYLES[builtin]='fg={{green}}'
ZSH_HIGHLIGHT_STYLES[function]='fg={{green}}'
ZSH_HIGHLIGHT_STYLES[alias]='fg={{green}}'
ZSH_HIGHLIGHT_STYLES[precommand]='fg={{green}},italic'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg={{magenta}}'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg={{vermilion}}'
ZSH_HIGHLIGHT_STYLES[path]='fg={{blue}},underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg={{cyan}}'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg={{yellow}}'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg={{yellow}}'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg={{terracotta}}'
ZSH_HIGHLIGHT_STYLES[comment]='fg={{comment}},italic'
ZSH_HIGHLIGHT_STYLES[redirection]='fg={{magenta}}'
export FZF_DEFAULT_OPTS="
  --height=60% --layout=reverse --border=rounded --info=inline
  --color=bg:-1,fg:{{fg}},hl:{{blue}}
  --color=bg+:{{surface}},fg+:{{fg}},hl+:{{blue}}
  --color=prompt:{{green}},pointer:{{magenta}},marker:{{green}}
  --color=info:{{yellow}},spinner:{{cyan}},header:{{cyan}},border:{{comment}}"
