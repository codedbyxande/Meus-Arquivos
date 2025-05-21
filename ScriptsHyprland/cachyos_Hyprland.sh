#!/bin/bash
# Instalação Minimalista do Hyprland no Arch Linux

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}\n===== INSTALANDO HYPRLAND E UTILITÁRIOS =====${NC}"
pacman -S --noconfirm hyprland fuzzel kitty git flatpak base-devel swaybg

echo -e "${CYAN}\n===== INSTALANDO NAUTILUS =====${NC}"
pacman -S --noconfirm nautilus

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    app.zen_browser.zen \
    dev.vencord.Vesktop \
    org.nickvision.tubeconverter

echo -e "${GREEN}\n✅ Instalação concluída! Reinicie o sistema e faça login no Hyprland.${NC}"
