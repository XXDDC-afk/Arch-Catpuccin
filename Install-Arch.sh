#!/bin/bash

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check for errors
check_error() {
  if [ $? -ne 0 ]; then
    echo -e "${RED}Error: $1${NC}"
    exit 1
  fi
}

# Update the system
echo -e "${BLUE}Updating the system...${NC}"
sudo pacman -Syu --noconfirm
check_error "Failed to update the system."

# Install basic packages
echo -e "${BLUE}Installing basic packages...${NC}"
sudo pacman -S --noconfirm --needed git base-devel curl wget xorg xorg-server xorg-xinit xorg-xrandr
check_error "Failed to install basic packages."

# Install GPU drivers
echo -e "${BLUE}Select your GPU driver:${NC}"
echo -e "${GREEN}1. NVIDIA${NC}"
echo -e "${GREEN}2. AMD${NC}"
echo -e "${GREEN}3. Intel${NC}"
read -p "Enter the number: " gpu

case $gpu in
  1)
    echo -e "${BLUE}Installing NVIDIA drivers...${NC}"
    sudo pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils
    ;;
  2)
    echo -e "${BLUE}Installing AMD drivers...${NC}"
    sudo pacman -S --noconfirm xf86-video-amdgpu
    ;;
  3)
    echo -e "${BLUE}Installing Intel drivers...${NC}"
    sudo pacman -S --noconfirm xf86-video-intel
    ;;
  *)
    echo -e "${YELLOW}No GPU driver selected. Skipping.${NC}"
    ;;
esac

# Install GNOME
echo -e "${BLUE}Installing GNOME...${NC}"
sudo pacman -S --noconfirm gnome gnome-extra gdm
sudo systemctl enable gdm
check_error "Failed to enable GDM."

# Install yay (AUR helper)
echo -e "${BLUE}Installing yay...${NC}"
if ! command -v yay &> /dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  check_error "Failed to install yay."
  cd ~
fi

# Install Catppuccin theme
echo -e "${BLUE}Installing Catppuccin theme...${NC}"
yay -S --noconfirm catppuccin-gtk-theme-frappe catppuccin-icon-theme
mkdir -p ~/Pictures/Wallpapers
wget https://raw.githubusercontent.com/catppuccin/wallpapers/main/frappe/frappe-mountain.png -O ~/Pictures/Wallpapers/catppuccin-frappe.png

# Configure GNOME
echo -e "${BLUE}Configuring GNOME...${NC}"
gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Frappe"
gsettings set org.gnome.desktop.interface icon-theme "Catppuccin"
gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/Wallpapers/catppuccin-frappe.png"

# Install additional software
echo -e "${BLUE}Installing additional software...${NC}"
sudo pacman -S --noconfirm alacritty fish neovim vlc gimp blender libreoffice-still audacity obs-studio steam discord telegram-desktop

# Install cava, PipeWire, and pavucontrol
echo -e "${BLUE}Installing cava, PipeWire, and pavucontrol...${NC}"
sudo pacman -S --noconfirm cava pipewire pipewire-pulse pavucontrol

# Install Fish shell with Catppuccin theme
echo -e "${BLUE}Installing Fish shell...${NC}"
sudo pacman -S --noconfirm fish
chsh -s /usr/bin/fish
curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
fisher install catppuccin/fish

# Install Neovim with Catppuccin theme
echo -e "${BLUE}Installing Neovim...${NC}"
sudo pacman -S --noconfirm neovim
mkdir -p ~/.config/nvim
cat > ~/.config/nvim/init.vim <<EOL
set termguicolors
colorscheme catppuccin-frappe
EOL

# Install TLauncher Legacy via Flatpak
echo -e "${BLUE}Installing TLauncher Legacy...${NC}"
sudo pacman -S --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.tlauncher.Legacy -y
flatpak override com.tlauncher.Legacy --user --env=TL_NO_LICENSE=1

# Set up keyboard layout (US + Russian)
echo -e "${BLUE}Setting up keyboard layout...${NC}"
localectl set-x11-keymap us,ru pc104 "" grp:alt_shift_toggle

# Final message
echo -e "${GREEN}Installation complete! Reboot your system.${NC}"
