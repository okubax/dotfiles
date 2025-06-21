# =============================================================================
# ~/.config/zsh/prompt.zsh
# =============================================================================

# Simple, clean prompt
PROMPT='%n@%m %~ %# '

# Optional: Add git branch to prompt (uncomment if desired)
# autoload -Uz vcs_info
# precmd() { vcs_info }
# zstyle ':vcs_info:git:*' formats ' (%b)'
# setopt PROMPT_SUBST
# PROMPT='%n@%m %~${vcs_info_msg_0_} %# '
