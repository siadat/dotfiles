--[[

=====================================================================
==================== READ THIS BEFORE CONTINUING ====================
=====================================================================

Kickstart.nvim is *not* a distribution.

Kickstart.nvim is a template for your own configuration.
  The goal is that you can read every line of code, top-to-bottom, understand
  what your configuration is doing, and modify it to suit your needs.

  Once you've done that, you should start exploring, configuring and tinkering to
  explore Neovim!

  If you don't know anything about Lua, I recommend taking some time to read through
  a guide. One possible example:
  - https://learnxinyminutes.com/docs/lua/


  And then you can explore or search through `:help lua-guide`
  - https://neovim.io/doc/user/lua-guide.html


Kickstart Guide:

I have left several `:help X` comments throughout the init.lua
You should run that command and read that help section for more information.

In addition, I have some `NOTE:` items throughout the file.
These are for you, the reader to help understand what is happening. Feel free to delete
them once you know what you're doing, but they should serve as a guide for when you
are first encountering a few different constructs in your nvim config.

I hope you enjoy your Neovim journey,
- TJ

P.S. You can delete this when you're done too. It's your config now :)
--]]

-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- [[ Install `lazy.nvim` plugin manager ]]
--    https://github.com/folke/lazy.nvim
--    `:help lazy.nvim.txt` for more info
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

-- [[ Configure plugins ]]
-- NOTE: Here is where you install your plugins.
--  You can configure plugins using the `config` key.
--
--  You can also configure plugins after the setup call,
--    as they will be available in your neovim runtime.

local python_diagnostic_plugin = {
  "siadat/python-diagnostic.nvim",
  dev = vim.fn.hostname() == "personalbox",
  config = function()
    require('python-diagnostic').setup({
      command = "poetry run pytest --tb native",
    })
    vim.api.nvim_create_autocmd({"BufReadPost"}, {
      pattern = "*.py",
      command = "PythonTestOnSave",
    })
  end,
}

