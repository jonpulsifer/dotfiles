# Homebrew drops every variable but HOMEBREW_*, so bootstrap:macos passes MISE_ENV as
# HOMEBREW_MISE_ENV. The work laptop sets MISE_ENV=work and leaves out the personal and homelab entries.
work = ENV["HOMEBREW_MISE_ENV"].to_s.split(",").include?("work")

# bootstrap
brew "git"

# shell and core developer tools
brew "bat"
brew "btop"
brew "cloudflared" unless work
brew "eza"
brew "fd"
brew "fzf"
brew "gh"
brew "git-delta"
brew "jq"
brew "neovim"
brew "nvm"
brew "pre-commit"
brew "ripgrep"
brew "ruby"
brew "sd"
brew "uv"
brew "watchman"

# cloud and containers
cask "gcloud-cli"
cask "docker-desktop"

# kubernetes
brew "helm"
brew "k9s"

# terraform
brew "tenv"
brew "terraform-docs"

# ai homies
cask "1password-cli"
cask "claude-code@latest"
brew "opencode" unless work

unless work
  tap "peonping/tap"
  brew "peonping/tap/peon-ping"
end

# apps and fonts
cask "font-caskaydia-cove-nerd-font"
cask "secretive" unless work
