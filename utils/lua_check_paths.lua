-- Print the paths the Lua type check needs, as shell exports for eval. Run with `nvim -l`, which like
-- --clean skips the user config and plugins; neither value needs them, since $VIMRUNTIME comes from
-- the Neovim install and stdpath('data') from HOME (or XDG_DATA_HOME).
io.write(('export VIMRUNTIME=%q NVIM_PACK=%q\n'):format(vim.env.VIMRUNTIME, vim.fn.stdpath('data') .. '/site/pack'))
