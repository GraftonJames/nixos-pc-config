# CLAUDE.md

NixOS flake config for several machines. Each machine is a host under `hosts/` and shares the modules in `modules/`.

Machines:
- `x201s`: ThinkPad X201s. The only NixOS host so far, used to stage and try out changes. Repo checked out at `~/nixos-config`.
- `desktop`: AMD desktop (Ryzen, Radeon GPU), NixOS. Claude Code runs here and edits this repo at `~/nixos-config`.
- Main laptop: used more often. The user plans to move it to NixOS. No details yet.

Changes are made here, pushed, and pulled on each NixOS machine with `rebuild`.

## Layout

```
flake.nix             # commonModules, mkHost helper, nixosConfigurations
flake.lock            # one lock for all hosts
hosts/<name>/default.nix                # host-only settings: boot loader, swap, power, stateVersions
hosts/<name>/hardware-configuration.nix # generated on that machine
modules/base.nix      # all hosts: nix settings, store optimise, NetworkManager, en_GB locale, UK keyboard (XKB layout `gb`, also on console), user james
modules/shell.nix     # all hosts: zsh, vim, git, nh + nh clean, `rebuild` script, ssh-agent, CLI tools
modules/home.nix      # all hosts: Home Manager settings
modules/cloud.nix     # all hosts: rclone remotes (pCloud, EU) mounted under ~/clouds/<name>
modules/desktop.nix   # imported per host: greetd login, sway, audio, swayidle/swaylock, tools the sway config calls, dotfile links
modules/apps.nix      # imported per host: desktop applications (firefox, foot)
modules/gaming.nix    # imported per host: Steam, gamemode, gamescope (for the desktop, not the x201s)
modules/theme.nix     # imported by desktop.nix: the colour palette (moonfly), generates ~/.config/theme/* and ~/.config/swaylock/config
scripts/rebuild.sh    # the `rebuild` command, packaged in modules/shell.nix
scripts/check-updates.sh # the `check-updates` command, packaged in modules/desktop.nix
dots/sway/status.sh   # sway bar status line, run once a second
dots/vim/vimrc        # vim config, linked to ~/.vimrc by modules/shell.nix
dots/nvim/            # neovim config, linked to ~/.config/nvim by modules/shell.nix
dots/nvim/colors/theme.lua # neovim colorscheme (`:colorscheme theme`), palette from modules/theme.nix
dots/sway/config      # shared sway config, linked to ~/.config/sway
dots/foot/foot.ini    # foot config, linked to ~/.config/foot
dots/fuzzel/fuzzel.ini # fuzzel config, linked to ~/.config/fuzzel
dots/sway/hosts/<name>.conf # per-host sway settings (monitors), linked to ~/.config/sway-host.conf
```

How the pieces fit:
- `mkHost { name = "..."; }` in `flake.nix` builds a host from `commonModules` plus `hosts/<name>`, and sets `networking.hostName = name`. The hostname, the flake attribute and the folder name are always the same, so `nh os switch` and `nixos-rebuild switch --flake .` pick the right host automatically.
- `mkHost` also takes `repo` (the checkout path on that machine, default `/home/james/nixos-config`) and `system` (default `x86_64-linux`). `repo` reaches modules through `specialArgs`. Prefer cloning to `~/nixos-config` on every machine so the default works.
- Dotfiles in `dots/` are linked with `mkOutOfStoreSymlink` to `repo`, so edits apply without a rebuild. Packages the dotfiles call must be in the Nix config.
- `home.stateVersion` is set per host, next to `system.stateVersion`.

Where packages go:
- `modules/desktop.nix`: the desktop environment itself and tools the sway config calls (launcher, screenshots, audio control, locking).
- `modules/apps.nix`: standalone desktop applications the user picks (browser, terminal).
- `modules/gaming.nix`: Steam and gaming tools. GPU drivers go in the host file.
- `modules/shell.nix`: CLI tools.
- `hosts/<name>/default.nix`: anything only one machine needs.

