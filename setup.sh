#!/bin/bash

echo -e "\e[32m[1/6] Обновление системы и установка базовых утилит...\e[0m"
apt update
apt upgrade -y
apt install -y ncdu git micro htop curl wget gpg zsh

echo -e "\e[32m[2/6] Установка eza...\e[0m"
mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg --yes
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
apt update
apt install -y eza

echo -e "\e[32m[3/6] Установка Oh My Zsh...\e[0m"
if [ ! -d "/root/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
    echo "Oh My Zsh уже установлен."
fi

echo -e "\e[32m[4/6] Назначение zsh оболочкой по умолчанию для root...\e[0m"
chsh -s $(which zsh) root

echo -e "\e[32m[5/6] Установка плагинов ZSH...\e[0m"
ZSH_CUSTOM="/root/.oh-my-zsh/custom"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions
fi

echo -e "\e[32m[6/6] Создание конфигурации /root/.zshrc...\e[0m"
cat << 'EOF' > /root/.zshrc
# =========================
# OH MY ZSH
# =========================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="bira"

DISABLE_UPDATE_PROMPT="true"
DISABLE_AUTO_UPDATE="true"
ENABLE_CORRECTION="false"

plugins=(
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# =========================
# HISTORY
# =========================
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt SHARE_HISTORY

# =========================
# НАВИГАЦИЯ
# =========================
alias ..='cd ..'
alias ...='cd ../..'
alias ll='eza -lah --color=always'
alias tree='eza -T --color=always'

# =========================
# ПОЛЕЗНОЕ
# =========================
alias h='htop'
alias du='ncdu'
alias m='micro'

alias i='apt install -y'
alias u='apt update && apt upgrade -y'

alias reload='source ~/.zshrc'
alias config='micro ~/.zshrc'
alias rr='remnawave_reverse'
alias rri='bash <(curl -Ls https://raw.githubusercontent.com/eGamesAPI/remnawave-reverse-proxy/refs/heads/main/install_remnawave.sh)'
# =========================
# DOCKER HELPERS
# =========================
dc() {
  docker compose -f "$1/docker-compose.yml" "${@:2}"
}

alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"'

# =========================
# PROJECTS
# =========================
typeset -A PROJECTS

PROJECTS[remna]=/opt/remnanode

for proj dir in ${(kv)PROJECTS}; do
  eval "
  function $proj() {
    local action=\$1
    local dir=${PROJECTS[$proj]}

    case \$action in
      u|'') dc \"\$dir\" up -d ;;
      d) dc \"\$dir\" down ;;
      r) dc \"\$dir\" down && dc \"\$dir\" up -d ;;
      p) dc \"\$dir\" pull ;;
      l) dc \"\$dir\" logs -f ;;
      dir) cd \"\$dir\" ;;
      n)
        docker exec -it remnawave-nginx nginx -t &&
        docker exec -it remnawave-nginx nginx -s reload
      ;;
      *) echo \"Usage: $proj [u|d|r|p|l|dir|n]\" ;;
    esac
  }
  "
done
EOF

echo -e "\e[32mУстановка завершена! Запускаем zsh...\e[0m"
exec zsh
