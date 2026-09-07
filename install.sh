#!/bin/sh
# Cloud-workspace entrypoint. The workspace host clones this repo to ~/dotfiles and runs
# this script on every workspace start. On macOS this is redundant with the
# usual chezmoi bootstrap; running it a second time is a no-op because
# `chezmoi apply` is idempotent.
#
# Locally: prefer the README's `sh -c "$(curl -fsLS get.chezmoi.io)" -- init …`
# route rather than this script — it's the tested Mac bootstrap path.

set -eu

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# Install chezmoi to ~/.local/bin if not already on PATH.
if ! command -v chezmoi >/dev/null 2>&1; then
  echo "[dotfiles/install.sh] chezmoi not found, installing to $HOME/.local/bin"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
fi

# The workspace has already cloned this repo to $DOTFILES_DIR. Point chezmoi at it as the
# source rather than re-cloning to ~/.local/share/chezmoi (which would leave
# the two out of sync on future pulls).
#
# `chezmoi init` processes src/.chezmoi.toml.tmpl (uses OS branching to
# provide sensible non-interactive defaults on Linux workspaces) and then
# applies. Idempotent across restarts.
echo "[dotfiles/install.sh] applying chezmoi from $DOTFILES_DIR (os=$(uname -s))"
chezmoi init --apply --source "$DOTFILES_DIR"

echo "[dotfiles/install.sh] done"
