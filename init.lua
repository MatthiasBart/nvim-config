-- created using Claude Opus 4.6 from Matthias Bartholomaeus
-- =============================================================================
-- Minimal Neovim IDE Config
-- =============================================================================
-- Plugins: nvim-lspconfig, nvim-treesitter, telescope.nvim, plenary.nvim,
--          nvim-cmp, cmp-nvim-lsp, cmp-buffer, cmp-path
-- Plugin manager: lazy.nvim (auto-bootstrapped)
--
-- INSTALLATION:
--   1. Back up any existing config:  mv ~/.config/nvim ~/.config/nvim.bak
--   2. Copy this file:               mkdir -p ~/.config/nvim && cp init.lua ~/.config/nvim/
--   3. Open Neovim:                   nvim
--      → lazy.nvim will auto-install itself and all plugins on first launch.
--   4. After install, run:            :TSInstall <language>   (e.g. :TSInstall python lua)
--   5. Install language servers externally (see LSP section below).
--
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. GENERAL SETTINGS
-- ---------------------------------------------------------------------------

vim.g.mapleader = ' '                  -- Space as leader key
vim.g.maplocalleader = ' '

vim.opt.number         = true          -- Line numbers
vim.opt.relativenumber = true          -- Relative line numbers
vim.opt.tabstop        = 4             -- Tab width
vim.opt.shiftwidth     = 4             -- Indent width
vim.opt.expandtab      = true          -- Tabs → spaces
vim.opt.smartindent    = true          -- Auto-indent new lines
vim.opt.wrap           = false         -- No line wrapping
vim.opt.cursorline     = true          -- Highlight current line
vim.opt.signcolumn     = 'yes'         -- Always show sign column (for diagnostics)
vim.opt.termguicolors  = true          -- 24-bit color
vim.opt.scrolloff      = 8             -- Keep 8 lines above/below cursor
vim.opt.updatetime     = 250           -- Faster CursorHold (for diagnostics)
vim.opt.splitright     = true          -- Vertical splits open right
vim.opt.splitbelow     = true          -- Horizontal splits open below
vim.opt.ignorecase     = true          -- Case-insensitive search...
vim.opt.smartcase      = true          -- ...unless you use uppercase
vim.opt.clipboard      = 'unnamedplus' -- Use system clipboard
vim.opt.undofile       = true          -- Persistent undo across sessions


-- ---------------------------------------------------------------------------
-- 2. KEYMAPS (plugin-independent)
-- ---------------------------------------------------------------------------

local map = vim.keymap.set

