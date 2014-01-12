dotfiles
========

Notes to self on how to install the dotfiles:

After cloning (git clone), get all the submodules (git submodule update --init). Run makesymlinks.sh to install all the dotfiles.
There are 2 submodules with compiled: tern_for_vim and YouCompleteMe.
As for YouCompleteMe, check the instructions on their github.
For tern_for_vim, just run npm install in the directory of the plugin.
Install git_diff_wrapper into /usr/bin
