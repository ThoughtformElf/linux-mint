-- Standard settings
vim.opt.relativenumber = true
vim.opt.wrap = true
vim.opt.linebreak = true
vim.opt.list = false
vim.opt.autoread = true
vim.opt.updatetime = 500
vim.opt.clipboard = "unnamedplus" -- Use system clipboard for yank/paste

-- undo history
local undodir_path = vim.fn.stdpath("data") .. "/undo"
vim.opt.undofile = true
vim.opt.undodir = undodir_path
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000
if vim.fn.isdirectory(undodir_path) == 0 then
  vim.fn.mkdir(undodir_path, "p")
end

-- 2 tab spaces
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true

-- Function to set the colorscheme based on the time of day.
local function update_colorscheme()
  local hour = tonumber(os.date("%H"))
  local current_theme = vim.g.colors_name
  local target_theme

  if hour >= 8 and hour < 20 then
    -- Daytime (8:00 a.m. to 7:59 p.m.)
    target_theme = "blue"
  else
    -- Nighttime
    target_theme = "slate"
  end

  -- Only execute the command if the theme needs to change.
  -- This prevents flickering or unnecessary processing.
  if current_theme ~= target_theme then
    vim.cmd("colorscheme " .. target_theme)
  end
end

-- Create a timer in milliseconds to udate function periodically
local timer = vim.loop.new_timer()
timer:start(0, 60000, vim.schedule_wrap(update_colorscheme))

-- Set path to lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Install lazy.nvim if not already installed
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim and load plugins from lua/plugins/
require("lazy").setup("plugins")

-- Mappings
local mappings = {
  n = {
    ['<leader>t'] = { 'strftime("%H%M")<CR>P', 'Insert current time (HHMM)' },
    ['<leader>hr'] = { 'o<CR><CR><CR><Esc>40i=<Esc>o<CR><CR><CR><Esc>', 'Insert horizontal rule' },
    [',t'] = { 'a<C-R>=luaeval("os.date(\'%H%M\') .. \' \'")<CR>', "Insert current time (HHMM)" },
    [',d'] = { 'a<C-R>=luaeval("os.date(\'%y%m%d\') .. \' \'")<CR>', "Insert current date (YYMMDD)" },
    [',sum'] = { ':%w !hey \'summarize the current buffer\' --more<CR>', 'Summarize buffer with hey' },
    [',next'] = { ':%w !hey \'what should i work on next?\' --more<CR>', 'Ask hey what to work on next' },
    [',save'] = { ':!cd ~/oz/;clear;save<CR>', 'Save with custom script' },
    [',hey'] = { ':%w !hey --more --prompt \'<CR>', 'Prompt hey with current buffer' },
    ['<Find>'] = { '<Home>', 'Move to beginning of line (Normal)' },
    ['<Select>'] = { '<End>', 'Move to end of line (Normal)' },
  },
  i = {
    ['jj'] = { '<Esc>', 'Exit insert mode' },
    ['<Find>'] = { '<C-o><Home>', 'Move to beginning of line (Insert)' },
    ['<Select>'] = { '<C-o><End>', 'Move to end of line (Insert)' },
    ['<leader>t'] = { '<C-R>=strftime("%H%M")<CR>', 'Insert current time (HHMM) in insert mode' },
    [',t'] = { '<C-R>=luaeval("os.date(\'%H%M\') .. \' \'")<CR>', "Insert current time (HHMM)" },
    [',d'] = { '<C-R>=luaeval("os.date(\'%y%m%d\') .. \' \'")<CR>', "Insert current date (YYMMDD)" },
    [',['] = { '[ ] ', 'Insert checkbox with space' },
  },
  v = {
    ['<Find>'] = { '<Home>', 'Move to beginning of line (Visual)' },
    ['<Select>'] = { '<End>', 'Move to end of line (Visual)' },
  }
}

for mode, mode_mappings in pairs(mappings) do
  for lhs, rhs_and_desc in pairs(mode_mappings) do
    local rhs = rhs_and_desc[1]
    local desc = rhs_and_desc[2]
    local opts = { noremap = true, silent = true, desc = desc }
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end