require('lazy').setup({
  -- {
  --   "mcchrish/zenbones.nvim",
  --   dependencies = {
  --     "rktjmp/lush.nvim",
  --   },
  --   config = function()
  --     if vim.fn.hostname() == "personalbox" then
  --       vim.cmd [[set background=light]]
  --       vim.cmd [[colorscheme zenbones]]
  --     end
  --   end,
  -- },
  -- 'HiPhish/nvim-ts-rainbow2',
  {
    "ray-x/go.nvim",
    dependencies = {  -- optional packages
      "ray-x/guihua.lua",
      "neovim/nvim-lspconfig",
      "nvim-treesitter/nvim-treesitter",
    },
    config = function()
      require("go").setup()
    end,
    event = {"CmdlineEnter"},
    ft = {"go", 'gomod'},
    build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
  },
  {
    "scalameta/nvim-metals",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    ft = { "scala", "sbt", "java" },
    opts = function()
      local metals_config = require("metals").bare_config()
      metals_config.on_attach = function(client, bufnr)
	-- your on_attach function
      end

      return metals_config
    end,
    config = function(self, metals_config)
      local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
	pattern = self.ft,
	callback = function()
	  require("metals").initialize_or_attach(metals_config)
	end,
	group = nvim_metals_group,
      })
    end
  },
  {
    "julienvincent/nvim-paredit",
    config = function()
      local paredit = require("nvim-paredit")
      paredit.setup({
	-- should plugin use default keybindings? (default = true)
	use_default_keys = true,
	-- sometimes user wants to restrict plugin to certain file types only
	-- defaults to all supported file types including custom lang
	-- extensions (see next section)
	filetypes = { "clojure" },

	-- This controls where the cursor is placed when performing slurp/barf operations
	--
	-- - "remain" - It will never change the cursor position, keeping it in the same place
	-- - "follow" - It will always place the cursor on the form edge that was moved
	-- - "auto"   - A combination of remain and follow, it will try keep the cursor in the original position
	--              unless doing so would result in the cursor no longer being within the original form. In
	--              this case it will place the cursor on the moved edge
	cursor_behaviour = "auto", -- remain, follow, auto

	indent = {
	  -- This controls how nvim-paredit handles indentation when performing operations which
	  -- should change the indentation of the form (such as when slurping or barfing).
	  --
	  -- When set to true then it will attempt to fix the indentation of nodes operated on.
	  enabled = false,
	  -- A function that will be called after a slurp/barf if you want to provide a custom indentation
	  -- implementation.
	  indentor = require("nvim-paredit.indentation.native").indentor,
	},

	-- list of default keybindings
	keys = {
	  ["<localleader>@"] = { paredit.unwrap.unwrap_form_under_cursor, "Splice sexp" },
	  [">)"] = { paredit.api.slurp_forwards, "Slurp forwards" },
	  [">("] = { paredit.api.barf_backwards, "Barf backwards" },

	  ["<)"] = { paredit.api.barf_forwards, "Barf forwards" },
	  ["<("] = { paredit.api.slurp_backwards, "Slurp backwards" },

	  [">e"] = { paredit.api.drag_element_forwards, "Drag element right" },
	  ["<e"] = { paredit.api.drag_element_backwards, "Drag element left" },

	  [">f"] = { paredit.api.drag_form_forwards, "Drag form right" },
	  ["<f"] = { paredit.api.drag_form_backwards, "Drag form left" },

	  ["<localleader>o"] = { paredit.api.raise_form, "Raise form" },
	  ["<localleader>O"] = { paredit.api.raise_element, "Raise element" },

	  ["E"] = {
	    paredit.api.move_to_next_element_tail,
	    "Jump to next element tail",
	    -- by default all keybindings are dot repeatable
	    repeatable = false,
	    mode = { "n", "x", "o", "v" },
	  },
	  ["W"] = {
	    paredit.api.move_to_next_element_head,
	    "Jump to next element head",
	    repeatable = false,
	    mode = { "n", "x", "o", "v" },
	  },

	  ["B"] = {
	    paredit.api.move_to_prev_element_head,
	    "Jump to previous element head",
	    repeatable = false,
	    mode = { "n", "x", "o", "v" },
	  },
	  ["gE"] = {
	    paredit.api.move_to_prev_element_tail,
	    "Jump to previous element tail",
	    repeatable = false,
	    mode = { "n", "x", "o", "v" },
	  },

	  ["("] = {
	    paredit.api.move_to_parent_form_start,
	    "Jump to parent form's head",
	    repeatable = false,
	    mode = { "n", "x", "v" },
	  },
	  [")"] = {
	    paredit.api.move_to_parent_form_end,
	    "Jump to parent form's tail",
	    repeatable = false,
	    mode = { "n", "x", "v" },
	  },

	  -- These are text object selection keybindings which can used with standard `d, y, c`, `v`
	  ["af"] = {
	    paredit.api.select_around_form,
	    "Around form",
	    repeatable = false,
	    mode = { "o", "v" }
	  },
	  ["if"] = {
	    paredit.api.select_in_form,
	    "In form",
	    repeatable = false,
	    mode = { "o", "v" }
	  },
	  ["aF"] = {
	    paredit.api.select_around_top_level_form,
	    "Around top level form",
	    repeatable = false,
	    mode = { "o", "v" }
	  },
	  ["iF"] = {
	    paredit.api.select_in_top_level_form,
	    "In top level form",
	    repeatable = false,
	    mode = { "o", "v" }
	  },
	  ["ae"] = {
	    paredit.api.select_element,
	    "Around element",
	    repeatable = false,
	    mode = { "o", "v" },
	  },
	  ["ie"] = {
	    paredit.api.select_element,
	    "Element",
	    repeatable = false,
	    mode = { "o", "v" },
	  },
          -- additional blah blah
          -- why the f* does it have to be so hard?
	  ["<localleader>w"] = {
	    function()
	      -- place cursor and set mode to `insert`
	      paredit.cursor.place_cursor(
		-- wrap element under cursor with `( ` and `)`
		paredit.wrap.wrap_element_under_cursor("( ", ")"),
		-- cursor placement opts
		{ placement = "inner_start", mode = "insert" }
	      )
	    end,
	    "Wrap element insert head",
	  },

	  ["<localleader>W"] = {
	    function()
	      paredit.cursor.place_cursor(
		paredit.wrap.wrap_element_under_cursor("(", ")"),
		{ placement = "inner_end", mode = "insert" }
	      )
	    end,
	    "Wrap element insert tail",
	  },

	  -- same as above but for enclosing form
	  ["<localleader>i"] = {
	    function()
	      paredit.cursor.place_cursor(
		paredit.wrap.wrap_enclosing_form_under_cursor("( ", ")"),
		{ placement = "inner_start", mode = "insert" }
	      )
	    end,
	    "Wrap form insert head",
	  },

	  ["<localleader>I"] = {
	    function()
	      paredit.cursor.place_cursor(
		paredit.wrap.wrap_enclosing_form_under_cursor("(", ")"),
		{ placement = "inner_end", mode = "insert" }
	      )
	    end,
	    "Wrap form insert tail",
	  }
	}
      })
    end
  },
  {
    -- Amazing, source: https://youtu.be/uBTRLBU-83A?si=MK1LUI5aAYu830K8&t=6605
    'gpanders/nvim-parinfer',
  },
  -- 'Olical/conjure',
  {
    "shellpad/shellpad.nvim",
    dev = vim.fn.hostname() == "personalbox",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function(opts)
      require('shellpad').setup(opts)
      vim.keymap.set('n', '<leader>sc', require('shellpad').telescope_history_search(), { desc = '[S]earch [C]ommands' })
    end,
  },
  {
    "treemotion/treemotion.nvim",
    dev = vim.fn.hostname() == "personalbox",
    enabled = vim.fn.hostname() == "personalbox",
    config = function(opts)
      require('treemotion').setup(opts)
    end,
  },
  {
    "filepad/filepad.nvim",
    dev = vim.fn.hostname() == "personalbox",
    enabled = vim.fn.hostname() == "personalbox",
    config = function(opts)
      require('filepad').setup(opts)
    end,
  },
  -- {
  --   "siadat/animated-resize.nvim",
  --   opts = {},
  --   dev = true,
  -- },
  -- NOTE: First, some plugins that don't require any configuration

  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',
  -- {
  --   'stevearc/oil.nvim',
  --   opts = {
  --     -- copied from https://github.com/stevearc/oil.nvim/blob/18dfd24/README.md
  --     columns = {
  --       -- "icon", -- sina: icons don't render properly for me
  --       -- "permissions",
  --       -- "size",
  --       -- "mtime",
  --     },
  --     { ["v"] = "actions.select_vsplit", }, -- sina: it was ["<C-s>"]
  --   },
  --   -- Optional dependencies
  --   -- dependencies = { "nvim-tree/nvim-web-devicons" },
  -- },
  {
    'L3MON4D3/LuaSnip',
    config = function()
      -- Copied from https://github.com/L3MON4D3/LuaSnip/blob/a7a4b46/Examples/snippets.lua#L190
      local ls = require("luasnip")
      local s = ls.snippet
      local sn = ls.snippet_node
      local t = ls.text_node
      local i = ls.insert_node
      local f = ls.function_node
      local c = ls.choice_node
      local d = ls.dynamic_node
      local r = ls.restore_node
      local l = require("luasnip.extras").lambda
      local rep = require("luasnip.extras").rep
      local p = require("luasnip.extras").partial
      local m = require("luasnip.extras").match
      local n = require("luasnip.extras").nonempty
      local dl = require("luasnip.extras").dynamic_lambda
      local fmt = require("luasnip.extras.fmt").fmt
      local fmta = require("luasnip.extras.fmt").fmta
      local types = require("luasnip.util.types")
      local conds = require("luasnip.extras.conditions")
      local conds_expand = require("luasnip.extras.conditions.expand")

      -- keybindings
      vim.keymap.set({"i"}, "<C-K>", function() ls.expand() end, {silent = true})
      vim.keymap.set({"i", "s"}, "<C-L>", function() ls.jump( 1) end, {silent = true})
      vim.keymap.set({"i", "s"}, "<C-J>", function() ls.jump(-1) end, {silent = true})
      vim.keymap.set({"i", "s"}, "<C-E>", function()
        if ls.choice_active() then
          ls.change_choice(1)
        end
      end, {silent = true})

      -- snippets
      ls.add_snippets("zig", {
	s("info", fmt('std.log.info("[]", .{});', i(1, ""), { delimiters = "[]" })),
      })
    end,
  },

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',
  {
    'mfussenegger/nvim-dap',
    config = function()
      local dap = require('dap')
      -- require('dap').session().current_frame.scopes[1].variables
      dap.set_log_level('TRACE')
      dap.adapters.lldb = {
        type = 'executable',
        command = '/home/linuxbrew/.linuxbrew/bin/lldb-vscode', -- adjust as needed, must be absolute path
        name = 'lldb'
      }
      dap.configurations.zig = {
        {
          name = 'zig',
          type = 'lldb',
          request = 'launch',
          program = '${fileBasenameNoExtension}',
          -- program = function()
          --   -- TODO: build then return the build
          --   -- or maybe build via jobstart *then* run dap.run({...})
          --   return '${fileBasenameNoExtension}'
          -- end,
          cwd = '${workspaceFolder}',
          stopOnEntry = false,
          args = {},
        },
      }

    end,
  },
  {
    "sourcegraph/sg.nvim",
    dependencies = { "nvim-lua/plenary.nvim", --[[ "nvim-telescope/telescope.nvim ]] },

    -- If you have a recent version of lazy.nvim, you don't need to add this!
    build = "nvim -l build/init.lua",
    -- DISABLED: opts = {},
  },

  'github/copilot.vim',
  -- NOTE: This is where your plugins related to LSP can be installed.
  --  The configuration is done below. Search for lspconfig to find it below.
  {
    -- LSP Configuration & Plugins
    'neovim/nvim-lspconfig',
    dependencies = {
      -- Automatically install LSPs to stdpath for neovim
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',

      -- Useful status updates for LSP
      -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
      { 'j-hui/fidget.nvim', opts = {} },

      -- Additional lua configuration, makes nvim stuff amazing!
      'folke/neodev.nvim',
    },
  },

  -- Useful plugin to show you pending keybinds.
  { 'folke/which-key.nvim',
    opts = {},
    dependencies = {
      'echasnovski/mini.icons',
      'nvim-tree/nvim-web-devicons',
    },
},
  {
    -- Adds git related signs to the gutter, as well as utilities for managing changes
    'lewis6991/gitsigns.nvim',
    opts = {
      -- See `:help gitsigns.txt`
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map({ 'n', 'v' }, ']c', function()
          if vim.wo.diff then
            return ']c'
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, desc = 'Jump to next hunk' })

        map({ 'n', 'v' }, '[c', function()
          if vim.wo.diff then
            return '[c'
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return '<Ignore>'
        end, { expr = true, desc = 'Jump to previous hunk' })

        -- Actions
        -- visual mode
        map('v', '<leader>hs', function()
          gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'stage git hunk' })
        map('v', '<leader>hr', function()
          gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
        end, { desc = 'reset git hunk' })
        -- normal mode
        map('n', '<leader>hs', gs.stage_hunk, { desc = 'git stage hunk' })
        map('n', '<leader>hr', gs.reset_hunk, { desc = 'git reset hunk' })
        map('n', '<leader>hS', gs.stage_buffer, { desc = 'git Stage buffer' })
        map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
        map('n', '<leader>hR', gs.reset_buffer, { desc = 'git Reset buffer' })
        map('n', '<leader>hp', gs.preview_hunk, { desc = 'preview git hunk' })
        map('n', '<leader>hb', function()
          gs.blame_line { full = false }
        end, { desc = 'git blame line' })
        map('n', '<leader>hd', gs.diffthis, { desc = 'git diff against index' })
        map('n', '<leader>hD', function()
          gs.diffthis '~'
        end, { desc = 'git diff against last commit' })

        -- Toggles
        map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'toggle git blame line' })
        map('n', '<leader>td', gs.toggle_deleted, { desc = 'toggle git show deleted' })

        -- Text object
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'select git hunk' })
      end,
    },
  },

  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'gruvbox'
      -- vim.cmd.colorscheme 'gruvbox'
      -- if vim.fn.hostname() ~= "personalbox" then
      --   vim.cmd.colorscheme 'gruvbox'
      -- end
    end,
  },

  -- {
  --   "bluz71/vim-nightfly-colors",
  --   name = "nightfly",
  --   -- lazy = false,
  --   priority = 1000,
  --   config = function()
  --     if vim.fn.hostname() == "personalbox" then
  --       vim.cmd.colorscheme 'nightfly'
  --     end
  --   end,
  -- },
  -- amongst your other plugins
  -- {'akinsho/toggleterm.nvim', version = "*", config = true},
  -- or
  {
    'akinsho/toggleterm.nvim',
    version = "*",
    opts = {
      open_mapping = [[<c-\>]],
    },
  },

  {
    -- Set lualine as statusline
    'nvim-lualine/lualine.nvim',
    -- See `:help lualine.txt`
    opts = {
      options = {
        icons_enabled = false,
        theme = 'gruvbox',
        component_separators = '|',
        section_separators = '',
      },
      sections = {
        lualine_a = {'filename'},
        lualine_b = {'mode'},
        lualine_c = {'branch', 'diff', 'diagnostics', function() return vim.fn.expand('%') end},
        lualine_x = { vim.loop.cwd },
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
    },
  },

  -- {
  --   -- Add indentation guides even on blank lines
  --   'lukas-reineke/indent-blankline.nvim',
  --   -- Enable `lukas-reineke/indent-blankline.nvim`
  --   -- See `:help ibl`
  --   main = 'ibl',
  --   opts = {},
  -- },

  -- "gc" to comment visual regions/lines
  { 'numToStr/Comment.nvim', opts = {} },

  -- Fuzzy Finder (files, lsp, etc)
  {
    'nvim-telescope/telescope.nvim',
    branch = '0.1.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Fuzzy Finder Algorithm which requires local dependencies to be built.
      -- Only load if `make` is available. Make sure you have the system
      -- requirements installed.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- NOTE: If you are having trouble with this installation,
        --       refer to the README for telescope-fzf-native for more instructions.
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
    },
  },

  {
    -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    dependencies = {
      'nvim-treesitter/nvim-treesitter-textobjects',
    },
    opts = {
      -- Add languages to be installed here that you want installed for treesitter
      ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'java', 'javascript', 'typescript', 'vimdoc', 'vim', 'bash', 'yaml', 'zig', 'clojure', 'rust', 'csv', 'racket' },

      -- Autoinstall languages that are not installed. Defaults to false (but you can change for yourself!)
      auto_install = false,
      -- Install languages synchronously (only applied to `ensure_installed`)
      sync_install = false,
      -- List of parsers to ignore installing
      ignore_install = {},
      -- You can specify additional Treesitter modules here: -- For example: -- playground = {--enable = true,-- },
      modules = {},
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<c-space>',
          node_incremental = '<c-space>',
          scope_incremental = '<c-s>',
          node_decremental = '<M-space>',
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
          keymaps = {
            -- You can use the capture groups defined in textobjects.scm
            ['aa'] = '@parameter.outer',
            ['ia'] = '@parameter.inner',
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            ['ic'] = '@class.inner',
          },
        },
        move = {
          enable = true,
          set_jumps = true, -- whether to set jumps in the jumplist
          goto_next_start = {
            [']m'] = '@function.outer',
            [']]'] = '@class.outer',
          },
          goto_next_end = {
            [']M'] = '@function.outer',
            [']['] = '@class.outer',
          },
          goto_previous_start = {
            ['[m'] = '@function.outer',
            ['[['] = '@class.outer',
          },
          goto_previous_end = {
            ['[M'] = '@function.outer',
            ['[]'] = '@class.outer',
          },
        },
        swap = {
          enable = true,
          swap_next = {
            ['<leader>a'] = '@parameter.inner',
          },
          swap_previous = {
            ['<leader>A'] = '@parameter.inner',
          },
        },
      },
  },
    config = function(_, opts)
    end,
    build = ':TSUpdate',
  },

  -- NOTE: Next Step on Your Neovim Journey: Add/Configure additional "plugins" for kickstart
  --       These are some example plugins that I've included in the kickstart repository.
  --       Uncomment any of the lines below to enable them.
  -- require 'kickstart.plugins.autoformat',
  -- require 'kickstart.plugins.debug',

  -- NOTE: The import below can automatically add your own plugins, configuration, etc from `lua/custom/plugins/*.lua`
  --    You can use this folder to prevent any conflicts with this init.lua if you're interested in keeping
  --    up-to-date with whatever is in the kickstart repo.
  --    Uncomment the following line and add your plugins to `lua/custom/plugins/*.lua` to get going.
  --
  --    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
  -- { import = 'custom.plugins' },
}, { dev = { path = '~/src/nvim-plugins' } })

