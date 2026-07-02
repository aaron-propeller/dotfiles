# Dotfiles

Personal macOS dotfiles managed via [chezmoi](https://www.chezmoi.io). Sets up a
new Mac from a single bootstrap command: dotfiles, brew formulae/casks, Node via
nvm, global CLI tools, fonts, wallpapers, and (on work machines) motion-sync +
pi-packages + an npm-token-refresh LaunchAgent.

macOS-only. Apple Silicon and Intel both supported.

## Getting started

### Prerequisites

**Before you run the bootstrap:**

1. **On Apple Silicon**, make sure your terminal is running **natively (arm64)**,
   not under Rosetta. The chezmoi installer detects arch via `uname -m`, and a
   Rosetta shell will fetch the wrong build. Verify with:

   ```sh
   uname -m   # must print "arm64" on Apple Silicon
   ```

   If it prints `x86_64` on Apple Silicon, uncheck "Open using Rosetta" in your
   terminal app's Get Info panel and re-launch.

2. Xcode Command Line Tools will be installed by the bootstrap if missing.

### Bootstrap

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --branch propelleraero --apply aaron-propeller
```

Chezmoi will prompt for:

- Git email address
- Git name
- Run as admin? (yes = install Homebrew and everything under it; no = dotfiles only)
- Personal or work machine? (`personal` skips work-only tools like tfenv, k9s,
  Motion, Notion Calendar, motion-sync, npm-token-refresh; `work` skips personal
  apps like Discord, Steam, OpenEmu)

## What gets installed

### Files applied to `$HOME`

Everything under `src/` is applied by chezmoi:

- `.zshrc` and the `.zsh/` runtime (prompt, aliases, plugin config)
- `.config/nvim/` (LazyVim-style config)
- `.config/ghostty/` (terminal + themes)
- `.config/cmux/`
- `.pi/agent/settings.json` (pi coding agent config)
- `.gitconfig`, `.gitignore_global`
- Templated `Library/LaunchAgents/com.aaron.npm-token-refresh.plist` (work only)
- Templated `bin/npm-token-refresh.sh` (work only)

Chezmoi then runs `src/.chezmoiscripts/*` in alphabetical order:

1. `copy-misc-files` — copies fonts to `~/Library/Fonts`, symlinks
   `~/Pictures/wallpapers` at the repo's `wallpapers/` dir.
2. `install-dependencies` — Xcode CLT, Homebrew, all brew formulae + casks
   (gated on `run_as_admin`), antidote, nvm + latest node, global npm/pnpm
   packages (`typescript-language-server`, `jjson`,
   `@earendil-works/pi-coding-agent`).
3. `install-interactive-1password` (work only) — **PAUSES**: opens 1Password,
   waits for signin + CLI integration, verifies `op whoami`.
4. `install-interactive-github-ssh` — **PAUSES**: generates a fresh ed25519 SSH
   key, waits while you upload the public key to GitHub, verifies `ssh -T
   git@github.com`.
5. `install-motion-sync` (work only) — clones `motion-sync`, installs npm deps,
   registers the every-15-minute Motion↔Jira sync LaunchAgent.
6. `install-pi-packages` — clones `pi-packages` and runs `npm install` in each
   sub-package.
7. `load-npm-token-refresh` (work only) — registers the daily 09:00 LaunchAgent
   that refreshes the Propeller npm token from 1Password and installs
   `@propelleraero/prp` on first successful fire.

### Notable brew packages

- **CLI (both):** neovim, direnv, gh, git-crypt, pnpm, pyenv, terminal-notifier,
  the_silver_searcher, tree, visidata, crystal
- **CLI (work):** awscli, tfenv, k9s
- **Casks (both):** 1password, slack, firefox, spotify, ghostty, docker, finicky
- **Casks (personal):** discord, mullvadvpn, steam, vlc, openemu
- **Casks (work):** visual-studio-code, google-chrome, 1password-cli, freelens,
  cmux, cmux-nightly, motion, notion-calendar, tailscale

The full list lives in
[`src/.chezmoiscripts/run_once_after_install-dependencies.zsh.tmpl`](src/.chezmoiscripts/run_once_after_install-dependencies.zsh.tmpl).

## Manual setup

The install scripts pause and walk you through the two credential-gathering
steps interactively (SSH key upload, 1Password signin). Everything else is
either automated or truly manual (Apple ID, browser prefs, wallpaper choice).

During `chezmoi apply`, you'll be prompted at two points:

1. **`install-interactive-1password`** (work only). Opens the 1Password app,
   waits while you sign in and enable **Settings → Developer → Integrate with
   1Password CLI**, then verifies `op whoami` works before continuing.
2. **`install-interactive-github-ssh`** (both). Generates a fresh ed25519 SSH
   key, copies the public half to your clipboard, opens
   <https://github.com/settings/ssh/new> in your browser, waits while you paste
   and save it, then verifies `ssh -T git@github.com` before continuing.

Both prompts also accept `skip` if you want to defer — skipped steps can be
re-run with:

```sh
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```

After chezmoi finishes, these are the remaining truly-manual steps:

- [ ] **General:** sign in to the App Store, sign in to Slack / Firefox etc.,
      configure browser plugins (1Password, adblocker).
- [ ] **Wallpaper:** pick one from `~/Pictures/wallpapers` in System Settings.
- [ ] **motion-sync `.env`** (work only). Copy `~/src/motion-sync/.env.example`
      to `.env`, fill in Motion + Jira credentials, then run:

  ```sh
  ~/src/motion-sync/scripts/install-daemon.sh
  ```

  (The `install-motion-sync` script skips the daemon install cleanly if `.env`
  is missing at bootstrap time.)

The first successful `npm-token-refresh` run — which happens automatically at
09:00 daily, or immediately after 1Password signin if you re-run
`~/bin/npm-token-refresh.sh` — also installs `@propelleraero/prp` globally.

## Caveats

### Ghostty

Ghostty is configured to use **Monaco Nerd Font**, which is bundled in this
repo and copied to `~/Library/Fonts` by `copy-misc-files`. If the font doesn't
appear after install, force a font-cache rebuild by opening Font Book.

### chezmoi apply overwrites pi settings

`~/.pi/agent/settings.json` is currently a fully-managed template. Any
interactive change pi writes at runtime (theme swaps, `lastChangelogVersion`,
etc.) is reverted on the next `chezmoi apply`. If you change settings you want
to keep, `chezmoi re-add ~/.pi/agent/settings.json` back to source.

## Reset / rebuild

To wipe everything chezmoi placed on this machine (plus the side effects the
install scripts create — motion-sync/pi-packages clones, nvm, antidote, fonts,
etc.) and re-bootstrap:

```sh
~/.local/share/chezmoi/scripts/nuke.sh              # preview + confirm, then wipe
~/.local/share/chezmoi/scripts/nuke.sh --dry-run    # preview only
~/.local/share/chezmoi/scripts/nuke.sh --yes --reinit   # unattended full rebuild
```

See `scripts/nuke.sh --help` for all flags and what it deliberately does not
touch (Homebrew formulae, 1Password app, App Store apps).

To just re-run the `run_once_*` scripts without wiping files (e.g. after
editing a script):

```sh
chezmoi state delete-bucket --bucket=scriptState
chezmoi apply
```
