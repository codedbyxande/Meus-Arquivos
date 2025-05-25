#!/bin/bash
# Instalação Minimalista do Hyprland no Fedora

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}\n===== OTIMIZANDO DNF =====${NC}"
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
echo 'fastestmirror=true' | sudo tee -a /etc/dnf/dnf.conf > /dev/null

echo -e "${CYYAN}\n===== CONFIGURANDO REPOSITÓRIOS RPM FUSION =====${NC}"
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" nvidia
if [[ ${nvidia,,} =~ ^(s|sim)$ ]]; then
    echo -e "${CYAN}\n===== INSTALANDO DRIVERS NVIDIA =====${NC}"
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    sudo dracut -f --regenerate-all
fi
echo -e "${CYAN}\n===== INSTALANDO COSMIC   =====${NC}"
sudo dnf copr enable -y ryanabx/cosmic-epoch
dnf install cosmic-desktop


echo -e "${CYAN}\n===== CONFIGURANDO REPOSITÓRIO VS CODE =====${NC}"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null

echo -e "${CYAN}\n===== INSTALANDO VS CODE =====${NC}"
sudo dnf install -y code # Added VS Code installation similar to other scripts

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    dev.vencord.Vesktop \
    app.zen_browser.zen \
    org.nickvision.tubeconverter

echo -e "${GREEN}\n✅ Instalação concluída! Reinicie o sistema.${NC}"