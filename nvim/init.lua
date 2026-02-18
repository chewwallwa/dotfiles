-- ==========================================================================
-- 1. INSTALADOR DE PLUGINS (LAZY.NVIM)
-- ==========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================================================
-- 2. CONFIGURAÇÕES GERAIS DO EDITOR E CUSTOM KEYMAPS
-- ==========================================================================
vim.g.mapleader = " "
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.cursorline = true
vim.opt.conceallevel = 2 
vim.opt.statusline = "%f%m\\ %=3l:%-2c\\ %y"

-- Ativa o corretor ortográfico para Português e Inglês
-- Ativa o corretor e define o idioma inicial como Português
vim.opt.spell = true
vim.opt.spelllang = "pt"

-- Atalho para alternar o dicionário (Modo Normal: Espaço + sl)
vim.keymap.set("n", "<leader>sl", function()
    if vim.o.spelllang == "pt" then
        vim.opt.spelllang = "en"
        vim.notify("Dicionário: INGLÊS", vim.log.levels.INFO)
    else
        vim.opt.spelllang = "pt"
        vim.notify("Dicionário: PORTUGUÊS", vim.log.levels.INFO)
    end
end, { desc = "Alternar Dicionário (PT/EN)" })

-- >> ATALHOS CUSTOMIZADOS (KEYMAPS) <<
local map = vim.keymap.set

-- Formatação Rápida Markdown (Modo Visual - Linha por Linha)
map("v", "<leader>b", [[:g/\S/s/^\s*\zs.\{-}\ze\s*$/**&**/<CR>:noh<CR>]], { desc = "Format: Bold", silent = true })
map("v", "<leader>i", [[:g/\S/s/^\s*\zs.\{-}\ze\s*$/*&*/<CR>:noh<CR>]], { desc = "Format: Italic", silent = true })
map("v", "<leader>x", [[:g/\S/s/^\s*\zs.\{-}\ze\s*$/***&***/<CR>:noh<CR>]], { desc = "Format: Bold + Italic", silent = true })
map("v", "<leader>s", [[:g/\S/s/^\s*\zs.\{-}\ze\s*$/~~&~~/<CR>:noh<CR>]], { desc = "Format: Strikethrough", silent = true })

-- Transformar linhas em Bullet List (Modo Visual - Ignora linhas vazias)
-- O '\s*\zs' garante que se a linha tiver indentação (espaços no começo), o bullet fica depois dos espaços!
map("v", "<leader>bl", [[:g/\S/s/^\s*\zs/- /<CR>:noh<CR>]], { desc = "Format: Add Bullets", silent = true })

-- Limpar TODAS as linhas em branco da seleção visual (Modo Visual)
map("v", "<leader>nl", ":g/^\\s*$/d<CR>:noh<CR>", { desc = "Remove Todas Newlines", silent = true })

-- Correção Instantânea de Typos (Modo Inserção)
map("i", "<C-l>", "<c-g>u<Esc>[s1z=`]a<c-g>u", { desc = "Corrige última palavra errada" })

-- ==========================================================================
-- 3. CONFIGURAÇÃO DO VIMTEX E ULTISNIPS
-- ==========================================================================
vim.g.vimtex_view_method = 'general'
vim.g.vimtex_view_general_viewer = 'zathura'
vim.g.vimtex_view_general_options = '--config-dir /home/thierry/.config/zathura-latex --synctex-forward @line:@col:@tex @pdf'
vim.g.vimtex_compiler_method = 'latexmk'
vim.g.vimtex_compiler_latexmk = {
    build_dir = '',
    callback = 1,
    continuous = 1,
    executable = 'latexmk',
    hooks = {},
    options = {
        '-verbose',
        '-file-line-error',
        '-synctex=1',
        '-interaction=nonstopmode',
        '-lualatex',
    },
}

vim.g.UltiSnipsExpandTrigger = '<tab>'
vim.g.UltiSnipsJumpForwardTrigger = '<tab>'
vim.g.UltiSnipsJumpBackwardTrigger = '<s-tab>'
vim.g.UltiSnipsSnippetDirectories = { "UltiSnips" }

