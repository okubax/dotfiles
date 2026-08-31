# =============================================================================
# ~/.config/zsh/plugins.zsh
# =============================================================================

# Source a plugin file, warning if it's missing
load_plugin() {
    [[ -f "$1" ]] && source "$1" || echo "Plugin not found: $1"
}

# autosuggestions and syntax-highlighting come from Arch packages
load_plugin /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
load_plugin /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Plugin configurations
if [[ -n "$ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE" ]]; then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
fi
