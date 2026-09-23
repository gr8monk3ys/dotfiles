-- lua/plugins.lua
return {
	-- Plugin Manager (lazy.nvim manages itself)
	{ "folke/lazy.nvim", version = "*", lazy = false },

	-- Colorschemes
	{
		"navarasu/onedark.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			-- onedark.nvim's "dark" style is this checkout's structure, but its own
			-- hexes are OneDark's: the red and orange were retuned to Matisse
			-- vermilion and terracotta everywhere else. Every onedark colour with a
			-- palette counterpart is overridden from the rendered palette, so a
			-- retune reaches the editor too instead of only the two that differ today.
			local p = require("palette")
			require("onedark").setup({
				style = "dark",
				colors = {
					bg0 = p.bg,
					bg_d = p.bg_dark,
					bg3 = p.surface,
					fg = p.fg,
					grey = p.comment,
					blue = p.blue,
					cyan = p.cyan,
					green = p.green,
					yellow = p.yellow,
					purple = p.magenta,
					red = p.vermilion,
					orange = p.terracotta,
					diff_add = p.diff_add,
					diff_delete = p.diff_delete,
				},
			})
			require("onedark").load()
		end,
	},

	-- File Explorer
	{
		"kyazdani42/nvim-tree.lua", -- File tree sidebar (replaces netrw)
		cmd = { "NvimTreeToggle", "NvimTreeRefresh" },
		keys = {
			{ "<C-a>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file tree" },
			{ "<C-r>", "<cmd>NvimTreeRefresh<CR>", desc = "Refresh file tree" },
		},
		config = function()
			require("nvim-tree").setup({
				hijack_netrw = true,
				view = { width = 30 },
				renderer = { icons = { show = { git = true, folder = true, file = true, folder_arrow = true } } },
			})
		end,
		dependencies = { "nvim-tree/nvim-web-devicons" }, -- Icons for file tree
	},

	-- Which-Key (leader cheat-sheet)
	{
		"folke/which-key.nvim",
		dependencies = { "echasnovski/mini.icons" }, -- Icons for which-key
		event = "VeryLazy",
		config = function()
			require("which-key").setup({ plugins = { spelling = { enabled = true } } })
		end,
	},

	-- Formatting & lint helpers
	{ "stevearc/conform.nvim", event = "BufWritePre", config = false }, -- real config lives in lua/config/format.lua

	-- Fuzzy Finder (files, grep, etc.)
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		dependencies = { "nvim-lua/plenary.nvim" },

		-- Lazy‑load on these keymaps -------------------------------------------
		keys = {
			{
				"<C-p>",
				function()
					local builtin = require("telescope.builtin")
					-- recurse_submodules = true so git submodule contents are listed
					-- Try submodules first (requires *no* --others flag)
					local ok = pcall(builtin.git_files, { recurse_submodules = true })
					if not ok then
						-- Fallback: root-only but include untracked files
						ok = pcall(builtin.git_files, { show_untracked = true })
					end
					if not ok then
						builtin.find_files()
					end
					if not ok then
						builtin.find_files()
					end
				end,
				desc = "Find files (incl. dot‑files)",
			},
			{
				"<C-g>",
				function()
					require("telescope.builtin").live_grep()
				end,
				desc = "Live Grep",
			},
			{
				"<C-b>",
				function()
					require("telescope.builtin").git_branches()
				end,
				desc = "Git Branches",
			},
		},

		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				---------------------------------------------------------------------
				-- Defaults apply to *all* pickers ----------------------------------
				---------------------------------------------------------------------
				defaults = {
					prompt_prefix = "🔍 ",
					mappings = { i = { ["<Esc>"] = actions.close } },
					file_ignore_patterns = {
						"^%.git/", -- keep .git ignored
						"^%.idea/",
						"^%.vscode/",
						"^%.venv/",
						"^node_modules/",
						"^%.cache/",
						"%.DS_Store$",
						"^docs/html/",
					},
				},

				---------------------------------------------------------------------
				-- Picker‑specific overrides ----------------------------------------
				---------------------------------------------------------------------
				pickers = {
					-- :Telescope find_files
					find_files = {
						hidden = true, -- include dot‑files / dot‑dirs
						follow = true, -- follow symlinks
						no_ignore = false, -- still respect .gitignore & friends
						find_command = {
							"rg",
							"--files",
							"--hidden",
							"--glob",
							"!.git/*", -- keep .git out
							"--glob",
							".github/**", -- BUT keep everything under .github
							"--exclude",
							"docs/html/**",
						},
					},

					-- :Telescope live_grep
					live_grep = {
						additional_args = function()
							return {
								"--hidden",
								"--glob",
								"!.git/*",
								"--glob",
								".github/**",
								"--exclude",
								"docs/html/**",
							}
						end,
					},
				},
			})
		end,
	},

	-- Dashboard (start screen)
	{
		"nvimdev/dashboard-nvim", -- new repo name
		lazy = false, -- load immediately
		priority = 1001, -- after colorscheme (1000), before the rest
		config = function()
			local db = require("dashboard")
			db.setup({
				theme = "doom",
				config = {
					header = { "🦖  Baby Yosh Dashboard  🦖" },
					center = {
						{ desc = "  Find File           ", action = "Telescope find_files" },
						{ desc = "  Live Grep           ", action = "Telescope live_grep" },
						{ desc = "  File Explorer       ", action = "NvimTreeToggle" },
						{ desc = "  Git Branches        ", action = "Telescope git_branches" },
						{ desc = "  Quit                ", action = "qa" },
					},
				},
			})
		end,
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},

	-- Statusline and Bufferline
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		config = function()
			require("lualine").setup({
				options = { theme = "onedark", section_separators = "", component_separators = "" },
				extensions = { "nvim-tree", "quickfix" },
			})
		end,
		dependencies = { "nvim-tree/nvim-web-devicons" }, -- for file icons in statusline
	},
	{
		"akinsho/bufferline.nvim",
		event = "VeryLazy",
		config = function()
			require("bufferline").setup({
				options = {
					numbers = "none",
					diagnostics = "nvim_lsp",
					show_buffer_close_icons = false,
					show_close_icon = false,
				},
			})
		end,
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},

	-- Git integration
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				current_line_blame = true,
				on_attach = function(bufnr)
					local gs = package.loaded.gitsigns
					-- Navigate hunks with ]c/[c
					vim.keymap.set("n", "]c", function()
						gs.next_hunk()
					end, { buffer = bufnr, desc = "Next hunk" })
					vim.keymap.set("n", "[c", function()
						gs.prev_hunk()
					end, { buffer = bufnr, desc = "Prev hunk" })
					-- Stage/undo stage hunk
					vim.keymap.set("n", "<Leader>hs", gs.stage_hunk, { buffer = bufnr, desc = "Stage hunk" })
					vim.keymap.set("n", "<Leader>hu", gs.undo_stage_hunk, { buffer = bufnr, desc = "Undo stage hunk" })
					-- Preview hunk
					vim.keymap.set("n", "<Leader>hp", gs.preview_hunk, { buffer = bufnr, desc = "Preview hunk" })
				end,
			})
		end,
	},

	-- LSP (Language Server Protocol) and related plugins
	{
		"neovim/nvim-lspconfig", -- Collection of configurations for built-in LSP client
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			-- LSP UI enhancements
			{ "nvimdev/lspsaga.nvim", config = true }, -- LSP UIs (hover docs, code actions, rename, diagnostics, and floating terminal)
			-- Automatically install LSP servers (optional, e.g., mason.nvim could be used here)
		},
		config = function()
			-- nvim 0.11+ API. The `require("lspconfig").<server>.setup()` framework
			-- is deprecated and goes away in nvim-lspconfig v3.0.0; nvim-lspconfig
			-- now only ships the server definitions, and they are turned on with
			-- vim.lsp.enable(). See :help lspconfig-nvim-0.11.

			-- Customize diagnostic display (virtual text, signs, etc.)
			vim.diagnostic.config({ virtual_text = false, signs = true, float = { border = "rounded" } })
			-- Show diagnostic popup on hover
			vim.api.nvim_create_autocmd("CursorHold", {
				callback = function()
					vim.diagnostic.open_float(nil, { focusable = false })
				end,
			})

			-- Buffer-local LSP maps. LspAttach replaces the per-server on_attach
			-- the old framework threaded through every setup() call.
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufmap = function(mode, lhs, rhs, desc)
						vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
					end
					bufmap("n", "gd", vim.lsp.buf.definition, "Go to definition")
					bufmap("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
					bufmap("n", "gr", vim.lsp.buf.references, "Go to references")
					bufmap("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
					bufmap("n", "K", "<cmd>Lspsaga hover_doc<CR>", "Hover documentation")
					bufmap("n", "<Leader>ca", "<cmd>Lspsaga code_action<CR>", "Code Action")
					bufmap("n", "<Leader>rn", "<cmd>Lspsaga rename<CR>", "Rename symbol")
					bufmap("n", "<Leader>f", function()
						vim.lsp.buf.format({ async = true })
					end, "Format file")
				end,
			})

			-- Completion capabilities for nvim-cmp, applied to every server.
			vim.lsp.config("*", {
				capabilities = require("cmp_nvim_lsp").default_capabilities(),
			})

			-- KittyCAD KCL: no definition ships with nvim-lspconfig, so declare it.
			vim.lsp.config("kcl_ls", {
				cmd = { "kcl-language-server", "server", "--stdio" },
				filetypes = { "kcl" },
				root_markers = { ".git" },
			})

			-- Enable only servers whose binary is actually installed, so a missing
			-- toolchain is silence rather than a startup error.
			local servers = {
				gopls = "gopls",
				pyright = "pyright",
				rust_analyzer = "rust-analyzer",
				ts_ls = "typescript-language-server",
				clangd = "clangd",
				nixd = "nixd",
				kcl_ls = "kcl-language-server",
			}
			for server, binary in pairs(servers) do
				if vim.fn.executable(binary) == 1 then
					vim.lsp.enable(server)
				end
			end

			-- vim.lsp.enable() attaches via a FileType autocmd, but this plugin
			-- lazy-loads on BufReadPre — FileType has already fired for the buffer
			-- that triggered the load, so without this nudge the first file you
			-- open gets no LSP at all. The old setup() framework started the
			-- client itself, which is why the naive migration silently lost it.
			for _, buf in ipairs(vim.api.nvim_list_bufs()) do
				if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
					vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
				end
			end
		end,
	},

	-- Autocompletion framework and snippet engine
	{
		"petertriho/cmp-git",
		dependencies = { "hrsh7th/nvim-cmp" },
		opts = {
			filetypes = { "gitcommit" },
			remotes = { "upstream", "origin" }, -- in order of most to least prioritized
		},
		init = function()
			table.insert(require("cmp").get_config().sources, { name = "git" })
		end,
	},
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
			"hrsh7th/cmp-buffer", -- Buffer words completion
			"hrsh7th/cmp-path", -- File path completion
			"f3fora/cmp-spell", -- Spell suggestions source
			"saadparwaiz1/cmp_luasnip", -- Snippet completions
			"L3MON4D3/LuaSnip", -- Snippet engine (LuaSnip, replacing vim-vsnip)
			"rafamadriz/friendly-snippets", -- Collection of snippets for many languages
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			require("luasnip.loaders.from_vscode").lazy_load() -- Load VSCode-style snippets from friendly-snippets

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body) -- Use LuaSnip to expand snippet
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.close(),
					["<Down>"] = cmp.mapping(
						cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
						{ "i" }
					),
					["<Up>"] = cmp.mapping(
						cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
						{ "i" }
					),
					["<CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
					{ name = "spell" },
				}),
			})
		end,
	},

	-- AI Assistant (GitHub Copilot) - using Lua plugin for better integration
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = { auto_trigger = true, keymap = { accept = "<Tab>" } },
			})
		end,
	},

	-- Editing enhancements
	{ "kylechui/nvim-surround", event = "VeryLazy", config = true }, -- Surround text objects easily (replaces tpope/vim-surround)
	{ "tpope/vim-endwise", ft = { "ruby", "vim", "lua", "zsh" } }, -- Automatically add "end" in certain filetypes (Ruby, etc.)
	{ "mg979/vim-visual-multi", branch = "master", keys = { "<C-n>", "<C-down>", "<C-up>" } }, -- Multi-cursor editing (Ctrl-N to add cursors)
	{ "stevearc/dressing.nvim", event = "VeryLazy", config = true }, -- Better UI for vim.ui (input/select) dialogs
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl", -- tells lazy.nvim the module name changed
		event = "BufReadPost",
		opts = {
			indent = { char = "│" }, -- or leave blank for default ▏
			scope = { enabled = false }, -- disable rainbow scope lines if you like
		},
	},

	-- Syntax and Language Support (Tree-sitter and filetype plugins)
	{
		"nvim-treesitter/nvim-treesitter",
		-- Pinned to master: the `main` branch is a ground-up rewrite that
		-- removed `nvim-treesitter.configs`, so the declarative setup below
		-- (ensure_installed / highlight / indent) does not exist there. lazy
		-- had resolved main, so this block errored on every startup and
		-- treesitter highlighting and indent were silently off.
		branch = "master",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = {
					-- "bash", not "zsh": there is no zsh parser, and the bash
					-- one handles zsh files. The old entry made treesitter
					-- print "Parser not available for language \"zsh\"" on every
					-- startup while shell files got no highlighting at all.
					"bash",
					"c",
					"cmake",
					"cpp",
					"css",
					"csv",
					"diff",
					"dockerfile",
					"gitcommit",
					"gitignore",
					"go",
					"javascript",
					"jinja",
					"json",
					"lua",
					"markdown",
					"markdown_inline",
					"nginx",
					"nix",
					"proto",
					"python",
					"rust",
					"terraform",
					"toml",
					"tsx",
					"typescript",
					"yaml",
				},
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
}
