-- ==========================================================================
-- 1. PLUGIN INSTALLER (LAZY.NVIM)
-- ==========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================================================
-- 2. GENERAL EDITOR SETTINGS AND CUSTOM KEYMAPS
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

-- Enables spell checker and sets the initial language to Portuguese
vim.opt.spell = true
vim.opt.spelllang = "pt"

-- Shortcut to toggle dictionary (Normal Mode: Space + sl)
vim.keymap.set("n", "<leader>sl", function()
    if vim.o.spelllang == "pt" then
        vim.opt.spelllang = "en"
        vim.notify("Dictionary: ENGLISH", vim.log.levels.INFO)
    else
        vim.opt.spelllang = "pt"
        vim.notify("Dictionary: PORTUGUESE", vim.log.levels.INFO)
    end
end, { desc = "Toggle Dictionary (PT/EN)" })

-- >> CUSTOM KEYMAPS <<
local map = vim.keymap.set

-- Smart Markdown Formatting Function:
-- 1 line ('v' selection): Formats exactly the selected word/text.
-- Multiple lines (or 'V' selection): Formats the beginning and end of each line, ignoring empty ones.
local function smart_format(marker)
    return function()
        local num_lines = math.abs(vim.fn.line("v") - vim.fn.line(".")) + 1
        local current_mode = vim.fn.mode()
        
        if num_lines == 1 and current_mode == "v" then
            -- Exact surgical replacement of the selected text
            return "c" .. marker .. "<C-r>\"" .. marker .. "<ESC>"
        else
            -- Smart line-by-line RegEx (ignores empty lines and spaces)
            return "<Esc>:'<,'>g/\\S/s/^\\s*\\zs.\\{-}\\ze\\s*$/" .. marker .. "&" .. marker .. "/<CR>:noh<CR>"
        end
    end
end

-- Mappings using the Smart Function
map("v", "<leader>b", smart_format("**"), { expr = true, desc = "Format: Bold" })
map("v", "<leader>i", smart_format("*"), { expr = true, desc = "Format: Italic" })
map("v", "<leader>x", smart_format("***"), { expr = true, desc = "Format: Bold + Italic" })
map("v", "<leader>s", smart_format("~~"), { expr = true, desc = "Format: Strikethrough" })

-- Transform lines into Bullet List (Visual Mode - Ignores empty lines)
map("v", "<leader>bl", "<Esc>:'<,'>g/\\S/s/^\\s*\\zs/- /<CR>:noh<CR>", { desc = "Format: Add Bullets", silent = true })

-- Clear ALL empty lines from visual selection (Visual Mode)
map("v", "<leader>nl", "<Esc>:'<,'>g/^\\s*$/d<CR>:noh<CR>", { desc = "Remove All Newlines", silent = true })

-- Instant Typo Correction (Insert Mode)
map("i", "<C-l>", "<c-g>u<Esc>[s1z=`]a<c-g>u", { desc = "Correct last misspelled word" })

-- ==========================================================================
-- 3. VIMTEX AND ULTISNIPS CONFIGURATION
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
-- 4. PLUGIN LIST (LAZY)
-- ==========================================================================
require("lazy").setup({

  -- >> KEYMAP CHEATSHEET (FLOATING WINDOW)
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = { delay = 500 },
  },

  -- >> AUTOCOMPLETE AND WORD CORRECTION (NEW SETUP)
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-buffer", 
      "hrsh7th/cmp-path",   
      "quangnguyen30192/cmp-nvim-ultisnips", 
      "f3fora/cmp-spell", -- New plugin: suggests spelling corrections in autocomplete
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
          
          -- Quickly cancels/closes the suggestions menu
          ['<C-c>'] = cmp.mapping.abort(), 
          
          -- Only completes the word if you selected one (prevents accidental completion on Enter)
          ['<CR>'] = cmp.mapping.confirm({ select = false }), 
        }),
        sources = cmp.config.sources({
          -- Limits to only 4 spelling correction suggestions
          { name = 'spell', max_item_count = 4 }, 
          -- Keeps your snippets and buffer text as backup
          { name = 'ultisnips', max_item_count = 2 },
          { name = 'buffer', max_item_count = 2 },
        })
      })
    end
  },

  -- >> THEME: GRUVBOX MATERIAL
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
  
  -- >> LATEX AND SNIPPETS
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

  -- >> OTHER PLUGINS (FOLDING, OUTLINE, BULLETS, FORMATTER)
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
