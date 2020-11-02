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
alias tmux="TERM=xterm-256color tmux"
alias vim="gvim -v --servername vimserver"

export HISTCONTROL="ignoredups"
export HISTIGNORE="clear:history"

[ -e "$HOME/.bashrc.local" ] && source "$HOME/.bashrc.local"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash
