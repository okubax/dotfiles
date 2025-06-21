# =============================================================================
# ~/.config/zsh/plugins.zsh
# =============================================================================

# Plugin loading function
load_plugin() {
    [[ -f "$1" ]] && source "$1" || echo "Plugin not found: $1"
}

# Load plugins (modify paths as needed)
load_plugin ~/.local/share/zsh/plugins/catppuccin_macchiato-zsh-syntax-highlighting.zsh
load_plugin /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
load_plugin /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Plugin configurations
if [[ -n "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" ]]; then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
fi
