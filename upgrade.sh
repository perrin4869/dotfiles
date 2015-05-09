#!/bin/bash

# Update all submodules
echo "Upgrade all submodules";
git subup && git submodule foreach git submodule update --recursive

echo "Upgrade tern-for-vim module";
( cd vim/bundle/tern_for_vim/node_modules && npm update )