These are modules in one flake, not separate flakes.

## Adding a host

1. Install NixOS on the machine and copy its `/etc/nixos/hardware-configuration.nix` into `hosts/<name>/`.
2. Create `hosts/<name>/default.nix`: import `hardware-configuration.nix` and, for a desktop machine, `../../modules/desktop.nix` and `../../modules/apps.nix` (plus `../../modules/gaming.nix` for a gaming machine). Set the boot loader and `system.stateVersion`/`home-manager.users.james.home.stateVersion` to the release it was installed with.
3. Add `<name> = mkHost { name = "<name>"; };` to `nixosConfigurations` in `flake.nix` (pass `repo` if it is not checked out at `~/nixos-config`).
4. Add `dots/sway/hosts/<name>.conf` (it can be empty). Sway fails to load the include if it is missing.
5. `git add` everything, build, and on the machine run `sudo nixos-rebuild switch --flake .#<name>` for the first switch.

## Rules

- Always `git add` new files before building. Flakes cannot see untracked files.
- Never change `system.stateVersion` or `home.stateVersion`. They are the original install release, not the current one.
- Do not run `nixos-rebuild switch` from here. Validate with `nixos-rebuild build --flake .#<host>` or `nix flake check`, and let the user run `switch` on the machine.
- Do not run `nix flake update` without asking. All hosts share one `flake.lock`, and a newer nixpkgs may move to a kernel that breaks the X201s Wi-Fi card. Reverting `flake.lock` with git undoes it.
- Keep secrets (Wi-Fi passwords, tokens, password hashes) out of the repo. Everything here ends up readable in the Nix store.
- Keep host-specific settings (hardware, monitors, power) in `hosts/<name>/` or `dots/sway/hosts/<name>.conf`, not in shared modules.
- List items in Nix lists are separated by whitespace, not commas. Define `environment.systemPackages` once per file.
- Quote the flake target in zsh: `'.#x201s'`.
- Prefer small, reviewable commits. Show the diff and explain each change.

## Shared setup

