# Add local bin to path
export PATH="$PATH:$HOME/bin"

# Add antidote to path to help manage plugins
export PATH="$PATH:$ZSH_DIR/plugins/antidote"

#Add brew to the path
export PATH=/opt/homebrew/bin:$PATH

# pnpm-managed global bins (pi, prp, etc.). pnpm refuses to install globals
# unless this is on PATH, and won't run them if it's missing at shell startup.
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"
