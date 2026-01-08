# =============================================================================
# Sean's ZSH Configuration
# =============================================================================

# Git branch in prompt
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

location="Dojo"
PS1='\[\e]0;\w\a\]\n\[\e[34m\]Work Hoodie @ ${location} \[\e[33m\][\d \T]\e[95m\]$(parse_git_branch) \[\e[36m\]\w \[\e[1;96m\]\n🍺 \[\e[0;0m\] '

# =============================================================================
# Aliases
# =============================================================================
alias grep='grep --color'

# Directory navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'

# Copy and go to dir
cpg() {
  if [ -d "$2" ]; then
    cp $1 $2 && cd $2
  else
    cp $1 $2
  fi
}

# Move and go to dir
mvg() {
  if [ -d "$2" ]; then
    mv $1 $2 && cd $2
  else
    mv $1 $2
  fi
}

# Docker status server
dhttp() {
    while true; do {
        echo -e 'HTTP/1.1 200 OK\r\n'
        docker images
    } | nc -l 8080; done
}

# =============================================================================
# PATH Configuration
# =============================================================================
export PATH="$HOME/.local/bin:$PATH"

# =============================================================================
# Local overrides (not version controlled)
# Source a local file for machine-specific config (API keys, credentials, etc.)
# =============================================================================
if [ -f ~/.zshrc.local ]; then
    source ~/.zshrc.local
fi
