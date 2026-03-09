# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH


# Source - https://stackoverflow.com/a/74323525
# Posted by Bodmas, modified by community. See post 'Timeline' for change history
# Retrieved 2026-01-14, License - CC BY-SA 4.0
autoload -Uz compinit
compinit
# ---

xinput set-prop "SYNA3602:00 0911:5288 Touchpad" "libinput Tapping Enabled" 1
setxkbmap -layout us,ru -option grp:alt_shift_toggle

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:/snap/bin
export PATH="$HOME/.npm-global/bin:$PATH"

#compdef opencode
###-begin-opencode-completions-###
#
# yargs command completion script
#
# Installation: opencode completion >> ~/.zshrc
#    or opencode completion >> ~/.zprofile on OSX.
#
_opencode_yargs_completions()
{
  local reply
  local si=$IFS
  IFS=$'
' reply=($(COMP_CWORD="$((CURRENT-1))" COMP_LINE="$BUFFER" COMP_POINT="$CURSOR" opencode --get-yargs-completions "${words[@]}"))
  IFS=$si
  if [[ ${#reply} -gt 0 ]]; then
    _describe 'values' reply
  else
    _default
  fi
}
if [[ "'${zsh_eval_context[-1]}" == "loadautofunc" ]]; then
  _opencode_yargs_completions "$@"
else
  compdef _opencode_yargs_completions opencode
fi
###-end-opencode-completions-###

# Ensure ZLE is available in interactive shells before plugins/completion
if [[ $- == *i* ]]; then
  zmodload -i zsh/zle 2>/dev/null || true
fi

# OpenAI token
if [ -f "$HOME/.openai_env" ]; then
  set -a
  source "$HOME/.openai_env"
  set +a
fi
# Antrophic token
if [ -f "$HOME/.antrophic_api_key" ]; then
  set -a
  source "$HOME/.antrophic_api_key"
  set +a
fi
# X-ai api key
if [ -f "$HOME/.xai_api_key" ]; then
  set -a
  source "$HOME/.xai_api_key"
  set +a
fi
# Socks proxy url
# if [ -f "$HOME/.socks_proxy" ]; then
#   set -a
#   source "$HOME/.socks_proxy"
#   set +a
# fi
# GH PAT
if [ -f "$HOME/.github_mcp_apikey" ]; then
  set -a
  source "$HOME/.github_mcp_apikey"
  set +a
fi

# Shell-GPT defaults
export SGPT_MODEL="${SGPT_MODEL:-gpt-5-nano-2025-08-07}"
export SGPT_MAX_TOKENS="${SGPT_MAX_TOKENS:-800}"

# Load OpenAI API key from config file if not already set
if [ -z "$OPENAI_API_KEY" ] && [ -f "$HOME/.config/sgpt/openai.key" ]; then
  export OPENAI_API_KEY="$(<"$HOME/.config/sgpt/openai.key")"
fi

# Helper to set/save OpenAI API key safely
sgpt-set-key() {
  if [ -z "$1" ]; then
    echo "Usage: sgpt-set-key sk-..." >&2
    return 1
  fi
  mkdir -p "$HOME/.config/sgpt"
  printf "%s" "$1" > "$HOME/.config/sgpt/openai.key"
  chmod 600 "$HOME/.config/sgpt/openai.key"
  export OPENAI_API_KEY="$1"
  echo "Saved key to $HOME/.config/sgpt/openai.key and exported OPENAI_API_KEY"
}

# Aliases
alias ai='sgpt --model "${SGPT_MODEL}"'
alias aish='sgpt --model "${SGPT_MODEL}" --shell'
alias aiex='sgpt --model "${SGPT_MODEL}" --explain'

# Zsh widgets and keybindings (only in interactive shells, after OMZ init)
if [[ $- == *i* ]]; then
  # Explain current command line (prints output, does not modify BUFFER)
  _ai_explain_line() {
    if ! command -v sgpt >/dev/null; then
      print -r -- "sgpt not found. Install with pipx install shell-gpt" >&2
      return 1
    fi
    local text expl
    text="$BUFFER"
    zle -I
    expl=$(sgpt --model "${SGPT_MODEL}" --temperature=1 --describe-shell -- "$text") || return $?
    print -r -- "$expl"
  }
  zle -N ai-explain-line _ai_explain_line

  # Suggest a single bash command to replace the current BUFFER
  _ai_suggest_to_line() {
    if ! command -v curl >/dev/null || ! command -v jq >/dev/null; then
      print -r -- "This feature requires curl and jq (pacman -S jq curl)" >&2
      return 1
    fi
    if [ -z "$OPENAI_API_KEY" ]; then
      print -r -- "Set OPENAI_API_KEY or run: sgpt-set-key sk-..." >&2
      return 1
    fi
    local sys_msg usr_msg payload suggestion
    usr_msg="Task: ${BUFFER}"
    sys_msg="You are a shell assistant. Output ONLY a single bash command. No prose, no code fences."
    payload=$(jq -n --arg sys "$sys_msg" --arg usr "$usr_msg" \
      '{model:"$SGPT_MODEL", input:[{role:"system",content:$sys},{role:"user",content:$usr}], temperature:1}')
    suggestion=$(curl -s ${OPENAI_HTTP_PROXY:+-x "$OPENAI_HTTP_PROXY"} https://api.openai.com/v1/responses \
      -H "Authorization: Bearer ${OPENAI_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$payload" | jq -r '.output_text // empty') || return $?
    if [ -n "$suggestion" ]; then
      suggestion=$(printf "%s" "$suggestion" | sed -E 's/^```[a-z]*//; s/```$//')
      BUFFER="$suggestion"
      CURSOR=${#BUFFER}
    fi
  }
  zle -N ai-suggest-to-line _ai_suggest_to_line

  # Keybindings (emacs keymap): Alt-g to suggest, Alt-e to explain
  bindkey -e
  # Unbind defaults if present, then bind our widgets
  bindkey -M emacs -r '^[g' 2>/dev/null || true
  bindkey -M emacs -r '^[e' 2>/dev/null || true
  bindkey -M emacs '^[g' ai-suggest-to-line
  bindkey -M emacs '^[e' ai-explain-line
fi


#pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# for user service "ssh-agent"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"

# Neovim git mergetool
alias vimdiff='nvim -d'

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="arrow"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# Re-apply AI keybindings after oh-my-zsh (which sets defaults)
if [[ $- == *i* ]]; then
  # Ensure our widgets exist
  (( $+functions[ai-suggest-to-line] )) || zle -N ai-suggest-to-line _ai_suggest_to_line
  (( $+functions[ai-explain-line] )) || zle -N ai-explain-line _ai_explain_line
  # Override bindings
  bindkey -M emacs -r '^[g' 2>/dev/null || true
  bindkey -M emacs -r '^[e' 2>/dev/null || true
  bindkey -M emacs '^[g' ai-suggest-to-line
  bindkey -M emacs '^[e' ai-explain-line
fi

export EDITOR='nvim'

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/mdar/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/home/mdar/anaconda3/etc/profile.d/conda.sh" ]; then
#         . "/home/mdar/anaconda3/etc/profile.d/conda.sh"
#     else
#         export PATH="/home/mdar/anaconda3/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# <<< conda initialize <<<

# Task Master aliases added on 8/25/2025
alias tm='task-master'
alias taskmaster='task-master'

# bun completions
[ -s "/home/danya/.bun/_bun" ] && source "/home/danya/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

export KAGGLE_API_TOKEN=KGAT_763d91fd299a4de575f18c3204203892
