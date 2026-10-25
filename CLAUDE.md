# CLAUDE.md

NixOS flake config for a ThinkPad X201s. Claude Code runs on a different (newer) machine and edits this repo. The laptop pulls changes with `git pull` and rebuilds.

## Target machine

- Host: ThinkPad X201s, hostname `x201s`, flake attribute `nixosConfigurations.x201s`
- Legacy BIOS (no UEFI, no Secure Boot): GRUB on MBR, no systemd-boot or EFI partition
- Old first-gen Core i-series CPU with no AVX. Native binaries built for newer CPUs crash with "illegal hardware instruction" (exit 132). Do not add packages that need modern CPU features without checking.
- Wi-Fi: Intel Ultimate-N 5300 (iwlwifi). It broke on kernel 6.18 and works on the default NixOS 25.05 kernel. Do NOT set `boot.kernelPackages` (no `linuxPackages_latest` or similar).
- `hardware.enableRedistributableFirmware = true;` must stay enabled.
- Old Intel integrated graphics. The user prefers apps that don't need GPU acceleration (this is why the terminal is foot, not alacritty).
- NixOS release: 25.05 (`nixpkgs` input is `nixos-25.05`). `nixpkgs-unstable` is available as `pkgs-unstable` via `specialArgs` for individual packages only.

## Current layout

```
flake.nix                            # commonModules + mkHost helper
flake.lock
hosts/x201s/default.nix              # boot, hostname, networking, stateVersion
hosts/x201s/hardware-configuration.nix
modules/base.nix      # nix settings, locale, users
modules/desktop.nix   # desktop environment: sway, audio, pavucontrol, tools the sway config calls, ~/.config/sway link
modules/apps.nix      # desktop applications: firefox, foot
modules/shell.nix     # zsh, vim, git, nh, `rebuild` script, CLI tools
modules/home.nix      # Home Manager settings for user james
dots/sway/            # sway config, linked to ~/.config/sway
```

Dotfiles in `dots/` are linked with `mkOutOfStoreSymlink` to the repo checkout at `/home/james/repos/nixos-pc-config` (set as `repo` in `flake.nix` and passed to modules through `specialArgs`), so edits apply without a rebuild. The repo must live at that path on the laptop. Packages the dotfiles call must be added to the Nix config.

Shared modules go in a `commonModules` list in `flake.nix`, with a `mkHost` helper so each host only lists what is unique to it. Machine-specific modules (`desktop.nix`, `apps.nix`) are imported by the host.

Where packages go:
- `modules/desktop.nix`: the desktop environment itself and tools the sway config calls (launcher, screenshots, audio control).
- `modules/apps.nix`: standalone desktop applications the user picks (browser, terminal).
- `modules/shell.nix`: CLI tools.

These are modules in one flake, not separate flakes, so there is a single `flake.lock`.

## Rules

- Always `git add` new files before building. Flakes cannot see untracked files.
- Never change `system.stateVersion`. It is the original install release, not the current one.
- Do not run `nixos-rebuild switch` from here. Validate with `nixos-rebuild build --flake .#x201s` or `nix flake check`, and let the user run `switch` on the laptop.
- Do not run `nix flake update` without asking. A newer nixpkgs may move to a kernel that breaks the Wi-Fi card. Reverting `flake.lock` with git undoes it.
- Keep secrets (Wi-Fi passwords, tokens, password hashes) out of the repo. Everything here ends up readable in the Nix store.
- List items in Nix lists are separated by whitespace, not commas. Define `environment.systemPackages` once per file.
- Quote the flake target in zsh: `'.#x201s'`.
- Prefer small, reviewable commits. Show the diff and explain each change.

## Setup in use

- Shell: zsh (`programs.zsh.enable = true;`, user shell set to `pkgs.zsh`)
- Editor: vim. The user plans to set up neovim from scratch later, in `dots/nvim`. Don't import the old config from `~/repos/dotfiles/nvim`.
- Window manager: sway (`programs.sway`), config is `dots/sway/config`, linked to `~/.config/sway` by Home Manager. Reload with `$mod+Shift+c`.
- Terminal: foot (`$term` in the sway config)
- Launcher: fuzzel (`$mod+i`)
- Audio: PipeWire with the PulseAudio shim, `pactl` for volume keys. `$mod+p` toggles pavucontrol as a centred floating window (a `for_window` rule in the sway config).
- Home Manager: input `release-25.05`, following `nixpkgs`, used as a NixOS module (`modules/home.nix`) with `backupFileExtension = "bak"`
- Garbage collection: `programs.nh.clean` runs weekly and keeps the last 3 generations plus anything from the past 14 days. Do not also enable `nix.gc.automatic`, because the two conflict.
- No automatic upgrades. Updates are done by hand: `nix flake update` here (only when the user asks), build, then switch on the laptop.
- Networking: NetworkManager
- Rebuild command on the laptop: `rebuild` (defined in `modules/shell.nix`). It fetches from `origin`, pulls fast-forward only (stops if the branches have diverged), warns about uncommitted changes, then runs `nh os switch`, passing through any extra arguments. If the laptop is offline, it builds the local copy. Plain `nh os switch` also works (run as the user, not with sudo; nh asks for sudo itself). `programs.nh.flake` points it at the repo, so it works from any directory. The fallback is `sudo nixos-rebuild switch --flake .` from the repo (the hostname matches the flake attribute).

## Known issues and cleanup tasks

1. Do not add `claude-code` (it crashes with illegal instruction on this CPU).
2. Optional later: move zsh dotfiles into `dots/` via Home Manager.
3. The sway config has `output DP-3` and `eDP-1` lines from another machine. Sway ignores them on the X201s, whose panel is 1280x800 (probably `LVDS-1`).
4. `dots/sway/brightness` is an empty file, and there are no brightness keybindings yet (`brightnessctl` would cover this).

## Workflow

1. Edit on the newer machine, run `nixos-rebuild build --flake .#x201s` to check it evaluates.
2. Commit and push.
3. On the laptop: `rebuild` (pulls, then switches).
4. If a rebuild breaks something, boot the previous generation from the GRUB menu.