-- Terminal: Esc exits terminal mode
map('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Window navigation with Ctrl+hjkl
map('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
map('n', '<C-j>', '<C-w>j', { desc = 'Move to lower window' })
map('n', '<C-k>', '<C-w>k', { desc = 'Move to upper window' })
map('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Clear search highlight
map('n', '<Esc>', '<cmd>nohlsearch<CR>', { desc = 'Clear search highlight' })

-- Quick terminal split
map('n', '<leader>t', '<cmd>vsplit | terminal<CR>', { desc = 'Open terminal in vsplit' })


-- ---------------------------------------------------------------------------
-- 3. PLUGIN MANAGER (lazy.nvim — auto-bootstrap)
-- ---------------------------------------------------------------------------

local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git', 'clone', '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable',
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)


-- ---------------------------------------------------------------------------
-- 4. PLUGINS
-- ---------------------------------------------------------------------------

require('lazy').setup({

    -- -----------------------------------------------------------------------
    -- Treesitter: syntax parsing, highlighting, text objects
    -- -----------------------------------------------------------------------
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        config = function()
            -- Treesitter highlighting and indent are now enabled via Neovim options
            -- (the old require('nvim-treesitter.configs').setup API was removed)
            vim.treesitter.language.register('bash', 'sh')

            -- Enable treesitter-based highlighting and indentation
            vim.api.nvim_create_autocmd('FileType', {
                callback = function()
                    -- Attempt to start treesitter highlight; silently fails
                    -- if no grammar is installed for this filetype
                    pcall(vim.treesitter.start)
                end,
            })

        end,
    },

    -- -----------------------------------------------------------------------
    -- Telescope: fuzzy finder for files, grep, buffers, LSP, everything
    -- -----------------------------------------------------------------------
    {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
        config = function()
            local telescope = require('telescope')
            local builtin   = require('telescope.builtin')

            telescope.setup({
                defaults = {
                    file_ignore_patterns = { 'node_modules', '.git/', '__pycache__' },
                },
            })

            -- File pickers
            map('n', '<leader>ff', builtin.find_files,  { desc = 'Find files' })
            map('n', '<leader>fg', builtin.live_grep,   { desc = 'Live grep' })
            map('n', '<leader>fb', builtin.buffers,     { desc = 'Find buffers' })
            map('n', '<leader>fr', builtin.oldfiles,    { desc = 'Recent files' })

            -- LSP pickers
            map('n', '<leader>fs', builtin.lsp_document_symbols,  { desc = 'Document symbols' })
            map('n', '<leader>fw', builtin.lsp_workspace_symbols, { desc = 'Workspace symbols' })
            map('n', '<leader>fd', builtin.diagnostics,           { desc = 'Diagnostics' })

            -- Vim pickers
            map('n', '<leader>fh', builtin.help_tags,   { desc = 'Help tags' })
            map('n', '<leader>fk', builtin.keymaps,     { desc = 'Keymaps' })
        end,
    },

    -- -----------------------------------------------------------------------
    -- Completion: nvim-cmp for automatic completions as you type
    -- -----------------------------------------------------------------------
    {
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',    -- LSP completions
            'hrsh7th/cmp-buffer',      -- Words from current buffer
            'hrsh7th/cmp-path',        -- File path completions
        },
        config = function()
            local cmp = require('cmp')

            cmp.setup({
                snippet = {
                    expand = function(args)
                        vim.snippet.expand(args.body) -- Native Neovim snippets (0.10+)
                    end,
                },
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-n>']     = cmp.mapping.select_next_item(),
                    ['<C-p>']     = cmp.mapping.select_prev_item(),
                    ['<C-b>']     = cmp.mapping.scroll_docs(-4),
                    ['<C-f>']     = cmp.mapping.scroll_docs(4),
                    ['<C-Space>'] = cmp.mapping.complete(),
                    ['<C-e>']     = cmp.mapping.abort(),
                    ['<CR>']      = cmp.mapping.confirm({ select = true }),
                }),
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'path' },
                }, {
                    { name = 'buffer' },
                }),
            })

            -- Advertise nvim-cmp capabilities to all LSP servers
            vim.lsp.config('*', {
                capabilities = require('cmp_nvim_lsp').default_capabilities(),
            })
        end,
    },

    -- -----------------------------------------------------------------------
    -- LSP: nvim-lspconfig provides default configs, we use native vim.lsp API
    -- -----------------------------------------------------------------------
    {
        'neovim/nvim-lspconfig',
        config = function()
            -- On-attach: extra keymaps when an LSP server connects
            -- NOTE: Neovim 0.11 already provides these DEFAULT keymaps:
            --   grn  → rename
            --   gra  → code action
            --   grr  → references
            --   gri  → implementation
            --   gO   → document symbols
            --   K    → hover
            --   C-s  → signature help (insert mode)
            --
            -- We add a few extras:
            vim.api.nvim_create_autocmd('LspAttach', {
                callback = function(event)
                    local opts = function(desc)
                        return { buffer = event.buf, desc = desc }
                    end

                    map('n', 'gd',        vim.lsp.buf.definition,  opts('Go to definition'))
                    map('n', 'gD',        vim.lsp.buf.declaration, opts('Go to declaration'))
                    map('n', '<leader>f', function()
                        vim.lsp.buf.format({ async = true })
                    end, opts('Format buffer'))
                    map('n', '<leader>e', vim.diagnostic.open_float, opts('Show diagnostic'))
                end,
            })

            -- ---------------------------------------------------------------
            -- LANGUAGE SERVERS
            -- ---------------------------------------------------------------
            -- nvim-lspconfig provides default configs (cmd, filetypes, root_markers)
            -- for hundreds of servers. We just enable them with the native API.
            --
            -- Install the server externally, then add it to vim.lsp.enable().
            --
            -- Swift:    comes with Xcode (xcrun --find sourcekit-lsp)
            -- Go:       go install golang.org/x/tools/gopls@latest
            -- SQL:      brew install sqls

            -- Override or extend configs if needed:
            --vim.lsp.config('sqls', {
            --    settings = {
            --        sqls = {
            --            connections = {
            --                {
            --                    driver = 'postgresql',
            --                    dataSourceName = 'host=127.0.0.1 port=5432 user=YOUR_USER dbname=YOUR_DB sslmode=disable',
            --                },
            --            },
            --        },
            --    },
            --})
            -- 
            vim.lsp.config('sourcekit', {
                cmd = { 'xcrun', 'sourcekit-lsp', '--default-workspace-type', 'buildServer' },
                --cmd_env = {
                --    SOURCEKIT_LOGGING = '3',
                --    XBS_LOGPATH = '/tmp/xbs_nvim.log',
                --},
            })

            vim.lsp.enable({ 'sourcekit', 'gopls' })
        end,
    },

}, {
    -- lazy.nvim options
    ui = { border = 'rounded' },
})


-- ---------------------------------------------------------------------------
-- 5. DIAGNOSTICS APPEARANCE
-- ---------------------------------------------------------------------------

vim.diagnostic.config({
    virtual_text     = true,     -- Inline diagnostic text
    signs            = true,     -- Signs in the gutter
    underline        = true,     -- Underline problems
    update_in_insert = false,    -- Don't update while typing
    float = {
        border = 'rounded',
        source = true,           -- Show which LSP server produced the diagnostic
    },
})
