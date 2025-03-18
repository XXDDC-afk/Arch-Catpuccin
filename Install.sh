#!/bin/bash

# Обновление системы
echo "Обновление системы..."
sudo pacman -Syu --noconfirm

# Установка необходимых пакетов
echo "Установка базовых пакетов..."
sudo pacman -S --noconfirm git base-devel curl wget xorg xorg-server xorg-xinit xorg-xrandr xf86-video-intel

# Установка драйверов NVIDIA и Intel
echo "Установка драйверов NVIDIA и Intel..."
sudo pacman -S --noconfirm nvidia nvidia-utils nvidia-settings lib32-nvidia-utils intel-ucode

# Установка GNOME
echo "Установка GNOME..."
sudo pacman -S --noconfirm gnome gnome-extra gdm
sudo systemctl enable gdm

# Установка yay (AUR-хелпер)
echo "Установка yay..."
git clone https://aur.archlinux.org/yay.git /tmp/yay
cd /tmp/yay
makepkg -si --noconfirm
cd ~

# Установка Catppuccin Frappé темы
echo "Установка Catppuccin Frappé темы..."
yay -S --noconfirm catppuccin-gtk-theme-frappe catppuccin-icon-theme

# Установка обоев Catppuccin
echo "Установка обоев Catppuccin..."
mkdir -p ~/Pictures/Wallpapers
wget https://raw.githubusercontent.com/catppuccin/wallpapers/main/frappe/frappe-mountain.png -O ~/Pictures/Wallpapers/catppuccin-frappe.png

# Настройка GNOME
echo "Настройка GNOME..."
gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Frappe"
gsettings set org.gnome.desktop.interface icon-theme "Catppuccin"
gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/Wallpapers/catppuccin-frappe.png"

# Установка Alacritty (современный терминал)
echo "Установка Alacritty..."
sudo pacman -S --noconfirm alacritty

# Настройка Alacritty с Catppuccin Frappé
echo "Настройка Alacritty..."
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

# Установка и настройка Fish (современная оболочка)
echo "Установка Fish..."
sudo pacman -S --noconfirm fish
chsh -s /usr/bin/fish
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
fisher install catppuccin/fish

# Установка и настройка Neovim с Catppuccin Frappé
echo "Настройка Neovim..."
mkdir -p ~/.config/nvim
cat > ~/.config/nvim/init.vim <<EOL
set termguicolors
colorscheme catppuccin-frappe
EOL

# Установка и настройка Wine
echo "Установка Wine..."
sudo pacman -S --noconfirm wine wine-mono wine-gecko winetricks

# Установка TLauncher Legacy через Flatpak (без лицензии)
echo "Установка TLauncher Legacy..."
sudo pacman -S --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.tlauncher.Legacy -y
flatpak override com.tlauncher.Legacy --user --env=TL_NO_LICENSE=1

# Установка приложений для учёбы
echo "Установка приложений для учёбы..."
sudo pacman -S --noconfirm libreoffice-still okular zathura zathura-pdf-mupdf xournalpp obsidian chromium firefox

# Установка дополнительных приложений
echo "Установка дополнительных приложений..."
sudo pacman -S --noconfirm vlc gimp blender audacity obs-studio steam discord telegram-desktop

# Установка и настройка клавиатуры (русская + английская)
echo "Настройка клавиатуры..."
localectl set-x11-keymap us,ru pc104 "" grp:alt_shift_toggle

# Завершение
echo "Установка завершена! Перезагрузите систему."