-- https://github.com/ray-x/go.nvim
require('go').setup()
-- Run gofmt + goimports on save
local format_sync_grp = vim.api.nvim_create_augroup("goimports", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
   require('go.format').goimports()
  end,
  group = format_sync_grp,
})

-- require('nvim-treesitter.configs').setup {
--   rainbow = {
--     enable = true,
--     -- list of languages you want to disable the plugin for
--     disable = { 'jsx', 'cpp' }, 
--     -- Which query to use for finding delimiters
--     query = 'rainbow-parens',
--     -- Highlight the entire buffer all at once
--     strategy = require('ts-rainbow').strategy.global,
--   }
-- }


-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- Set highlight on search
vim.o.hlsearch = true

-- Make line numbers default
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.wrap = false

vim.keymap.set('n', '<ScrollWheelUp>', '2<c-y>') -- I think this only works when mouse='n'
vim.keymap.set('n', '<ScrollWheelDown>', '2<c-e>') -- I think this only works when mouse='n'
vim.o.mouse = ''

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
-- vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = false
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
-- vim.o.completeopt = 'menuone,noselect'

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- [[ Basic Keymaps ]]

-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  defaults = {
    mappings = {
      i = {
        ['<C-u>'] = false,
        ['<C-d>'] = false,
      },
    },
  },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- Telescope live_grep in git root
-- Function to find the git root directory based on the current buffer's path
local function find_git_root()
  -- Use the current buffer's path as the starting point for the git search
  local current_file = vim.api.nvim_buf_get_name(0)
  local current_dir
  local cwd = vim.fn.getcwd()
  -- If the buffer is not associated with a file, return nil
  if current_file == '' then
    current_dir = cwd
  else
    -- Extract the directory from the current file's path
    current_dir = vim.fn.fnamemodify(current_file, ':h')
  end

  -- Find the Git root directory from the current file's path
  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.escape(current_dir, ' ') .. ' rev-parse --show-toplevel')[1]
  if vim.v.shell_error ~= 0 then
    print 'Not a git repository. Searching on current working directory'
    return cwd
  end
  return git_root
end

-- Custom live_grep function to search in git root
local function live_grep_git_root()
  local git_root = find_git_root()
  if git_root then
    require('telescope.builtin').live_grep {
      search_dirs = { git_root },
    }
  end
end

vim.api.nvim_create_user_command('LiveGrepGitRoot', live_grep_git_root, {})

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

local function telescope_live_grep_open_files()
  require('telescope.builtin').live_grep {
    grep_open_files = true,
    prompt_title = 'Live Grep in Open Files',
  }
end

