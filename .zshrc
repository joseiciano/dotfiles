if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Uncomment the following line if pasting URLs and other text is messed up.
DISABLE_MAGIC_FUNCTIONS="true"
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
plugins=(git docker docker-compose fzf)

source $ZSH/oh-my-zsh.sh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
alias k="kubectl"
alias mux='tmuxinator'
export JAVA_HOME=$HOME/OpenJDK/jdk-23.0.1.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# yazi script to open file explorer in current directory
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
export EDITOR="nvim"
export GEMINI_API_KEY="AIzaSyDM0QCNZhi07i988cCcsDcWpxb7oyU8r5M"

# Automatically start or attach to a tmux session
# if command -v tmux &> /dev/null && [ -z "$TMUX" ]; then
#     tmux new-session -A -s main
# fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/joseiciano/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/joseiciano/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/joseiciano/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/joseiciano/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
export PATH=/Users/joseiciano/.local/bin:$PATH

# bun completions
[ -s "/Users/joseiciano/.bun/_bun" ] && source "/Users/joseiciano/.bun/_bun"

# LLama server
alias llama-15="llama-server --fim-qwen-1.5b-default"
alias llama-3="llama-server --fim-qwen-3b-default"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
