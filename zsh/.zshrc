# Uncomment to time zshrc load time
# zmodload zsh/zprof

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Plugins
source $HOME/dotfiles/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh 2>/dev/null
source $HOME/dotfiles/zsh/plugins/zsh-you-should-use/zsh-you-should-use.plugin.zsh 2>/dev/null
source $HOME/dotfiles/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh 2>/dev/null

# macOS (BSD ls)
# The 'ow' equivalent is 'G' and 'tw' is 'H'
# Format: 'gx' means blue foreground (g), default background (x)
export LSCOLORS="Gxfxcxdxbxegedabagacad"

# Linux (GNU ls)
# 'ow' = other-writable, 'tw' = sticky bit
# '0;34' = Blue text, no background
export LS_COLORS=$LS_COLORS:"ow=0;34:tw=0;34:"

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
alias k="kubectl"
alias mux='tmuxinator'
alias llama-15="llama-server --fim-qwen-1.5b-default"
alias llama-3="llama-server --fim-qwen-3b-default"
alias python=python3
alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'
alias init-ts='$HOME/dotfiles/scripts/init-ts.sh'
alias new-wt-branch='$HOME/dotfiles/scripts/new-worktree-branch.sh'
alias mako-new-wt="new-wt-branch mako --prompt --agent orchestration"
alias mako-delete-wt="$HOME/dotfiles/scripts/delete-worktree-branch.sh mako"


# Editor
export EDITOR="nvim"

# Pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Java
export JAVA_HOME=$HOME/OpenJDK/jdk-23.0.1.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# NVM
export NVM_DIR=$HOME/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && nvm_load() {
  . "$NVM_DIR/nvm.sh" # This loads nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Obsidian
export obsidianpath="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Pepega"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "/Users/joseiciano/.bun/_bun" ] && source "/Users/joseiciano/.bun/_bun"

# Local bin
export PATH=/Users/joseiciano/.local/bin:$PATH

# Google Cloud SDK
if [ -f '/Users/joseiciano/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/joseiciano/Downloads/google-cloud-sdk/path.zsh.inc'; fi
if [ -f '/Users/joseiciano/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/joseiciano/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

# fzf integration
source <(fzf --zsh)

source $HOME/dotfiles/zsh/plugins/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Uncomment to time zshrc load time
# zprof
