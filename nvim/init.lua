-- ==========================================================================
-- 1. PLUGIN MANAGER (LAZY.NVIM)
-- ==========================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ==========================================================================
-- 2. GENERAL EDITOR SETTINGS & CUSTOM KEYMAPS
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
vim.opt.splitbelow = true
vim.opt.splitright = true

-- >> CUSTOM KEYMAPS <<
local map = vim.keymap.set

-- Transform lines into Bullet List (Visual Mode - Ignores empty lines)
map("v", "<leader>bl", "<Esc>:'<,''g/\\S/s/^\\s*\\zs/- /<CR>:noh<CR>", { desc = "Format: Add Bullets", silent = true })

-- Remove ALL blank lines from visual selection (Visual Mode)
map("v", "<leader>nl", "<Esc>:'<,'>g/^\\s*$/d<CR>:noh<CR>", { desc = "Remove All Newlines", silent = true })

-- Instant Typos Correction (Insert Mode)
map("i", "<C-l>", "<c-g>u<Esc>1z=`]a<c-g>u", { desc = "Correct current word" })

-- ==========================================================================
-- MARKDOWN FOLD SHIELDING (Prevents Esc/:w from resetting folds)
-- ==========================================================================
-- Configure Neovim to save ONLY folds and cursor position in the "view"
vim.opt.viewoptions = "folds,cursor"

local fold_fix_group = vim.api.nvim_create_augroup("FixMarkdownFolds", { clear = true })

-- 1. Split second BEFORE saving: take a "snapshot" of current folds
vim.api.nvim_create_autocmd("BufWritePre", {
    group = fold_fix_group,
    pattern = "*.md",
    callback = function()
        vim.cmd("silent! mkview 1")
    end
})

-- 2. Split second AFTER saving: restore folds exactly as they were
vim.api.nvim_create_autocmd("BufWritePost", {
    group = fold_fix_group,
    pattern = "*.md",
    callback = function()
        vim.cmd("silent! loadview 1")
    end
})

-- ==========================================================================
-- SMART BLOCKQUOTE TOGGLE
-- ==========================================================================
local function toggle_quote()
    local mode = vim.fn.mode()
    
    if mode == 'v' or mode == 'V' or mode == '\22' then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'x', false)
        
        vim.schedule(function()
            local r1 = vim.fn.line("'<")
            local r2 = vim.fn.line("'>")
            
            if r1 > r2 then r1, r2 = r2, r1 end 
            
            for i = r1, r2 do
                local line = vim.fn.getline(i)
                if line:match("%S") then
                    if line:match("^%s*>%s?") then
                        local new_line = line:gsub("^%s*>%s?", "")
                        vim.fn.setline(i, new_line)
                    else
                        vim.fn.setline(i, "> " .. line)
                    end
                end
            end
        end)
    else
        local r1 = vim.fn.line(".")
        local line = vim.fn.getline(r1)
        
        if line:match("%S") then
            if line:match("^%s*>%s?") then
                local new_line = line:gsub("^%s*>%s?", "")
                vim.fn.setline(r1, new_line)
            else
                vim.fn.setline(r1, "> " .. line)
            end
        end
    end
end

vim.keymap.set({"n", "v"}, "<leader>q", toggle_quote, { desc = "Toggle Blockquote" })


