#!/usr/bin/env bash
# nuke.sh — wipe chezmoi state, deployed files, and script-created artifacts
# from this machine, then optionally re-init from the repo.
#
# NOT chezmoi-managed. Lives at scripts/nuke.sh in the repo root so it is
# still available after `chezmoi purge` deletes ~/.local/share/chezmoi.
#
# Usage:
#   scripts/nuke.sh                # preview + confirm, then wipe
#   scripts/nuke.sh --dry-run      # print what would happen, change nothing
#   scripts/nuke.sh --yes          # skip the "type nuke" prompt
#   scripts/nuke.sh --reinit       # also run `chezmoi init --apply aaron-propeller` at the end
#   scripts/nuke.sh --yes --reinit # full unattended rebuild
#
# What it does NOT touch:
#   - Homebrew and its formulae/casks
#   - Xcode Command Line Tools
#   - 1Password app
#   - Anything under ~/src not created by chezmoi scripts

set -euo pipefail

DRY_RUN=false
SKIP_CONFIRM=false
REINIT=false
CHEZMOI_INIT_USER="aaron-propeller"
CHEZMOI_INIT_BRANCH="propelleraero"

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --yes|-y)  SKIP_CONFIRM=true ;;
    --reinit)  REINIT=true ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      echo "unknown arg: $arg" >&2
      exit 2
      ;;
  esac
done

# -----------------------------------------------------------------------------
# Preflight
# -----------------------------------------------------------------------------

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: this script is macOS-only" >&2
  exit 1
fi

if ! command -v chezmoi >/dev/null 2>&1; then
  echo "error: chezmoi is not on PATH; cannot enumerate managed files" >&2
  exit 1
fi

CHEZMOI_BIN="$(command -v chezmoi)"
CHEZMOI_ARCH="$(file -b "$CHEZMOI_BIN" | awk '{print $NF}')"
HOST_ARCH="$(uname -m)"
if [[ "$HOST_ARCH" == "arm64" && "$CHEZMOI_ARCH" == "x86_64" ]]; then
  cat >&2 <<WARN
warning: $CHEZMOI_BIN is x86_64 but this Mac is arm64.
         You are probably running in a Rosetta shell. Re-run this script from a
         native arm64 terminal, or the re-init step will download an x86_64
         chezmoi and you'll be back where you started.
WARN
  $SKIP_CONFIRM || { read -r -p "Continue anyway? [y/N] " ans; [[ "$ans" == "y" || "$ans" == "Y" ]] || exit 1; }
fi

# -----------------------------------------------------------------------------
# Gather targets
# -----------------------------------------------------------------------------

MANAGED_FILE="$(mktemp -t chezmoi-managed.XXXXXX)"
trap 'rm -f "$MANAGED_FILE"' EXIT

chezmoi managed --path-style absolute > "$MANAGED_FILE"

LAUNCH_AGENTS=(
  "com.aaron.npm-token-refresh"
  "com.motion-sync.daemon"
)

# Everything scripts create that chezmoi doesn't track.
ARTIFACTS=(
  "$HOME/src/motion-sync"
  "$HOME/src/pi-packages"
  "$HOME/.nvm"
  "$HOME/.zsh/.antidote"
  "$HOME/Pictures/wallpapers"
  "$HOME/Library/LaunchAgents/com.motion-sync.daemon.plist"
  "$HOME/Library/pnpm"
  "$HOME/Library/Logs/npm-token-refresh.log"
  "$HOME/.npmrc"
)

# Fonts copied by copy-misc-files — only remove the ones this repo owns.
FONT_SRC_DIR="${HOME}/.local/share/chezmoi/fonts"
FONTS_TO_REMOVE=()
if [[ -d "$FONT_SRC_DIR" ]]; then
  while IFS= read -r -d '' f; do
    FONTS_TO_REMOVE+=("$HOME/Library/Fonts/$(basename "$f")")
  done < <(find "$FONT_SRC_DIR" -maxdepth 1 -type f -print0)
