vim.cmd.colorscheme("theme")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

local o = vim.opt

o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false
o.splitright = true
o.splitbelow = true

o.tabstop = 4
o.shiftwidth = 0
o.softtabstop = -1
o.smartindent = true

o.ignorecase = true
o.smartcase = true
o.inccommand = "split"

o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

o.undofile = true
o.backupdir = vim.fn.stdpath("state") .. "/backup//"
vim.fn.mkdir(vim.fn.stdpath("state") .. "/backup", "p", tonumber("700", 8))

o.clipboard = "unnamedplus"

o.updatetime = 250
o.timeoutlen = 500
o.confirm = true

local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>")

map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function() vim.hl.on_yank() end,
})
