-- Vim settings
vim.g.mapleader = " "
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.softtabstop = 2
vim.opt.number = true
vim.opt.showmode = false
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.keymap.set('n', '[d',
  vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" }
)

vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })

vim.keymap.set('n', '<leader>e',
  vim.diagnostic.open_float, { desc = "Show diagnostic error messages" }
)

vim.keymap.set('n', '<leader>q',
  vim.diagnostic.setloclist, { desc = "Open dianostic quickfix list" }
)

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-hightlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Package manager install
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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


-- Plugins
require("lazy").setup({
	"folke/which-key.nvim",
	{ "folke/neoconf.nvim", cmd = "Neoconf"},
	"folke/neodev.nvim",
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000 },
  {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
  },
  {"williamboman/mason.nvim"},
  {"williamboman/mason-lspconfig.nvim"},
  {"j-hui/fidget.nvim", opts = {}},
  {"neovim/nvim-lspconfig"},
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'hrsh7th/cmp-nvim-lsp',
      'hrsh7th/cmp-path',
      'rafamadriz/friendly-snippets',
    },
  },
  {"nvim-tree/nvim-web-devicons"},
  {
    'nvim-telescope/telescope.nvim', tag = '0.1.5',
    dependencies = {
      'nvim-lua/plenary.nvim',
    }
  },
  { "folke/neodev.nvim", opts = {} },
  {
    'numToStr/Comment.nvim',
  },
  {
      'nvim-lualine/lualine.nvim',
      dependencies = { 'nvim-tree/nvim-web-devicons' }
  },
  { "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    opts = {
      ensure_installed = { 'lua', 'rust' },
      auto_install = true,
      highlight = {
        enable = true,
      },
    },
    config = function(_, opts)
      require('nvim-treesitter.install').prefer_git = true
      require('nvim-treesitter.configs').setup(opts)
    end,
  }
})

-- Theme configuration for catppuccin
require("catppuccin").setup({
    flavour = "macchiato", -- latte, frappe, macchiato, mocha
    background = { -- :h background
        light = "frappe",
        dark = "macchiato",
    },
    transparent_background = false, -- disables setting the background color.
    integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        notify = false,
        mini = {
            enabled = true,
            indentscope_color = "",
        },
    },
})

-- setup must be called before loading
vim.cmd.colorscheme "catppuccin"

-- LSP configs
local on_attach = function(_, bufnr)
  local nmap = function(keys, func, desc)
    if desc then
      desc = 'LSP: ' .. desc
    end

    vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
  end

  nmap('gd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
  nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
  nmap('gI', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
  nmap('<leader>rn', vim.lsp.buf.rename, 'Rename')
  nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
  nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')
  nmap('gD', vim.lsp.buf.declaration, 'Goto declaration')
end

require("lualine").setup({})
require("neodev").setup({})
require("mason").setup()
require("mason-lspconfig").setup()

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)


require("lspconfig").lua_ls.setup ({
   settings = {
     Lua = {
        completion = {
          callSnipper = "Replace"
        },
        diagnostics = {
          globals = {'vim'},
        },
      },
    },
    capabilities = capabilities,
    on_attach = on_attach,
})

require("lspconfig").rust_analyzer.setup ({
    on_attach = on_attach,
})

-- Cmp configs
local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = 'menu,menuone,noinsert',
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete {},
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = 'path' },
  },
}

-- Telescope configs
require('telescope').setup{
  defaults = {
    file_ignore_patterns = {
      "node_modules",
      "build",
      "target",
      ".git",
    }
  },
}

-- Telescope shortcuts
vim.keymap.set('n', '<leader>sf',
require('telescope.builtin').find_files, { desc = 'Search Files' })

vim.keymap.set('n', '<leader>sw',
require('telescope.builtin').grep_string, { desc = 'Search current Word'})

vim.keymap.set('n', '<leader>sk',
require('telescope.builtin').keymaps, { desc = 'Search Keymaps' })

vim.keymap.set('n', '<leader>sd',
require('telescope.builtin').diagnostics, { desc = 'Search Diagnostics' })