vim.keymap.set('n', '<leader>s/', telescope_live_grep_open_files, { desc = '[S]earch [/] in Open Files' })
vim.keymap.set('n', '<leader>ss', require('telescope.builtin').builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sG', ':LiveGrepGitRoot<cr>', { desc = '[S]earch by [G]rep on Git Root' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })

-- [[ Configure LSP ]]
--  This function gets run when an LSP connects to a particular buffer.
local on_attach = function(_, bufnr)
  -- NOTE: Remember that lua is a real programming language, and as such it is possible
  -- to define small helper and utility functions so you don't have to repeat yourself
  -- many times.
  --
  -- In this case, we create a function that lets us more easily define mappings specific
  -- for LSP related items. It sets the mode, buffer and description for us each time.
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
  nmap('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

  nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
  nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
  nmap('gD', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
  nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
  nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

  -- See `:help K` for why this keymap
  nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  nmap('gG', vim.lsp.buf.signature_help, 'Signature Documentation')

  -- Lesser used LSP functionality
  -- nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
  nmap('<leader>wa', vim.lsp.buf.add_workspace_folder, '[W]orkspace [A]dd Folder')
  nmap('<leader>wr', vim.lsp.buf.remove_workspace_folder, '[W]orkspace [R]emove Folder')
  nmap('<leader>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, '[W]orkspace [L]ist Folders')

  -- Create a command `:Format` local to the LSP buffer
  vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
    vim.lsp.buf.format()
  end, { desc = 'Format current buffer with LSP' })
end

-- mason-lspconfig requires that these setup functions are called in this order
-- before setting up the servers.
require('mason').setup()
require('mason-lspconfig').setup()

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--
--  Add any additional override configuration in the following tables. They will be passed to
--  the `settings` field of the server config. You must look up that documentation yourself.
--
--  If you want to override the default filetypes that your language server will attach to you can
--  define the property 'filetypes' to the map in question.
local servers = {
  -- clangd = {},
  gopls = {},
  -- pyright = {},
  -- rust_analyzer = {},
  -- tsserver = {},
  -- html = { filetypes = { 'html', 'twig', 'hbs'} },

  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
      -- NOTE: toggle below to ignore Lua_LS's noisy `missing-fields` warnings
      -- diagnostics = { disable = { 'missing-fields' } },
      diagnostics = { globals = { 'vim' } },
    },
  },
}

-- Setup neovim lua configuration
require('neodev').setup()

-- Ensure the servers above are installed
local mason_lspconfig = require 'mason-lspconfig'

mason_lspconfig.setup {
  ensure_installed = vim.tbl_keys(servers),
}

mason_lspconfig.setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {
      on_attach = on_attach,
      settings = servers[server_name],
      filetypes = (servers[server_name] or {}).filetypes,
    }
  end,
}

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et

vim.keymap.set('n', '<c-f>', '<esc>', { desc = 'Sina: escape' })
vim.keymap.set('i', '<c-f>', '<esc>', { desc = 'Sina: escape' })
vim.keymap.set('v', '<c-f>', '<esc>', { desc = 'Sina: escape' })
vim.keymap.set('c', '<c-f>', '<esc>', { desc = 'Sina: escape' })
vim.keymap.set('t', '<c-f>', '<esc>', { desc = 'Sina: escape' })
vim.keymap.set('s', '<c-f>', '<esc>', { desc = 'Sina: escape' })
vim.keymap.set('n', '<c-j>', '<c-w>j', { desc = 'Sina: navigating windows' })
vim.keymap.set('n', '<c-k>', '<c-w>k', { desc = 'Sina: navigating windows' })
vim.keymap.set('n', '<c-h>', '<c-w>h', { desc = 'Sina: navigating windows' })
vim.keymap.set('n', '<c-l>', '<c-w>l', { desc = 'Sina: navigating windows' })
vim.keymap.set('n', ';w', ':up<cr>', { desc = 'Sina: write/update buffer' })
vim.keymap.set('n', ';q', ':q<cr>', { desc = 'Sina: close window' })
vim.keymap.set('n', ';:', 'q:', { desc = 'Sina: open Normal mode command window' })
vim.keymap.set('n', '<c-p>', require('telescope.builtin').find_files, { desc = 'Sina: search files' })
vim.keymap.set('c', '<c-a>', '<c-b>', { desc = 'Sina: go to beginning of the line' })
vim.o.hlsearch = true
vim.o.splitright = true
vim.o.equalalways = true
vim.wo.number = not true
vim.wo.relativenumber = false
vim.wo.wrap = false
vim.o.linebreak = true -- wrap at word boundaries, insead of in the middle of a word
vim.o.wrapscan = false
vim.o.inccommand = 'split'
vim.wo.signcolumn = 'no'
vim.opt.iskeyword:append("-") -- Same as 'set iskeyword+=-' in Neovim, ie add - to the list of word characters
vim.opt.iskeyword:append("$")

local SinaStuff = {}

SinaStuff.create_floating_window = function()
  local parent_width = vim.api.nvim_win_get_width(0)
  local parent_height = vim.api.nvim_win_get_height(0)
  local width = math.floor(1+parent_width / 5)
  local height = math.floor(1+parent_height / 3)

  print(parent_width, parent_height, width, height)
  local buf = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_open_win(buf, true, {
    relative='win',
    row=(parent_height-height)/2,
    col=(parent_width-width)/2,
    width=width,
    height=height,
  })
end
-- vim.api.nvim_create_user_command("Dialog", SinaStuff.create_floating_window, {})

-- :term poetry run python -m cql_struct
-- tabnew | term man --pager=cat git-add | set ft=man
SinaStuff.Man = function(opts)
  vim.cmd.tabnew()

  -- To support the number 2 as in `:Man 2 write`, I will pass everything
  -- given to the man command, without quoting (ie %s instead of %q)
  vim.cmd(string.format("term man --pager=cat %s", opts.fargs[1]))

  vim.cmd("set ft=man")
end
vim.api.nvim_create_user_command("Man", SinaStuff.Man, { nargs = 1 })

