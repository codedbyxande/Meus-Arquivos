#!/bin/bash
# Instalação Minimalista do Hyprland no Arch Linux

set -e

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

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
