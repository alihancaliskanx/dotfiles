# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ZSH configuration
bindkey -v


export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    history
    git
    colorize
    python
    ssh
    sudo
    tmux
    copybuffer
    zsh-syntax-highlighting
    zsh-autosuggestions
    you-should-use
    zsh-autocomplete
    web-search
    autoswitch_virtualenv
    zsh-interactive-cd
    z
    fzf
)

source $ZSH/oh-my-zsh.sh

# User configuration
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

export ARCHFLAGS="-arch $(uname -m)"

# . "$HOME/.local/bin/env"

# Aliases
alias mavproxy='~/.mavproxy_env/bin/mavproxy.py'
alias reloadzsh="source ~/.zshrc"
alias zc='nvim ~/.zshrc'
alias c='clear'
alias lt='eza -lT'
alias ll='ls -lah'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gco='git checkout'
alias trnt='tornet --count 0 --interval'
alias pc='proxychains'
alias v='vim'
alias n='nvim'
alias uconfig='nvim .config/hypr/userconfig.conf'
alias se='sudo -E'
alias yayp='sudo -E yay'
alias t='tmux'
alias terconf='n ~/.config/alacritty/alacritty.toml;'
alias code_path='~/Documents/Code/'
alias f='flatpak'
alias gconfig='nvim ~/.config/git/config'
alias pconfig='sudo nvim /etc/proxychains.conf'
alias tconfig='sudo nvim /etc/tor/torrc'
alias stmcube='pc /home/sups/st/stm32cubeide_1.19.0_2/stm32cubeide_wayland'
alias s='sudo'
alias pacsil='sudo rm -rf /var/lib/pacman/db.lck'
alias goo=google
alias qgc='~/Documents/Code/qgroundcontrol/build/Release/QGroundControl > /dev/null 2>&1 &'

# Functions
sha256_kontrol() {
    [ "$(sha256sum "$1" | awk '{print $1}')" = "$2" ] && echo "True" || echo "False"
}

function gitproxy_on() {
    git config --global http.proxy http://192.168.49.1:8000
    git config --global https.proxy http://192.168.49.1:8000

    echo "✅ Git Global Proxy ENABLED: 192.168.49.1:8000"
}

function gitproxy_off() {
    git config --global --unset http.proxy
    git config --global --unset https.proxy

    echo "❌ Git Global Proxy DISABLED."
}

function proxy_on() {
    export http_proxy="http://192.168.49.1:8000"
    export https_proxy="http://192.168.49.1:8000"
    export ftp_proxy="http://192.168.49.1:8000"
    export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
    export HTTP_PROXY=$http_proxy
    export HTTPS_PROXY=$https_proxy
    echo "✅ Proxy activated: 192.168.49.1:8000"
}

function proxy_off() {
    unset http_proxy https_proxy ftp_proxy no_proxy HTTP_PROXY HTTPS_PROXY
    echo "✅ Proxy deactivated."
}

function tor_on() {
    local proxy_url="socks5h://127.0.0.1:9050"
    export http_proxy="$proxy_url"
    export https_proxy="$proxy_url"
    export ftp_proxy="$proxy_url"
    export all_proxy="$proxy_url"
    export no_proxy="localhost,127.0.0.1,localaddress,.localdomain.com"
    export HTTP_PROXY=$http_proxy
    export HTTPS_PROXY=$https_proxy
    export FTP_PROXY=$ftp_proxy
    export ALL_PROXY=$all_proxy
    echo "🧅 Tor Proxy activated: 127.0.0.1:9050"
}

function tor_off() {
    unset http_proxy https_proxy ftp_proxy all_proxy no_proxy
    unset HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY
    echo "🚫 Tor Proxy deactivated."
}

function http_tor() {
    echo "⚙️  Tor ayarları düzenleniyor (Upstream Proxy: 192.168.49.1:8000)..."
    sudo sed -i '/^HTTPProxy/d' /etc/tor/torrc
    sudo sed -i '/^HTTPSProxy/d' /etc/tor/torrc
    sudo sed -i '/^ReachableAddresses/d' /etc/tor/torrc
    echo "HTTPProxy 192.168.49.1:8000" | sudo tee -a /etc/tor/torrc > /dev/null
    echo "HTTPSProxy 192.168.49.1:8000" | sudo tee -a /etc/tor/torrc > /dev/null
    echo "ReachableAddresses *:80,*:443" | sudo tee -a /etc/tor/torrc > /dev/null
    echo "🔄 Tor servisi yeniden başlatılıyor..."
    sudo systemctl restart tor
    if systemctl is-active --quiet tor; then
        echo "✅ BAŞARILI: Tor artık 192.168.49.1:8000 üzerinden tünelleniyor."
    else
        echo "❌ HATA: Tor başlatılamadı!"
    fi
}

