# =============================================================================
# ~/.config/zsh/completion.zsh
# =============================================================================

# Initialize completion system
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit promptinit
compinit
promptinit

# Completion styling
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' squeeze-slashes true
