# =============================================================================
# Sean's ZSH Configuration
# =============================================================================

# =============================================================================
# Prompt
# =============================================================================
zmodload zsh/datetime
setopt PROMPT_SUBST

# -- Exec time tracking ------------------------------------------------------
_prompt_exec_start=0
_prompt_exec_time=""

_prompt_preexec() {
  _prompt_exec_start=$EPOCHSECONDS
}

_prompt_precmd_timer() {
  if (( _prompt_exec_start == 0 )); then
    _prompt_exec_time=""
    return
  fi
  local elapsed=$(( EPOCHSECONDS - _prompt_exec_start ))
  _prompt_exec_start=0
  if (( elapsed < 5 )); then
    _prompt_exec_time=""
    return
  fi
  local hours=$(( elapsed / 3600 ))
  local mins=$(( (elapsed % 3600) / 60 ))
  local secs=$(( elapsed % 60 ))
  if (( hours > 0 )); then
    _prompt_exec_time="${hours}h ${mins}m ${secs}s"
  elif (( mins > 0 )); then
    _prompt_exec_time="${mins}m ${secs}s"
  else
    _prompt_exec_time="${secs}s"
  fi
}

# -- Git info -----------------------------------------------------------------
_prompt_git_info() {
  # Bail early if not in a git repo
  local git_dir
  git_dir=$(command git rev-parse --git-dir 2>/dev/null) || return

  local branch="" ahead=0 behind=0
  local staged=0 unstaged=0 untracked=0 conflicts=0
  local line xy

  # Single call for branch + file status
  while IFS= read -r line; do
    case "$line" in
      "# branch.head "*)
        branch="${line#\# branch.head }"
        ;;
      "# branch.ab "*)
        ahead="${line#\# branch.ab }"
        ahead="${ahead%% *}"
        ahead="${ahead#+}"
        behind="${line##* }"
        behind="${behind#-}"
        ;;
      "1 "*|"2 "*)
        xy="${line:2:2}"
        [[ "${xy[1]}" != "." ]] && (( staged++ ))
        [[ "${xy[2]}" != "." ]] && (( unstaged++ ))
        ;;
      "u "*)
        (( conflicts++ ))
        ;;
      "? "*)
        (( untracked++ ))
        ;;
    esac
  done < <(command git status --porcelain=v2 --branch 2>/dev/null)

  # Detached HEAD
  if [[ "$branch" == "(detached)" ]]; then
    branch=$(command git describe --tags --short --always 2>/dev/null)
    branch=":${branch}"
  fi

  # Stash count
  local stash=0
  stash=$(command git stash list 2>/dev/null | wc -l | tr -d ' ')

  # Rebase/merge/cherry-pick/bisect state
  local state=""
  if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" ]]; then
    state="|REBASE"
  elif [[ -f "$git_dir/MERGE_HEAD" ]]; then
    state="|MERGE"
  elif [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
    state="|PICK"
  elif [[ -f "$git_dir/BISECT_LOG" ]]; then
    state="|BISECT"
  fi

  # Build output
  local info=""
  info+="%F{240} on %f"
  info+="%F{180}${branch}${state}%f"
  (( staged > 0 ))    && info+=" %F{114}+${staged}%f"
  (( unstaged > 0 ))  && info+=" %F{216}~${unstaged}%f"
  (( untracked > 0 )) && info+=" %F{174}?${untracked}%f"
  (( conflicts > 0 )) && info+=" %F{167}!${conflicts}%f"
  (( ahead > 0 ))     && info+=" %F{114}↑${ahead}%f"
  (( behind > 0 ))    && info+=" %F{216}↓${behind}%f"
  (( stash > 0 ))     && info+=" %F{139}≡${stash}%f"

  echo -n "$info"
}

# -- Assemble prompt ----------------------------------------------------------
_prompt_precmd() {
  local top=""

  # Exec time (if any)
  if [[ -n "$_prompt_exec_time" ]]; then
    top+="%F{244}${_prompt_exec_time}%f "
  fi

  # CWD
  top+="%F{110}%~%f"

  # Git info
  top+='$(_prompt_git_info)'

  # Two-line prompt
  PROMPT="${top}"$'\n'"%(?.%F{114}.%F{167})❱%f "
}

# -- Register hooks -----------------------------------------------------------
precmd_functions+=(_prompt_precmd_timer _prompt_precmd)
preexec_functions+=(_prompt_preexec)

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
# Claude Worktree Helper
# =============================================================================
# cw <branch>        — open Claude in a worktree for an existing branch
# cw -n <name>       — create new branch from develop, open Claude
# cw -l              — list worktrees
# cw -c              — prune dead worktrees
cw() {
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "error: not in a git repo" >&2; return 1
  }
  local wt_dir="${repo_root}/.claude/worktrees"

  case "${1:-}" in
    -l)
      git worktree list
      ;;
    -c)
      git worktree prune -v
      ;;
    -n)
      [[ -z "${2:-}" ]] && { echo "usage: cw -n <name>" >&2; return 1; }
      local name="$2"
      mkdir -p "$wt_dir"
      git worktree add "$wt_dir/$name" -b "$name" origin/develop
      (cd "$wt_dir/$name" && claude)
      ;;
    "")
      echo "usage: cw <branch> | cw -n <name> | cw -l | cw -c" >&2
      echo "" >&2
      echo "branches:" >&2
      git branch --format='  %(refname:short)' | grep -v '^  worktree-' >&2
      ;;
    *)
      local branch="$1"
      local safe_name="${branch//\//-}"
      # Verify branch exists (local or remote)
      local is_remote=false
      if ! git rev-parse --verify "$branch" &>/dev/null; then
        if git rev-parse --verify "origin/$branch" &>/dev/null; then
          is_remote=true
        else
          echo "error: branch '$branch' not found (checked local and origin)" >&2
          echo "local branches:" >&2
          git branch --format='  %(refname:short)' | grep -v '^  worktree-' >&2
          return 1
        fi
      fi
      # Check if worktree already exists for this branch
      local existing
      existing=$(git worktree list --porcelain | awk -v b="$branch" '
        /^worktree / { wt=$2 }
        /^branch / && $2 == "refs/heads/" b { print wt; exit }
      ')
      if [[ -n "$existing" ]]; then
        echo "worktree already exists at $existing"
        (cd "$existing" && claude)
      else
        mkdir -p "$wt_dir"
        if $is_remote; then
          # Create local tracking branch in the worktree
          git worktree add -b "$branch" "$wt_dir/$safe_name" "origin/$branch"
        else
          git worktree add "$wt_dir/$safe_name" "$branch"
        fi
        (cd "$wt_dir/$safe_name" && claude)
      fi
      ;;
  esac
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
