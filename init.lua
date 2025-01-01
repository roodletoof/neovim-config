-- GENERAL SETTINGS
do
	local leader_key = ','
	vim.g.mapleader = leader_key
	vim.g.maplocalleader = leader_key
end
vim.opt.tabstop = 8
vim.opt.shiftwidth = 0
vim.opt.rnu = true
vim.opt.nu = true
vim.opt.wrap = false
vim.opt.shiftround = true
vim.opt.expandtab = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.scrolloff = 8

vim.o.exrc = true       -- Enable local project configuration files
vim.o.secure = true     -- Disable potentially unsafe commands in .nvimrc

vim.api.nvim_set_option("clipboard", "unnamedplus")

ALPHABET_LOWER = 'abcdefghijklmnopqrstuvwxyz'
ALPHABET_UPPER = string.upper(ALPHABET_LOWER)
DIGITS = '0123456789'

for i = 1, #ALPHABET_LOWER do
	local lower = string.sub(ALPHABET_LOWER, i, i)
	local upper = string.sub(ALPHABET_UPPER, i, i)
	vim.api.nvim_set_keymap('n', 'm' .. lower, 'm' .. upper, {silent = true})
	vim.api.nvim_set_keymap('n', "'" .. lower, "'" .. upper, {silent = true})
end

do
	local function map_command(key, command)
		vim.api.nvim_set_keymap('n', key, '<cmd>'..command..'<CR>', {silent = true})
	end

	-- quickfix
	map_command('<leader>co', 'copen')
	map_command('<leader>cc', 'cclose')
	map_command('<leader>cf', 'cfirst')
	map_command('<leader>cl', 'clast')
	map_command('<leader>cn', 'cnext')
	map_command('<leader>cp', 'cprevious')

	-- folder navigation
	map_command('<leader>cd', 'cd %:p:h')
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

--move buffer to window
vim.cmd [[ nnoremap <leader>bh :let buf=bufnr('%')<CR><C-w>h:buffer <C-r>=buf<CR><CR> ]]
vim.cmd [[ nnoremap <leader>bj :let buf=bufnr('%')<CR><C-w>j:buffer <C-r>=buf<CR><CR> ]]
vim.cmd [[ nnoremap <leader>bk :let buf=bufnr('%')<CR><C-w>k:buffer <C-r>=buf<CR><CR> ]]
vim.cmd [[ nnoremap <leader>bl :let buf=bufnr('%')<CR><C-w>l:buffer <C-r>=buf<CR><CR> ]]

local function file_exists(name)
	local f = io.open(name,"r")
	if f~=nil then
		f:close()
		return true
	else
		return false
	end
end

do -- split line
	local SPLIT_WHITESPACE = '	'
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

	local split_line = function()
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

	vim.keymap.set(
		'n',
		"<leader>s",
		split_line,
		{ silent = true }
	)
end

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

require'lazy'.setup(
	{
		{ 'justinmk/vim-sneak', },
		{ 'michaeljsmith/vim-indent-object', },
		{ 'kylechui/nvim-surround',
			version = '*', -- Use for stability; omit to use `main` branch for the latest features
			event = 'VeryLazy',
			config = function()
				require('nvim-surround').setup{}
			end
		},
		{ 'sainnhe/everforest',
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
		{ 'nvim-telescope/telescope.nvim',
			tag = '0.1.8',
			dependencies = { 'nvim-lua/plenary.nvim', },
			config = function()
				vim.cmd [[
					noremap ,ff :lua require'telescope.builtin'.find_files()<CR>
					noremap ,fo :lua require'telescope.builtin'.oldfiles()<CR>
					noremap ,fg :lua require'telescope.builtin'.live_grep()<CR>
					noremap ,fz :lua require'telescope.builtin'.current_buffer_fuzzy_find()<CR>
					noremap ,fh :lua require'telescope.builtin'.help_tags()<CR>
					noremap ,fm :lua require'telescope.builtin'.man_pages()<CR>
				]]
			end,
		},
		{ 'neovim/nvim-lspconfig',
			config = function()
				require'lspconfig'.gopls.setup{}
				vim.cmd [[
					noremap ,rn :lua vim.lsp.buf.rename()<CR>
					noremap ,fd :lua vim.lsp.buf.definition()<CR>
					noremap ,ft :lua vim.lsp.buf.type_definition()<CR>
					noremap ,fr :lua vim.lsp.buf.references()<CR>
					noremap ,ca :lua vim.lsp.buf.code_action()<CR>
					noremap ,oe :lua vim.diagnostic.open_float()<CR>
					noremap ,fe :lua vim.diagnostic.setqflist()<CR>
				]]
			end
		},
		{ 'dcampos/nvim-snippy',
			config = function()
				require'snippy'.setup{ enable_auto = true, }
				vim.cmd [[
					imap <expr> <c-l> '<Plug>(snippy-expand-or-advance)'
					imap <expr> <c-k> '<Plug>(snippy-previous)'
					smap <expr> <c-l> '<Plug>(snippy-next)'
					smap <expr> <c-k> '<Plug>(snippy-previous)'
					xmap <Tab> <Plug>(snippy-cut-text)
				]]

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
			end
		},
	}
)
