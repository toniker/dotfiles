-- Minimal Neovim config.
-- Use case: editing git commit messages, quick checks of Swift / JSON files,
-- and jumping between files with a fuzzy finder. No heavy editing, no LSP.

-- Cache compiled Lua modules for faster startup.
vim.loader.enable()

-- Leader must be set before plugins load.
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- ============================================================
-- Options
-- ============================================================
local o = vim.o
o.number = true
o.mouse = 'a'
o.showmode = false -- mode is redundant with the ruler
o.breakindent = true
o.undofile = true
o.ignorecase = true
o.smartcase = true -- case-sensitive if the search has a capital letter
o.signcolumn = 'yes'
o.updatetime = 250
o.timeoutlen = 300
o.splitright = true
o.splitbelow = true
o.inccommand = 'split' -- live preview of :substitute
o.cursorline = true
o.scrolloff = 10
o.confirm = true -- ask instead of failing on :q with unsaved changes
o.completeopt = 'menuone,noselect,popup,fuzzy' -- completion menu behaviour

-- Sync with the system clipboard (scheduled: it slows startup otherwise).
vim.schedule(function() o.clipboard = 'unnamedplus' end)

vim.cmd.colorscheme 'retrobox'

-- ============================================================
-- Keymaps
-- ============================================================
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Focus window left' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Focus window right' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Focus window down' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Focus window up' })

