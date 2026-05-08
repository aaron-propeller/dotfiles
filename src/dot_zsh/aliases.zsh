# misc
alias et='cd ~'
alias c='clear'

# ls
alias l='ls'
alias la='ls -a'
alias lal='ls -al'

# cd
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# git
alias gc="git commit -m"

alias gs="git status"

alias ga='git add'
alias gaa='git add --all'

alias gb='git branch'
alias gba='git branch --all'
alias gbd='git branch --delete'

alias gco='git checkout'

alias gd='git diff'

alias gf='git fetch'

alias ggpull='git pull origin "$(git_current_branch)"'
alias ggpush='git push origin "$(git_current_branch)"'
alias ggp='ggpush'
alias gpr='git pull --rebase'

alias gl='/usr/bin/git log --date-order --graph --pretty=format:'\''%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --abbrev-commit --date=relative'

# neovim
alias vi='nvim'

# chezmoi
alias chedit='chezmoi edit --apply'
alias cm='cd $(chezmoi source-path)'
