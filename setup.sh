#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"

# Packages
sudo apt update
sudo apt install tmux git jq redshift ttyd xsel tree python3 python3-pip python3-venv

# NodeJS
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 22

# Configs
. "$DIR/copyconfigs.sh"
if [[ ! -d "$HOME/.local/share/nvim/lazy/lazy.nvim" ]]; then
  git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable ~/.local/share/nvim/lazy/lazy.nvim
fi

# Install Brave
if ! command -v brave-browser >/dev/null 2>&1; then
  curl -fsS https://dl.brave.com/install.sh | sh
fi
gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'

# Install latest Neovim via AppImage only if not already installed
mkdir -p "$HOME/Applications"
if ! command -v nvim >/dev/null 2>&1; then
  wget https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
  chmod +x nvim-linux-x86_64.appimage
  sudo mv nvim-linux-x86_64.appimage /usr/local/bin/nvim
fi

# Install code editor
if ! command -v code >/dev/null 2>&1; then
  sudo apt install -y wget gpg apt-transport-https ca-certificates software-properties-common # prereqs
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg # key to keyring file
  sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg # place key
  sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list' # repo
  rm -f /tmp/packages.microsoft.gpg # cleanup
  sudo apt update # refresh lists
  sudo apt install -y code # install stable VS Code
fi

# Install video editor
KDENLIVE_APPIMAGE="$HOME/Applications/kdenlive.appimage"
if [[ ! -f "$KDENLIVE_APPIMAGE" ]] && ! command -v kdenlive >/dev/null 2>&1; then
  wget -O "$KDENLIVE_APPIMAGE" https://download.kde.org/stable/kdenlive/25.04/linux/kdenlive-25.04.2-x86_64.AppImage
  chmod +x "$KDENLIVE_APPIMAGE"
  echo "Kdenlive AppImage installed to $KDENLIVE_APPIMAGE"
fi

# Install Espanso text expander
if ! command -v espanso >/dev/null 2>&1; then
  wget https://github.com/espanso/espanso/releases/latest/download/espanso-debian-x11-amd64.deb
  sudo apt install ./espanso-debian-x11-amd64.deb
  rm espanso-debian-x11-amd64.deb
  
  # Register and start espanso service
  espanso service register
  espanso start
fi

# Install Ollama if it doesn't exist
if ! command -v ollama >/dev/null 2>&1; then
  echo "Ollama not found. Installing..."
  curl -fsSL https://ollama.com/install.sh | sh
else
  echo "Ollama is already installed."
fi

# Install Ollama models only if they don't already exist
if command -v ollama >/dev/null 2>&1; then
  MODELS_TO_INSTALL=(
    "qwen3:0.6b-q4_K_M"
    "qwen3:1.7b-q4_K_M"
    "qwen3:4b-q4_K_M"
    "embeddinggemma:300m"
    "phi4-mini:3.8b-q4_K_M"
    "gemma3:270m-it-qat"
    "gemma3:1b-it-qat"
    "gemma3n:e2b-it-q4_K_M"
    "deepseek-r1:1.5b-qwen-distill-q4_K_M"
  )

  echo "Checking for and installing missing Ollama models..."
  for model in "${MODELS_TO_INSTALL[@]}"; do
    if ! ollama list | grep -q "^$model"; then
      echo "Model $model not found. Pulling..."
      ollama pull "$model"
    else
      echo "Model $model already exists. Skipping."
    fi
  done
else
  echo "Cannot check for models because Ollama is not installed."
fi

# Services
systemctl --user enable --now redshift.service
sudo systemctl disable --now ttyd