-- ==========================================================================
-- 4. LISTA DE PLUGINS (LAZY)
-- ==========================================================================
require("lazy").setup({

  -- >> CHEATSHEET DE ATALHOS (JANELA FLUTUANTE)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = { delay = 500 },
  },

  -- >> AUTOCOMPLETAR E CORREÇÃO DE PALAVRAS (NOVO SETUP)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer", 
      "hrsh7th/cmp-path",   
      "quangnguyen30192/cmp-nvim-ultisnips", 
      "f3fora/cmp-spell", -- Plugin novo: sugere correção ortográfica no autocompletar
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn["UltiSnips#Anon"](args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          
          -- Cancela/fecha o menu de sugestões rápido
          ['<C-c>'] = cmp.mapping.abort(), 
          
          -- Só completa a palavra se você selecionou uma (evita completar coisas sem querer ao dar Enter)
          ['<CR>'] = cmp.mapping.confirm({ select = false }), 
        }),
        sources = cmp.config.sources({
          -- Limita para apenas 4 sugestões de correção ortográfica
          { name = 'spell', max_item_count = 4 }, 
          -- Deixa seus snippets e texto do arquivo como backup
          { name = 'ultisnips', max_item_count = 2 },
          { name = 'buffer', max_item_count = 2 },
        })
      })
    end
  },

  -- >> TEMA: GRUVBOX MATERIAL
  { 
    "sainnhe/gruvbox-material", 
    lazy = false, 
    priority = 1000, 
    config = function()
        vim.g.gruvbox_material_background = 'soft'
        vim.g.gruvbox_material_foreground = 'material'
        vim.g.gruvbox_material_enable_italic = 1
        vim.g.gruvbox_material_transparent_background = 1

        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("GruvboxCustom", { clear = true }),
            pattern = "gruvbox-material",
            callback = function()
                local hl = vim.api.nvim_set_hl

                hl(0, "CursorLine", { bg = "#3c3836" })
                hl(0, "CursorLineNr", { fg = "#d79921", bg = "#3c3836", bold = true })

                local bold = { fg = "#eaac2e", bold = true }
                hl(0, "@markup.strong", bold)
                hl(0, "markdownBold", bold)

                local bold_italic_props = { fg = "#d3869b", bold = true, italic = true }
                hl(0, "markdownBoldItalic", bold_italic_props)

                local italic = { fg = "#70c985", italic = true }
                hl(0, "@markup.italic", italic)
                hl(0, "markdownItalic", italic)

                local strike_props = { fg = "#477e89", strikethrough = true }
                hl(0, "markdownStrike", strike_props)
                hl(0, "@markup.strikethrough", strike_props)

                hl(0, "MeuH1", { fg = "#f3f0dd", bg = "#98813C", bold = true })
                hl(0, "MeuH2", { fg = "#f3f0dd", bg = "#618B6B", bold = true })
                hl(0, "MeuH3", { fg = "#f3f0dd", bg = "#496385", bold = true })
                hl(0, "MeuH4", { fg = "#f3f0dd", bg = "#4F4E6E", bold = true })
                hl(0, "MeuH5", { fg = "#f3f0dd", bg = "#664E3D", bold = true })
                hl(0, "MeuH6", { fg = "#f3f0dd", bg = "#5E3634", bold = true })

                hl(0, "RenderMarkdownInlineHighlight", { fg = "#282828", bg = "#d79921" })
            end
        })

        vim.cmd("colorscheme gruvbox-material")
    end
  },
  
  -- >> LATEX E SNIPPETS
  { "lervag/vimtex", ft = "tex" },
  { "sirver/ultisnips" },
  { "honza/vim-snippets" },

  -- >> TREE-SITTER
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function() 
      local status, configs = pcall(require, "nvim-treesitter.configs")
      if not status then return end
      configs.setup({ 
        ensure_installed = { "markdown", "markdown_inline", "lua", "vim", "latex", "bash" },
        highlight = { enable = true },
      })
    end
  },

  -- >> MARKDOWN RENDERER
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    config = function()
        require('render-markdown').setup({
            on = { attach = function() return true end },
            heading = {
                enabled = true,
                sign = false,
                left_pad = 0,
                icons = { "㊀ ", "㊁ ", "㊂ ", "㊃ ", "㊄ ", "㊅ " },
                position = 'overlay', 
                backgrounds = { "MeuH1", "MeuH2", "MeuH3", "MeuH4", "MeuH5", "MeuH6" },
                width = "full", 
            },
            highlights = {
                highlight = { bg = "RenderMarkdownInlineHighlight", fg = "RenderMarkdownInlineHighlight" },
            },
            code = {
                sign = false,
                width = "block",
                right_pad = 1,
            },
            anti_conceal = { enabled = false }, 
        })
    end
  },

  -- >> OUTROS PLUGINS (FOLDING, OUTLINE, BULLETS, FORMATTER)
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufRead",
    config = function()
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldenable = true
      local status, ufo = pcall(require, "ufo")
      if status then
          ufo.setup({
            provider_selector = function() return {'treesitter', 'indent'} end
          })
      end
    end
  },

  {
    "hedyhli/outline.nvim",
    keys = { { "<leader>o", "<cmd>Outline<CR>", desc = "Toggle Outline" } },
    config = function() 
        local status, outline = pcall(require, "outline")
        if status then outline.setup({}) end
    end
  },

  {
    "dkarter/bullets.vim",
    ft = { "markdown", "text" },
    init = function() vim.g.bullets_enabled_file_types = { 'markdown', 'text' } end
  },

  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    opts = {
      formatters_by_ft = { markdown = { "prettier" } },
      format_on_save = { timeout_ms = 500, lsp_fallback = true },
    },
  },

  {
    "okuuva/auto-save.nvim",
    event = { "InsertLeave", "TextChanged" },
    opts = { debounce_delay = 5000 },
  },

  {
    "brenoprata10/nvim-highlight-colors",
    config = function() 
        local status, hc = pcall(require, "nvim-highlight-colors")
        if status then hc.setup({ render = 'background' }) end
    end
  },
})
