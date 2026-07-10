# =============================================================================
# ~/.config/zsh/completion.zsh
# =============================================================================

# Initialize completion system
zstyle :compinstall filename "$HOME/.zshrc"
autoload -Uz compinit promptinit
compinit
promptinit

# Completion styling
zstyle ':completion:*' menu select                            # Arrow-key menu selection
zstyle ':completion:*' list-colors "${(@s.:.)LS_COLORS}"      # Color entries like ls
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'     # Case-insensitive matching
zstyle ':completion:*' special-dirs true                      # Complete ./ and ../
zstyle ':completion:*' squeeze-slashes true                   # Treat // as /
