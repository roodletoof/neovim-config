-- GENERAL SETTINGS
vim.cmd [[ autocmd VimEnter * NoMatchParen ]]
do
    local leader_key = ','
    vim.g.mapleader = leader_key
    vim.g.maplocalleader = leader_key
end
vim.opt.tabstop = 4
vim.opt.shiftwidth = 0
vim.opt.rnu = true
vim.opt.nu = true
vim.opt.wrap = false
vim.opt.shiftround = true
vim.opt.expandtab = true
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.scrolloff = 8

vim.api.nvim_set_option("clipboard", "unnamedplus")

-- highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', {}),
  desc = 'Hightlight selection on yank',
  pattern = '*',
  callback = function()
    vim.highlight.on_yank { higroup = 'IncSearch', timeout = 180 }
  end,
})

ALPHABET_LOWER = 'abcdefghijklmnopqrstuvwxyz'
ALPHABET_UPPER = string.upper(ALPHABET_LOWER)
DIGITS = '0123456789'

do
    local move_left = '<c-h>'
    local move_down = '<c-j>'
    local move_up = '<c-k>'
    local move_right = '<c-l>'

    vim.api.nvim_set_keymap('n', move_left, '<cmd>wincmd h<CR>', {silent = true})
    vim.api.nvim_set_keymap('n', move_down, '<cmd>wincmd j<CR>', {silent = true})
    vim.api.nvim_set_keymap('n', move_up, '<cmd>wincmd k<CR>', {silent = true})
    vim.api.nvim_set_keymap('n', move_right, '<cmd>wincmd l<CR>', {silent = true})

    vim.api.nvim_set_keymap('t', move_left, '<cmd>wincmd h<CR>', {silent = true})
    vim.api.nvim_set_keymap('t', move_down, '<cmd>wincmd j<CR>', {silent = true})
    vim.api.nvim_set_keymap('t', move_up, '<cmd>wincmd k<CR>', {silent = true})
    vim.api.nvim_set_keymap('t', move_right, '<cmd>wincmd l<CR>', {silent = true})
end

do -- always global marks
    for i = 1, #ALPHABET_LOWER do
        local lower = string.sub(ALPHABET_LOWER, i, i)
        local upper = string.sub(ALPHABET_UPPER, i, i)
        vim.api.nvim_set_keymap('n', 'm' .. lower, 'm' .. upper, {silent = true})
        vim.api.nvim_set_keymap('n', "'" .. lower, "'" .. upper, {silent = true})
    end
end

do -- building, errors and folder navigation
    ---comment
    ---@param key string
    ---@param command string
    local function map(key, command)
        local prefix = '<leader>'
        vim.api.nvim_set_keymap('n', prefix .. key, '<cmd>'..command..'<CR>', {silent = true})
    end

    map('co', 'copen')
    map('cc', 'cclose')
    map('cf', 'cfirst')
    map('cl', 'clast')
    map('cn', 'cnext')
    map('cp', 'cprevious')
    map('cd', 'cd %:p:h')
    map('m', 'make')

end

vim.api.nvim_set_keymap('t', '<esc>', '<C-\\><C-n>', {silent = true})
vim.cmd [[ autocmd BufEnter * if &buftype == 'terminal' | :startinsert | endif ]]

vim.cmd [[ autocmd BufWinLeave *.* silent! mkview ]]
vim.cmd [[ autocmd BufWinEnter *.* silent! loadview ]]

vim.g.c_syntax_for_h = 1
vim.g.python_indent = { -- Fixes retarded default python indentation.
    open_paren = 'shiftwidth()',
    nested_paren = 'shiftwidth()',
    continue = 'shiftwidth()',
    closed_paren_align_last_line = false,
    searchpair_timeout = 300,
}

vim.o.exrc = true -- Allows project specific .nvim.lua config files.

--better scrolling
vim.cmd [[ noremap <c-d> <c-d>M0w ]]
vim.cmd [[ noremap <c-u> <c-u>M0w ]]

--move buffer to window
vim.cmd [[ nnoremap <leader>bh :let buf=bufnr('%')<CR><C-w>h:buffer <C-r>=buf<CR><CR> ]]
vim.cmd [[ nnoremap <leader>bj :let buf=bufnr('%')<CR><C-w>j:buffer <C-r>=buf<CR><CR> ]]
vim.cmd [[ nnoremap <leader>bk :let buf=bufnr('%')<CR><C-w>k:buffer <C-r>=buf<CR><CR> ]]
vim.cmd [[ nnoremap <leader>bl :let buf=bufnr('%')<CR><C-w>l:buffer <C-r>=buf<CR><CR> ]]

