-- Neovim colorscheme using only the terminal's 16 colours. Loaded by `:colorscheme theme`.
-- Neovim sends colour numbers and the terminal decides what they look like, so in foot the
-- colours come from modules/theme.nix; in another terminal they follow that terminal's palette.
-- The background is never set: it is the terminal's own.
--
--   0 grey0   1 red      2 green    3 yellow   4 blue   5 violet   6 turquoise  7 white
--   8 grey58  9 crimson 10 emerald 11 khaki   12 sky   13 purple  14 lime     15 grey89
--   (moonfly's names for foot's colours; 0 is the only shade between background and text)

vim.cmd("highlight clear")
vim.g.colors_name = "theme"
vim.o.background = "dark"
vim.o.termguicolors = false -- use the terminal's palette instead of exact colours

-- hl(fg, bg, extra): extra holds bold/italic/underline/undercurl/reverse.
local function hl(fg, bg, extra)
  local spec = extra or {}
  spec.ctermfg = fg
  spec.ctermbg = bg
  return spec
end

local groups = {
  -- Editor UI (colour 0 does all the shading: lines, bars, popups)
  Normal = {},
  NormalFloat = hl(nil, 0),
  FloatBorder = hl(8, 0),
  CursorLine = hl(nil, 0),
  CursorLineNr = hl(4, 0, { bold = true }),
  LineNr = hl(8),
  SignColumn = {},
  ColorColumn = hl(nil, 0),
  Folded = hl(8, 0),
  NonText = hl(0),
  Whitespace = hl(0),
  EndOfBuffer = hl(0),
  Visual = hl(nil, 0),
  Search = hl(0, 11),
  CurSearch = hl(0, 9),
  IncSearch = hl(0, 3),
  MatchParen = hl(nil, 0, { bold = true }),
  StatusLine = hl(7, 0),
  StatusLineNC = hl(8, 0),
  WinBar = hl(7),
  WinSeparator = hl(0),
  TabLine = hl(8, 0),
  TabLineSel = hl(0, 4),
  TabLineFill = hl(nil, 0),
  Pmenu = hl(7, 0),
  PmenuSel = hl(0, 4),
  PmenuSbar = hl(nil, 0),
  PmenuThumb = hl(nil, 8),
  WildMenu = hl(0, 4),
  QuickFixLine = hl(nil, 0),
  Directory = hl(4),
  Title = hl(12, nil, { bold = true }),
  Conceal = hl(8),
  ModeMsg = hl(8),
  MoreMsg = hl(14),
  Question = hl(14),
  ErrorMsg = hl(1),
  WarningMsg = hl(3),

  -- Syntax. Treesitter's @captures fall back to these when not set below.
  Comment = hl(8, nil, { italic = true }),
  Constant = hl(13),
  String = hl(11),
  Character = hl(13),
  Number = hl(13),
  Boolean = hl(9),
  Identifier = hl(6),
  Function = hl(12),
  Statement = hl(5),
  Keyword = hl(5),
  Conditional = hl(5),
  Repeat = hl(5),
  Label = hl(6),
  Exception = hl(9),
  Operator = hl(9),
  PreProc = hl(9),
  Include = hl(9),
  Type = hl(10),
  StorageClass = hl(5),
  Structure = hl(4),
  Special = hl(9),
  Delimiter = {},
  Underlined = hl(10, nil, { underline = true }),
  Error = hl(1),
  Todo = hl(3, 0, { bold = true }),

  -- Treesitter
  ["@variable"] = {},
  ["@variable.builtin"] = hl(2),
  ["@variable.member"] = hl(4),
  ["@variable.parameter"] = hl(nil, nil, { italic = true }),
  ["@property"] = hl(4),
  ["@constant"] = hl(6),
  ["@constant.builtin"] = hl(2),
  ["@module"] = hl(6),
  ["@string.regexp"] = hl(6),
  ["@type.builtin"] = hl(10),
  ["@constructor"] = hl(10),
  ["@attribute"] = hl(12),
  ["@tag"] = hl(4),
  ["@tag.attribute"] = hl(6),
  ["@tag.delimiter"] = hl(2),
  ["@markup.heading"] = hl(5, nil, { bold = true }),
  ["@markup.link"] = hl(2, nil, { underline = true }),
  ["@markup.raw"] = { link = "String" },
  ["@markup.strong"] = { bold = true },
  ["@markup.italic"] = { italic = true },

  -- Diagnostics (LSP and linters)
  DiagnosticError = hl(1),
  DiagnosticWarn = hl(3),
  DiagnosticInfo = hl(12),
  DiagnosticHint = hl(6),
  DiagnosticOk = hl(10),
  DiagnosticUnderlineError = { undercurl = true },
  DiagnosticUnderlineWarn = { undercurl = true },
  DiagnosticUnderlineInfo = { undercurl = true },
  DiagnosticUnderlineHint = { undercurl = true },
  LspReferenceText = hl(nil, 0),
  LspReferenceRead = hl(nil, 0),
  LspReferenceWrite = hl(nil, 0),

  -- Diffs (coloured text, not tinted backgrounds) and spelling
  DiffAdd = hl(10),
  DiffChange = hl(3),
  DiffDelete = hl(1),
  DiffText = hl(11, 0, { bold = true }),
  Added = hl(2),
  Changed = hl(3),
  Removed = hl(1),
  SpellBad = { undercurl = true },
  SpellCap = { undercurl = true },
  SpellRare = { undercurl = true },
  SpellLocal = { undercurl = true },
}

for name, spec in pairs(groups) do
  vim.api.nvim_set_hl(0, name, spec)
end