-- The code for jumping to last known position was copied from
-- https://github.com/creativenull/dotfiles/blob/18bf48c855/config/nvim/init.lua#L60-L80
-- "When editing a file, always jump to the last known cursor position.
-- Don't do it when the position is invalid, when inside an event handler
-- (happens when dropping a file on gvim) and for a commit message (it's
-- likely a different one than last time)."
vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup("SinaLastPosGroup", {}),
  callback = function(args)
    local valid_line = vim.fn.line([['"]]) >= 1 and vim.fn.line([['"]]) < vim.fn.line('$')
    local not_commit = vim.b[args.buf].filetype ~= 'commit'

    if valid_line and not_commit then
      vim.cmd([[normal! g`"]])
    end
  end,
})

-- vim.api.nvim_create_autocmd('DirChanged', {
--   pattern = "*",
--   callback = function(args)
--     if args.match == "global" then
--       vim.api.nvim_err_writeln("Please don't change the global cwd. Use `:tcd` or other cd alternatives")
--       vim.cmd.cd("-")
--     end
--   end,
-- })

SinaStuff.get_chezmoi_sources = function()
  return vim.fn.systemlist("chezmoi managed -i files -p source-absolute", "", 0)
end

SinaStuff.chezmoi_sources = SinaStuff.get_chezmoi_sources()

-- TODO: convert diff_sticky_win to a table to support multiple tabs
local diff_sticky_win = nil
SinaStuff.show_or_update_diff_win = function()
    local current_win = vim.api.nvim_get_current_win()
    local wins = vim.api.nvim_tabpage_list_wins(0)

    local command1 = "Shell --no-follow git --no-pager diff --exit-code --stat -p"
    local command2 = "set ft=diff"
    if vim.tbl_contains(wins, diff_sticky_win) then
      -- run command in that existing terminal window:
      vim.api.nvim_set_current_win(diff_sticky_win)
      vim.cmd(command1)
      vim.cmd(command2)
    else
      -- open a new terminal window:
      vim.cmd.vsplit()
      vim.cmd(command1)
      vim.cmd(command2)
      -- TODO: any benefits in using nvim_open_term()?
      diff_sticky_win = vim.api.nvim_get_current_win()
    end
    vim.api.nvim_set_current_win(current_win)
end
vim.api.nvim_create_autocmd({"BufWritePost"}, {
  pattern = "*",
  callback = function()
    if diff_sticky_win == nil then
      return
    end

    -- if diff_sticky_win is still open, run SinaStuff.show_or_update_diff_win()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    if vim.tbl_contains(wins, diff_sticky_win) then
      SinaStuff.show_or_update_diff_win()
    end
  end,
  group = vim.api.nvim_create_augroup('SinaStickyDiff', { clear = true }),
})

SinaStuff.syntax_highlighted_content = function(language, content)
  -- This is noop in Lua. The purpose of this function is to help my
  -- treesitter injection know the language for the given string.
  _ = language
  return content
end

vim.api.nvim_create_user_command("FPB", function()
  vim.cmd("w !fpb")
end, { nargs = 0 })

SinaStuff.execute_command = function(command, callback)
  local stdout = ""
  local stderr = ""
  vim.fn.jobstart(command, {
    pty = false,
    detach = false,
    stdout_buffered = false,
    clear_env = true,
    on_stdout = function(_, data)
      local lines = table.concat(data, "\n")
      if lines == "" then
        return
      end
      stdout = stdout .. lines
    end,
    on_stderr = function(_, data)
      local lines = table.concat(data, "\n")
      if lines == "" then
        return
      end
      stderr = stderr .. lines
    end,
    on_exit = function(_, code)
      callback(code, stdout, stderr)
    end
  })
end

SinaStuff.execute_command_stream = function(pty, command, callback)
  -- We need pty to support commands that want to read user input, eg for password.
  -- But that results in commands printing ANSI codes.
  -- That is why I pipe the output to something like `cat` as a workaround.

  if pty then
    -- Why 'cat'? ANSI escape codes are not rendered well in pty mode,
    -- so we disable them by piping through `cat`
    -- Why 'ssty -echo'? Because tty by defaut prints user input, which we don't want.
    command = string.format("stty -echo; %s | cat", command)
    -- command = string.format("stty -echo; %s | sed 's/\\x1b\\[[0-9;]*m//g; s/\\x1b\\[[0-9;]*[A-Za-z]//g'; stty echo", command)
  end

  return vim.fn.jobstart(command, {
    pty = pty,
    detach = false,
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(chan, data)
      print("got", vim.inspect(data))
      callback({stdout = data, channel = chan})
    end,
    on_stderr = function(chan, data)
      callback({stderr = data, channel = chan})
    end,
    on_exit = function(chan, code)
      callback({code = code, channel = chan})
    end
  })
end

SinaStuff.commit_all = function()
  local command = vim.fn.trim(SinaStuff.syntax_highlighted_content("bash", [[
    file=$(mktemp)
    cat sina-project.yaml | yq -o json > $file
    echo $file
  ]]))

  SinaStuff.execute_command(command, function(code, stdout, stderr)
    local project_filepath = vim.fn.trim(stdout)

    local path = require("plenary.path")
    local json = path:new(project_filepath):read()
    local project = vim.json.decode(json)
    if project and project.auto_commit and project.auto_commit.enabled == true then
      SinaStuff.execute_command(string.format(SinaStuff.syntax_highlighted_content("bash", [[
        project_filepath=%q
        prompt_message=$(mktemp)
        prompt=$(mktemp)
        cat $project_filepath | yq -o json | jq .auto_commit.commit_message_prompt > $prompt_message
        git diff --stat -p >> $prompt_message
        cat $prompt_message | jq -nR '[inputs] | join("\n") | {model: "gpt-4", messages: [{role: "user", content: .}]}' > $prompt

        OPENAI_API_KEY="$(cat ~/.openai_api_key.txt)"
        curl --silent https://api.openai.com/v1/chat/completions \
          -H "Content-Type: application/json" \
          -H "Authorization: Bearer $OPENAI_API_KEY" \
          -d @$prompt | jq -r '.choices[0].message.content'
      ]]), project_filepath), function(code, stdout, stderr)
          print("GPT says:", vim.fn.trim(stdout))
      end)
    end
  end)
end

vim.keymap.set('n', ';d', SinaStuff.show_or_update_diff_win, { noremap = true, desc = "Sina: show diff" })

-- The commit messages are terrible
-- vim.keymap.set('n', ';c', SinaStuff.commit_all, { noremap = true, desc = "Sina: commit all" })


SinaStuff.prompt_single_char = function(prompt_message)
  print(prompt_message)
  local char = vim.fn.nr2char(vim.fn.getchar())
  return char
end

-- open dotfiles with Telescope
SinaStuff.telescope_wrapper = function(opts)
    opts = opts or {}
    -- https://github.com/nvim-telescope/telescope.nvim/blob/7b5c5f56/developers.md
    local pickers = require "telescope.pickers"
    local finders = require "telescope.finders"
    local conf = require("telescope.config").values

    local attach_mappings = nil

    -- For custom action (openning in new tab), otherwise it will open in the current buffer
    local actions = require "telescope.actions"
    local action_state = require "telescope.actions.state"
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection == nil then
          return
        end
        print("Running:", vim.inspect(selection.value))
        vim.cmd(selection.value)
      end)
      return true
    end

    pickers.new(opts.telescope_opts, {
      prompt_title = opts.prompt,
      finder = finders.new_table {
        results = opts.items,
        entry_maker = function(entry)
          return {
            value = entry[2],
            display = entry[1],
            ordinal = entry[1],
          }
        end
      },
      sorter = conf.generic_sorter(opts.telescope_opts),
      attach_mappings = attach_mappings,

    }):find()
end

vim.keymap.set('n', ';v', function()
  local files = SinaStuff.get_chezmoi_sources()
  local items = {}
  for _,v in ipairs(files) do
    local command = string.format("tabnew %s | tcd ~/.local/share/chezmoi/", v)
    local display = string.gsub(v, "^.*/.local/share/chezmoi/", "")
    table.insert(items, {display, command})
  end
  SinaStuff.telescope_wrapper({
    prompt = "Pick a file",
    telescope_opts = require("telescope.themes").get_dropdown{},
    items = items,
  })
end, { desc = 'Sina: open dotfiles with Telescope' })

vim.keymap.set('n', ';f', function()
  local items = SinaStuff.get_commandsfile()
  SinaStuff.telescope_wrapper({
    prompt = "Pick a command",
    telescope_opts = require("telescope.themes").get_dropdown{},
    items = items,
  })
end, { desc = 'Sina: open common files with Telescope' })

SinaStuff.get_commandsfile = function()
  -- curl -L "https://github.com/mikefarah/yq/releases/download/v4.40.5/yq_linux_amd64" -o ~/bin/yq && chmod +x ~/bin/yq
  local commandsfile = vim.fn.system("yq -o json ~/commandsfile.yaml")
  local got = vim.json.decode(commandsfile)
  local items = {}
  for k,v in pairs(got.commands) do
    table.insert(items, {k, v})
  end
  return items
end

-- open dotfiles without Telescope
vim.keymap.set('n', ';V', function()
  local files = SinaStuff.chezmoi_sources
  vim.cmd.tabnew(files[1])
  for i = 2,#files do
    vim.cmd.vsplit(files[i])
  end
end, { desc = 'Sina: open dotfiles' })


SinaStuff.chezmoi_targets = vim.fn.systemlist("chezmoi managed -i files -p absolute", "", 0)

vim.api.nvim_create_autocmd({"BufReadPost"}, {
  pattern = SinaStuff.chezmoi_targets,
  -- command = "bo vs | term cd ~/.local/share/chezmoi && make update",
  callback = function()
    vim.api.nvim_err_writeln("This file is managed by chezmoi. You should edit the files in ~/.local/share/chezmoi instead.")
    vim.bo.modifiable = false
    vim.bo.readonly = true
  end,
  group = vim.api.nvim_create_augroup('SinaTargetsReadonly', { clear = true }),
})

SinaStuff.open_search_matches = function()
  local vi_pattern = vim.fn.getreg("/")

  local rg_pattern = string.gsub(vi_pattern, "\\c", "")
  -- replace \< and \> with \b
  rg_pattern = string.gsub(vi_pattern, "\\<", "\\b")
  rg_pattern = string.gsub(rg_pattern, "\\>", "\\b")
  -- replace \V with ""
  rg_pattern = string.gsub(rg_pattern, "\\V", "")

  local out = vim.fn.system(string.format("rg -l %q | sort", rg_pattern))
  local files = vim.fn.split(out)
  vim.print("Searched for: " .. vi_pattern)

  if #files == 0 then
    vim.print("No matches found")
    return
  end
  vim.cmd.tabnew(files[1])
  local first_win = vim.api.nvim_get_current_win()
  vim.cmd.normal("gg0nzz")

  for i = 2,#files do
    vim.cmd.vsplit(files[i])
    vim.cmd.normal("gg0nzz")
  end
  vim.api.nvim_set_current_win(first_win)
end

-- Sina commands:
-- pull, apply, commit, push :bo vs | term cd ~/.local/share/chezmoi && make update
-- open makefile :bo vs ~/.local/share/chezmoi/makefile
SinaStuff.run_command_in_current_line = function()
  -- Runs the command in the current line.
  -- Assumes that the command starts from the first occurance of ":"
  local line = tostring(vim.api.nvim_get_current_line())
  local command = string.match(line, ":.+")
  vim.cmd(command)
end
-- vim.keymap.set('n', ';:', SinaStuff.run_command_in_current_line, { noremap = true, desc = "Sina: run command in current line" })

-- use <c-t>n to go to the next tab, similar to <c-w>w
vim.keymap.set('n', '<c-t>h', function() vim.cmd('tabprevious') end, { noremap = true, desc = "Sina: prev tab" })
vim.keymap.set('n', '<c-t>l', function() vim.cmd('tabnext') end, { noremap = true, desc = "Sina: next tab" })

vim.keymap.set('n', ';s', function() vim.api.nvim_feedkeys(':Shell ', 'n', false) end, { noremap = true, desc = 'shellpad: prepare shell command' })

-- vim.keymap.set('n', '<c-s>', function() vim.cmd('tabprevious') end, { noremap = true, desc = "Sina: prev tab" })
-- vim.keymap.set('n', '<c-f>', function() vim.cmd('tabnext') end, { noremap = true, desc = "Sina: next tab" })

vim.keymap.set('n', ';ts', SinaStuff.open_search_matches, { noremap = true, desc = "Sina: search in new tab" })
vim.keymap.set('n', ';tq', function() vim.cmd('tabclose') end, { noremap = true, desc = "Sina: close tab" })
-- vim.keymap.set('n', ';t', SinaStuff.open_search_matches, { noremap = true, desc = "Sina: search in new tab" })
-- vim.keymap.set('n', ';T', function() vim.cmd('tabclose') end, { noremap = true, desc = "Sina: close tab" })

-- General purpose function to get treesitter root node
SinaStuff.get_root = function(bufnr, lang)
  local parser = vim.treesitter.get_parser(bufnr, lang, {})
  local tree = parser:parse()[1]
  return tree:root()
end

-- See https://tree-sitter.github.io/tree-sitter/using-parsers
local function_call_arguments_queries = {
  go = [[
  (
    (argument_list) @call
  )
  ]],
  zig = [[
  (
    (FnCallArguments) @call
  )
  ]],
  lua = [[
  (
    (arguments) @call
  )
  ]],
}

local function_call_arguments_trailing_comma = {
  go = true,
  zig = true,
  lua = false,
}

local test_exploder = function()
  local filetype = "lua"
  local query = vim.treesitter.query.parse(filetype, function_call_arguments_queries[filetype])
  local parser = vim.treesitter.get_string_parser([[
    local a = fn(1, 2, 3, 4, 5)
  ]], filetype, {})
  local tree = parser:parse()[1]
  local root = tree:root()
  -- TODO: implement the rest
end

-- This will work like the reverse of J: it will split the args for
-- a function call in the current line into separate lines.
-- It will do so for the first function call in the current line.
-- For the nested ones you can run it again.
local split_args_into_lines = function(bufnr, filetype)
  local debug = false
  if function_call_arguments_queries[filetype] == nil then
    return
  end

  local query = vim.treesitter.query.parse(filetype, function_call_arguments_queries[filetype])
  local parser = vim.treesitter.get_parser(bufnr, filetype, {})
  local tree = parser:parse()[1]
  local root = tree:root()

  local call_expr_nodes = {}

  local current_row = vim.fn.line(".") - 1
  local current_col = vim.fn.col(".") - 1
  -- for id, node in query:iter_captures(root, bufnr, 0, -1) do
  for id, node, metadata in query:iter_captures(root, bufnr, current_row, current_row+1) do
    local range = { node:range() }
    local start_row = range[1]
    local start_col = range[2]
    local end_row = range[3]
    local end_col = range[4]

    if current_row == start_row and current_col <= end_col then
      call_expr_nodes[#call_expr_nodes+1] = node

      if debug then
        local name = query.captures[id]
        local text = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
        print("capture", id, name, node:type(), vim.inspect(metadata), vim.fn.line("."), "range", node:range(), vim.inspect(text))
      end

      -- I only want the first function call in the current line, so I'm breaking:
      break
    end
  end

  -- Returns the whitespaces at the beginning of the line where node starts.
  -- Note that node itself might not start at the beginning of the line,
  -- but we usually want to indent line level after whatever intentation is there.
  local get_node_indent = function(node)
    local range = { node:range() }
    local start_row = range[1]
    local start_col = range[2]
    local indent = vim.api.nvim_buf_get_text(bufnr, start_row, 0, start_row, start_col, {})
    return string.match(indent[1], "^(%s*)") or ""
  end

  local get_node_text = function(node)
    local range = { node:range() }
    local start_row = range[1]
    local start_col = range[2]
    local end_row = range[3]
    local end_col = range[4]
    return vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
  end

  local set_node_text = function(node, lines)
    local range = { node:range() }
    local start_row = range[1]
    local start_col = range[2]
    local end_row = range[3]
    local end_col = range[4]
    vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, lines)
  end

  for _, call_node in ipairs(call_expr_nodes) do
    local indent = get_node_indent(call_node)

    if debug then
      print("parent indent", vim.inspect(indent))
    end

    local args = {}

    if call_node:child_count() == 0 then
      -- No arguments, let's not change anything and keep the parenthesis in one line.
      return
    end

    -- for arg_node in call_node:iter_children() do
    for arg_idx = 0, call_node:named_child_count()-1 do
      local arg_node = call_node:named_child(arg_idx)
      local arg_lines = get_node_text(arg_node)
      if debug then
        print("arg:", arg_node:named(), arg_node:type(), "range", arg_node:range(), vim.inspect(arg_lines))
      end

      local new_indent = "    "
      -- if arg_node:named() then
        for arg_line_idx,line in ipairs(arg_lines) do
          local formatted_line = indent .. new_indent .. line
          if arg_line_idx == #arg_lines then
            local wants_trailing_comma = function_call_arguments_trailing_comma[filetype] or arg_idx < call_node:named_child_count()-1
            if wants_trailing_comma then
              formatted_line =  formatted_line .. ","
            end
          end
          args[#args+1] = formatted_line
        end
      -- end
    end

    -- FnCallArguments include parenthesis and commas, but we have skipped them
    -- above when we checked arg_node:named() and ignored unnamed nodes.
    -- So we need to add them back here.
    args = vim.list_extend({"("}, args)
    args = vim.list_extend(args, {indent .. ")"})
    set_node_text(call_node, args)
  end
end

vim.api.nvim_create_user_command("SplitArgs", function()
  local filetype = vim.bo.filetype
  split_args_into_lines(vim.api.nvim_get_current_buf(), filetype)
end, { nargs = 0 })

SinaStuff.convert_seconds_to_age = function(seconds)
  local days = math.floor(seconds / 86400)
  local hours = math.floor((seconds % 86400) / 3600)
  local minutes = math.floor((seconds % 3600) / 60)
  seconds = seconds % 60
  local age = ""
  if days > 0 then
    age = age .. days .. "d"
  end
  if hours > 0 then
    age = age .. hours .. "h"
  end
  if minutes > 0 then
    age = age .. minutes .. "m"
  end
  age = age .. seconds .. "s"
  return age
end

vim.api.nvim_create_autocmd({"BufReadCmd"}, {
  pattern = "docker://containers",
  callback = function()
    SinaStuff.execute_command("docker inspect $(docker ps -q)", function(code, stdout, stderr)
      -- TODO: nnoremap <buffer> q :bwipeout!<CR>

      local containers = vim.json.decode(stdout)
      local items = {}
      for _,container in ipairs(containers) do
        -- join all lines in the Cmd array
       
        -- Source: docker inspect $(docker ps -q) | jq . | less -nSR
        local cmd = container.Config.Cmd or {}
        if cmd == vim.NIL then
          cmd = {}
        end
        table.insert(items, {
          { key = "age", value = SinaStuff.convert_seconds_to_age(os.time() - vim.fn.strptime("%Y-%m-%dT%H:%M:%S", container.State.StartedAt)) },
          { key = "status", value = container.State.Status },
          { key = "id", value = string.sub(container.Id, 0, 8) },
          { key = "image", value = string.sub(container.Config.Image, 0, 30) },
          { key = "name", value = container.Name },
          { key = "cmd", value = table.concat(cmd, " ") },
          -- { key = "env", value = table.concat(container.Config.Env, " ") },
          -- { key = "ports", value = vim.inspect(container.HostConfig.PortBindings) },
        })
      end

      local longest_value_width = {}

      for _,item in ipairs(items) do
        for _,col in ipairs(item) do
          local k = col.key
          local v = col.value
          longest_value_width[k] = math.max(longest_value_width[k] or 0, string.len(v))
        end
      end

      local lines = {}
      for i,item in ipairs(items) do
        local line = ""
        for _,col in ipairs(item) do
          local k = col.key
          local v = col.value
          local width = longest_value_width[k]
          local format = "%" .. (-width) .. "s"
          if i == 1 then
            line = line .. string.format(format, k) .. "  "
          else
            line = line .. string.format(format, v) .. "  "
          end
        end
        table.insert(lines, line)
      end

      vim.bo.modifiable = true
      vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)

      -- TODO: use vim.api.nvim_buf_set_option(buf, 'modified', false)
      vim.bo.modified = false
      vim.bo.modifiable = false
    end)
  end,
  group = vim.api.nvim_create_augroup('SinaDockerPs', { clear = true }),
})

SinaStuff.append_to_file = function(filepath, line)
  -- Open the file in append mode
  local file = io.open(filepath, "a")
  if not file then
    print("Could not open file: " .. filepath)
    return
  end

  -- Append the line to the file
  file:write(line .. "\n")

  -- Close the file
  file:close()
end

SinaStuff.read_file_reversed = function(file_path)
  local file = io.open(file_path, "r") -- Open the file for reading
  if not file then return nil, "Could not open file for reading." end

  local lines = {}
  for line in file:lines() do
    table.insert(lines, 1, line) -- Insert each line at the beginning
  end

  file:close() -- Close the file
  return lines
end

vim.api.nvim_create_autocmd({"BufReadCmd"}, {
  pattern = "nshell://*",
  callback = function()
    local output_prefix = "   "
    local buf = vim.api.nvim_get_current_buf()
    local channel_id = nil
    local job_pid = nil
    local child_pids = {}
    local pty = false
    local shell = "/usr/bin/bash" --os.getenv("SHELL") or "sh"

    local stop_shell = function()
      if channel_id ~= nil then
        vim.fn.jobstop(channel_id)
        print("Stopped job")
        job_pid = nil
      end
      -- send a <c-c>
      -- vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<c-c>', true, false, true), 'n', false)
      vim.api.nvim_command('stopinsert')
    end

    --vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile') -- The buffer is not related to a file
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'hide') -- The buffer is hidden when abandoned
    vim.api.nvim_buf_set_option(buf, 'swapfile', false) -- No swap file for the buffer
    vim.api.nvim_create_autocmd({"BufUnload"}, {
      buffer = buf,
      callback = function()
        stop_shell()
      end,
    })

    -- TODO: support stdin
    local history_lines = SinaStuff.read_file_reversed(os.getenv("HOME") .. "/.nshell_history")
    if history_lines ~= nil then
      vim.api.nvim_buf_set_lines(buf, 1, -1, false, history_lines)
    end

    local maybe_prompt_password = function(line)
      if string.match(line, "password.*:%s*$") or string.match(line, "Password.*:%s*$") then
        vim.defer_fn(function()
          local password = vim.fn.inputsecret(line)
          vim.fn.chansend(channel_id, password .. "\n")
        end, 0)
      end
    end

    local insert_output = function(bufnr, data)
      -- replace '\r' with '\n' at the end of each line
      -- print("insert_output", vim.inspect(data))
      for i,line in ipairs(data) do
        -- local ansi_pattern = '\027%[[0-9;]*[a-zA-Z]'
        -- line = string.gsub(line, ansi_pattern, '\r')
        if i > 1 then
          -- The reason we don't add prefix to the first item,
          -- is that the first item might be joined with the last line.
          -- See channel.txt
          data[i] = output_prefix .. string.gsub(line, "\r$", "")
        else
          data[i] = string.gsub(line, "\r$", "")
        end
      end

      local last_lines = vim.api.nvim_buf_get_lines(bufnr, -2, -1, false)
      -- complete the previous line (see channel.txt)
      local first_line = last_lines[1] .. data[1]

      -- append (last item may be a partial line, until EOF)
      vim.api.nvim_buf_set_lines(bufnr, -2, -1, false, vim.list_extend(
        {first_line},
        vim.list_slice(data, 2, #data)
      ))
    end

    local on_enter = function()
      local command = tostring(vim.api.nvim_get_current_line())
      SinaStuff.append_to_file(os.getenv("HOME") .. "/.nshell_history", command)
      if channel_id == nil then
        return
      end

      -- TODO: only replace until start of next command
      local current_line_number = vim.fn.line(".") - 1
      vim.api.nvim_buf_set_lines(buf, current_line_number, -1, true, {command, output_prefix .. ""})
      vim.api.nvim_buf_set_option(buf, 'modified', false)

      command = string.format('%s ; echo "(Command exited with code $?)"', command)
      vim.fn.chansend(channel_id, command .. "\n")
      vim.api.nvim_command('stopinsert')
    end

    local display_child_process_commands = function()
      if job_pid ~= nil then
        local child_pids_lines = vim.fn.system(string.format("cat /proc/%s/task/%s/children", job_pid, job_pid))
        child_pids = vim.fn.split(child_pids_lines)
        local child_commands = {}
        for i,pid in ipairs(child_pids) do
          -- get the command line of the process
          local cmdline = vim.fn.system(string.format("ps --no-headers -o args -p %s", pid))
          cmdline = string.gsub(cmdline, "\n$", "")
          child_commands[i] = cmdline
        end
        print("INFO Child cmds", vim.inspect(child_commands))
      else
        print("INFO No child")
      end
    end

    local function trigger_child_process_monitor()
      display_child_process_commands()

      vim.defer_fn(function()
        trigger_child_process_monitor()
      end, 1000)
    end


    local start_shell = function()
      channel_id = SinaStuff.execute_command_stream(pty, string.format("PS1= TERM=xterm %s --noediting --norc --noprofile", shell), function(event)
        display_child_process_commands()

        if vim.api.nvim_buf_is_loaded(buf) == false then
          -- Buffer might have unloaded before exiting the editor.
          return
        end

        -- ignore events from older channels
        if event.channel ~= channel_id then
          return
        end

        if event.code ~= nil then
          local exit_lines = {
            string.format("[Process exited with code %d]", event.code),
          }
          vim.api.nvim_buf_set_lines(buf, -1, -1, false, exit_lines)
          vim.api.nvim_buf_set_option(buf, 'modified', false)
          return
        end

        if event.stdout ~= nil then
          insert_output(buf, event.stdout)
        end

        if event.stderr ~= nil then
          insert_output(buf, event.stderr)
        end

        if event.stdout ~= nil or event.stderr ~= nil then
          local last_line = vim.api.nvim_buf_get_lines(buf, -2, -1, false)
          if last_line[1] ~= nil then
            maybe_prompt_password(last_line[1])
          end
        end

        vim.api.nvim_buf_set_option(buf, 'modified', false)
      end)
      job_pid = vim.fn.jobpid(channel_id)

      display_child_process_commands()
      -- trigger_child_process_monitor()
    end

    local stop_command = function()
      -- this stops the shell as well, so we need to start a new shell
      stop_shell()
      start_shell()
    end

    start_shell()

    vim.keymap.set('n', '<cr>', on_enter, { noremap = true, desc = "Sina: execute command in current line", buffer = buf })
    vim.keymap.set('i', '<cr>', on_enter, { noremap = true, desc = "Sina: execute command in current line", buffer = buf })
    vim.keymap.set('n', '<c-c>', stop_command, { noremap = true, desc = "Sina: stop running command", buffer = buf })
    vim.keymap.set('i', '<c-c>', stop_command, { noremap = true, desc = "Sina: stop running command", buffer = buf })
  end,
  group = vim.api.nvim_create_augroup('SinaDockerPs', { clear = true }),
})

SinaStuff.animate_width = function(win, keyframes, current)
  vim.defer_fn(function()
    vim.api.nvim_win_set_width(win, keyframes[current])
    if current == #keyframes then
      return
    end
    SinaStuff.animate_width(win, keyframes, current + 1)
  end, 16)
end

SinaStuff.enable_session_history = function()
  local group = vim.api.nvim_create_augroup('SinaSessionHistory', { clear = true })

  -- local dir = vim.fn.stdpath("state") .. "/session-history/"
  local dir = "/dev/shm/" .. os.getenv("USER") .. "-session-history/"
  local tree_filename = dir .. string.format("session-tree-%d-%d.json", vim.loop.hrtime(), vim.fn.getpid())
  function clear_autocmds()
    vim.api.nvim_clear_autocmds({ group = group })
  end
  local setup_autocmds = function()
    -- not implemented yet, throw error:
    error("Not implemented yet")
  end

  local tree = {
    children = {},
    cursor = {},
  }
  if vim.fn.isdirectory(dir) ~= 1 then
    vim.fn.mkdir(dir, "p")
  end
  if vim.fn.filereadable(tree_filename) == 1 then
    local tree_str = vim.fn.readfile(tree_filename)
    tree = vim.json.decode(tree_str[1])
  end
  -- print(vim.inspect(tree))

  local is_floating = function(win_id)
    print("INFO: win_id", vim.inspect(win_id))
    if not vim.api.nvim_win_is_valid(win_id) then
      return false
    end
    local config = vim.api.nvim_win_get_config(win_id)
    -- print("INFO: config:", vim.inspect(config))
    return config.relative ~= "" -- A non-empty 'relative' field indicates a floating window
  end

  local on_session_changed = function(event)
    -- print("INFO: session changed event=", event.event)
    -- print("INFO: session changed", vim.inspect(event))
    -- if vim.g.SessionLoaded == 1 then
    --   return
    -- end

    -- event.file is a string representing the window id
    if event.event == "WinClosed" then
      print("INFO: WinClosed", vim.inspect(event))
      local win_id = tonumber(event.file)
      if is_floating(win_id) then
	return -- Exit if the window is floating
      end
    end

    local filename = dir .. string.format("session-source-%d-%d.vim", vim.loop.hrtime(), vim.fn.getpid())
    local new_node = {
      filename = filename,
      children = {},
    }
    vim.cmd.mksession(filename)
    local current_node = tree
    for i = 1,#tree.cursor do
      local idx = tree.cursor[i]
      current_node = current_node.children[idx]
    end
    local idx = #current_node.children + 1
    current_node.children[idx] = new_node
    tree.cursor[#tree.cursor+1] = idx

    local tree_str = vim.json.encode(tree)
    vim.fn.writefile({tree_str}, tree_filename)
  end

  local do_undo = function()
    clear_autocmds()
    vim.defer_fn(function()
      setup_autocmds()
    end, 1)

    local current_node = tree
    for i = 1,(#tree.cursor-1) do
      local idx = tree.cursor[i]
      current_node = current_node.children[idx]
    end
    if current_node.filename == nil then
      print("No session to undo")
      return
    end
    vim.cmd.source(current_node.filename)
    -- vim.cmd("silent source " .. current_node.filename)
    -- vim.api.nvim_command("source " .. current_node.filename)

    table.remove(tree.cursor, #tree.cursor)
    --print("INFO: cursor after undo", vim.inspect(tree.cursor))

    local tree_str = vim.json.encode(tree)
    vim.fn.writefile({tree_str}, tree_filename)
  end

  local do_redo = function()
    clear_autocmds()
    vim.defer_fn(function()
      setup_autocmds()
    end, 1)

    local current_node = tree
    for i = 1,#tree.cursor do
      local idx = tree.cursor[i]
      current_node = current_node.children[idx]
    end

    if current_node == nil then
      print("No session to redo")
      return
    end
    if #current_node.children == 0 then
      print("No session to redo")
      return
    end

    local idx = #current_node.children
    tree.cursor[#tree.cursor+1] = idx
    current_node = current_node.children[idx]

    vim.cmd.source(current_node.filename)
    -- vim.cmd("silent source " .. current_node.filename)
    -- vim.api.nvim_command("source " .. current_node.filename)

    local tree_str = vim.json.encode(tree)
    vim.fn.writefile({tree_str}, tree_filename)
  end

  local throttled_timer = nil
  local throttled_callback = function(event)
    if throttled_timer ~= nil then
      return
    end
    -- print("INFO: wrapper session changed event=", event.event)
    throttled_timer = vim.defer_fn(function()
      on_session_changed(event)
      throttled_timer = nil
    end, 100)
  end

  setup_autocmds = function()
    -- group = vim.api.nvim_create_augroup('SinaSessionHistory', { clear = true })
    vim.keymap.set('n', '<c-w>u', do_undo, { noremap = true, desc = "Sina: undo session" })
    vim.keymap.set('n', '<c-w>U', do_redo, { noremap = true, desc = "Sina: redo session" })
    -- on all events that means a change in window or buffer, eg split, resize, etc
    -- vim.api.nvim_create_autocmd({"WinNew", "WinClose", "WinResized"}, {
    -- "WinEnter", 
    vim.api.nvim_create_autocmd({"WinNew", "WinClosed", "WinResized"}, {
      -- TODO: wait for a few milliseconds before running the callback and perform the callback only once for multiple consecutive events
      callback = throttled_callback,
      group = group,
    })
  end

  setup_autocmds()
  -- clear_autocmds()

  -- This is a hack to save the initial session without adding more events to autocmd
  vim.defer_fn(function()
    on_session_changed({event = ""})
  end, 5)
end

SinaStuff.enable_session_history()

SinaStuff.setup_code_navigation = function()
  vim.api.nvim_create_user_command("SinaSetupCodeNavigation", function()
    -- create a virtual text on the current line of the current buffer
    local bufnr = vim.api.nvim_get_current_buf()
    local winnr = vim.api.nvim_get_current_win()
    local line = vim.fn.line(".")
    local col = vim.fn.col(".")
    local text = "Hello, world!"

    local mark_ns = vim.api.nvim_create_namespace('sina-code-navigation')
    local mark_id = vim.api.nvim_buf_set_extmark(0, mark_ns, line-1, col-1, {
      virt_text = {{text, "Comment"}},
      virt_text_pos = "overlay",
      priority = 10,
    })

    vim.lsp.buf_request(0, 'textDocument/documentSymbol', {
      textDocument = vim.lsp.util.make_text_document_params(),
    }, function(err, result)
      print(vim.inspect(result[1]))
    end)

    vim.lsp.buf.references()

  end, { nargs = 0 })
end

SinaStuff.setup_code_navigation()
