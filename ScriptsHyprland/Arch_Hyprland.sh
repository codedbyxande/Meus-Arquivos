#!/bin/bash
# Instalação Minimalista do GNOME no Arch Linux

set -e

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


echo -e "${CYAN}\n===== CONFIGURANDO PACMAN E MIRRORS =====${NC}"
sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf
pacman -Sy reflector --noconfirm
reflector --country Brazil --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf

echo -e "${CYAN}\n===== ATUALIZANDO O SISTEMA =====${NC}"
pacman -Syu --noconfirm

echo -e "${CYAN}\n===== INSTALANDO PARU (AUR HELPER) =====${NC}"
temp_dir=$(mktemp -d)
echo "Usando diretório temporário: $temp_dir"
pacman -S --needed base-devel git --noconfirm
git clone https://aur.archlinux.org/paru.git "$temp_dir/paru"
(cd "$temp_dir/paru" && makepkg -si --noconfirm)
rm -rf "$temp_dir"

read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" nvidia
if [[ ${nvidia,,} =~ ^(s|sim)$ ]]; then
    echo -e "${CYAN}\n===== INSTALANDO DRIVERS NVIDIA =====${NC}"
    if ! paru -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings cuda; then
        echo -e "${YELLOW}Falha ao instalar drivers NVIDIA!${NC}"
        exit 1
    fi
    mkinitcpio -P
fi

echo -e "${CYAN}\n===== INSTALANDO HYPRLAND =====${NC}"
pacman -S --noconfirm hyprland fuzzel nautilus kitty git flatpak

echo -e "${CYAN}\n===== INSTALANDO VS CODE =====${NC}"
paru -S visual-studio-code-bin --noconfirm

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    app.zen_browser.zen \
    dev.vencord.Vesktop \
    org.nickvision.tubeconverter

echo -e "${GREEN}\n✅ Instalação concluída! Reinicie o sistema e faça login no Hyprland.${NC}"