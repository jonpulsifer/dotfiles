{
  config,
  lib,
  pkgs,
  ...
}:
let
  zshConfigEarlyInit = ''
    setopt TRANSIENT_RPROMPT
    zstyle ':autocomplete:tab:*' fzf-completion
    zstyle :prompt:pure:prompt:success color cyan

    typeset -g -A ZSH_HIGHLIGHT_STYLES

    ZSH_HIGHLIGHT_STYLES[default]=none
    ZSH_HIGHLIGHT_STYLES[unknown-token]=fg=009
    ZSH_HIGHLIGHT_STYLES[reserved-word]=fg=009,standout
    ZSH_HIGHLIGHT_STYLES[alias]=fg=white,bold
    ZSH_HIGHLIGHT_STYLES[builtin]=fg=white,bold
    ZSH_HIGHLIGHT_STYLES[function]=fg=white,bold
    ZSH_HIGHLIGHT_STYLES[command]=fg=white,bold
    ZSH_HIGHLIGHT_STYLES[precommand]=fg=white,underline
    ZSH_HIGHLIGHT_STYLES[commandseparator]=none
    ZSH_HIGHLIGHT_STYLES[hashed-command]=fg=009
    ZSH_HIGHLIGHT_STYLES[path]=fg=004,underline
    ZSH_HIGHLIGHT_STYLES[globbing]=fg=063
    ZSH_HIGHLIGHT_STYLES[history-expansion]=fg=white,underline
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]=fg=033
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]=fg=039
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]=none
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]=fg=063
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]=fg=063
    ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]=fg=009
    ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]=fg=009
    ZSH_HIGHLIGHT_STYLES[assign]=none
  '';

  zshConfig = ''
    fpath+=("${config.home.profileDirectory}"/share/zsh/site-functions "${config.home.profileDirectory}"/share/zsh/$ZSH_VERSION/functions "${config.home.profileDirectory}"/share/zsh/vendor-completions)
    declare -a files=(
      ${config.home.homeDirectory}/.nix-profile/etc/profile.d/nix.sh
    )
    for file ("$files[@]"); do
      [ -r $file ] && source $file
    done

    typeset -g -A key

    key[Home]="''${terminfo[khome]}"
    key[End]="''${terminfo[kend]}"
    key[Insert]="''${terminfo[kich1]}"
    key[Backspace]="''${terminfo[kbs]}"
    key[Delete]="''${terminfo[kdch1]}"
    key[Up]="''${terminfo[kcuu1]}"
    key[Down]="''${terminfo[kcud1]}"
    key[Left]="''${terminfo[kcub1]}"
    key[Right]="''${terminfo[kcuf1]}"
    key[PageUp]="''${terminfo[kpp]}"
    key[PageDown]="''${terminfo[knp]}"
    key[Shift-Tab]="''${terminfo[kcbt]}"

    bindkey "^[[1;5C" forward-word
    bindkey "^[[1;5D" backward-word
    [[ -n "''${key[Home]}"      ]] && bindkey -- "''${key[Home]}"       beginning-of-line
    [[ -n "''${key[End]}"       ]] && bindkey -- "''${key[End]}"        end-of-line
    [[ -n "''${key[Insert]}"    ]] && bindkey -- "''${key[Insert]}"     overwrite-mode
    [[ -n "''${key[Backspace]}" ]] && bindkey -- "''${key[Backspace]}"  backward-delete-char
    [[ -n "''${key[Delete]}"    ]] && bindkey -- "''${key[Delete]}"     delete-char
    [[ -n "''${key[Up]}"        ]] && bindkey -- "''${key[Up]}"         fzf-history-widget
    [[ -n "''${key[Down]}"      ]] && bindkey -- "''${key[Down]}"       down-line-or-history
    [[ -n "''${key[Left]}"      ]] && bindkey -- "''${key[Left]}"       backward-char
    [[ -n "''${key[Right]}"     ]] && bindkey -- "''${key[Right]}"      forward-char
    [[ -n "''${key[PageUp]}"    ]] && bindkey -- "''${key[PageUp]}"     beginning-of-buffer-or-history
    [[ -n "''${key[PageDown]}"  ]] && bindkey -- "''${key[PageDown]}"   end-of-buffer-or-history
    [[ -n "''${key[Shift-Tab]}" ]] && bindkey -- "''${key[Shift-Tab]}"  reverse-menu-complete
  '';
in
{
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    zprof.enable = false;
    shellAliases = { };
    initContent =
      let
        early = lib.mkOrder 1200 zshConfigEarlyInit;
        late = lib.mkOrder 1200 zshConfig;
      in
      lib.mkMerge [
        early
        late
      ];

    plugins = [
      # # https://github.com/marlonrichert/zsh-autocomplete/issues/763
      # {
      #   name = "zsh-autocomplete";
      #   src = fetchFromGitHub {
      #     owner = "marlonrichert";
      #     repo = "zsh-autocomplete";
      #     rev = "24.09.04";
      #     sha256 = "sha256-o8IQszQ4/PLX1FlUvJpowR2Tev59N8lI20VymZ+Hp4w=";
      #   };
      # }
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "v1.2.0";
          sha256 = "sha256-q26XVS/LcyZPRqDNwKKA9exgBByE0muyuNb0Bbar2lY=";
        };
      }
      {
        name = "pure";
        src = pkgs.fetchFromGitHub {
          owner = "sindresorhus";
          repo = "pure";
          rev = "v1.23.0";
          sha256 = "sha256-BmQO4xqd/3QnpLUitD2obVxL0UulpboT8jGNEh4ri8k=";
        };
      }
    ];
  };
}
