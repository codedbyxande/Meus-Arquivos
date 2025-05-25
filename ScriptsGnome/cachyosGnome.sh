#!/bin/bash
# Instalação Minimalista do gnome cachyos 
# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

set -e

echo -e "${CYAN}\n===== INSTALANDO GNOME E UTILITÁRIOS =====${NC}"
pacman -S --noconfirm gnome-shell gdm nautilus kitty git flatpak pop-icon-theme nautilus || { echo -e "${YELLOW}Falha ao instalar gnome e utilitários!${NC}"; exit 1; }

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    com.mattjakeman.ExtensionManager \
    dev.vencord.Vesktop \
    org.nickvision.tubeconverter \
    com.valvesoftware.Steam \
    com.heroicgameslauncher.hgl \
    com.vysp3r.ProtonPlus \
    org.vinegarhq.Sober \
    io.mrarm.mcpelauncher

echo -e "${GREEN}\n✅ Instalação concluída! Reinicie o sistema e faça login no Gnome.${NC}"