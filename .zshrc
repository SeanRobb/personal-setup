# =============================================================================
# Sean's ZSH Configuration
# =============================================================================

# =============================================================================
# Prompt Configuration
# =============================================================================
autoload -Uz vcs_info
precmd() { vcs_info }
setopt PROMPT_SUBST

# Git info format
zstyle ':vcs_info:git:*' formats '%F{magenta}%b%f'
zstyle ':vcs_info:git:*' actionformats '%F{magenta}%b%f|%F{red}%a%f'

# Git dirty/clean indicator
git_status() {
    if git rev-parse --git-dir > /dev/null 2>&1; then
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            echo "%F{yellow}*%f"
        else
            echo "%F{green}✓%f"
        fi
    fi
}

# Prompt: time | directory | git branch + status
# Arrow is green on success, red on error
PROMPT='%F{8}%T%f %F{cyan}%~%f ${vcs_info_msg_0_}$(git_status)
%(?.%F{cyan}.%F{red})❯%f '

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
