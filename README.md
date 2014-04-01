dotfiles
========

Notes to self on how to install the dotfiles:

After cloning run `makesymlinks.sh` to install all the dotfiles. It'll also automatically initialize and update all submodules.

	chmod +x makesymlinks.sh
	./makesymlinks.sh

Install `git_diff_wrapper` into `/usr/bin`

	sudo cp git_diff_wrapper /usr/bin

Update the font cache - `fc-cache` (from `fontconfig`). Currently I am using `Inconsolata Medium 11`.

Source the `bashrc` in the repo inside the local `~/.bashrc`:

	echo "source ~/dotfiles/bashrc" >> ~/.bashrc

There are 2 submodules with compiled elements: `tern_for_vim` and `YouCompleteMe`.

For `tern_for_vim`, install `node` from `sbopkg` and then just run `npm install` in the directory of the plugin.

	su -c "sbopkg -i node" && cd ~/.vim/bundle/tern_for_vim && nmp install

For `YouCompleteMe`, according to the github `README.md`, run the following:

	cd ~
	mkdir ycm_build
	cd ycm_build

	cmake -G "Unix Makefiles" -DUSE_SYSTEM_LIBCLANG=ON . ~/.vim/bundle/youcompleteme/cpp
	make ycm_support_libs
	cd ~/.vim/bundle/youcompleteme && git submodule init && git submodule update

For the conky_seamod rings to work, conky must be compiled with lua support, and for the mpd conky to work, exiftool and mpc must be installed
Run the scripts with:

	bash -c "~/.conky_startup"

On XFCE, remember to uncheck "Save session for future logins" when logging out