-- ==========================================================================
-- OCTAVE: MATLAB IDE LAYOUT (100% Clean Visual)
-- ==========================================================================
_G.run_octave_matlab_layout = function()
    -- 0. SAFETY CHECK
    if vim.bo.buftype ~= "" then
        vim.notify("⚠️ Click on your .m code before pressing the shortcut!", vim.log.levels.WARN)
        return
    end

    vim.cmd("silent! update")
    
    local filedir = vim.fn.expand("%:p:h")
    local filename = vim.fn.expand("%:t:r")
    local ws_file = "/tmp/octave_workspace.txt"
    local helper_file = "/tmp/refresh_ws.m"

    -- 1. FIXED HELPER FUNCTION
    local helper_code = "function refresh_ws()\n" ..
                        "  fid = fopen('" .. ws_file .. "', 'w');\n" ..
                        "  if fid > 0\n" ..
                        "    str = evalin('base', \"evalc('whos')\");\n" ..
                        "    if ischar(str), fputs(fid, str); end\n" ..
                        "    fclose(fid);\n" ..
                        "  end\n" ..
                        "endfunction\n"
    
    local f = io.open(helper_file, "w")
    if f then
        f:write(helper_code)
        f:close()
    end
    os.execute("touch " .. ws_file)

    -- 2. Watcher to update the window
    local uv = vim.uv or vim.loop
    if _G.ws_watcher then _G.ws_watcher:stop() end
    _G.ws_watcher = uv.new_fs_event()
    _G.ws_watcher:start(ws_file, {}, vim.schedule_wrap(function()
        vim.cmd("silent! checktime " .. ws_file)
    end))

    -- 3. Check and build Layout
    local term_exists = _G.octave_term_buf and vim.api.nvim_buf_is_valid(_G.octave_term_buf)

    if not term_exists then
        -- TOP PANEL (Workspace)
        vim.cmd("botright vsplit " .. ws_file)
        vim.opt_local.autoread = true
        vim.opt_local.swapfile = false
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.winbar = "%#Title#%= WORKSPACE VARIABLES %="
        vim.opt_local.statusline = " " 
        vim.opt_local.cursorline = false 
        
        -- BOTTOM PANEL (Command Window)
        vim.cmd("belowright split")
        vim.cmd("enew")
        vim.opt_local.winbar = "%#Title#%= COMMAND WINDOW %="
        vim.opt_local.statusline = " "
        vim.opt_local.cursorline = false 
        
        _G.octave_term_buf = vim.api.nvim_get_current_buf()
        _G.octave_job_id = vim.fn.termopen("env QT_QPA_PLATFORM=xcb octave --no-gui -q")
        
        vim.fn.chansend(_G.octave_job_id, "addpath('/tmp'); clc;\n")
        
        vim.cmd("wincmd h")
    end

    -- 4. Execution command
    local cmd = string.format("clc; cd '%s'; %s; refresh_ws;\n", filedir, filename)
    vim.fn.chansend(_G.octave_job_id, cmd)
end

pcall(vim.keymap.del, "n", "<leader>r")

vim.api.nvim_create_autocmd("FileType", {
    pattern = { "matlab", "octave" },
    callback = function()
        -- Run shortcut
        vim.keymap.set("n", "<leader>r", _G.run_octave_matlab_layout, { buffer = true, desc = "Run Interactive Octave" })
        
        -- Close panels shortcut (Space + q)
        if _G.close_octave_matlab_layout then
            vim.keymap.set("n", "<leader>q", _G.close_octave_matlab_layout, { buffer = true, desc = "Close Panels" })
        end
    end,
})

-- ==========================================================================
-- PYTHON: MATLAB IDE LAYOUT (Streamlined & Formatted Workspace)
-- ==========================================================================
_G.run_python_ide_layout = function()
    if vim.bo.buftype ~= "" then
        vim.notify("⚠️ Click on your .py code before pressing the shortcut!", vim.log.levels.WARN)
        return
    end

    vim.cmd("silent! update")
    
    local filepath = vim.fn.expand("%:p")
    local ws_file = "/tmp/python_workspace.txt"
    local helper_file = "/tmp/dump_ws.py"

    -- 1. Updated Workspace Extractor
    local helper_code = [[
def dump(glbs):
    with open('/tmp/python_workspace.txt', 'w', encoding='utf-8') as f:
        f.write(f"{'Name'.ljust(15)} {'Type'.ljust(12)} Info\n")
        f.write("-" * 50 + "\n")
        
        for k, v in glbs.items():
            if k.startswith('_'): continue
            t = type(v).__name__
            if t in ['module', 'function', 'builtin_function_or_method', 'type']: continue
            if k in ['In', 'Out', 'get_ipython', 'exit', 'quit', 'dump']: continue
            
            # Value formatting: 4 decimal places for floats, truncated strings
            if 'float' in t:
                val = f"{v:.4f}"
            elif t == 'ndarray':
                val = f"{v.shape} {v.dtype}"
            elif t == 'DataFrame':
                val = f"DF {v.shape}"
            elif t in ['list', 'dict', 'tuple', 'set']:
                val = f"L:{len(v)} -> {str(v)[:20]}..." if len(str(v)) > 20 else f"L:{len(v)} -> {str(v)}"
            else:
                s = str(v).replace('\n', ' ')
                val = f"{s[:30]}..." if len(s) > 30 else s
                
            f.write(f"{k.ljust(15)} {t.ljust(12)} {val}\n")
]]
    local f = io.open(helper_file, "w")
    if f then
        f:write(helper_code)
        f:close()
    end
    os.execute("touch " .. ws_file)

    local uv = vim.uv or vim.loop
    if _G.py_ws_watcher then _G.py_ws_watcher:stop() end
    _G.py_ws_watcher = uv.new_fs_event()
    _G.py_ws_watcher:start(ws_file, {}, vim.schedule_wrap(function()
        vim.cmd("silent! checktime " .. ws_file)
    end))

    local term_exists = _G.python_term_buf and vim.api.nvim_buf_is_valid(_G.python_term_buf)

    if not term_exists then
        vim.cmd("botright vsplit " .. ws_file)
        vim.opt_local.autoread = true
        vim.opt_local.swapfile = false
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.winbar = "%#Title#%= WORKSPACE VARIABLES %="
        vim.opt_local.statusline = " "
        vim.opt_local.cursorline = false
        
        vim.cmd("belowright split")
        vim.cmd("enew")
        vim.opt_local.winbar = "%#Title#%= COMMAND WINDOW %="
        vim.opt_local.statusline = " "
        vim.opt_local.cursorline = false
        
        _G.python_term_buf = vim.api.nvim_get_current_buf()
        _G.python_job_id = vim.fn.termopen("ipython")
        
        vim.fn.chansend(_G.python_job_id, "import sys; sys.path.append('/tmp'); from dump_ws import dump\nclear\n")
        
        vim.cmd("wincmd h")
    end

    local cmd = string.format("clear\n%%reset -f\nfrom dump_ws import dump\n%%run -i '%s'\ndump(globals())\n", filepath)
    vim.fn.chansend(_G.python_job_id, cmd)
