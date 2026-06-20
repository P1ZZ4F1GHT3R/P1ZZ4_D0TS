# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
fastfetch

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source /usr/share/cachyos-zsh-config/cachyos-config.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Created by `pipx` on 2025-12-16 18:49:59
export PATH="$PATH:/home/p1zz4f1ght3r/.local/bin"

## [Completion]
## Completion scripts setup. Remove the following line to uninstall
[[ -f /home/p1zz4f1ght3r/.dart-cli-completion/zsh-config.zsh ]] && . /home/p1zz4f1ght3r/.dart-cli-completion/zsh-config.zsh || true
## [/Completion]


fpath+=~/.zfunc; autoload -Uz compinit; compinit

zstyle ':completion:*' menu select
export PATH=$PATH:~/.spicetify

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/p1zz4f1ght3r/.lmstudio/bin"
# End of LM Studio CLI section

export PATH=$PATH:~/.spicetify

# Dynamic System Paths
export WALLPAPER_DIR="/home/p1zz4f1ght3r/Pictures/Wallpapers"
export SCRIPT_DIR="/home/p1zz4f1ght3r/.config/hypr/scripts"
PATH="$HOME/.local/bin:${PATH}"
export PATH
