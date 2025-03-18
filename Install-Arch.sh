#!/bin/bash

# Цвета для красивого вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для проверки ошибок
check_error() {
  if [ $? -ne 0 ]; then
    echo -e "${RED}Ошибка: $1${NC}"
    exit 1
  fi
}

# Функция для установки пакетов с проверкой
install_package() {
  echo -e "${BLUE}Установка $1...${NC}"
  if sudo pacman -S --noconfirm --needed $1 &> /dev/null; then
    echo -e "${GREEN}$1 успешно установлен.${NC}"
  else
    echo -e "${YELLOW}$1 не найден в репозиториях. Пропускаем.${NC}"
  fi
}

# Функция для установки из AUR с проверкой
install_aur() {
  echo -e "${BLUE}Установка $1 из AUR...${NC}"
  if yay -S --noconfirm --needed $1 &> /dev/null; then
    echo -e "${GREEN}$1 успешно установлен из AUR.${NC}"
  else
    echo -e "${YELLOW}$1 не найден в AUR. Пропускаем.${NC}"
  fi
}

# Функция для установки из Git
install_from_git() {
  echo -e "${BLUE}Установка $1 из Git...${NC}"
  if [ -d "$3" ]; then
    echo -e "${YELLOW}$1 уже установлен. Пропускаем.${NC}"
  else
    if git clone $2 $3 &> /dev/null; then
      echo -e "${GREEN}$1 успешно установлен из Git.${NC}"
    else
      echo -e "${RED}Не удалось установить $1 из Git.${NC}"
    fi
  fi
}

# Добавление локалей (русская и английская)
echo -e "${BLUE}Добавление локалей...${NC}"
sudo sed -i 's/#\(ru_RU\.UTF-8\)/\1/' /etc/locale.gen
sudo sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
sudo locale-gen
check_error "Не удалось сгенерировать локали."
sudo localectl set-locale LANG=en_US.UTF-8
check_error "Не удалось установить локаль."
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Обновление системы
echo -e "${BLUE}Обновление системы...${NC}"
sudo pacman -Syu --noconfirm
check_error "Не удалось обновить систему."

# Установка необходимых пакетов
echo -e "${BLUE}Установка базовых пакетов...${NC}"
sudo pacman -S --noconfirm --needed git base-devel curl wget xorg xorg-server xorg-xinit xorg-xrandr xf86-video-intel
check_error "Не удалось установить базовые пакеты."

# Установка драйверов NVIDIA и Intel
echo -e "${BLUE}Установка драйверов NVIDIA и Intel...${NC}"
install_package nvidia
install_package nvidia-utils
install_package lib32-nvidia-utils
install_package intel-ucode

# Установка GNOME
echo -e "${BLUE}Установка GNOME...${NC}"
install_package gnome
install_package gnome-extra
install_package gdm
sudo systemctl enable gdm
check_error "Не удалось включить GDM."

# Установка yay (AUR-хелпер)
echo -e "${BLUE}Установка yay...${NC}"
if ! command -v yay &> /dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  check_error "Не удалось установить yay."
  cd ~
fi

# Установка Catppuccin Frappé темы
echo -e "${BLUE}Установка Catppuccin Frappé темы...${NC}"
install_aur catppuccin-gtk-theme-frappe
if ! command -v catppuccin-gtk-theme-frappe &> /dev/null; then
  install_from_git "Catppuccin GTK тема" "https://github.com/catppuccin/gtk.git" ~/.themes/Catppuccin-Frappe
fi

# Установка Catppuccin иконок
echo -e "${BLUE}Установка Catppuccin иконок...${NC}"
install_aur catppuccin-icon-theme
if ! command -v catppuccin-icon-theme &> /dev/null; then
  install_from_git "Catppuccin иконки" "https://github.com/catppuccin/icons.git" ~/.icons/Catppuccin
fi

# Установка обоев Catppuccin
echo -e "${BLUE}Установка обоев Catppuccin...${NC}"
mkdir -p ~/Pictures/Wallpapers
wget https://raw.githubusercontent.com/catppuccin/wallpapers/main/frappe/frappe-mountain.png -O ~/Pictures/Wallpapers/catppuccin-frappe.png
check_error "Не удалось загрузить обои Catppuccin."

# Настройка GNOME
echo -e "${BLUE}Настройка GNOME...${NC}"
gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Frappe"
gsettings set org.gnome.desktop.interface icon-theme "Catppuccin"
gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/Wallpapers/catppuccin-frappe.png"
check_error "Не удалось настроить GNOME."

# Установка Alacritty (современный терминал)
echo -e "${BLUE}Установка Alacritty...${NC}"
install_package alacritty

# Настройка Alacritty с Catppuccin Frappé
echo -e "${BLUE}Настройка Alacritty...${NC}"
mkdir -p ~/.config/alacritty
cat > ~/.config/alacritty/alacritty.yml <<EOL
colors:
  primary:
    background: '#303446'
    foreground: '#c6d0f5'
  cursor:
    text: '#303446'
    cursor: '#f2d5cf'
  normal:
    black: '#51576d'
    red: '#e78284'
    green: '#a6d189'
    yellow: '#e5c890'
    blue: '#8caaee'
    magenta: '#f4b8e4'
    cyan: '#81c8be'
    white: '#b5bfe2'
  bright:
    black: '#626880'
    red: '#e78284'
    green: '#a6d189'
    yellow: '#e5c890'
    blue: '#8caaee'
    magenta: '#f4b8e4'
    cyan: '#81c8be'
    white: '#a5adce'
EOL
check_error "Не удалось настроить Alacritty."

# Установка и настройка Fish (современная оболочка)
echo -e "${BLUE}Установка Fish...${NC}"
install_package fish
if command -v fish &> /dev/null; then
  chsh -s /usr/bin/fish
  curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
  fisher install catppuccin/fish
  check_error "Не удалось настроить Fish."
fi

# Установка и настройка Neovim с Catppuccin Frappé
echo -e "${BLUE}Настройка Neovim...${NC}"
install_package neovim
mkdir -p ~/.config/nvim
cat > ~/.config/nvim/init.vim <<EOL
set termguicolors
colorscheme catppuccin-frappe
EOL
check_error "Не удалось настроить Neovim."

# Установка и настройка Wine
echo -e "${BLUE}Установка Wine...${NC}"
install_package wine
install_package wine-mono
install_package wine-gecko
install_package winetricks

# Установка TLauncher Legacy через Flatpak (без лицензии)
echo -e "${BLUE}Установка TLauncher Legacy...${NC}"
install_package flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.tlauncher.Legacy -y
flatpak override com.tlauncher.Legacy --user --env=TL_NO_LICENSE=1
check_error "Не удалось настроить TLauncher Legacy."

# Установка приложений для учёбы
echo -e "${BLUE}Установка приложений для учёбы...${NC}"
install_package libreoffice-still
install_package okular
install_package zathura
install_package zathura-pdf-mupdf
install_package xournalpp
install_package obsidian
install_package chromium
install_package firefox

# Установка дополнительных приложений
echo -e "${BLUE}Установка дополнительных приложений...${NC}"
install_package vlc
install_package gimp
install_package blender
install_package audacity
install_package obs-studio
install_package steam
install_package discord
install_package telegram-desktop

# Установка и настройка клавиатуры (русская + английская)
echo -e "${BLUE}Настройка клавиатуры...${NC}"
localectl set-x11-keymap us,ru pc104 "" grp:alt_shift_toggle
check_error "Не удалось настроить клавиатуру."

# Завершение
echo -e "${GREEN}Установка завершена! Перезагрузите систему.${NC}"
