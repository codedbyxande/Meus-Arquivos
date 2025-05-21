#!/bin/bash
# Instalação Minimalista do Hyprland no openSUSE

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

set -e

echo -e "${CYAN}\n===== OTIMIZANDO ZYPPER =====${NC}"
sudo sed -i "s/^#\?download\.max_concurrent_connections.*/download.max_concurrent_connections = 5/; T; a download.max_concurrent_connections = 5" /etc/zypp/zypp.conf
sudo env ZYPP_CURL2=1 zypper ref || { echo -e "${YELLOW}Falha ao atualizar repositórios!${NC}"; exit 1; }

echo -e "${CYAN}\n===== ATUALIZANDO O SISTEMA =====${NC}"
sudo env ZYPP_PCK_PRELOAD=1 zypper dup -y || { echo -e "${YELLOW}Falha ao atualizar o sistema!${NC}"; exit 1; }

echo -e "${CYAN}\n===== ADICIONANDO REPOSITÓRIO E INSTALANDO VISUAL STUDIO CODE =====${NC}"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/zypp/repos.d/vscode.repo > /dev/null
sudo zypper ref || { echo -e "${YELLOW}Falha ao atualizar repositórios do VS Code!${NC}"; exit 1; }
# VS Code installation moved here, as it's added as a repo and installed with zypper in the next step.

read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" nvidia
if [[ ${nvidia,,} =~ ^(s|sim)$ ]]; then
    echo -e "${CYAN}\n===== INSTALANDO DRIVERS NVIDIA =====${NC}"
    sudo env ZYPP_PCK_PRELOAD=1 zypper in \
        libnvidia-egl-gbm1 \
        libnvidia-egl-wayland1 \
        nvidia-common-G06 \
        nvidia-compute-G06 \
        nvidia-compute-utils-G06 \
        nvidia-driver-G06-kmp-default \
        nvidia-gl-G06 \
        nvidia-libXNVCtrl \
        nvidia-modprobe \
        nvidia-persistenced \
        nvidia-settings \
        nvidia-video-G06 || { echo -e "${YELLOW}Falha ao instalar drivers NVIDIA!${NC}"; exit 1; }
    echo -e "${CYAN}\n===== RECRIANDO INITRAMFS =====${NC}"
    sudo dracut -f --regenerate-all
fi

echo -e "${CYAN}\n===== INSTALANDO HYPRLAND MINIMAL =====${NC}"
sudo env ZYPP_PCK_PRELOAD=1 zypper in -y hyprland-devel hyprland fuzzel  kitty git flatpak code fastfetch || { echo -e "${YELLOW}Falha ao instalar Hyprland!${NC}"; exit 1; } # Replaced gnome-shell, gdm with hyprland, fuzzel and included nautilus, kitty, git, flatpak, code, fastfetch

echo -e "${CYAN}\n===== INSTALANDO NAUTILUS (SEM RECOMENDAÇÕES) =====${NC}"
sudo env ZYPP_PCK_PRELOAD=1 zypper in -y nautilus --no-recommends

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    app.zen_browser.zen \
    dev.vencord.Vesktop \
    org.nickvision.tubeconverter # Adjusted flatpak apps to match other scripts, removed ExtensionManager

echo -e "${GREEN}\n✅ Instalação concluída! Reinicie o sistema para usar o Hyprland.${NC}"