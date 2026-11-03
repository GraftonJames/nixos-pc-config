-- Neovim config, linked to ~/.config/nvim by modules/shell.nix (edits apply on restart, no rebuild).

-- Colours: dots/nvim/colors/theme.lua, which takes its palette from modules/theme.nix.
-- Hosts without the desktop modules have no palette and keep Neovim's default colours.
if not pcall(vim.cmd.colorscheme, "theme") then
  vim.cmd.colorscheme("default")
end
