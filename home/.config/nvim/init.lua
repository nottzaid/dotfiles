-- ~/.config/nvim/init.lua
-- Neovim configuration
require('plugins')

-- Enable loader and set basic options
vim.loader.enable()
vim.opt.termguicolors = true

-- Gruvbox settings (if installed)
vim.g.gruvbox_invert_selection = 0
pcall(vim.cmd.colorscheme, "gruvbox")

-- Setup render-markdown plugin (if installed)
local ok, render_markdown = pcall(require, 'render-markdown')
if ok then
  render_markdown.setup({
    enabled = true,
    -- These are optional render-markdown features. Keep the configuration
    -- honest instead of warning about parsers and converters we do not use.
    html = { enabled = false },
    latex = { enabled = false },
    yaml = { enabled = false },
  })
end

-- Window style configuration
local WINDOW_STYLE = {
  border = 'single',
  style = 'minimal',
  winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder'
}

-- Set highlights with transparent background
local function set_highlights()
  local highlights = {
    Normal = { bg = 'NONE' },  -- Transparent background like Vim
    Visual = { bold = false, bg = '#22272b' },
  }
  for group, settings in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, settings)
  end
end
set_highlights()

-- Set various options
local options = {
  number = true,
  guicursor = "n-v-c-i:block",
  relativenumber = true,
  updatetime = 300,
  completeopt = "menu,menuone,noselect",
}
for k, v in pairs(options) do
  vim.opt[k] = v
end

-- Define keymaps
local function set_keymaps()
  local maps = {
    { mode = 'n', lhs = 'y', rhs = '"+y' },
    { mode = 'v', lhs = 'y', rhs = '"+y' },
    { mode = 'v', lhs = 'x', rhs = '"+x' },
    { mode = 'n', lhs = '<A-l>', rhs = '<Esc>l' },
    { mode = 'n', lhs = 'p', rhs = '"+p' },
    { mode = 'n', lhs = '<Esc>', rhs = ':noh<CR><Esc>' },
  }
  for _, map in ipairs(maps) do
    vim.keymap.set(map.mode, map.lhs, map.rhs, { noremap = true })
  end
end
set_keymaps()
