local keymap = {
    search_for_files_in_working_directory   = '<c-p>',
    search_for_previously_opened_files      = '<Space><Space>',
    live_grep                               = '<Space>fg',
    search_help_pages                       = '<Space>fh',

    rename_symbol                           = '<leader>rn',
    code_action                             = '<leader>ca',
    go_to_definition                        = 'gd',
    go_to_implementation                    = 'gi',
    show_references                         = 'gr',
    hovering_documentation                  = 'K',

    autocomplete_scroll_down_docs           = '<C-d>',
    autocomplete_scroll_up_docs             = '<C-f>',
    autocomplete_abort                      = '<C-e>',
    autocomplete_confirm                    = '<CR>',
    jump_forward_in_snippet                 = '<C-n>',
    jump_backward_in_snippet                = '<C-a>',

    toggle_file_explorer                    ='<c-n>',

    leader_key                              = ';',

    move_to_panel_left                      = '<c-h>',
    move_to_panel_down                      = '<c-j>',
    move_to_panel_up                        = '<c-k>',
    move_to_panel_right                     = '<c-l>',
}

local theme_with_real_colors = true

vim.g.mapleader = keymap.leader_key
vim.g.maplocalleader = keymap.leader_key
vim.opt.tabstop = 4     -- Character width of a tab
vim.opt.shiftwidth = 0  -- Will always be eual to the tabstop
vim.opt.rnu = true      -- Shows relative line numbers
vim.opt.nu = true       -- Shows current line number
vim.opt.wrap = false    -- Don't wrap the line. Let it go offscreen.
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.api.nvim_set_option("clipboard", "unnamed")
vim.keymap.set('n', keymap.move_to_panel_left, '<c-w>h', {})
vim.keymap.set('n', keymap.move_to_panel_down, '<c-w>j', {})
vim.keymap.set('n', keymap.move_to_panel_up, '<c-w>k', {})
vim.keymap.set('n', keymap.move_to_panel_right, '<c-w>l', {})

-- Will only run the first time nvim launches to install packer
local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
        vim.cmd [[packadd packer.nvim]]
        return true
    end
    return false
end
local packer_bootstrap = ensure_packer()

