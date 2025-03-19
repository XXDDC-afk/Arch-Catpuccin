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

# Function to install a package
install_package() {
  echo -e "${BLUE}Installing $1...${NC}"
  if sudo pacman -S --noconfirm --needed $1 &> /dev/null; then
    echo -e "${GREEN}$1 installed successfully.${NC}"
  else
    echo -e "${YELLOW}$1 not found in repositories. Skipping.${NC}"
  fi
}

# Function to install from AUR
install_aur() {
  echo -e "${BLUE}Installing $1 from AUR...${NC}"
  if yay -S --noconfirm --needed $1 &> /dev/null; then
    echo -e "${GREEN}$1 installed successfully from AUR.${NC}"
  else
    echo -e "${YELLOW}$1 not found in AUR. Skipping.${NC}"
  fi
}

# Function to install from Git
install_from_git() {
  echo -e "${BLUE}Installing $1 from Git...${NC}"
  if [ -d "$3" ]; then
    echo -e "${YELLOW}$1 already installed. Skipping.${NC}"
  else
    if git clone $2 $3 &> /dev/null; then
      echo -e "${GREEN}$1 installed successfully from Git.${NC}"
    else
      echo -e "${RED}Failed to install $1 from Git.${NC}"
    fi
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
install_aur catppuccin-gtk-theme-frappe
if ! command -v catppuccin-gtk-theme-frappe &> /dev/null; then
  install_from_git "Catppuccin GTK theme" "https://github.com/catppuccin/gtk.git" ~/.themes/Catppuccin-Frappe
fi

# Install Catppuccin icons (fallback to Git if AUR fails)
echo -e "${BLUE}Installing Catppuccin icons...${NC}"
install_aur catppuccin-icon-theme
if ! command -v catppuccin-icon-theme &> /dev/null; then
  install_from_git "Catppuccin icons" "https://github.com/catppuccin/icons.git" ~/.icons/Catppuccin
fi

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
sudo pacman -S --noconfirm alacritty zsh neovim vlc gimp blender libreoffice-still audacity obs-studio steam discord telegram-desktop

# Install cava, PipeWire, and pavucontrol
echo -e "${BLUE}Installing cava, PipeWire, and pavucontrol...${NC}"
sudo pacman -S --noconfirm cava pipewire pipewire-pulse pavucontrol

# Install Zsh with Oh My Zsh and Powerlevel10k
echo -e "${BLUE}Installing Zsh, Oh My Zsh, and Powerlevel10k...${NC}"
install_package zsh
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
sudo pacman -S --noconfirm neovim
mkdir -p ~/.config/nvim
cat > ~/.config/nvim/init.vim <<EOL
set termguicolors
colorscheme catppuccin-frappe
EOL

# Install TLauncher via Flatpak
echo -e "${BLUE}Installing TLauncher...${NC}"
sudo pacman -S --noconfirm flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub ch.tlaun.TL -y
flatpak --user override ch.tlaun.TL --env=TL_BOOTSTRAP_OPTIONS="-Dtl.useForce"
check_error "Failed to install or configure TLauncher."

# Set up keyboard layout (US + Russian)
echo -e "${BLUE}Setting up keyboard layout...${NC}"
localectl set-x11-keymap us,ru pc104 "" grp:alt_shift_toggle

# Final message and reboot
echo -e "${GREEN}Installation complete! Rebooting in 5 seconds...${NC}"
sleep 5
sudo reboot
