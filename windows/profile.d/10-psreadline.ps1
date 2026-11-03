# PSReadLine settings that stand in for the zsh plugins and options.

# Use the bundled editor and history prediction without loading extra modules.
if ([Console]::IsOutputRedirected -or $env:TERM -eq 'dumb') {
    return
}
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle InlineView

Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
Set-PSReadLineOption -MaximumHistoryCount 10000

# setopt HIST_IGNORE_SPACE
Set-PSReadLineOption -AddToHistoryHandler {
    param([string] $line)
    return -not $line.StartsWith(' ')
}

# zsh-syntax-highlighting, with the ZSH_HIGHLIGHT_STYLES palette from .config/zsh/.zshrc.
Set-PSReadLineOption -Colors @{
    Command                = "$([char]27)[97;1m"
    Parameter              = "$([char]27)[38;5;33m"
    Operator               = "$([char]27)[0m"
    Variable               = "$([char]27)[38;5;209m"
    String                 = "$([char]27)[38;5;63m"
    Number                 = "$([char]27)[38;5;63m"
    Type                   = "$([char]27)[97m"
    Comment                = "$([char]27)[38;5;61m"
    Keyword                = "$([char]27)[38;5;209m"
    Error                  = "$([char]27)[38;5;9m"
    InlinePrediction       = "$([char]27)[38;5;240m"
    ListPrediction         = "$([char]27)[38;5;240m"
    ListPredictionSelected = "$([char]27)[48;5;238m"
}

Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious

# Up/Down search history by prefix; Ctrl-R uses PSReadLine's history search.
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

Set-PSReadLineKeyHandler -Key Ctrl+LeftArrow -Function BackwardWord
Set-PSReadLineKeyHandler -Key Ctrl+RightArrow -Function ForwardWord

Set-PSReadLineKeyHandler -Key Home -Function BeginningOfLine
Set-PSReadLineKeyHandler -Key End -Function EndOfLine
Set-PSReadLineKeyHandler -Key PageUp -Function BeginningOfHistory
Set-PSReadLineKeyHandler -Key PageDown -Function EndOfHistory

# At the end of the line, ForwardWord accepts the next word of the inline suggestion.
Set-PSReadLineKeyHandler -Key Ctrl+f -Function ForwardWord
