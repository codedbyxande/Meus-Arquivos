#!/bin/bash
# Instalação Minimalista do KDE no Fedora

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

set -e

echo -e "${CYAN}\n===== OTIMIZANDO DNF =====${NC}"
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
echo 'fastestmirror=true' | sudo tee -a /etc/dnf/dnf.conf > /dev/null

echo -e "${CYAN}\n===== ATUALIZANDO O SISTEMA =====${NC}"
sudo dnf upgrade -y || { echo -e "${YELLOW}Falha ao atualizar o sistema!${NC}"; exit 1; }

echo -e "${CYAN}\n===== CONFIGURANDO REPOSITÓRIOS RPM FUSION =====${NC}"
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || { echo -e "${YELLOW}Falha ao adicionar RPM Fusion!${NC}"; exit 1; }

read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" nvidia
if [[ ${nvidia,,} =~ ^(s|sim)$ ]]; then
    echo -e "${CYAN}\n===== INSTALANDO DRIVERS NVIDIA =====${NC}"
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda || { echo -e "${YELLOW}Falha ao instalar drivers NVIDIA!${NC}"; exit 1; }
    sudo dracut -f --regenerate-all
fi

echo -e "${CYAN}\n===== INSTALANDO KDE PLASMA =====${NC}"
sudo dnf install -y flatpak git plasma-desktop dolfin dolphin-plugins ffmpegthumbs ark sddm sddm-kcm kitty || { echo -e "${YELLOW}Falha ao instalar KDE Plasma!${NC}"; exit 1; }

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    app.zen_browser.zen \
    dev.vencord.Vesktop \
    org.nickvision.tubeconverter

echo -e "${CYAN}\n===== FINALIZANDO INSTALAÇÃO =====${NC}"
sudo systemctl set-default graphical.target
sudo systemctl enable sddm

echo -e "${GREEN}\n✅ Instalação concluída! Reinicie o sistema para usar o KDE Plasma.${NC}"