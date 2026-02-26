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

-- Transformar linhas em Bullet List (Modo Visual - Ignora linhas vazias)
map("v", "<leader>bl", "<Esc>:'<,'>g/\\S/s/^\\s*\\zs/- /<CR>:noh<CR>", { desc = "Format: Add Bullets", silent = true })

-- Limpar TODAS as linhas em branco da seleção visual (Modo Visual)
map("v", "<leader>nl", "<Esc>:'<,'>g/^\\s*$/d<CR>:noh<CR>", { desc = "Remove Todas Newlines", silent = true })

-- Correção Instantânea de Typos (Modo Inserção)
map("i", "<C-l>", "<c-g>u<Esc>[s1z=`]a<c-g>u", { desc = "Corrige última palavra errada" })
-- ==========================================================================
-- TOGGLE BLOCKQUOTE INTELIGENTE (Corrigido)
-- ==========================================================================
local function toggle_quote()
    local mode = vim.fn.mode()
    
    if mode == 'v' or mode == 'V' or mode == '\22' then
        -- Sai do modo visual para registrar as coordenadas '< e '>
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)
        
        -- Aguarda o Neovim processar a saída do modo visual
        vim.schedule(function()
            local r1 = vim.fn.line("'<")
            local r2 = vim.fn.line("'>")
            
            -- Previne erro se a seleção for feita de baixo para cima
            if r1 > r2 then r1, r2 = r2, r1 end 
            
            for i = r1, r2 do
                local line = vim.fn.getline(i)
                if line:match("%S") then
                    if line:match("^%s*>%s?") then
                        -- Isola a string para não vazar o segundo retorno do gsub
                        local nova_linha = line:gsub("^%s*>%s?", "")
                        vim.fn.setline(i, nova_linha)
                    else
                        vim.fn.setline(i, "> " .. line)
                    end
                end
            end
        end)
    else
        -- Modo normal: processa apenas a linha atual
        local r1 = vim.fn.line(".")
        local line = vim.fn.getline(r1)
        
        if line:match("%S") then
            if line:match("^%s*>%s?") then
                local nova_linha = line:gsub("^%s*>%s?", "")
                vim.fn.setline(r1, nova_linha)
            else
                vim.fn.setline(r1, "> " .. line)
            end
        end
    end
end

vim.keymap.set({"n", "v"}, "<leader>q", toggle_quote, { desc = "Toggle Blockquote" })
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

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function()
        -- foldlevel = 2 -- fecha tudo (H1, H2, etc). 
        -- Se quisesse deixar o H1 aberto e fechar do H2 em diante, usaria 1.
        vim.opt_local.foldlevel = 0
    end
})
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

  -- >> AUTOCOMPLETAR E CORREÇÃO DE PALAVRAS
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer", 
      "hrsh7th/cmp-path",   
      "quangnguyen30192/cmp-nvim-ultisnips", 
      "f3fora/cmp-spell", 
    },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        snippet = { expand = function(args) vim.fn["UltiSnips#Anon"](args.body) end },
        mapping = cmp.mapping.preset.insert({
          ['<C-b>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-c>'] = cmp.mapping.abort(), 
          ['<CR>'] = cmp.mapping.confirm({ select = false }), 
        }),
        sources = cmp.config.sources({
          { name = 'spell', max_item_count = 4 }, 
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

  -- >> FORMATAÇÃO INTELIGENTE DE MARKDOWN (Substitui o script gigante)
  {
    "tadmccorkle/markdown.nvim",
    ft = "markdown",
    opts = {}, -- Carrega o plugin com inteligência Treesitter
    config = function(_, opts)
        require("markdown").setup(opts)
        local wk_map = vim.keymap.set
        
        -- Mapeia seus atalhos antigos para o motor inteligente do plugin (remap = true)
        wk_map({"n", "v"}, "<leader>b", "gsb", { remap = true, desc = "Format: Bold" })
        wk_map({"n", "v"}, "<leader>i", "gsi", { remap = true, desc = "Format: Italic" })
        wk_map({"n", "v"}, "<leader>s", "gss", { remap = true, desc = "Format: Strikethrough" })
        wk_map({"n", "v"}, "<leader>c", "gsc", { remap = true, desc = "Format: Inline Code" })
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
            render_modes = { 'n', 'i', 'c' },
            heading = {
                enabled = true, sign = false, left_pad = 0,
                icons = { "㊀ ", "㊁ ", "㊂ ", "㊃ ", "㊄ ", "㊅ " },
                position = 'overlay', 
                backgrounds = { "MeuH1", "MeuH2", "MeuH3", "MeuH4", "MeuH5", "MeuH6" },
                width = "full", 
            },
            highlights = { highlight = { bg = "RenderMarkdownInlineHighlight", fg = "RenderMarkdownInlineHighlight" } },
            pipe_table = { enabled = true, preset = 'round', style = 'full', cell = 'padded' },
            code = { sign = false, width = "block", right_pad = 1 },
            anti_conceal = { enabled = true }, 
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
      if status then ufo.setup({ provider_selector = function() return {'treesitter', 'indent'} end }) end
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
