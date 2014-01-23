# enable colors in less
# -R or --RAW-CONTROL-CHARS
export LESS=-R

# git related config
if [ -f ~/.git-completion.bash ]; then
. ~/.git-completion.bash

if [ -f ~/.git_ps1.bash ]; then
. ~/.git_ps1.bash
fi
fi

#enable 256color for terminal multiplexs
alias tmux="tmux -2"
alias vim="gvim -v"

source ~/dotfiles/bashrc