function normal_tor() {
    echo "⚙️  Tor ayarları varsayılana döndürülüyor..."
    sudo sed -i '/^HTTPProxy/d' /etc/tor/torrc
    sudo sed -i '/^HTTPSProxy/d' /etc/tor/torrc
    sudo sed -i '/^ReachableAddresses/d' /etc/tor/torrc
    echo "🔄 Tor servisi yeniden başlatılıyor..."
    sudo systemctl restart tor
    if systemctl is-active --quiet tor; then
        echo "✅ BAŞARILI: Tor standart modda çalışıyor."
    else
        echo "❌ HATA: Tor başlatılamadı!"
    fi
}

function gclink() {
    local last_path="$PWD"
    local install_path="$HOME/temp"

    mkdir -p "$install_path"
    cd "$install_path" || return 1

    if [ -z "$1" ]; then
        echo "Error: You must provide a package name."
        cd "$last_path"
        return 1
    fi

    local package="$1"
    shift
    local link="$*"
    
    local target_dir="${link:-$package}"

    if [ -z "$link" ]; then
        git clone "https://aur.archlinux.org/$package.git"
    else
        git clone "https://aur.archlinux.org/$package.git" "$link"
    fi

    if [ ! -d "$target_dir" ]; then
        echo "Error: Directory not found, cloning might have failed."
        cd "$last_path"
        return 1
    fi

    cd "$target_dir" || { cd "$last_path"; return 1; }

    if makepkg -si; then
        echo "Installation completed successfully!"
    else
        echo "Error: An issue occurred during makepkg."
    fi

    cd "$last_path"
}

source <(fzf --zsh)
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# DISTROBOX
if [[ -n "$CONTAINER_ID" || -n "$DISTROBOX_ENTER" ]]; then
  export TERM=xterm-256color
  alias ls='ls --color=auto'
  PS1="%n@%m %1~ %# "
  # Eğer bu dosya yoksa hata verebilir, varsa kalsın:
  [ -f /opt/ros/noetic/setup.zsh ] && source /opt/ros/noetic/setup.zsh
  clear
fi


# --- Docker Proxy Helper Functions ---

# Define your proxy URL here
DOCKER_HTTP_PROXY="http://192.168.49.1:8000"
DOCKER_CONF_DIR="/etc/systemd/system/docker.service.d"
DOCKER_CONF_FILE="$DOCKER_CONF_DIR/http-proxy.conf"

docker_proxy_on() {
    echo "🔌 Enabling Docker Proxy ($DOCKER_HTTP_PROXY)..."

    # 1. Create directory if it doesn't exist
    if [ ! -d "$DOCKER_CONF_DIR" ]; then
        sudo mkdir -p "$DOCKER_CONF_DIR"
    fi

    # 2. Write the proxy configuration
    sudo bash -c "cat > $DOCKER_CONF_FILE" <<EOF
[Service]
Environment="HTTP_PROXY=$DOCKER_HTTP_PROXY"
Environment="HTTPS_PROXY=$DOCKER_HTTP_PROXY"
Environment="NO_PROXY=localhost,127.0.0.1,::1"
EOF

    # 3. Reload systemd and restart Docker
    echo "🔄 Reloading Docker daemon..."
    sudo systemctl daemon-reload
    sudo systemctl restart docker

    echo "✅ Docker Proxy is ON."
}

docker_proxy_off() {
    echo "🔌 Disabling Docker Proxy..."

    if [ -f "$DOCKER_CONF_FILE" ]; then
        # 1. Remove the configuration file
        sudo rm "$DOCKER_CONF_FILE"

        # 2. Reload systemd and restart Docker
        echo "🔄 Reloading Docker daemon..."
        sudo systemctl daemon-reload
        sudo systemctl restart docker

        echo "❌ Docker Proxy is OFF."
    else
        echo "⚠️  Proxy configuration not found. It might be already OFF."
    fi
}

