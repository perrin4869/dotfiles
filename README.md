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

	su -c "sbopkg -i node" && cd ~/.vim/bundle/tern_for_vim && npm install

Uses eslint\_d in syntastic, so you need to install that globally too:

	npm install -g eslint_d

For node express autocompletion support (as of this writing it's quite buggy), install tern-node-express in the tern module

	cd vim/bundle/tern_for_vim/node_modules/tern && npm install --save tern-node-express

For markdown autopreview, install grip with `pip install --user grip`

For `YouCompleteMe`, according to the github `README.md`, run the following:

	cd ~
	mkdir ycm_build
	cd ycm_build

	cmake -G "Unix Makefiles" -DUSE_SYSTEM_LIBCLANG=ON . ~/.vim/bundle/YouCompleteMe/third_party/ycmd/cpp
	cmake --build . --target ycm_core --config Release
