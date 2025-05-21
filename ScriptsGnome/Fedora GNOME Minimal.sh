#!/bin/bash
# Instalação Minimalista do GNOME no Fedora

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}\n===== OTIMIZANDO DNF =====${NC}"
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
echo 'fastestmirror=true' | sudo tee -a /etc/dnf/dnf.conf > /dev/null

echo -e "${CYAN}\n===== CONFIGURANDO REPOSITÓRIOS RPM FUSION =====${NC}"
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" nvidia
if [[ ${nvidia,,} =~ ^(s|sim)$ ]]; then
    echo -e "${CYAN}\n===== INSTALANDO DRIVERS NVIDIA =====${NC}"
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    sudo dracut -f --regenerate-all
fi

echo -e "${CYAN}\n===== INSTALANDO GNOME MINIMAL =====${NC}"
sudo dnf install -y gnome-shell gdm nautilus git flatpak kitty fastfetch

echo -e "${CYAN}\n===== INSTALANDO POP SHELL =====${NC}"
sudo dnf install -y make nodejs npm
git clone https://github.com/pop-os/shell.git /tmp/popshell
(cd /tmp/popshell && make local-install)
rm -rf /tmp/popshell

# Utilitários opcionais
sudo dnf install -y kitty code

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
sudo systemctl enable gdm

echo -e "${GREEN}\n✅ Instalação concluída! Reinicie o sistema.${NC}"
