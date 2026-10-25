# CLAUDE.md

NixOS flake config for a ThinkPad X201s. Claude Code runs on a different (newer) machine and edits this repo. The laptop pulls changes with `git pull` and rebuilds.

## Target machine

- Host: ThinkPad X201s, hostname `x201s`, flake attribute `nixosConfigurations.x201s`
- Legacy BIOS (no UEFI, no Secure Boot): GRUB on MBR, no systemd-boot or EFI partition
- Old first-gen Core i-series CPU with no AVX. Native binaries built for newer CPUs crash with "illegal hardware instruction" (exit 132). Do not add packages that need modern CPU features without checking.
- Wi-Fi: Intel Ultimate-N 5300 (iwlwifi). It broke on kernel 6.18 and works on the default NixOS 25.05 kernel. Do NOT set `boot.kernelPackages` (no `linuxPackages_latest` or similar).
- `hardware.enableRedistributableFirmware = true;` must stay enabled.
- NixOS release: 25.05 (`nixpkgs` input is `nixos-25.05`). `nixpkgs-unstable` is available as `pkgs-unstable` via `specialArgs` for individual packages only.

## Current layout

```
flake.nix                            # commonModules + mkHost helper
flake.lock
hosts/x201s/default.nix              # boot, hostname, networking, stateVersion
hosts/x201s/hardware-configuration.nix
modules/base.nix      # nix settings, locale, users
modules/desktop.nix   # desktop environment: sway, audio, tools the sway config calls, ~/.config/sway link
modules/apps.nix      # desktop applications: firefox, foot
modules/shell.nix     # zsh, vim, git, CLI tools
modules/home.nix      # Home Manager settings for user james
dots/sway/            # sway config, linked to ~/.config/sway
```

Dotfiles in `dots/` are linked with `mkOutOfStoreSymlink` to the repo checkout at `/home/james/repos/nixos-pc-config` (set as `repo` in `modules/desktop.nix`), so edits apply without a rebuild. The repo must live at that path on the laptop. Packages the dotfiles call must be added to the Nix config.

Shared modules go in a `commonModules` list in `flake.nix`, with a `mkHost` helper so each host only lists what is unique to it. Machine-specific modules (for example `desktop.nix`) are imported by the host.

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
- Editor: vim
- Window manager: sway (`programs.sway`), config is `dots/sway/config`, linked to `~/.config/sway` by Home Manager
- Networking: NetworkManager
- Rebuild command on the laptop: `sudo nixos-rebuild switch --flake .` (the hostname matches the flake attribute)

## Known issues and cleanup tasks

1. Do not add `claude-code` (it crashes with illegal instruction on this CPU).
2. Optional later: move zsh and vim/neovim dotfiles into `dots/` via Home Manager, and `nh` for nicer rebuild output.
3. Optional: `nix.gc` weekly with `--delete-older-than 14d`, since the laptop has limited disk.

## Workflow

1. Edit on the newer machine, run `nixos-rebuild build --flake .#x201s` to check it evaluates.
2. Commit and push.
3. On the laptop: `git pull`, then `sudo nixos-rebuild switch --flake .`.
4. If a rebuild breaks something, boot the previous generation from the GRUB menu.
