#!/bin/bash
# Instalação Minimalista do KDE Plasma 6 no openSUSE

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

set -e

echo -e "${CYAN}\n===== OTIMIZANDO ZYPPER =====${NC}"
# Configura o número máximo de conexões simultâneas para download no Zypper
sudo sed -i "s/^#\?download\.max_concurrent_connections.*/download.max_concurrent_connections = 5/; T; a download.max_concurrent_connections = 5" /etc/zypp/zypp.conf
# Atualiza os repositórios do Zypper
sudo env ZYPP_CURL2=1 zypper ref || { echo -e "${YELLOW}Falha ao atualizar repositórios!${NC}"; exit 1; }

echo -e "${CYAN}\n===== ATUALIZANDO O SISTEMA =====${NC}"
# Realiza uma atualização completa do sistema
sudo env ZYPP_PCK_PRELOAD=1 zypper dup -y || { echo -e "${YELLOW}Falha ao atualizar o sistema!${NC}"; exit 1; }

echo -e "${CYAN}\n===== ADICIONANDO REPOSITÓRIO E INSTALANDO VISUAL STUDIO CODE (OPCIONAL) =====${NC}"
# Importa a chave GPG da Microsoft
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
# Adiciona o repositório do Visual Studio Code
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/zypp/repos.d/vscode.repo > /dev/null
# Atualiza os repositórios novamente para incluir o VS Code
sudo zypper ref || { echo -e "${YELLOW}Falha ao atualizar repositórios do VS Code!${NC}"; exit 1; }
# Instala o Visual Studio Code - removido da instalação minimalista do KDE, mas mantido aqui como opcional
sudo env ZYPP_PCK_PRELOAD=1 zypper in -y code || { echo -e "${YELLOW}Falha ao instalar Visual Studio Code!${NC}"; }


read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" nvidia
if [[ ${nvidia,,} =~ ^(s|sim)$ ]]; then
    echo -e "${CYAN}\n===== INSTALANDO DRIVERS NVIDIA =====${NC}"
    # Instala os pacotes de drivers NVIDIA
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
    # Recria o initramfs após a instalação dos drivers NVIDIA
    sudo dracut -f --regenerate-all
fi

echo -e "${CYAN}\n===== INSTALANDO KDE PLASMA 6 MINIMALISTA =====${NC}"
# Instala os pacotes essenciais para um ambiente KDE Plasma 6 minimalista.
# 'plasma6-desktop' é o pacote principal para o ambiente de desktop Plasma 6.
# 'sddm' é o gerenciador de exibição padrão do KDE.
# 'dolphin' é o gerenciador de arquivos do KDE (considerado essencial para um desktop funcional).
# 'flatpak' e 'fastfetch' são mantidos como utilitários úteis, mas podem ser removidos para um mínimo ainda mais extremo.
sudo env ZYPP_PCK_PRELOAD=1 zypper in -y plasma6-desktop dolphin flatpak fastfetch dolphin-plugins ffmpegthumbs ark sddm sddm-kcm || { echo -e "${YELLOW}Falha ao instalar KDE Plasma 6 minimalista!${NC}"; exit 1; }

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK (OPCIONAL) =====${NC}"
# Adiciona o repositório Flathub para Flatpak, se ainda não existir
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
# Exemplo de instalação de aplicativos Flatpak - Removido para manter a instalação minimalista
# flatpak install -y flathub \
#     app.zen_browser.zen \
#     dev.vencord.Vesktop \
#     org.nickvision.tubeconverter

echo -e "${CYAN}\n===== FINALIZANDO INSTALAÇÃO =====${NC}"
# Define o alvo gráfico como padrão para iniciar o ambiente gráfico na inicialização
sudo systemctl set-default graphical.target
# Habilita o SDDM (gerenciador de exibição) para iniciar no boot
sudo systemctl enable sddm

echo -e "${GREEN}\n✅ Instalação minimalista do KDE Plasma 6 concluída! Reinicie o sistema para usar o KDE Plasma.${NC}"
