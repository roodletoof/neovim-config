local keymap = {
    -- n
    search_for_files_in_working_directory   = '<c-p>',
    search_for_previously_opened_files      = '<Space><Space>',
    live_grep                               = '<Space>fg',
    search_help_pages                       = '<Space>fh',

    -- n
    rename_symbol                           = '<leader>rn',
    code_action                             = '<leader>ca',
    go_to_definition                        = 'gd',
    go_to_implementation                    = 'gi',
    show_references                         = 'gr',
    hovering_documentation                  = 'K',

    -- n
    toggle_file_explorer                    ='<c-n>',

    -- n
    leader_key                              = ';',

    -- n
    move_to_panel_left                      = '<c-h>',
    move_to_panel_down                      = '<c-j>',
    move_to_panel_up                        = '<c-k>',
    move_to_panel_right                     = '<c-l>',

    -- i, s
    autocomplete_abort                      = '<C-e>',
    autocomplete_confirm                    = '<C-j>',
    jump_forward_in_snippet                 = '<C-k>',
    jump_backward_in_snippet                = '<C-h>',
    jump_to_snippet_end                     = '<C-l>',
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
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.scrolloff = 8
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

    use 'hrsh7th/nvim-cmp'                  -- Autocompletion framework
    use 'hrsh7th/cmp-nvim-lsp'              -- Autocompletion lsp integration
    use 'folke/neodev.nvim'                 -- lsp integration with the nvim lua API

    use 'dcampos/nvim-snippy'               -- Snippet engine Handles the actual
                                            -- pasting of lsp suggestions. As well as custom snippets

    use 'dcampos/cmp-snippy'                -- nvim-cmp integration

    use {                                   -- LSP
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'neovim/nvim-lspconfig',
    }
    use { 'nvim-telescope/telescope.nvim',  -- FuzzyFind
        tag = '0.1.1',
        requires = {
            {'nvim-lua/plenary.nvim'},
        }
    }

    use{    "roodletoof/markdown-preview.nvim-asciimath",
            run = "cd app && npm install",
            setup = function() vim.g.mkdp_filetypes = { "markdown" } end,
            ft = { "markdown" }, }

    if packer_bootstrap then --Comes after packages
        require('packer').sync()
    end

    vim.g.mkdp_auto_start = 1

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
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        }
    }

    local cmp = require('cmp')
    local types = require('cmp.types')
    local snippy = require('snippy')

    cmp.setup{
        mapping = {
            ['<Down>'] = { i = cmp.mapping.select_next_item{ behavior = types.cmp.SelectBehavior.Select } },
            ['<Up>'] = { i = cmp.mapping.select_prev_item{ behavior = types.cmp.SelectBehavior.Select } },
            [keymap.autocomplete_abort]         = cmp.mapping(
                function (_)
                    cmp.mapping.abort()
                end,
                { "i", "s" }
            ),
            [keymap.autocomplete_confirm]       = cmp.mapping(
                function (_)
                    cmp.confirm{ select = true }
                end,
                { "i", "s" }
            ),
            [keymap.jump_backward_in_snippet]   = cmp.mapping(
                function (_)
                    if snippy.can_jump(-1) then
                        snippy.previous()
                    end
                end,
                { "i", "s" }
            ),
            [keymap.jump_forward_in_snippet]    = cmp.mapping(
                function(_)
                    if snippy.can_jump(1) then
                        snippy.next()
                    end
                end,
                { "i", "s" }
            ),
            [keymap.jump_to_snippet_end]        = cmp.mapping(
                function(_)
                    while snippy.can_jump(1) do
                        snippy.next()
                    end
                end,
                { "i", "s" }
            ),
        },
        snippet = {
            expand = function(args)
                snippy.expand_snippet(args.body)
            end,
        },
        sources = cmp.config.sources(
            {
                { name = 'nvim_lsp' },
                { name = 'snippy' }
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
            require("neodev").setup{} -- load the neovim api
            require("lspconfig").lua_ls.setup {
                capabilities = capabilities
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

    vim.g.python_indent = { -- Fixes retarded default python indentation.
        open_paren = 'shiftwidth()',
        nested_paren = 'shiftwidth()',
        continue = 'shiftwidth()',
        closed_paren_align_last_line = false,
        searchpair_timeout = 300,
    }
end

local function file_exists(name)
    local f = io.open(name,"r")

    if f~=nil then
        f:close()
        return true
    else
        return false
    end
end

-- Opens a default .snippets file for the filetype you are currently editing in a horizontal split pane.
-- If the .snippets file does not exist, it will be created.
-- This requires the snippets folder to exist in the config folder.
-- If the folder does not exist, the command will print out a helpful error message showing what the path
-- should look like.
vim.api.nvim_create_user_command(
    'S',
    function ()
        ---@type string
        local snippets_path = vim.fn.stdpath('config') .. '/snippets/' ..
                              vim.api.nvim_buf_get_option(0, "filetype") .. '.snippets'

        if not file_exists(snippets_path) then
            local file = io.open(snippets_path, 'w')
            assert(
                file ~= nil,
                ("io.open('%s', 'w') returned nil.\n"):format(snippets_path) ..
                "Make sure the snippets folder in the above path exists."
            )
            file:close()
            print('created file: ', snippets_path)
        end

        vim.api.nvim_command(('SnippyEdit %s'):format(snippets_path))
    end,
    { nargs = 0 }
)

return require('packer').startup(packer_startup)
