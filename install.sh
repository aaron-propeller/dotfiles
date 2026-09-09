#!/bin/sh
# Entrypoint for cloud workspaces that clone this repo and expect an install.sh.
set -eu

DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "$0")" && pwd)}"

if ! command -v chezmoi >/dev/null 2>&1; then
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
fi

chezmoi init --apply --source "$DOTFILES_DIR"
