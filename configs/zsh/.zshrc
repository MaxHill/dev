# Interactive Zsh configuration

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS SHARE_HISTORY

# Completion and Emacs-style editing.
autoload -Uz compinit
compinit
bindkey -e

# Pure-style prompt using Zsh's built-in Git integration.
autoload -Uz vcs_info add-zsh-hook
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr '+'
zstyle ':vcs_info:git:*' unstagedstr '*'
zstyle ':vcs_info:git:*' formats ' %b%u%c'
zstyle ':vcs_info:git:*' actionformats ' %b|%a%u%c'

_zsh_prompt_precmd() {
    vcs_info
    # Escape percent signs in branch names so they stay literal prompt text.
    local git_info="${vcs_info_msg_0_//\%/%%}"
    PROMPT=$'\n''%F{blue}%~%f%F{brightblack}'"$git_info"'%f'$'\n''%(?.%F{magenta}.%F{red})❯%f '
}
add-zsh-hook precmd _zsh_prompt_precmd

# Activate mise for interactive shells once it is installed.
if (( $+commands[mise] )); then
    eval "$(mise activate zsh)"
fi

# fzf: Ctrl+R searches history, Ctrl+T inserts paths, Alt+C changes directory.
# Fuzzy completion: type ** then Tab (for example, nvim ** or cd **).
if (( $+commands[fzf] )); then
    source <(fzf --zsh)
fi

# Autosuggestions (zsh-autosuggestions package).
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Accept the current autosuggestion with Ctrl+Y.
bindkey '^Y' autosuggest-accept

# Shell aliases.
source "${XDG_CONFIG_HOME:-$HOME/.config}/zsh/aliases"

# Keep syntax highlighting last (zsh-syntax-highlighting package).
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# opencode
export PATH=/home/max/.opencode/bin:$PATH
