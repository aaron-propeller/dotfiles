# Set file for compdump cache
export ZSH_COMPDUMP="$CACHEDIR/.zcompdump-$HOST"

# Load completion
autoload -Uz compinit
compinit -u

# Register completions
compdef _wt wt

# Use menu select style
zstyle ':completion:*:*:*:*:*' menu select
# Autocomplete . and ..
zstyle ':completion:*' special-dirs true
# Set colors for completion; use defaults
zstyle ':completion:*' list-colors ''