end

-- Function to clean up and close Python tabs
_G.close_python_ide_layout = function()
    local ws_buf = vim.fn.bufnr("/tmp/python_workspace.txt")
    if ws_buf ~= -1 then vim.api.nvim_buf_delete(ws_buf, { force = true }) end
    if _G.python_term_buf and vim.api.nvim_buf_is_valid(_G.python_term_buf) then
        vim.api.nvim_buf_delete(_G.python_term_buf, { force = true })
        _G.python_term_buf = nil
    end
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "python",
    callback = function()
        vim.keymap.set("n", "<leader>r", _G.run_python_ide_layout, { buffer = true, desc = "Run Python IDE" })
        vim.keymap.set("n", "<leader>q", _G.close_python_ide_layout, { buffer = true, desc = "Close Panels" })
    end,
})


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

  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = { delay = 500 },
  },

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

                hl(0, "MyH1", { fg = "#f3f0dd", bg = "#98813C", bold = true })
                hl(0, "MyH2", { fg = "#f3f0dd", bg = "#618B6B", bold = true })
                hl(0, "MyH3", { fg = "#f3f0dd", bg = "#496385", bold = true })
                hl(0, "MyH4", { fg = "#f3f0dd", bg = "#4F4E6E", bold = true })
                hl(0, "MyH5", { fg = "#f3f0dd", bg = "#664E3D", bold = true })
                hl(0, "MyH6", { fg = "#f3f0dd", bg = "#5E3634", bold = true })

                hl(0, "RenderMarkdownInlineHighlight", { fg = "#282828", bg = "#d79921" })
            end
        })
        vim.cmd("colorscheme gruvbox-material")
    end
  },
  
  { "lervag/vimtex", ft = "tex" },
  { "sirver/ultisnips" },
  { "honza/vim-snippets" },

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

  {
    "tadmccorkle/markdown.nvim",
    ft = "markdown",
    opts = {}, 
    config = function(_, opts)
        require("markdown").setup(opts)
        local wk_map = vim.keymap.set
        
        wk_map({"n", "v"}, "<leader>b", "gsb", { remap = true, desc = "Format: Bold" })
        wk_map({"n", "v"}, "<leader>i", "gsi", { remap = true, desc = "Format: Italic" })
        wk_map({"n", "v"}, "<leader>s", "gss", { remap = true, desc = "Format: Strikethrough" })
        wk_map({"n", "v"}, "<leader>c", "gsc", { remap = true, desc = "Format: Inline Code" })
    end
  },

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
                backgrounds = { "MyH1", "MyH2", "MyH3", "MyH4", "MyH5", "MyH6" },
                width = "full", 
            },
            highlights = { highlight = { bg = "RenderMarkdownInlineHighlight", fg = "RenderMarkdownInlineHighlight" } },
            pipe_table = { enabled = true, preset = 'round', style = 'full', cell = 'padded' },
            code = { sign = false, width = "block", right_pad = 1 },
            anti_conceal = { enabled = true }, 
        })
    end
  },

{
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    init = function()
      -- Native Neovim config set BEFORE plugin loads.
      -- Level 99 forces editor to open everything and stop auto-closing folds.
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    config = function()
      require("ufo").setup({
        provider_selector = function(bufnr, filetype, buftype)
          -- Strictly locks the fold engine to Treesitter.
          return {'treesitter', 'indent'}
        end
      })
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
      format_on_save = function(bufnr)
        -- NATIVE LOCK: Prevents Prettier from rewriting the file 
        -- on every Auto-Save, keeping folds intact when pressing Esc.
        if vim.bo[bufnr].filetype == "markdown" then
            return nil
        end
        return { timeout_ms = 500, lsp_fallback = true }
      end,
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
