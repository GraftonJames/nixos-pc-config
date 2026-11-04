{ lib, pkgs, ... }:

# The one place colours and fonts are set.
#
# Fonts: fontconfig's generic `monospace` means Commit Mono, with Nerd Font icons as a fallback
# for glyphs it lacks. Apps ask for `monospace` (foot, fuzzel, the sway bar and title bars), never
# a font by name, so changing the font here changes it everywhere. Sizes stay in each app.
#
# Colours: the one place they are set. Everything else reads these generated files:
#   ~/.config/theme/sway.conf   included by dots/sway/config ($bg, $fg, $accent, ... and $c_<name>)
#   ~/.config/theme/foot.ini    included by dots/foot/foot.ini
#   ~/.config/theme/fuzzel.ini  included by dots/fuzzel/fuzzel.ini
#   ~/.config/swaylock/config   read by swaylock directly (it only holds colours)
# Dotfiles never hold hex codes. Change a colour here, `rebuild`, then reload the app.
let
	# moonfly (github.com/bluz71/vim-moonfly-colors, MIT): lua/moonfly/init.lua. Hex without '#'.
	c = {
		black = "080808";
		white = "c6c6c6";
		grey0 = "323437";
		grey1 = "373c4d";
		grey89 = "e4e4e4";
		grey70 = "b2b2b2";
		grey62 = "9e9e9e";
		grey58 = "949494";
		grey50 = "808080";
		grey39 = "626262";
		grey35 = "585858";
		grey30 = "4e4e4e";
		grey27 = "444444";
		grey23 = "3a3a3a";
		grey18 = "2e2e2e";
		grey16 = "292929";
		grey15 = "262626";
		grey13 = "212121";
		grey11 = "1c1c1c";
		grey7 = "121212";
		red = "ff5d5d";
		crimson = "ff5189";
		cranberry = "e65e72";
		coral = "f09479";
		cinnamon = "e9958e";
		orchid = "e196a2";
		orange = "de935f";
		yellow = "e3c78a";
		khaki = "c6c684";
		lime = "85dc85";
		green = "8cc85f";
		emerald = "36c692";
		turquoise = "79dac8";
		sky = "74b2ff";
		blue = "80a0ff";
		lavender = "adadf3";
		violet = "cf87e8";
		purple = "ae81ff";
		mineral = "314940";
		bay = "4d5d8d";
		slate = "748999";
		haze = "88a2b7";
		# From moonfly's terminal themes (extras/moonfly-kitty.conf).
		termFg = "bdbdbd";
		selection = "b2ceee";
	};

	# What each colour is for. Apps use these names, so a role can be repointed in one line.
	role = {
		bg = c.black;
		term_bg = c.black; # foot's background (Neovim shows it too). Lighter: grey7, grey11, grey15, grey18
		fg = c.white;
		fg_dim = c.grey50;
		surface = c.grey0; # raised areas: inactive titles, the bar's other workspaces
		accent = c.blue;
		urgent = c.red;
		good = c.green;
		warn = c.yellow;
	};

	# Terminal colours 0-15, in moonfly's order (extras/moonfly-kitty.conf). Neovim uses these by
	# number (dots/nvim/colors/theme.lua), so changing one here recolours Neovim too.
	ansi = with c; [ grey0 red green yellow blue violet turquoise white grey58 crimson emerald khaki sky purple lime grey89 ];

	# `key=value` lines from [ [ key value ] ... ], in the order given.
	# (Lists instead of '' strings: Nix doesn't strip tab indentation from those.)
	kv = pairs: lib.concatLines (map (p: "${lib.elemAt p 0}=${lib.elemAt p 1}") pairs);
	# Sway `set $name #hex` lines.
	swayVars = prefix: attrs: lib.concatLines (lib.mapAttrsToList (n: v: "set \$${prefix}${n} #${v}") attrs);
in
{
	fonts.packages = [
		pkgs.commit-mono
		pkgs.nerd-fonts.symbols-only # icons only; used wherever the main font has no glyph
	];
	fonts.fontconfig.defaultFonts.monospace = [ "CommitMono" "Symbols Nerd Font Mono" ];

	home-manager.users.james.xdg.configFile = {
		"theme/sway.conf".text = swayVars "" role + swayVars "c_" c;

		"theme/foot.ini".text =
			"[colors]\n"
			+ kv ([
				[ "background" role.term_bg ]
				[ "foreground" c.termFg ]
				[ "selection-background" c.selection ]
				[ "selection-foreground" role.term_bg ]
				[ "urls" c.turquoise ]
			] ++ lib.imap0 (i: v: [ (if i < 8 then "regular${toString i}" else "bright${toString (i - 8)}") v ]) ansi)
			+ "[cursor]\n"
			+ kv [ [ "color" "${role.term_bg} ${c.grey62}" ] ];

		# fuzzel wants RRGGBBAA.
		"theme/fuzzel.ini".text =
			"[colors]\n"
			+ kv (map (p: [ (lib.elemAt p 0) "${lib.elemAt p 1}ff" ]) [
				[ "background" role.bg ]
				[ "text" role.fg ]
				[ "prompt" role.accent ]
				[ "placeholder" role.fg_dim ]
				[ "input" role.fg ]
				[ "match" c.yellow ]
				[ "selection" role.surface ]
				[ "selection-text" c.grey89 ]
				[ "selection-match" c.yellow ]
				[ "counter" role.fg_dim ]
				[ "border" role.accent ]
			]);

		"swaylock/config".text =
			kv [
				[ "color" role.bg ]
				[ "inside-color" role.bg ]
				[ "inside-clear-color" role.bg ]
				[ "inside-ver-color" role.bg ]
				[ "inside-wrong-color" role.bg ]
				[ "inside-caps-lock-color" role.bg ]
				[ "ring-color" role.surface ]
				[ "ring-clear-color" c.turquoise ]
				[ "ring-ver-color" role.accent ]
				[ "ring-wrong-color" role.urgent ]
				[ "ring-caps-lock-color" role.warn ]
				[ "key-hl-color" role.accent ]
				[ "caps-lock-key-hl-color" role.warn ]
				[ "bs-hl-color" role.urgent ]
				[ "caps-lock-bs-hl-color" role.urgent ]
				[ "separator-color" role.bg ]
				[ "text-color" role.fg ]
				[ "text-clear-color" role.fg ]
				[ "text-ver-color" role.fg ]
				[ "text-wrong-color" role.urgent ]
				[ "text-caps-lock-color" role.warn ]
				[ "layout-bg-color" role.surface ]
				[ "layout-border-color" role.surface ]
				[ "layout-text-color" role.fg ]
			]
			+ "line-uses-ring\n";
	};
}
