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

local python_diagnostic_plugin = {}

if vim.fn.hostname() == "personalbox" then
  python_diagnostic_plugin = {
      "siadat/python-diagnostic.nvim",
      dev = true,
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
else
  python_diagnostic_plugin = {
      "siadat/python-diagnostic.nvim",
      dev = true,
      config = function()
        require('python-diagnostic').setup({
          command = "bash run-tests.bash",
        })
        vim.api.nvim_create_autocmd({"BufReadPost"}, {
          pattern = "*.py",
          command = "PythonTestOnSave",
        })
      end,
    }
end

require('lazy').setup({
  python_diagnostic_plugin,
  -- NOTE: First, some plugins that don't require any configuration

  -- Git related plugins
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb',

  -- Detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',
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
  { 'folke/which-key.nvim', opts = {} },
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

  -- {
  --   -- Theme inspired by Atom
  --   'navarasu/onedark.nvim',
  --   priority = 1000,
  --   config = function()
  --     if false and vim.fn.hostname() == "personalbox" then
  --       vim.g.onedark_config = { style = 'darker' }
  --       vim.cmd.colorscheme 'onedark'
  --     end
  --   end,
  -- },

  {
    'ellisonleao/gruvbox.nvim',
    priority = 1000,
    config = function()
      if vim.fn.hostname() ~= "personalbox" then
        vim.cmd.colorscheme 'gruvbox'
      end
    end,
  },

  {
    "bluz71/vim-nightfly-colors",
    name = "nightfly",
    -- lazy = false,
    priority = 1000,
    config = function()
      if vim.fn.hostname() == "personalbox" then
        vim.cmd.colorscheme 'nightfly'
      end
    end,
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
        lualine_c = {'branch', 'diff', 'diagnostics'},
        lualine_x = {'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
    },
  },

  {
    -- Add indentation guides even on blank lines
    'lukas-reineke/indent-blankline.nvim',
    -- Enable `lukas-reineke/indent-blankline.nvim`
    -- See `:help ibl`
    main = 'ibl',
    opts = {},
  },

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


-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!

-- Set highlight on search
vim.o.hlsearch = true

-- Make line numbers default
vim.wo.number = true
vim.wo.relativenumber = true
vim.wo.wrap = false

-- Enable mouse mode
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

-- [[ Configure Treesitter ]]
-- See `:help nvim-treesitter`
-- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
vim.defer_fn(function()
  require('nvim-treesitter.configs').setup {
    -- Add languages to be installed here that you want installed for treesitter
    ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'javascript', 'typescript', 'vimdoc', 'vim', 'bash', 'yaml', 'zig' },

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
  }
end, 0)

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
  nmap('<leader>D', require('telescope.builtin').lsp_type_definitions, 'Type [D]efinition')
  nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
  nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

  -- See `:help K` for why this keymap
  nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

  -- Lesser used LSP functionality
  nmap('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
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

-- document existing key chains
require('which-key').register {
  ['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
  ['<leader>d'] = { name = '[D]ocument', _ = 'which_key_ignore' },
  ['<leader>g'] = { name = '[G]it', _ = 'which_key_ignore' },
  ['<leader>h'] = { name = 'Git [H]unk', _ = 'which_key_ignore' },
  ['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
  ['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
  ['<leader>t'] = { name = '[T]oggle', _ = 'which_key_ignore' },
  ['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
}
-- register which-key VISUAL mode
-- required for visual <leader>hs (hunk stage) to work
require('which-key').register({
  ['<leader>'] = { name = 'VISUAL <leader>' },
  ['<leader>h'] = { 'Git [H]unk' },
}, { mode = 'v' })

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
  -- gopls = {},
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

vim.keymap.set('n', '<c-f>', '<esc>', { desc = 'sina: escape' })
vim.keymap.set('i', '<c-f>', '<esc>', { desc = 'sina: escape' })
vim.keymap.set('v', '<c-f>', '<esc>', { desc = 'sina: escape' })
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
vim.o.hlsearch = true
vim.o.splitright = true
vim.o.equalalways = true
vim.wo.number = true
vim.wo.relativenumber = false
vim.wo.wrap = false
vim.o.wrapscan = false

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
  vim.cmd(string.format("term man --pager=cat %q", opts.fargs[1]))
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

SinaStuff.get_chezmoi_sources = function()
  return vim.fn.systemlist("chezmoi managed -i files -p source-absolute", "", 0)
end

SinaStuff.chezmoi_sources = SinaStuff.get_chezmoi_sources()

-- TODO: convert chezmoi_sticky_term_win to a table to support multiple tabs
-- The reason for using a global variable is that I am re-:source-ing this file
-- on save, and I want to keep using the same terminal window.
-- If a new terminal window is opened each time then keeping track of chezmoi_sticky_term_win is pointless
-- or I shouldn't :source this file automatically on save and I will have to manually :source it or restart neovim
vim.g.chezmoi_sticky_term_win = vim.g.chezmoi_sticky_term_win or nil

-- vim.api.nvim_create_autocmd({"BufWritePost"}, {
--   pattern = SinaStuff.chezmoi_sources,
--   callback = function()
--     local command = "cd ~/.local/share/chezmoi && make update_short"
--     local final_command = string.format("bash -c %q", command)
--     vim.fn.jobstart(final_command, {
--         pty = false,
--         detach = false,
--         stdout_buffered = true,
--         on_stderr = function(_, data)
--             if #data == 1 and data[1] == "" then
--                 return
--             end
--             print(string.format("STDERR for %q:", final_command), vim.inspect(data))
--         end,
--         on_stdout = function(_, data)
--             if #data == 1 and data[1] == "" then
--                 print("Chezmoi sources updated")
--                 return
--             end
--             if #data > 0 and data[1] == "HAS_DIFF" then
--                 print("Chezmoi sources updated, but found changes, please commit and push changes using :SinaReviewAndPushChezmoiChanges")
--                 return
--             end
--             print(vim.inspect(data))
--         end,
--         on_exit = function(_, code)
--             if code > 0 then
--                 vim.cmd("silent source ~/.local/share/chezmoi/dot_config/nvim/init.lua")
--             else
--                 vim.cmd("silent source ~/.config/nvim/init.lua")
--             end
--         end,
--     })
--   end,
--   group = vim.api.nvim_create_augroup('SinaSourcesUpdate', { clear = true }),
-- })
vim.api.nvim_create_user_command("SinaReviewAndPushChezmoiChanges", function()
  vim.cmd.vsplit()
  vim.cmd("term cd ~/.local/share/chezmoi && make update")
end, { nargs = 0 })

-- TODO: convert diff_sticky_win to a table to support multiple tabs
local diff_sticky_win = nil
SinaStuff.show_or_update_diff_win = function()
    local current_win = vim.api.nvim_get_current_win()
    local wins = vim.api.nvim_tabpage_list_wins(0)

    local command = "term git --no-pager diff --exit-code --stat -p"
    if vim.tbl_contains(wins, diff_sticky_win) then
      -- run command in that existing terminal window:
      vim.api.nvim_set_current_win(diff_sticky_win)
      vim.cmd(command)
    else
      -- open a new terminal window:
      vim.cmd.vsplit()
      vim.cmd(command)
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
  vim.cmd.term("fpb %")
end, { nargs = 0 })

SinaStuff.execute_command = function(command, callback)
  local stdout = ""
  local stderr = ""
  vim.fn.jobstart(command, {
    pty = false,
    detach = false,
    stdout_buffered = false,
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
      prompt_title = "Pick a command",
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
  local commands = {}
  for _,v in ipairs(files) do
    local command = string.format("tabnew %s", v)
    -- remove ".../.local/share/chezmoi/" from v:
    display = string.gsub(v, "^.*sina/.local/share/chezmoi/", "")
    table.insert(commands, {display, command})
  end
  SinaStuff.telescope_wrapper({
    telescope_opts = require("telescope.themes").get_dropdown{},
    items = commands,
  })
end, { desc = 'Sina: open dotfiles with Telescope' })

vim.keymap.set('n', ';f', function()
  local commands = SinaStuff.get_commandsfile()
  SinaStuff.telescope_wrapper({
    items = commands,
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


vim.keymap.set('n', ';tp', function() vim.cmd('tabprevious') end, { noremap = true, desc = "Sina: prev tab" })
vim.keymap.set('n', ';tn', function() vim.cmd('tabnext') end, { noremap = true, desc = "Sina: next tab" })
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

-- SinaStuff.format_script_in_yaml = function()
--   local bufnr = vim.api.nvim_get_current_buf()
--   if vim.bo[bufnr].filetype ~= "yaml" then
--     -- TODO: TIL vim.notify, use it more often!
--     vim.notify("Not a yaml file")
--     return
--   end
--   local root = SinaStuff.get_root(bufnr, "yaml")
--   local query_string = [[
--   (
--     (block_mapping_pair
--       key: (_) @key1
--       value: (block_node (block_scalar)) @injection.language
--     )
--     (block_mapping_pair
--       key: (_) @key
--       value: ((block_node (block_scalar)) @value)  @injection.content
--     )
--     (#eq? @key1 "language")
--     (#eq? @key "content")
--   )
--   ]]
--   local query = vim.treesitter.query.parse("yaml", query_string)
--   for id, node in query:iter_captures(root, bufnr, 0, -1) do
--     local node_text = string.format(">> %q", vim.treesitter.get_node_text(node, bufnr))
--     print(id, node_text)
--   end
-- end
-- vim.api.nvim_create_user_command("FormatScriptInYaml", SinaStuff.format_script_in_yaml, { nargs = 0 })
-- SinaStuff.format_script_in_yaml()
