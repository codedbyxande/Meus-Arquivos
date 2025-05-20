#!/bin/bash
# Instalação Minimalista do KDE no Arch Linux

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

set -e

echo -e "${CYAN}\n===== OTIMIZANDO PACMAN =====${NC}"
sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
sudo pacman -Sy reflector --noconfirm
sudo reflector --country Brazil --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf

echo -e "${CYAN}\n===== ATUALIZANDO O SISTEMA =====${NC}"
sudo pacman -Syu --noconfirm

echo -e "${CYAN}\n===== INSTALANDO PARU (AUR HELPER) =====${NC}"
temp_dir=$(mktemp -d)
sudo pacman -S --needed base-devel git --noconfirm
git clone https://aur.archlinux.org/paru.git "$temp_dir/paru"
(cd "$temp_dir/paru" && makepkg -si --noconfirm)
rm -rf "$temp_dir"

read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" nvidia
if [[ ${nvidia,,} =~ ^(s|sim)$ ]]; then
    echo -e "${CYAN}\n===== INSTALANDO DRIVERS NVIDIA =====${NC}"
    paru -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings
    sudo mkinitcpio -P
fi

echo -e "${CYAN}\n===== INSTALANDO KDE PLASMA =====${NC}"
sudo pacman -S --noconfirm plasma-desktop sddm dolphin dolphin-plugins kitty ark git flatpak fastfetch

echo -e "${CYAN}\n===== INSTALANDO VISUAL STUDIO CODE =====${NC}"
paru -S --noconfirm visual-studio-code-bin

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    app.zen_browser.zen \
    dev.vencord.Vesktop \
    org.nickvision.tubeconverter

echo -e "${CYAN}\n===== FINALIZANDO INSTALAÇÃO =====${NC}"
sudo systemctl set-default graphical.target
sudo systemctl enable sddm

echo -e "${GREEN}\n✅ Instalação concluída! Reinicie o sistema para usar o KDE Plasma.${NC}"