-- Packages
local function packer_startup(use)
    use 'wbthomason/packer.nvim'
    use 'lervag/vimtex'                     -- Latex
    use 'ellisonleao/gruvbox.nvim'          -- Theme
    use 'nvim-tree/nvim-tree.lua'           -- File explorer
    use 'nvim-tree/nvim-web-devicons'       -- Icons for file explorer and info bar
    use 'nvim-lualine/lualine.nvim'         -- Lower info-bar
    use 'nvim-treesitter/nvim-treesitter'   -- Syntax highlighting
    use 'hrsh7th/nvim-cmp'                  -- Autocompletion
    use 'hrsh7th/cmp-nvim-lsp'
    use 'L3MON4D3/LuaSnip'
    use 'saadparwaiz1/cmp_luasnip'
    use 'rafamadriz/friendly-snippets'
    use {                                   -- LSP
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'neovim/nvim-lspconfig',
    }
    use { 'nvim-telescope/telescope.nvim',  -- FuzzyFind
        tag = '0.1.1',
        requires = {
            {'nvim-lua/plenary.nvim'},
            {'BurntSushi/ripgrep'},
            -- ripgrep might not actually
            -- be a nvim package
        }
    }
    use 'roodletoof/autoclose.nvim'

    if packer_bootstrap then --Comes after packages
        require('packer').sync()
    end

    vim.g.vimtex_view_method = 'zathura'
    vim.g.vimtex_syntax_enabled = false

    if theme_with_real_colors then
        vim.o.termguicolors = true
        vim.o.background = "dark"
        vim.cmd [[ colorscheme gruvbox ]]
    end

    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    require('nvim-tree').setup()
    vim.keymap.set('n', keymap.toggle_file_explorer, ':NvimTreeFindFileToggle<CR>')

    require('lualine').setup {options = {icons_enabled = true, theme = 'gruvbox'}}

    require('nvim-treesitter.configs').setup {
        ensure_installed = 'all',
        sync_install = false,
        auto_install = true,
        --indent = { enable = true },
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        }
    }

    local luasnip = require('luasnip')
    local cmp = require('cmp')
    require('luasnip.loaders.from_vscode').lazy_load()
    cmp.setup{
        mapping = cmp.mapping.preset.insert {
            [keymap.autocomplete_scroll_down_docs]   = cmp.mapping.scroll_docs(-4),
            [keymap.autocomplete_scroll_up_docs]     = cmp.mapping.scroll_docs( 4),
            [keymap.autocomplete_abort]         = cmp.mapping.abort(),
            [keymap.autocomplete_confirm]       = cmp.mapping.confirm{ select = true },
            [keymap.jump_forward_in_snippet] = cmp.mapping(function(fallback)
                if luasnip.jumpable(1) then
                    luasnip.jump(1)
                else
                    fallback()
                end
            end, { "i", "s" }),
            [keymap.jump_backward_in_snippet] = cmp.mapping(function(fallback)
                if luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                else
                    fallback()
                end
            end, { "i", "s" }),
        },
        snippet = {
            expand = function(args)
                require('luasnip').lsp_expand(args.body)
            end,
        },
        sources = cmp.config.sources(
            {
                { name = 'nvim_lsp' },
                { name = 'luasnip' },
            },
            {{ name = 'buffer' }}
        )
    }

    require('mason').setup()
    require('mason-lspconfig').setup{
        ensure_installed = {
            'clangd', 'golangci_lint_ls', 'kotlin_language_server',
            'ltex', 'lua_ls', 'marksman', 'pyright', 'zls', 'rust_analyzer'
        }
    }
    local capabilities = require('cmp_nvim_lsp').default_capabilities()
    require("mason-lspconfig").setup_handlers {
        function (server_name) -- default_handler
            require("lspconfig")[server_name].setup {
                capabilities = capabilities
            }
        end,

        lua_ls = function()
            require("lspconfig").lua_ls.setup {
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = {
                            globals = {'vim'}
                        }
                    }
                }
            }
        end,
    }
    vim.keymap.set('n', keymap.rename_symbol, vim.lsp.buf.rename, {})
    vim.keymap.set('n', keymap.code_action, vim.lsp.buf.code_action, {})
    vim.keymap.set('n', keymap.go_to_definition, vim.lsp.buf.definition, {})
    vim.keymap.set('n', keymap.go_to_implementation, vim.lsp.buf.implementation, {})
    vim.keymap.set('n', keymap.show_references, require('telescope.builtin').lsp_references, {})
    vim.keymap.set('n', keymap.hovering_documentation, vim.lsp.buf.hover, {})

    local builtin = require('telescope.builtin')
    vim.keymap.set('n', keymap.search_for_files_in_working_directory, builtin.find_files, {})
    vim.keymap.set('n', keymap.search_for_previously_opened_files, builtin.oldfiles, {})
    vim.keymap.set('n', keymap.live_grep, builtin.live_grep, {})
    vim.keymap.set('n', keymap.search_help_pages, builtin.help_tags, {})

    require('autoclose').setup{
        filetype_specific_keys = {
            tex = {
                ['$'] = { escape = true, close = true, pair = '$$' },
                ["'"] = false,
            }
        },
        options = {
            pair_spaces = true,
            auto_indent = true,
        }
    }

    vim.g.python_indent = { -- Fixes retarded default python indentation.
        open_paren = 'shiftwidth()',
        nested_paren = 'shiftwidth()',
        continue = 'shiftwidth()',
        closed_paren_align_last_line = false,
        searchpair_timeout = 300,
    }
end

return require('packer').startup(packer_startup)
