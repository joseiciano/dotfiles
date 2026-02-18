# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git)

source $ZSH/oh-my-zsh.sh

# macOS (BSD ls)
# The 'ow' equivalent is 'G' and 'tw' is 'H'
# Format: 'gx' means blue foreground (g), default background (x)
export LSCOLORS="Gxfxcxdxbxegedabagacad"

# Linux (GNU ls)
# 'ow' = other-writable, 'tw' = sticky bit
# '0;34' = Blue text, no background
export LS_COLORS=$LS_COLORS:"ow=0;34:tw=0;34:"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# --- FZF & RIPGREP CONFIGURATION ---
if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi
if [ -f /usr/share/doc/fzf/examples/completion.zsh ]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi

if command -v rg > /dev/null; then
  export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git/*"'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview '[[ \$(file --mime-type -b {}) == text/* ]] && batcat --color=always {} || file -b {}'"
# -----------------------------------

# Docker Dev Environment Function
ddev() {
  if [ ! "$(docker ps -q -f name=dev_container)" ]; then
    echo "Starting development container..."
    docker compose up -d dev-shell
  fi

  case "$1" in
    "llm-15")
      echo "Switching to Qwen 1.5B..."
      docker compose --profile llm-3 stop llama-3 2>/dev/null
      docker compose --profile llm-15 up -d llama-15
      ;;
    "llm-3")
      echo "Switching to Qwen 3B..."
      docker compose --profile llm-15 stop llama-15 2>/dev/null
      docker compose --profile llm-3 up -d llama-3
      ;;
  esac

  docker compose exec -it dev-shell tmux attach || docker compose exec -it dev-shell tmux
}

# Aliases
alias mux='tmuxinator'
alias llama-15="curl http://llama-15:8080/v1/completions"
alias llama-3="curl http://llama-3:8080/v1/completions"
alias python=python3
alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'

# Editor
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Java
export JAVA_HOME="$HOME/OpenJDK/jdk-23.0.1.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"

# Android
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/platform-tools"

# Obsidian
export obsidianpath="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Pepega"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"

# Local bin
export PATH="$HOME/.local/bin:$PATH"

# Google Cloud SDK
if [ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"; fi
if [ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"; fi

# Yazi function
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