vim.cmd [[ autocmd FileType * set formatoptions-=cro ]] -- Disable automatic comment.

-- HELPER FUNCTIONS
---@param name string
---@return boolean
local function file_exists(name)
    local f = io.open(name,"r")

    if f~=nil then
        f:close()
        return true
    else
        return false
    end
end

-- SNIPPET EDIT FUNCTIONALITY. REQUIRES SNIPPY.
-- Opens a default .snippets file for the filetype you are currently editing in a horizontal split pane.
-- If the .snippets file does not exist, it will be created.
-- This requires the snippets folder to exist in the config folder.
-- If the folder does not exist, the command will print out a helpful error message showing what the path
-- should look like.
vim.api.nvim_create_user_command(
    'S',
    function ()
        ---@type string
        local snippets_path = vim.fn.stdpath('config') .. '/snippets/' .. vim.api.nvim_buf_get_option(0, "filetype") .. '.snippets'

        if not file_exists(snippets_path) then
            local file = io.open( snippets_path, 'w' )
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

-- JSON2GO COMMAND. CONVERT SELECTED JSON INTO A GO STRUCT BY USING JSON2STRUCT TERMINAL COMMAND. (INSTALL SEPARATELEY)
vim.api.nvim_create_user_command(
    'Json2go',
    function(opts)
        local lstart = opts.line1 - 1
        local lend = opts.line2
        local lines = vim.api.nvim_buf_get_lines(
            vim.api.nvim_get_current_buf(),
            lstart,
            lend,
            false
        )
        local lines_str = vim.fn.join(lines, ' ')
        lines_str = lines_str:gsub('\\', '\\\\')
        lines_str = lines_str:gsub("'", "\\'")
        ---@type string[]
        local struct_lines = {}

        local file = io.popen( "json2struct -s " .. "'" .. lines_str .. "'", "r" )
        assert(file ~= nil)
        for line in file:lines() do
            table.insert(struct_lines, line)
        end
        file:close()

        vim.api.nvim_buf_set_lines(0, lstart, lend, false, struct_lines)

    end,
    { range = true }
)

-- EXECUTE PROJECT SPECIFIC SCRIPTS
do
    ---Returns function that runs the given script_name in the current working directory.
    ---Only implemented for Linux. ( Uses the sh command )
    ---@param script_name string
    ---@return fun() 
    local function get_run_script_function(script_name)
        return function()
            ---@type "Linux" | "Darwin" | "Windows_NT"
            local os_name = vim.loop.os_uname().sysname
            if os_name == "Windows_NT" then
                error('run_file not implemented for non-unix platforms')
            end

            local run_script_path = vim.fn.getcwd() .. "/" .. script_name
            if not file_exists(run_script_path) then
                error(
                    "The run script: '" .. run_script_path .. "' does not exist.\n"..
                    "All this command does, is to execute that file."
                )
            end

            vim.cmd([[ TermExec cmd="sh ]].. run_script_path ..[[" direction=vertical size=80 ]])
        end
    end

    -- To create a script that runs when typing the command "<leader>er",
    -- create a script called ".r.sh" in the current directory.
    local characters = ALPHABET_LOWER .. ALPHABET_UPPER .. DIGITS
    for i = 1, #characters do
        local char = characters:sub(i, i)
        vim.keymap.set(
            'n',
            "<leader>e" .. char,
            get_run_script_function("." .. char .. ".sh"),
            { silent = true }
        )
    end
end

-- SPLIT LINE FUNCTIONALITY
---@type function
local split_line
do

    -- split_line settings
    local SPLIT_WHITESPACE = '    '
    local SPLIT_DELIMETERS = { -- single characters only
        [','] = true,
        [';'] = true,
    }
    local SPLIT_BETWEEN = { -- single characters only
        ['('] = ')',
        ['['] = ']',
        ['{'] = '}',
    }
    local SPLIT_IGNORE_BETWEEN = { --single characters only
        ['"'] = '"',
        ["'"] = "'",
    }

    split_line = function()
        local line = vim.api.nvim_get_current_line()
        local _, col =  unpack(vim.api.nvim_win_get_cursor(0))
        col = col + 1 -- Doing this to make it 1-indexed

        ---@type integer?
        local first_bracket_i = nil
        for i = col, #line do
            local char = line:sub(i, i)
            if SPLIT_BETWEEN[char] ~= nil then
                first_bracket_i = i
                break
            end
        end

        if not first_bracket_i then
            print('No opening brackets found after cursor on this line.')
            return
        end

        ---@type integer[]
        local split_indexes = {} -- Populate this array
        ---@type integer?
        local last_bracket_i = nil -- And find this index

        do
            ---@type string[]
            local closing_bracket_stack = {}
            local icon_to_close_ignore = ''
            local in_ignore = false

            for i = first_bracket_i, #line do
                local char = line:sub(i,i)

                if in_ignore then
                    in_ignore = not (char == icon_to_close_ignore)
                    goto continue
                end

                if SPLIT_IGNORE_BETWEEN[char] ~= nil then
                    icon_to_close_ignore = SPLIT_IGNORE_BETWEEN[char]
                    in_ignore = true
                    goto continue
                end
                -- string handling complete

                if SPLIT_BETWEEN[char] ~= nil then
                    table.insert(
                        closing_bracket_stack,
                        SPLIT_BETWEEN[char]
                    )
                end

                if char == closing_bracket_stack[#closing_bracket_stack] then
                    table.remove(closing_bracket_stack)
                end

                if #closing_bracket_stack == 1 and SPLIT_DELIMETERS[char] then
                    table.insert(split_indexes, i)
                end

                if #closing_bracket_stack == 0 then
                    last_bracket_i = i
                    break
                end
                ::continue::
            end
        end

        if not last_bracket_i then
            print("The first opening bracket found after the cursor was not closed on this line.")
            return
        end
        if #split_indexes == 0 then
            print('No comma separated items within brackets that were opened and closed after the cursor.')
            return
        end

        ---@type string
        local leading_whitespace = string.match(line, "^%s*")
        local first_line = line:sub(1, first_bracket_i)
        local last_line = leading_whitespace .. line:sub(last_bracket_i, #line)

        local middle_lines = {}
        table.insert(
            middle_lines,
            line:sub(first_bracket_i+1, split_indexes[1])
        )
        for i = 1, #split_indexes-1 do
            table.insert(
                middle_lines,
                line:sub(split_indexes[i], split_indexes[i+1])
            )
        end
        table.insert(
            middle_lines,
            line:sub(split_indexes[#split_indexes], last_bracket_i-1)
        )

        local leading_pattern = "^[%s"
        for k, _ in pairs(SPLIT_DELIMETERS) do
            leading_pattern = leading_pattern .. k
        end
        leading_pattern = leading_pattern .. "]*"

        -- Cleanup step
        for i, middle_line in ipairs(middle_lines) do
            middle_line = middle_line:gsub(leading_pattern, leading_whitespace .. SPLIT_WHITESPACE, 1)
            middle_line = middle_line:gsub("[%s]*$", '', 1)
            middle_lines[i] = middle_line
        end

        local row, _ = unpack(vim.api.nvim_win_get_cursor(0))
        vim.api.nvim_buf_set_lines(0, row-1, row, false, {first_line})
        vim.api.nvim_buf_set_lines(0, row, row, false, {last_line})
        vim.api.nvim_buf_set_lines(0, row, row, false, middle_lines)
    end
end

vim.keymap.set(
    'n',
     "<leader>s",
    split_line,
    { silent = true }
)

-- LAZY.NVIM BOOTSTRAP
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

--=> This package requires additional configuration for use in editors. Install package
--   'user-setup', or manually:
--   * for Vim, add this line to ~/.vimrc:
--     set rtp^="/home/ivarfatland/.opam/default/share/ocp-indent/vim"

require('lazy').setup(
    {
        { 'neovim/nvim-lspconfig',
            dependencies = {
                "Hoffs/omnisharp-extended-lsp.nvim"
            },
            config = function()
                local lspconfig = require('lspconfig')
                lspconfig.lua_ls.setup{
                    settings = {
                        Lua = {
                            runtime = {
                                version = 'LuaJIT'
                            },
                            diagnostics = {
                                globals = {
                                    'vim'
                                }
                            },
                            workspace = {
                                checktirdparty = true,
                                library = {
                                    vim.env.VIMRUNTIME
                                }
                            }
                        }
                    }
                }
                lspconfig.gopls.setup{}
                lspconfig.pyright.setup{}
                -- lspconfig.csharp_ls.setup{} -- install with: "dotnet tool install --global csharp-ls"
                -- TODO ALSO TELESCOPE
                -- https://github.com/Hoffs/omnisharp-extended-lsp.nvim
                lspconfig.omnisharp.setup {
                    cmd = { "dotnet", "/Users/ivar.fatland/bin/omnisharp/OmniSharp.dll"},

                    settings = {
                        FormattingOptions = {
                            -- Enables support for reading code style, naming convention and analyzer
                            -- settings from .editorconfig.
                            EnableEditorConfigSupport = true,
                            -- Specifies whether 'using' directives should be grouped and sorted during
                            -- document formatting.
                            OrganizeImports = nil,
                        },
                        MsBuild = {
                            -- If true, MSBuild project system will only load projects for files that
                            -- were opened in the editor. This setting is useful for big C# codebases
                            -- and allows for faster initialization of code navigation features only
                            -- for projects that are relevant to code that is being edited. With this
                            -- setting enabled OmniSharp may load fewer projects and may thus display
                            -- incomplete reference lists for symbols.
                            LoadProjectsOnDemand = nil,
                        },
                        RoslynExtensionsOptions = {
                            -- Enables support for roslyn analyzers, code fixes and rulesets.
                            EnableAnalyzersSupport = nil,
                            -- Enables support for showing unimported types and unimported extension
                            -- methods in completion lists. When committed, the appropriate using
                            -- directive will be added at the top of the current file. This option can
                            -- have a negative impact on initial completion responsiveness,
                            -- particularly for the first few completion sessions after opening a
                            -- solution.
                            EnableImportCompletion = nil,
                            -- Only run analyzers against open files when 'enableRoslynAnalyzers' is
                            -- true
                            AnalyzeOpenDocumentsOnly = nil,
                        },
                        Sdk = {
                            -- Specifies whether to include preview versions of the .NET SDK when
                            -- determining which version to use for project loading.
                            IncludePrereleases = true,
                        },
                    },
                }
                lspconfig.gdscript.setup{}
                lspconfig.clangd.setup{
                    cmd = { "clangd", "--compile-commands-dir=build" }, -- Specify the directory of compile_commands.json
                    filetypes = { "c", "cpp", "objc", "objcpp" },
                    root_dir = lspconfig.util.root_pattern("compile_commands.json", ".git"),
                }
                lspconfig.sqlls.setup{}
                lspconfig.rust_analyzer.setup{}
                lspconfig.hls.setup{
                    filetypes = { 'haskell', 'lhaskell', 'cabal' }
                }

                vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Perform code action" })
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename token under cursor" })

                function OpenDiagnosticIfNoFloat()
                    for _, winid in pairs(vim.api.nvim_tabpage_list_wins(0)) do
                        if vim.api.nvim_win_get_config(winid).zindex then
                            return
                        end
                    end
                    -- THIS IS FOR BUILTIN LSP
                    vim.diagnostic.open_float{
                        scope = "cursor",
                        focusable = false,
                        close_events = {
                            "CursorMoved",
                            "CursorMovedI",
                            "BufHidden",
                            "InsertCharPre",
                            "WinLeave",
                        },
                    }
                end
                vim.keymap.set("n", "<leader>oe", OpenDiagnosticIfNoFloat, { desc = "Show full error in floating window" })
            end,
        },
        { 'dcampos/nvim-snippy',
            config = function()
                require('snippy').setup({
                    enable_auto = true,
                    mappings = {
                        nx = {
                            ['<leader>x'] = 'cut_text',
                        },
                    },
                })
            end
        },
        { 'hrsh7th/nvim-cmp',
            dependencies = {
                'dcampos/cmp-snippy',
                'hrsh7th/cmp-nvim-lsp'
            },
            config = function()
                local cmp = require('cmp')
                local snippy = require('snippy')
                cmp.setup{
                    snippet = {
                        expand = function(args)
                            snippy.expand_snippet(args.body)
                        end,
                    },
                    sources = {
                        {name = 'snippy'},
                        {name = 'nvim_lsp'},
                    },
                    mapping = {
                        ['<c-j>'] = cmp.mapping(function (_) cmp.confirm({select = true}) end, { "i", "s" }),
                        ['<c-k>'] = cmp.mapping(function (_) snippy.next() end, { "i", "s" }),
                        ['<c-h>'] = cmp.mapping(function (_) snippy.previous() end, { "i", "s" }),
                        ['<c-d>'] = cmp.mapping.scroll_docs(4),
                        ['<c-u>'] = cmp.mapping.scroll_docs(-4),
                        ['<c-n>'] = cmp.mapping.select_next_item(),
                        ['<c-p>'] = cmp.mapping.select_prev_item(),
                    },
                }
            end,
        },
        { 'kylechui/nvim-surround',
            version = '*', -- Use for stability; omit to use `main` branch for the latest features
            event = 'VeryLazy',
            config = function()
                require('nvim-surround').setup({
                    -- Configuration here, or leave empty to use defaults
                })
            end
        },
        { 'nvim-treesitter/nvim-treesitter',
            build = ':TSUpdate',
            config = function ()
                local configs = require('nvim-treesitter.configs')

                configs.setup({
                    ensure_installed = 'all',
                    sync_install = false,
                    highlight = { enable = true },
                    indent = { enable = true },
                })
            end,
        },
        { 'nvim-telescope/telescope.nvim',
            tag = '0.1.6',
            dependencies = {
                'nvim-lua/plenary.nvim',
                'Hoffs/omnisharp-extended-lsp.nvim'
            },
            config = function()
                local builtin = require('telescope.builtin')

                ---@param key string
                ---@param fun function
                local map = function(key, fun)
                    vim.keymap.set('n', '<leader>f' .. key, fun, {})
                end

                map('f', builtin.find_files)
                map('o', builtin.oldfiles)
                map('g', builtin.live_grep)
                map('b', builtin.buffers)
                map('h', builtin.help_tags)
                map('m', builtin.man_pages)

                local function cswrapper(default, cs)
                    -- TODO cs is null for some reason...

                    return function(...)
                        if vim.api.nvim_buf_get_option(0, "filetype") == 'cs' then
                            cs(...)
                        else
                            default(...)
                        end
                    end
                end

                local omnisharp_extended = require('omnisharp_extended')

                map('r', cswrapper(builtin.lsp_references, omnisharp_extended.telescope_lsp_references))
                map('d', cswrapper(builtin.lsp_definitions, omnisharp_extended.telescope_lsp_definitions))
                map('t', cswrapper(builtin.lsp_type_definitions, omnisharp_extended.telescope_lsp_type_definitions))
                map('i', cswrapper(builtin.lsp_implementations, omnisharp_extended.telescope_lsp_implementations))

                -- map('r', builtin.lsp_references)
                -- map('d', builtin.lsp_definitions)
                -- map('t', builtin.lsp_type_definitions)
                -- map('i', builtin.lsp_implementations)

                map('s', builtin.lsp_document_symbols)
                map('e', builtin.diagnostics)

            end,
        },
        { 'sainnhe/everforest', -- THE THEME SETUP
            lazy = false,
            priority = 1000,
            config = function()
                vim.o.termguicolors = true
                vim.g.everforest_enable_italic = true
                vim.cmd.colorscheme('everforest')
            end,
        },
        { 'folke/zen-mode.nvim',
            config = function ()
                vim.keymap.set(
                    'n',
                    "<leader>z",
                    vim.cmd.ZenMode,
                    { silent = true }
                )
            end
        },
        { 'stevearc/oil.nvim',
            dependencies = { 'nvim-tree/nvim-web-devicons', },
            config = function ()
                local oil = require('oil')
                oil.setup{
                    default_file_explorer = true,
                    columns = {'icon'},
                    view_options = {
                        show_hidden = true,
                    },
                }
                vim.keymap.set("n", "-", vim.cmd.Oil, { desc = "Open parent directory" })
            end,
        },
        { 'akinsho/toggleterm.nvim',
            version = "*",
            config = function ()
                require('toggleterm').setup{
                    direction = 'vertical',
                    size = 80,
                }
                vim.keymap.set("n", "<leader>t", vim.cmd.ToggleTerm, { desc = "Toggle terminal" })
            end,
        },
        { 'michaeljsmith/vim-indent-object',
        },
        { "iamcco/markdown-preview.nvim",
            cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
            build = "cd app && yarn install",
            init = function()
                vim.g.mkdp_filetypes = { "markdown" }
            end,
            ft = { "markdown" },
            config = function ()
                vim.keymap.set('n', '<leader>md', ':MarkdownPreviewToggle<cr>', {})
            end,
        },
        { 'justinmk/vim-sneak',
        }
    }
)
