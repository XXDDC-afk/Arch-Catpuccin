#!/bin/bash

# Colors for pretty output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check for errors and retry command if failed
retry_command() {
  local retries=3
  local count=0
  local command="$@"

  until $command; do
    count=$((count + 1))
    if [ $count -eq $retries ]; then
      echo -e "${RED}Error: Command '$command' failed after $retries attempts.${NC}"
      exit 1
    fi
    echo -e "${YELLOW}Retrying '$command'... (${count}/${retries})${NC}"
    sleep 2
  done
}

# Function to run commands with sudo
run_sudo() {
  echo "$PASSWORD" | sudo -S "$@"
  retry_command "$@"
}

# Ask for password at the beginning
echo -e "${BLUE}Please enter your password:${NC}"
read -s PASSWORD
echo

# Update the system
echo -e "${BLUE}Updating the system...${NC}"
run_sudo pacman -Syu --noconfirm

# Install basic packages
echo -e "${BLUE}Installing basic packages...${NC}"
run_sudo pacman -S --noconfirm --needed git base-devel curl wget xorg xorg-server xorg-xinit xorg-xrandr

# Install GPU drivers
echo -e "${BLUE}Select your GPU driver:${NC}"
echo -e "${GREEN}1. NVIDIA${NC}"
echo -e "${GREEN}2. AMD${NC}"
echo -e "${GREEN}3. Intel${NC}"
read -p "Enter the number: " gpu

case $gpu in
  1)
    echo -e "${BLUE}Installing NVIDIA drivers...${NC}"
    run_sudo pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils
    ;;
  2)
    echo -e "${BLUE}Installing AMD drivers...${NC}"
    run_sudo pacman -S --noconfirm xf86-video-amdgpu
    ;;
  3)
    echo -e "${BLUE}Installing Intel drivers...${NC}"
    run_sudo pacman -S --noconfirm xf86-video-intel
    ;;
  *)
    echo -e "${YELLOW}No GPU driver selected. Skipping.${NC}"
    ;;
esac

# Install CPU drivers (assuming Intel or AMD)
echo -e "${BLUE}Select your CPU driver:${NC}"
echo -e "${GREEN}1. Intel${NC}"
echo -e "${GREEN}2. AMD${NC}"
read -p "Enter the number: " cpu

case $cpu in
  1)
    echo -e "${BLUE}Installing Intel CPU microcode...${NC}"
    run_sudo pacman -S --noconfirm intel-ucode
    ;;
  2)
    echo -e "${BLUE}Installing AMD CPU microcode...${NC}"
    run_sudo pacman -S --noconfirm amd-ucode
    ;;
  *)
    echo -e "${YELLOW}No CPU driver selected. Skipping.${NC}"
    ;;
esac

# Install GNOME
echo -e "${BLUE}Installing GNOME...${NC}"
run_sudo pacman -S --noconfirm gnome gnome-extra gdm
run_sudo systemctl enable gdm

# Install yay (AUR helper)
echo -e "${BLUE}Installing yay...${NC}"
if ! command -v yay &> /dev/null; then
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  echo "$PASSWORD" | sudo -S makepkg -si --noconfirm
  check_error "Failed to install yay."
  cd ~
fi

# Install Catppuccin theme
echo -e "${BLUE}Installing Catppuccin theme...${NC}"
retry_command yay -S --noconfirm catppuccin-gtk-theme-frappe || {
  echo -e "${YELLOW}Catppuccin GTK theme AUR installation failed. Attempting to install from Git...${NC}"
  git clone https://github.com/catppuccin/gtk.git ~/.themes/Catppuccin-Frappe
}

# Install Catppuccin icons
echo -e "${BLUE}Installing Catppuccin icons...${NC}"
retry_command yay -S --noconfirm catppuccin-icon-theme || {
  echo -e "${YELLOW}Catppuccin icons AUR installation failed. Attempting to install from Git...${NC}"
  git clone https://github.com/catppuccin/icons.git ~/.icons/Catppuccin
}

# Install Catppuccin wallpaper
echo -e "${BLUE}Installing Catppuccin wallpaper...${NC}"
mkdir -p ~/Pictures/Wallpapers
wget https://raw.githubusercontent.com/catppuccin/wallpapers/main/frappe/frappe-mountain.png -O ~/Pictures/Wallpapers/catppuccin-frappe.png
check_error "Failed to download Catppuccin wallpaper."

# Configure GNOME
echo -e "${BLUE}Configuring GNOME...${NC}"
gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Frappe"
gsettings set org.gnome.desktop.interface icon-theme "Catppuccin"
gsettings set org.gnome.desktop.background picture-uri "file://$HOME/Pictures/Wallpapers/catppuccin-frappe.png"

# Install additional software
echo -e "${BLUE}Installing additional software...${NC}"
run_sudo pacman -S --noconfirm alacritty zsh neovim vlc gimp blender libreoffice-still audacity obs-studio steam discord telegram-desktop

# Install cava, PipeWire, and pavucontrol
echo -e "${BLUE}Installing cava, PipeWire, and pavucontrol...${NC}"
run_sudo pacman -S --noconfirm cava pipewire pipewire-pulse pavucontrol

# Install Zsh with Oh My Zsh and Powerlevel10k
echo -e "${BLUE}Installing Zsh, Oh My Zsh, and Powerlevel10k...${NC}"
run_sudo pacman -S --noconfirm zsh
if ! command -v zsh &> /dev/null; then
  echo -e "${RED}Zsh installation failed. Skipping Oh My Zsh and Powerlevel10k.${NC}"
else
  # Install Oh My Zsh
  echo -e "${BLUE}Installing Oh My Zsh...${NC}"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  check_error "Failed to install Oh My Zsh."

  # Install Powerlevel10k
  echo -e "${BLUE}Installing Powerlevel10k...${NC}"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/custom/themes/powerlevel10k
  sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
  echo -e "${GREEN}Powerlevel10k installed successfully.${NC}"

  # Set Zsh as the default shell
  echo -e "${BLUE}Setting Zsh as the default shell...${NC}"
  chsh -s /usr/bin/zsh
  check_error "Failed to set Zsh as the default shell."
fi

# Install Neovim with Catppuccin theme
echo -e "${BLUE}Installing Neovim...${NC}"
run_sudo pacman -S --noconfirm neovim
mkdir -p ~/.config/nvim
cat > ~/.config/nvim/init.vim <<EOL
set termguicolors
colorscheme catppuccin-frappe
EOL

# Install TLauncher (legacy launcher)
echo -e "${BLUE}Installing TLauncher...${NC}"
run_sudo pacman -S --noconfirm tl-launcher
check_error "Failed to install TLauncher."

# Set up keyboard layout (US + Russian)
echo -e "${BLUE}Setting up keyboard layout...${NC}"
localectl set-x11-keymap us,ru pc104 "" grp:alt_shift_toggle

# Install an application for changing icons and GTK themes
echo -e "${BLUE}Installing GNOME Tweaks...${NC}"
run_sudo pacman -S --noconfirm gnome-tweaks

# Final message and reboot
echo -e "${GREEN}Installation complete! Rebooting in 5 seconds...${NC}"
sleep 5
run_sudo reboot
