#!/usr/bin/env bash
# Instalação Minimalista do KDE no Debian/Ubuntu

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}\n===== CONFIGURANDO REPOSITÓRIOS =====${NC}"
sudo cp /etc/apt/sources.list{,.bak}
sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://deb.debian.org/debian sid main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian sid main contrib non-free non-free-firmware
EOF

echo -e "${CYAN}\n===== ATUALIZANDO O SISTEMA =====${NC}"
sudo apt update && sudo apt full-upgrade -y

echo -e "${CYAN}\n===== INSTALANDO VISUAL STUDIO CODE =====${NC}"
sudo apt-get install -y wget gpg apt-transport-https
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo apt update
sudo apt install -y code

echo -e "${CYAN}\n===== INSTALANDO KDE PLASMA MINIMAL =====${NC}"
    sudo apt install -y flatpak git gnome-shell gdm nautilus git flatpak kitty fastfetch

read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA COMPLETOS? [s/N]: ${NC}")" nvidia
if [[ ${nvidia,,} =~ ^(s|sim)$ ]]; then
    echo -e "${CYAN}\n===== INSTALANDO DRIVERS NVIDIA =====${NC}"
    sudo apt install -y nvidia-driver nvidia-driver-libs nvidia-driver-bin nvidia-settings nvidia-xconfig \
        libnvidia-gl-*-i386 libnvidia-gl-*-amd64 libnvidia-egl-wayland1 firmware-misc-nonfree
    sudo apt install -y linux-headers-amd64
fi

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    com.mattjakeman.ExtensionManager \
    app.zen_browser.zen \
    dev.vencord.Vesktop \
    org.nickvision.tubeconverter

echo -e "${CYAN}\n===== DEFININDO DISPLAY MANAGER =====${NC}"
sudo systemctl set-default graphical.target
sudo dpkg-reconfigure gdm

echo -e "${GREEN}\n✅ Instalação concluída! Reinicie o sistema.${NC}"
