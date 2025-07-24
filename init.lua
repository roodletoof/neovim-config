vim.cmd[[
	set clipboard=unnamedplus
	set nu
	set rnu
	nnoremap <c-p> <cmd>cprevious<cr>
	nnoremap <c-n> <cmd>cnext<cr>
	nnoremap ,cf <cmd>cfirst<cr>
	nnoremap ,co <cmd>copen<cr>
	nnoremap ,cc <cmd>cclose<cr>
	nnoremap ,ff :find ./**/*
]]

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require'lazy'.setup{
    { 'sainnhe/everforest',
        lazy = false,
        priority = 1000,
        config = function()
            vim.o.termguicolors = true
            vim.g.everforest_enable_italic = true
            vim.cmd.colorscheme('everforest')
        end,
    },
    { 'nvim-treesitter/nvim-treesitter',
        config = function()
            require'nvim-treesitter.configs'.setup{
                sync_install = false,
                auto_install = true,
                indent = {
                    enable = true,
                },
                highlight = {
                    enable = true,
                    additional_vim_regex_highlighting = false,
                },
            }
        end,
    },
}
