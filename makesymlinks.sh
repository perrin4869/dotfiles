#!/bin/bash
############################
# .make.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables

dir=~/dotfiles # dotfiles directory
olddir=~/dotfiles_old # old dotfiles backup directory
files="git-completion.bash gitconfig git_ps1.bash vimrc gvimrc gitignore_global fonts vim tmux.conf bash_profile screenrc conky mpdconfig ncmpcpp" # list of files/folders to symlink in homedir

##########

# create dotfiles_old in homedir
echo -n "Creating $olddir for backup of any existing dotfiles in ~ ..."
mkdir -p $olddir
echo "done"

# change to the dotfiles directory
echo -n "Changing to the $dir directory ..."
cd $dir
echo "done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks from the homedir to any files in the ~/dotfiles directory specified in $files
for file in $files; do
echo "Moving any existing dotfiles from ~ to $olddir"
    mv ~/.$file ~/dotfiles_old/
    echo "Creating symlink to $file in home directory."
    ln -s $dir/$file ~/.$file
done

#install config files
mkdir -p $olddir/.config
for file in config/*; do
echo "Moving any existing config files from ~/.config to $olddir/.config"
    # Here $file looks like: $file=config/foo
    mv ~/.$file ~/dotfiles_old/.$file
    echo "Creating symlink to $file in .config directory."
    ln -s $dir/$file ~/.$file
done

echo "Initializing submodules..."
git submodule init && git submodule update
