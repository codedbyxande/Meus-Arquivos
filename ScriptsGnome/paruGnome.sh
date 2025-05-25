#!/bin/bash

# Define colors for output
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}\n===== INSTALANDO PARU (AUR HELPER) =====${NC}"
mkdir -p tmp # -p ensures no error if tmp exists
cd tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si # This will prompt for sudo password and confirmation
cd ../.. # Go back to the original directory
rm -rf tmp # Remove the temporary directory

echo -e "${CYAN}\n===== INSTALANDO ZEN  =====${NC}"
paru -S --noconfirm zen-browser-bin

echo -e "${CYAN}\n===== INSTALANDO EXTENSÃO POP SHELL =====${NC}"
paru -S --noconfirm gnome-shell-extension-pop-shell-git

echo -e "${CYAN}\n===== INSTALAÇÃO CONCLUÍDA! =====${NC}"
