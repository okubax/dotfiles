# =============================================================================
# ~/.config/zsh/options.zsh
# =============================================================================

# General shell options
unsetopt autocd                  # Don't auto-change directory
bindkey -e                       # Use emacs key bindings

# Additional useful options
setopt AUTO_PUSHD               # Push directories onto stack automatically
setopt PUSHD_IGNORE_DUPS        # Don't push duplicate directories
setopt PUSHD_SILENT             # Don't print directory stack after pushd/popd
setopt CORRECT                  # Try to correct spelling of commands
setopt COMPLETE_IN_WORD         # Complete from both ends of a word
setopt ALWAYS_TO_END            # Move cursor to end of completed word