- NixOS release: 25.05 (`nixpkgs` input is `nixos-25.05`). There is no unstable input. If one is needed for a single package, add it as a flake input and pass it through `specialArgs`.
- Shell: zsh (`programs.zsh.enable = true;`, user shell set to `pkgs.zsh`)
- Editor: vim, config in `dots/vim/vimrc` (loads vim's defaults, keeps swap/backup/undo files in `~/.cache/vim/` so they stay out of `~/clouds`). Neovim (in `modules/shell.nix`, all hosts) is being set up from scratch in `dots/nvim`; so far it only sets colours. Don't import the old config from `~/repos/dotfiles/nvim`. No colorscheme plugin: the user chose a colorscheme generated from theme.nix over the moonfly plugin.
- Window manager: sway (`programs.sway`), config is `dots/sway/config`, linked to `~/.config/sway` by Home Manager. Reload with `$mod+Shift+c`.
- Per-host sway: `dots/sway/hosts/<name>.conf` is linked to `~/.config/sway-host.conf` and included near the top of the main config, after the default variables. Host files override `$bar_font_size`, `$bar_height`, `$lock_cmd`, `$lock_after`, `$screen_off_after`, `$idle_sleep_after` and `$idle_sleep_cmd` with `set`, and hold outputs, inputs and host-only bindings/execs. When adding something that differs per machine to the main config, make it a variable with a default instead of hard-coding it.
- Idle and hibernate: swayidle in the sway config locks with swaylock after 1 hour, turns the screen off a minute later, and hibernates after 2 hours. It also locks before any sleep. `$mod+Shift+z` locks, `$mod+Shift+x` hibernates.
- Login: greetd with tuigreet (text-mode, starts sway, remembers the last username in `/var/cache/tuigreet`). LightDM was not used because it needs an X server.
- Terminal: foot (`$term` in the sway config)
- Launcher: fuzzel (`$mod+i`)
- Colours: `modules/theme.nix` is the only place colours are set (moonfly palette `c`, plus roles `bg`, `fg`, `fg_dim`, `surface`, `accent`, `urgent`, `good`, `warn`). It generates `~/.config/theme/{sway.conf,foot.ini,fuzzel.ini}`, which the dotfiles `include`, `~/.config/theme/nvim.lua` (a Lua table of every colour and role plus `ansi`, loaded by `dots/nvim/colors/theme.lua`), and the whole `~/.config/swaylock/config`. foot and Neovim use the `term_bg` role. Dotfiles never contain hex codes: sway uses `$bg`/`$accent`/... or `$c_<name>`, Neovim uses `p.<name>`. Changing a colour needs a rebuild. Build the text from lists, not tab-indented `''` strings (Nix doesn't strip tabs).
- Audio: PipeWire with the PulseAudio shim, `pactl` for volume keys. `$mod+p` toggles pavucontrol as a centred floating window (a `for_window` rule in the sway config).
- Brightness: `brightnessctl` on the brightness keys (user is in the `video` group)
- Home Manager: input `release-25.05`, following `nixpkgs`, used as a NixOS module (`modules/home.nix`) with `backupFileExtension = "bak"`
- Garbage collection: `programs.nh.clean` runs weekly and keeps the last 3 generations plus anything from the past 14 days. Do not also enable `nix.gc.automatic`, because the two conflict.
- No automatic upgrades. Updates are done by hand: `nix flake update` here (only when the user asks), build, then switch on each machine.
- Git: `programs.git` in `modules/shell.nix` sets `user.name`/`user.email` in `/etc/gitconfig` (needed for `rebuild` commits). A `~/.gitconfig` on a machine overrides it.
- Cloud storage: Home Manager `programs.rclone` in `modules/cloud.nix`. pCloud (EU, `eapi.pcloud.com`) is mounted at `~/clouds/pCloud` (2G local cache, folder listings refreshed after 30s) by the `rclone-mount:.@pcloud` user service. The token is not in the repo: each machine needs it in `~/.config/rclone-secrets/pcloud-token` (from `rclone authorize "pcloud"`), and the switch copies it into `~/.config/rclone/rclone.conf`. Without the file the switch still works but the mount fails. `rsync` is in `modules/shell.nix` for copies over SSH.
- SSH: `programs.ssh.startAgent` plus `AddKeysToAgent yes`, so the key passphrase is asked once per login. On the Arch desktop, the same is done with the `ssh-agent.socket` user unit, `SSH_AUTH_SOCK` in `~/.bashrc` and `~/.config/environment.d/ssh-agent.conf`, and `AddKeysToAgent yes` in `~/.ssh/config`.
- Networking: NetworkManager
- Rebuild command: `rebuild` (script in `scripts/rebuild.sh`, packaged in `modules/shell.nix`, which passes the repo path as `REPO`). It fetches from `origin`, pulls fast-forward only (stops if the branches have diverged), lists uncommitted changes, then runs `nh os switch` on the repo, passing through any extra arguments. If the switch succeeds, it commits changes to tracked files (`git add --update`, so `flake.lock` is included) plus anything already staged, with message `rebuild on <host>: <date>`, and pushes. It never adds untracked files (the repo may be public); it lists them instead, and they must be `git add`ed by hand. If the machine is offline, it builds the local copy and skips the push. Plain `nh os switch` also works (run as the user, not with sudo). The fallback is `sudo nixos-rebuild switch --flake .` from the repo.
- Status bar: `dots/sway/status.sh` prints pending package updates, a pCloud warning, time since the last switch, network, download speed (from `/proc/net/dev`), CPU % and temperature, RAM, free space on `/`, volume (`wpctl`), battery (only if there is one) and the clock. Each part is left out on machines that lack it. It runs every second, so keep it cheap: per-second parts use shell builtins (only `date` and `wpctl` are started); slower parts are cached in `$XDG_RUNTIME_DIR/sway-status-slow` and refreshed every 15 seconds.
- Update check: `check-updates` copies the repo to a temp folder, runs `nix flake update` there (the real `flake.lock` is never touched), builds this host and counts version changes against `/run/current-system` with `nvd`. It writes `~/.cache/check-updates/status` (read by the status bar) and `~/.cache/check-updates/list`. A user timer runs it 15 minutes after login and every 6 hours on hosts that set `checkUpdates.enable = true;` (only `desktop`; too heavy for the x201s). On 25.05 nixpkgs itself no longer moves, so only the claude-code input changes anything.

## Host: x201s

- ThinkPad X201s, staging machine. Repo at `/home/james/nixos-config`.
- Legacy BIOS (no UEFI, no Secure Boot): GRUB on MBR, no systemd-boot or EFI partition. `configurationLimit = 10`.
- Old first-gen Core i-series CPU with no AVX. Native binaries built for newer CPUs crash with "illegal hardware instruction" (exit 132). Do not add packages that need modern CPU features without checking. Do not add `claude-code`.
- Wi-Fi: Intel Ultimate-N 5300 (iwlwifi). It broke on kernel 6.18 and works on the default NixOS 25.05 kernel. Do NOT set `boot.kernelPackages` (no `linuxPackages_latest` or similar).
- `hardware.enableRedistributableFirmware = true;` must stay enabled.
- Old Intel integrated graphics. The user prefers apps that don't need GPU acceleration (this is why the terminal is foot, not alacritty).
- zram swap and TLP are enabled in the host file.
- `system.stateVersion = "26.05"` while running 25.05: the machine was likely installed from 26.05 and moved back to 25.05 for the Wi-Fi kernel. Leave it.
- Sway: `dots/sway/hosts/x201s.conf`. The built-in panel is 1280x800 (probably `LVDS-1`).

## Host: desktop

- AMD desktop, UEFI with systemd-boot. `boot.kernelPackages = pkgs.linuxPackages_latest` is fine here (the kernel rule is for the x201s).
- Imports `gaming.nix` (Steam via `programs.steam`). Desktop-only packages in the host file: `claude-code` (from the `claude-code-nix` flake input overlay) and `discord`.
- No swap, so `dots/sway/hosts/desktop.conf` sets `$idle_sleep_cmd systemctl suspend` instead of hibernate.
- Monitors (`desktop.conf`): DP-1 1920x1080 turned portrait on the left (1080 wide in the layout), DP-2 2560x1440@144Hz on the right at `pos 1080 240`.
- `checkUpdates.enable = true;`.
- `system.stateVersion = "26.05"` (matches `/etc/nixos/configuration.nix`), `home.stateVersion = "25.05"`.

## Known issues and cleanup tasks

1. NixOS 25.05 no longer gets security updates. A possible fix is moving to 26.05 and pinning the X201s to an older kernel series, which would mean relaxing the `boot.kernelPackages` rule. The user hasn't decided.
2. Hibernation on the x201s is not wired up yet. It needs the disk swapfile declared in `swapDevices`, `boot.resumeDevice`, and `boot.kernelParams = [ "resume_offset=..." ]` (from `filefrag -v` on the swapfile). Waiting on the swapfile path, size, RAM size and offset from the laptop. Until then, `systemctl hibernate` fails and the machine just stays locked. zram cannot be used for hibernation.
3. `dots/sway/hosts/x201s.conf` holds commented-out `output DP-3`/`eDP-1` lines from another machine. Move them to that machine's host file when it's added.
4. `dots/sway/brightness` is an empty file left over from the old setup.
5. Optional later: move zsh dotfiles into `dots/` via Home Manager.

## Workflow

1. Edit on the desktop, run `nixos-rebuild build --flake .#<host>` to check it evaluates (needs Nix installed here).
2. Commit and push.
3. On the machine: `rebuild` (pulls, switches, then commits and pushes anything changed there, such as `flake.lock`).
4. If a rebuild breaks something, boot the previous generation from the boot menu.
