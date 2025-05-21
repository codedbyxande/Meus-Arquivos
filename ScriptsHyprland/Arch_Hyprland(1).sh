#!/bin/bash
# Instalação Minimalista do Hyprland no Arch Linux

set -e

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
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
    echo -e "${CYAN}\n===== ESCOLHA O TIPO DE DRIVER NVIDIA =====${NC}"
    echo -e "${YELLOW}1) Completo (nvidia, nvidia-utils, nvidia-settings, cuda)"
    echo -e "2) DKMS (nvidia-dkms, nvidia-utils, nvidia-settings, cuda)"
    echo -e "3) Cancelar${NC}"
    read -r -p "$(echo -e "${YELLOW}Digite o número da opção desejada [1/2/3]: ${NC}")" nvidia_opt

    case "$nvidia_opt" in
        1)
            echo -e "${CYAN}Instalando pacote NVIDIA completo...${NC}"
            if ! paru -S --noconfirm nvidia nvidia-utils nvidia-settings cuda; then
                echo -e "${RED}Falha ao instalar drivers NVIDIA!${NC}"
                exit 1
            fi
            ;;
        2)
            echo -e "${CYAN}Instalando pacote NVIDIA DKMS...${NC}"
            if ! paru -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings cuda; then
                echo -e "${RED}Falha ao instalar drivers NVIDIA DKMS!${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${YELLOW}Instalação dos drivers NVIDIA cancelada pelo usuário.${NC}"
            ;;
    esac
    mkinitcpio -P
fi

echo -e "${CYAN}\n===== INSTALANDO HYPRLAND E UTILITÁRIOS =====${NC}"
pacman -S --noconfirm hyprland fuzzel kitty git flatpak

echo -e "${CYAN}\n===== INSTALANDO AGS-HYPRPANEL E WAYPAPER =====${NC}"
paru -S --noconfirm ags-hyprpanel-git waypaper

echo -e "${CYAN}\n===== INSTALANDO NAUTILUS =====${NC}"
pacman -S --noconfirm nautilus

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
