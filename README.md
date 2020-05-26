dotfiles
========

Notes to self on how to install the dotfiles:

	./install

Update the font cache - `fc-cache` (from `fontconfig`). Currently I am using `Inconsolata Medium 11`.

Source the `bashrc` in the repo inside the local `~/.bashrc`:

	echo "source ~/dotfiles/bashrc" >> ~/.bashrc

For node express autocompletion support (as of this writing it's quite buggy), install tern-node-express in the tern module

	cd vim/bundle/tern_for_vim/node_modules/tern && npm install --save tern-node-express

Uses eslint\_d in ale, so you need to install that globally too:

	npm install -g eslint_d

For markdown autopreview, install grip with `pip install --user grip`