# --- Sart Checker Proxy Functions ---

function sart_proxy_on() {
    local target_file="/home/sups/Documents/Code/sart_checker/src/check.sh"

    # Dosya var mı kontrol et
    if [ ! -f "$target_file" ]; then
        echo "❌ HATA: Dosya bulunamadı -> $target_file"
        return 1
    fi

    # Önce temizlik yap (tekrar eklemeyi önlemek için)
    sed -i '/export http.*_proxy="http:\/\/192.168.49.1:8000"/d' "$target_file"

    # Shebang (#!/usr/bin/env bash) satırının hemen altına (2. satıra) proxy ekle
    sed -i '1a export http_proxy="http://192.168.49.1:8000"\nexport https_proxy="http://192.168.49.1:8000"' "$target_file"

    echo "✅ Sart Checker Proxy EKLENDİ (192.168.49.1:8000)"
    echo "Dosya: $target_file"
}

function sart_proxy_off() {
    local target_file="/home/sups/Documents/Code/sart_checker/src/check.sh"

    # Dosya var mı kontrol et
    if [ ! -f "$target_file" ]; then
        echo "❌ HATA: Dosya bulunamadı -> $target_file"
        return 1
    fi

    # Proxy satırlarını sil
    sed -i '/export http.*_proxy="http:\/\/192.168.49.1:8000"/d' "$target_file"

    echo "🚫 Sart Checker Proxy KALDIRILDI."
}

function ros_docker() {
    CONTAINER_NAME="ros_noetic_clean"
    IMAGE_NAME="osrf/ros:noetic-desktop-full"

    xhost +local:root > /dev/null 2>&1

    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo "🟢 $CONTAINER_NAME zaten açık. İçeri giriliyor..."
        docker exec -it $CONTAINER_NAME bash
    elif [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
        echo "🟡 $CONTAINER_NAME uyuyor. Uyandırılıyor..."
        docker start $CONTAINER_NAME
        docker exec -it $CONTAINER_NAME bash
    else
        echo "🔴 Konteyner bulunamadı! Taze kurulum yapılıyor..."
        docker run -it \
            --net=host \
            --env="DISPLAY" \
            --env="QT_X11_NO_MITSHM=1" \
            --device /dev/dri:/dev/dri \
            --volume="/tmp/.X11-unix:/tmp/.X11-unix:rw" \
            --name $CONTAINER_NAME \
            $IMAGE_NAME \
            bash
    fi
}

function ssh_proxy_on() {
    local cf="$HOME/.ssh/config"
    [ ! -f "$cf" ] && touch "$cf"
    if ! grep -q "corkscrew 192.168.49.1 8000" "$cf"; then
        printf "\nHost github.com\n    Hostname ssh.github.com\n    Port 443\n    User git\n    IdentityFile ~/.ssh/github\n    ProxyCommand corkscrew 192.168.49.1 8000 %%h %%p\n" >> "$cf"
        echo "SSH Proxy EKLENDI"
    fi
}

function ssh_proxy_off() {
    local cf="$HOME/.ssh/config"
    if [ -f "$cf" ]; then
        sed -i '/Host github.com/,/ProxyCommand corkscrew 192.168.49.1 8000 %h %p/d' "$cf"
        sed -i '/^$/N;/^\n$/D' "$cf"
        echo "SSH Proxy KALDIRILDI"
    fi
}

function sart_status() {
  systemctl --user status sart_checker.timer
  systemctl --user list-timers sart_checker.timer
}

function ardudev () {
# source $HOME/venv-ardupilot/bin/activate  # commented out by conda initialize
  export PATH=/opt/gcc-arm-none-eabi-10-2020-q4-major/bin:$PATH
  export PATH=/home/sups/Documents/Code/ardupilot/Tools/autotest:$PATH
}

function ardupilot_dev ()
{
  source /home/sups/venv-ardupilot/bin/activate
}


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


export PATH="$HOME/.local/bin:$PATH"
export PATH=/home/sups/Documents/Code/aurapilot/ardupilot/Tools/autotest:$PATH

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/sups/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/sups/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/home/sups/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/home/sups/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<


# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='/home/sups/miniforge3/bin/mamba';
export MAMBA_ROOT_PREFIX='/home/sups/miniforge3';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
