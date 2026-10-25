# Homebrew drops every variable but HOMEBREW_*, so bootstrap passes MISE_ENV as
# HOMEBREW_MISE_ENV. The work laptop sets MISE_ENV=work and leaves out the personal and homelab entries.
work = ENV["HOMEBREW_MISE_ENV"].to_s.split(",").include?("work")

# bootstrap
brew "git"

# shell and core developer tools
brew "bat"
brew "btop"
brew "eza"
brew "fd"
brew "fzf"
brew "gh"
brew "git-delta"
brew "jq"
brew "pre-commit"
brew "ripgrep"
brew "sd"
brew "uv"

unless work
  tap "peonping/tap"
  brew "peonping/tap/peon-ping"
end

# apps and fonts
cask "font-caskaydia-cove-nerd-font"
