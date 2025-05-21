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

echo -e "${CYAN}\n===== INSTALANDO HYPRLAND =====${NC}"
pacman -S --noconfirm hyprland fuzzel nautilus kitty git flatpak

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    app.zen_browser.zen \
    dev.vencord.Vesktop \
    org.nickvision.tubeconverter

echo -e "${GREEN}\n✅ Instalação concluída! Reinicie o sistema e faça login no Hyprland.${NC}"
