#!/bin/bash
# install.sh - Set up symlinks for dotfiles and Claude Code config
# Works on any Mac - run after cloning the repo

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Personal Setup Installer ==="
echo "Repo: $REPO_DIR"
echo ""

# Helper function to backup and link
link_file() {
    local src="$1"
    local dest="$2"

    if [ ! -f "$src" ]; then
        echo "  Skipping $dest (source not found)"
        return
    fi

    if [ -f "$dest" ] && [ ! -L "$dest" ]; then
        echo "  Backing up $dest -> ${dest}.backup"
        mv "$dest" "${dest}.backup"
    fi

    ln -sf "$src" "$dest"
    echo "  Linked $dest"
}

# --- Shell Config ---
echo "Shell config:"
link_file "$REPO_DIR/.zshrc" "$HOME/.zshrc"
link_file "$REPO_DIR/.profile" "$HOME/.profile"

# --- Claude Code ---
echo ""
echo "Claude Code:"
mkdir -p "$HOME/.claude"

# Global instructions
link_file "$REPO_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"

# Skills and agents are provided by the plugin (claude/ is the plugin root).
# Install with: /plugin marketplace add SeanRobb/personal-setup
#               /plugin install personal-setup@sean-tools

# Link all skills (whole directory each, so skills can carry helpers/refs)
mkdir -p "$HOME/.claude/skills"
if [ -d "$REPO_DIR/claude/skills" ]; then
    for skill_dir in "$REPO_DIR/claude/skills"/*/; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            dest="$HOME/.claude/skills/$skill_name"
            if [ -e "$dest" ] && [ ! -L "$dest" ]; then
                echo "  Backing up $dest -> ${dest}.backup"
                mv "$dest" "${dest}.backup"
            fi
            ln -sfn "${skill_dir%/}" "$dest"
            echo "  Linked $dest"
        fi
    done
fi

echo ""
echo "=== Done! ==="
echo ""
echo "Restart your shell or run: source ~/.zshrc"