fi

# -----------------------------------------------------------------------------
# Preview
# -----------------------------------------------------------------------------

echo "==> LaunchAgents to unload:"
for label in "${LAUNCH_AGENTS[@]}"; do
  echo "    $label"
done

echo
echo "==> Managed files chezmoi will unpack from tracking ($(wc -l < "$MANAGED_FILE") entries):"
head -20 "$MANAGED_FILE" | sed 's/^/    /'
if [[ $(wc -l < "$MANAGED_FILE") -gt 20 ]]; then
  echo "    ... (see $MANAGED_FILE for the full list)"
fi

echo
echo "==> Script-created artifacts to remove:"
for a in "${ARTIFACTS[@]}"; do
  echo "    $a"
done

if (( ${#FONTS_TO_REMOVE[@]} > 0 )); then
  echo
  echo "==> Fonts to remove from ~/Library/Fonts:"
  for f in "${FONTS_TO_REMOVE[@]}"; do
    echo "    $f"
  done
fi

echo
echo "==> Then: chezmoi purge --force (removes ~/.local/share/chezmoi + ~/.config/chezmoi + state)"
if $REINIT; then
  echo "==> Then: chezmoi init --branch $CHEZMOI_INIT_BRANCH --apply $CHEZMOI_INIT_USER"
fi

if $DRY_RUN; then
  echo
  echo "(dry run — no changes made)"
  exit 0
fi

# -----------------------------------------------------------------------------
# Confirm
# -----------------------------------------------------------------------------

if ! $SKIP_CONFIRM; then
  echo
  read -r -p "This is destructive. Type 'nuke' to continue: " ans
  if [[ "$ans" != "nuke" ]]; then
    echo "aborted"
    exit 1
  fi
fi

# -----------------------------------------------------------------------------
# Execute
# -----------------------------------------------------------------------------

run() {
  echo "+ $*"
  "$@" || true    # best-effort; do not halt the wipe on a single failure
}

echo
echo "==> Unloading LaunchAgents"
DOMAIN="gui/$(id -u)"
for label in "${LAUNCH_AGENTS[@]}"; do
  run launchctl bootout "$DOMAIN/$label"
done

echo
echo "==> Removing chezmoi-managed files (deepest-first)"
# Reverse sort by path length so files go before their containing dirs.
awk '{print length, $0}' "$MANAGED_FILE" | sort -rn | cut -d' ' -f2- \
  | while IFS= read -r target; do
      [[ -e "$target" || -L "$target" ]] || continue
      run rm -rf "$target"
    done

echo
echo "==> Removing script-created artifacts"
for a in "${ARTIFACTS[@]}"; do
  [[ -e "$a" || -L "$a" ]] || continue
  run rm -rf "$a"
done

if (( ${#FONTS_TO_REMOVE[@]} > 0 )); then
  echo
  echo "==> Removing repo-owned fonts"
  for f in "${FONTS_TO_REMOVE[@]}"; do
    [[ -e "$f" ]] || continue
    run rm -f "$f"
  done
fi

echo
echo "==> Purging chezmoi state"
run chezmoi purge --force

if $REINIT; then
  echo
  echo "==> Re-initialising chezmoi from $CHEZMOI_INIT_USER ($CHEZMOI_INIT_BRANCH)"
  # Use the official bootstrap so it fetches the correct-arch binary if brew's
  # copy has been clobbered too.
  sh -c "$(curl -fsLS get.chezmoi.io)" -- init --branch "$CHEZMOI_INIT_BRANCH" --apply "$CHEZMOI_INIT_USER"
fi

echo
echo "==> Done."
if ! $REINIT; then
  cat <<NOTE

Re-install with:
  sh -c "\$(curl -fsLS get.chezmoi.io)" -- init --branch $CHEZMOI_INIT_BRANCH --apply $CHEZMOI_INIT_USER
NOTE
fi
