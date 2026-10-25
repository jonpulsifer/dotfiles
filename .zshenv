export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"
# home-manager's session variables, such as EDITOR, on the NixOS hosts it manages.
[[ -r /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh ]] && source /etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh
[[ -f $HOME/.zshrc ]] && source $HOME/.zshrc