-- ============================================================
-- Autocommands
-- ============================================================
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Briefly highlight yanked text',
  group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('FileType', {
  desc = 'Prose settings for commit messages and markdown',
  pattern = { 'gitcommit', 'markdown' },
  group = vim.api.nvim_create_augroup('prose', { clear = true }),
  callback = function()
    vim.opt_local.spell = true
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

-- ============================================================
-- Plugins
-- ============================================================
vim.pack.add {
  { src = 'https://github.com/ibhagwan/fzf-lua' },
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  { src = 'https://github.com/folke/which-key.nvim' },
}

-- which-key: a second after a bare <space>, pop up a panel at the bottom
-- listing the mappings that start with it.
require('which-key').setup {
  preset = 'classic', -- compact panel docked to the bottom
  delay = 1000,
  icons = { mappings = false },
}

-- fzf-lua: fuzzy finder with a floating prompt field.
-- Loaded on first use so it stays out of the startup path.
--
-- Reuse Neovim's own RPC server instead of letting fzf-lua call serverstart():
-- this machine's $TMPDIR path is long enough that fzf-lua's socket name
-- ("fzf-lua.<timestamp>") overflows the ~104-char unix socket path limit and
-- fails with "serverstart(): invalid argument".
local fzf_ready = false
local function fzf(fn)
  return function()
    if vim.g.fzf_lua_server == nil and vim.v.servername ~= '' then
      vim.g.fzf_lua_server = vim.v.servername
    end
    local fzf_lua = require 'fzf-lua'
    if not fzf_ready then
      fzf_lua.setup {
        'default-title',
        winopts = { height = 0.75, width = 0.75, preview = { hidden = true } },
      }
      fzf_ready = true
    end
    fzf_lua[fn]()
  end
end

vim.keymap.set('n', '<leader><leader>', fzf 'files', { desc = 'Jump to file' })
vim.keymap.set('n', '<leader>b', fzf 'buffers', { desc = 'Jump to buffer' })
vim.keymap.set('n', '<leader>/', fzf 'live_grep', { desc = 'Grep in project' })
vim.keymap.set('n', '<leader>r', fzf 'resume', { desc = 'Resume last picker' })

-- ============================================================
-- Formatting
-- ============================================================
-- Each formatter reads the buffer text on stdin and writes the result to
-- stdout. `%:p` is expanded to the current file path.
local formatters = {
  swift = { 'swiftformat', '--quiet', '--stdin-path', '%:p' },
  json = { 'jq', '--indent', '2', '.' },
}

--- Format the whole buffer, or lines [first, last] when given.
local function format(first, last)
  local ft = vim.bo.filetype
  local spec = formatters[ft]
  if not spec then
    vim.notify('No formatter for ' .. (ft == '' and 'this buffer' or ft), vim.log.levels.WARN)
    return
  end

  local argv = {}
  for _, arg in ipairs(spec) do
    argv[#argv + 1] = arg == '%:p' and vim.fn.expand '%:p' or arg
  end

  local from = (first or 1) - 1
  local to = last or vim.api.nvim_buf_line_count(0)
  local input = table.concat(vim.api.nvim_buf_get_lines(0, from, to, false), '\n') .. '\n'

  local result = vim.system(argv, { stdin = input, text = true }):wait()
  if result.code ~= 0 then
    local msg = result.stderr ~= '' and result.stderr or result.stdout
    vim.notify(('%s failed:\n%s'):format(argv[1], msg), vim.log.levels.ERROR)
    return
  end

  local output = vim.split((result.stdout:gsub('\n$', '')), '\n', { plain = true })
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(0, from, to, false, output)
  vim.fn.winrestview(view)
end

vim.keymap.set('n', '<leader>f', function() format() end, { desc = 'Format buffer' })
vim.keymap.set('x', '<leader>f', function()
  local a, b = vim.fn.getpos('v')[2], vim.fn.getpos('.')[2]
  vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'n', false)
  format(math.min(a, b), math.max(a, b))
end, { desc = 'Format selection' })

-- ============================================================
-- Swift LSP (sourcekit-lsp)
-- ============================================================
-- Uses Neovim's built-in LSP client and built-in completion -- no plugins.
-- sourcekit-lsp ships with Xcode / the Swift toolchain. For SwiftPM packages
-- it works out of the box; for .xcodeproj/.xcworkspace, generate a
-- buildServer.json with `xcode-build-server` (brew install xcode-build-server)
-- so cross-file jumps and diagnostics work.
--
-- The whole thing is wired up on the first Swift buffer, so opening a commit
-- message or a JSON file never touches vim.lsp.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'swift',
  once = true,
  group = vim.api.nvim_create_augroup('swift-lsp', { clear = true }),
  callback = function()
    if vim.fn.executable 'sourcekit-lsp' ~= 1 then
      vim.notify('sourcekit-lsp not found on PATH', vim.log.levels.WARN)
      return
    end

    vim.diagnostic.config {
      virtual_text = true, -- inline diagnostics
      severity_sort = true,
      float = { border = 'rounded', source = true },
    }

    vim.api.nvim_create_autocmd('LspAttach', {
      desc = 'Enable completion and LSP keymaps on attach',
      group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
      callback = function(ev)
        local client = vim.lsp.get_client_by_id(ev.data.client_id)
        if client and client:supports_method 'textDocument/completion' then
          -- as-you-type completions via the built-in popup menu
          vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, { autotrigger = true })
        end
        -- grn/gra/grr/gri/grt/gO/K are Neovim defaults; add plain go-to-definition
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf, desc = 'Goto definition' })
        vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { buffer = ev.buf, desc = 'Line diagnostics' })
      end,
    })

    vim.lsp.config('sourcekit', {
      cmd = { 'sourcekit-lsp' },
      filetypes = { 'swift' },
      root_markers = { 'Package.swift', 'buildServer.json', 'compile_commands.json', '.git' },
    })
    vim.lsp.enable 'sourcekit' -- also attaches to the Swift buffer already open
  end,
})

-- Treesitter: syntax highlighting for Swift, JSON, and a few common filetypes.
-- nvim-treesitter provides the highlight queries; parsers live in
-- ~/.local/share/nvim/site/parser. To add or refresh a parser, run
--   :lua require('nvim-treesitter').install { 'lang' }   (needs tree-sitter CLI >= 0.26)
vim.api.nvim_create_autocmd('FileType', {
  desc = 'Start treesitter highlighting when a parser is available',
  group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(args.match)
    if not lang then return end
    local ok, loaded = pcall(vim.treesitter.language.add, lang)
    if ok and loaded ~= false then
      pcall(vim.treesitter.start, args.buf, lang)
    end
  end,
})

-- vim: ts=2 sts=2 sw=2 et
