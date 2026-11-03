-- Neovim colorscheme built on the palette from modules/theme.nix (moonfly colours).
-- Loaded by `:colorscheme theme`. This file decides which colour goes where; the colours
-- themselves come from ~/.config/theme/nvim.lua, so never put hex codes here.
-- Names: every moonfly colour (blue, khaki, grey15, ...) and the roles (bg, term_bg, fg, accent, ...).

local p = dofile(vim.fn.expand("~/.config/theme/nvim.lua"))

vim.cmd("highlight clear")
vim.g.colors_name = "theme"
vim.o.background = "dark"
vim.o.termguicolors = true

local groups = {
  -- Editor UI
  Normal = { fg = p.fg, bg = p.term_bg }, -- same background as foot
  NormalFloat = { fg = p.fg, bg = p.grey13 },
  FloatBorder = { fg = p.grey27, bg = p.grey13 },
  Cursor = { fg = p.term_bg, bg = p.grey62 },
  CursorLine = { bg = p.grey18 },
  CursorLineNr = { fg = p.accent, bg = p.grey18 },
  LineNr = { fg = p.grey39 },
  SignColumn = { fg = p.haze },
  ColorColumn = { bg = p.grey18 },
  Folded = { fg = p.haze, bg = p.grey18 },
  NonText = { fg = p.grey39 },
  Whitespace = { fg = p.grey0 },
  EndOfBuffer = { fg = p.grey30 },
  Visual = { bg = p.grey0 },
  Search = { fg = p.grey89, bg = p.grey1 },
  CurSearch = { fg = p.black, bg = p.coral },
  IncSearch = { fg = p.black, bg = p.yellow },
  MatchParen = { bg = p.grey0, bold = true },
  StatusLine = { fg = p.fg, bg = p.grey11 },
  StatusLineNC = { fg = p.grey62, bg = p.grey11 },
  WinBar = { fg = p.fg },
  WinSeparator = { fg = p.grey0 },
  TabLine = { fg = p.grey62, bg = p.grey11 },
  TabLineSel = { fg = p.black, bg = p.accent },
  TabLineFill = { bg = p.grey11 },
  Pmenu = { fg = p.fg, bg = p.grey13 },
  PmenuSel = { fg = p.grey89, bg = p.bay },
  PmenuSbar = { bg = p.grey13 },
  PmenuThumb = { bg = p.grey35 },
  WildMenu = { fg = p.grey89, bg = p.bay },
  QuickFixLine = { bg = p.grey13 },
  Directory = { fg = p.blue },
  Title = { fg = p.sky, bold = true },
  Conceal = { fg = p.grey70 },
  ModeMsg = { fg = p.grey62 },
  MoreMsg = { fg = p.lime },
  Question = { fg = p.lime },
  ErrorMsg = { fg = p.urgent },
  WarningMsg = { fg = p.orange },

  -- Syntax. Treesitter's @captures fall back to these when not set below.
  Comment = { fg = p.grey58, italic = true },
  Constant = { fg = p.orange },
  String = { fg = p.khaki },
  Character = { fg = p.purple },
  Number = { fg = p.orange },
  Boolean = { fg = p.cranberry },
  Identifier = { fg = p.turquoise },
  Function = { fg = p.sky },
  Statement = { fg = p.violet },
  Keyword = { fg = p.violet },
  Conditional = { fg = p.violet },
  Repeat = { fg = p.violet },
  Label = { fg = p.turquoise },
  Exception = { fg = p.crimson },
  Operator = { fg = p.cranberry },
  PreProc = { fg = p.cranberry },
  Include = { fg = p.cranberry },
  Type = { fg = p.emerald },
  StorageClass = { fg = p.violet },
  Structure = { fg = p.blue },
  Special = { fg = p.cranberry },
  Delimiter = { fg = p.fg },
  Underlined = { fg = p.emerald, underline = true },
  Error = { fg = p.urgent },
  Todo = { fg = p.yellow, bg = p.grey15, bold = true },

  -- Treesitter
  ["@variable"] = { fg = p.fg },
  ["@variable.builtin"] = { fg = p.green },
  ["@variable.member"] = { fg = p.lavender },
  ["@variable.parameter"] = { fg = p.orchid },
  ["@property"] = { fg = p.lavender },
  ["@constant"] = { fg = p.turquoise },
  ["@constant.builtin"] = { fg = p.green },
  ["@module"] = { fg = p.turquoise },
  ["@string.regexp"] = { fg = p.turquoise },
  ["@type.builtin"] = { fg = p.emerald },
  ["@constructor"] = { fg = p.emerald },
  ["@attribute"] = { fg = p.sky },
  ["@tag"] = { fg = p.blue },
  ["@tag.attribute"] = { fg = p.turquoise },
  ["@tag.delimiter"] = { fg = p.green },
  ["@markup.heading"] = { fg = p.violet, bold = true },
  ["@markup.link"] = { fg = p.green },
  ["@markup.raw"] = { link = "String" },
  ["@markup.strong"] = { bold = true },
  ["@markup.italic"] = { italic = true },

  -- Diagnostics (LSP and linters)
  DiagnosticError = { fg = p.urgent },
  DiagnosticWarn = { fg = p.warn },
  DiagnosticInfo = { fg = p.sky },
  DiagnosticHint = { fg = p.turquoise },
  DiagnosticOk = { fg = p.emerald },
  DiagnosticUnderlineError = { undercurl = true, sp = p.urgent },
  DiagnosticUnderlineWarn = { undercurl = true, sp = p.warn },
  DiagnosticUnderlineInfo = { undercurl = true, sp = p.sky },
  DiagnosticUnderlineHint = { undercurl = true, sp = p.turquoise },
  LspReferenceText = { bg = p.grey0 },
  LspReferenceRead = { bg = p.grey0 },
  LspReferenceWrite = { bg = p.grey0 },

  -- Diffs and spelling
  DiffAdd = { bg = p.mineral },
  DiffChange = { bg = p.grey18 },
  DiffDelete = { fg = p.grey39, bg = p.grey18 },
  DiffText = { bg = p.bay },
  Added = { fg = p.good },
  Changed = { fg = p.warn },
  Removed = { fg = p.urgent },
  SpellBad = { undercurl = true, sp = p.red },
  SpellCap = { undercurl = true, sp = p.yellow },
  SpellRare = { undercurl = true, sp = p.green },
  SpellLocal = { undercurl = true, sp = p.sky },
}

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end

-- :terminal uses the same 16 colours as foot.
for i, colour in ipairs(p.ansi) do
  vim.g["terminal_color_" .. (i - 1)] = colour
end
