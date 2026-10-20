# AGENTS.md

Guidance for AI coding agents working in this directory.

## Repository overview

mise-managed dotfiles (`mise bootstrap`): zsh (pure + plugins — home-manager on NixOS, `http:` backend on macOS, see `mise-global-config.toml`),
PowerShell 7 on Windows (`windows/`), tmux, vim, git, Homebrew / Nix (home-manager) / WinGet / Mise tooling, SSH, GPG, Ghostty, and agent skill deployment.

## Development tools

- **Homebrew (macOS)**: Core shell tools (`eza`, `fzf`, `neovim`, `bat`, `ripgrep`, `fd`, `git-delta`, `jq`, `gh`, `btop`, `sd`), Casks & fonts, plus zsh plugins via the mise `http:` backend.
- **Nix (Linux/NixOS)**: OS system state, system closure, and home-manager-managed shell tooling + zsh plugins for the `jawn` user (`nix/home/jawn.nix`).
- **Mise**: Polyglot runtimes (`bun`, `node`), K8s/Cloud tools (`kubectl`, `helm`, `k9s`), AI agents, macOS zsh plugins, task orchestration (`mise bootstrap`), and profile switching (`MISE_ENV=work`). On Windows it also carries the shell tooling Homebrew and home-manager provide elsewhere, behind an `os = ["windows"]` filter.
- **WinGet (Windows)**: applications and OS settings as a DSC v3 configuration (`windows/configuration.winget`), applied with `winget configure`.

## Build & validation

```bash
mise run check      # from the repo root: shfmt, shellcheck, PSScriptAnalyzer
mise run dotfiles:check   # deploy into scratch homes under each profile; changes nothing in $HOME
```

## Architecture

- **Bootstrap**: `mise bootstrap` auto-detects OS (`uname -s`) and routes to `bootstrap:macos` or `bootstrap:linux`, which run `dotfiles:deploy`. That task applies the `[dotfiles]` table in `mise.toml` with `mise dotfiles apply`. On Windows mise takes the task's `run_windows` branch to `bootstrap:windows`, which runs `windows/deploy-dotfiles.ps1`.
- **The table**: every entry names its `source`, because an implied source writes link targets that dangle from `$HOME`. Directories are `symlink-each`, so other tools keep their own files beside the links. `mise dotfiles apply` refuses the whole table when a real file sits at a target. `dotfiles:deploy` moves the read-only copies and directory links from older deploys into `~/.dotfiles-backup/`. Anything else in the way stops the deploy, and it puts back what it moved. Never pass `--force`: it deletes what is in the way with no backup.
- **Where to apply from**: links point into the directory the table is applied from, so apply from the main checkout, never from a worktree. NixOS hosts apply from a store copy of this directory on every activation (`nix/system/mise-dotfiles.nix`).
- **The WSL boundary**: Windows and the distro each keep their own clone, and nothing symlinks between them. Do not "simplify" this to one clone — `$PROFILE` must resolve before the WSL VM is awake, and Windows bootstraps first so that it can install WSL. See [Install a Windows desktop](https://wiki.lolwtf.ca/runbooks/install-a-windows-desktop/).
- **Profiles**: `MISE_ENV=hm` loads `mise.hm.toml`, which leaves zsh and nvim to home-manager; NixOS activation sets it where home-manager runs. On a NixOS host with home-manager, a manual run needs `MISE_ENV=hm` too, because mise replaces any existing symlink at a target; `dotfiles:deploy` refuses to run without it. `MISE_ENV=work` drops the personal WSL signing key from the rendered `~/.config/git/config.local`, and `.config/git/config.work` applies in work repos via Git `[includeIf]`.
- **Git signing**: `.config/git/config` includes `config.local`, which `mise dotfiles` renders from `.config/git/config.local.tera`: the 1Password signing program and key on WSL. Elsewhere it renders empty and is not written, and a work Mac gets its 1Password program from `.config/git/config.work`.
- **Skills**: source under `skills/`; each skill is linked into `~/.agents/skills`, `~/.claude/skills`, and `~/.gemini/config/skills`.
- **Claude settings**: `.claude/settings.json` is a seed, not a table entry. Claude Code writes its own changes to `~/.claude/settings.json`, so copy the seed there by hand.
- **Profiles**: `MISE_ENV=lab` loads `mise.lab.toml`, which links `.agents/AGENTS.lab.md` and `.ssh/config.lab` (the lab hosts) for the machines that operate the homelab. `.claude/settings.lab.json` holds the lab's `autoMode` entries; Claude Code reads `autoMode` only from `~/.claude/settings.json`, so merge it there by hand: `jq --slurpfile lab .claude/settings.lab.json '.autoMode = $lab[0].autoMode' ~/.claude/settings.json`. A work machine leaves `lab` out.
- **Profiles**: `MISE_ENV=work` loads `mise.work.toml`, which links `mise-global-config.work.toml` to disable the homelab's tools, and `Brewfile` skips its personal entries. It also activates `.config/git/config.work` via Git `[includeIf]`.
- **Skills**: source under `skills/`; deployed directly to `~/.agents/skills`, `~/.claude/skills`, and `~/.gemini/config/skills`.
- **pi package**: `pi/mate/` is a local pi package, loaded in place from `~/.dotfiles/pi/mate` (`mise run pi:setup` declares it in `~/.pi/agent/settings.json` as `../../.dotfiles/pi/mate`, seeds missing settings from `pi/settings.seed.json`, and removes links into `.pi/agent` and copies of this repo's files from pi's `extensions`, `prompts` and `themes`; it runs on Linux and macOS only). Its extensions put `persona.md`, then `memory.md` from the infra checkout at `~/src/github.com/jonpulsifer/infra/apps/mate/profile/` when the machine has one, then `workstation.md` into pi's system prompt and register the weather, kthx and `.mcp.json` MCP servers, and expose the infra checkout's `.agents/skills` in other repos; `mcp.ts` and `repo-skills.ts` read the infra checkout at `~/src/github.com/jonpulsifer/infra` and do nothing on a machine without it. `apps/mate` bakes `persona.md` and `.agents/AGENTS.md` into Rowbutt's system prompt, so an edit to any rebuilds the mate image, and `persona.md` must claim no capability; local-only facts go in `workstation.md`. `apps/mate/profile/memory.md` in the infra repo is what Rowbutt has learned, one dated fact a line; Rowbutt's nightly dream edits it through a pull request on the infra repo, and it holds no capability, credential or private detail. `~/.pi/agent/agents` is still a link to `.pi/agent/agents`.


## Git workflow

Commits signed (SSH) with Conventional Commits. Do not commit directly to `main` — use PRs (`gh pr create`).
