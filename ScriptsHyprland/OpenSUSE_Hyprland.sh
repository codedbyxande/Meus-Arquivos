#!/bin/bash
# Hyprland Minimal Installation Script for openSUSE

# Este script automatiza a instalação mínima do Hyprland,
# junto com utilitários e aplicativos essenciais, no openSUSE.
# Inclui opções para drivers NVIDIA e o repositório COSMIC.

# Cores para a saída do terminal
GREEN='\033[1;32m' # Mensagens de sucesso
CYAN='\033[1;36m'  # Títulos de seção
YELLOW='\033[1;33m' # Avisos e prompts
RED='\033[1;31m'   # Mensagens de erro
NC='\033[0m'      # Sem Cor - Reseta a cor do texto

# --- Configuração do Script e Tratamento de Erros ---

# Sai imediatamente se um comando falhar.
set -e
# Trata variáveis não definidas como erro.
set -u
# O valor de retorno de um pipeline é o status do último comando a falhar,
# ou zero se todos os comandos no pipeline tiverem sucesso.
set -o pipefail

# Função para exibir mensagens de erro e sair
handle_error() {
    echo -e "${RED}ERRO: $1${NC}" >&2
    exit 1
}

# Verifica por privilégios de root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Este script precisa ser executado com privilégios de root (sudo).${NC}"
    handle_error "Execute o script com 'sudo bash <nome_do_script>.sh'"
fi

# --- Otimização e Atualização do Sistema ---

echo -e "${CYAN}\n===== OTIMIZANDO ZYPPER =====${NC}"
# Define o máximo de conexões simultâneas para downloads mais rápidos
# Usando 'sed' para adicionar ou modificar a linha de forma inteligente
sudo sed -i "s/^#\?download\.max_concurrent_connections.*/download.max_concurrent_connections = 5/; T; a download.max_concurrent_connections = 5" /etc/zypp/zypp.conf || handle_error "Falha ao otimizar zypper."
echo -e "${GREEN}Zypper otimizado para 5 conexões simultâneas.${NC}"

echo -e "${CYAN}\n===== ATUALIZANDO REPOSITÓRIOS =====${NC}"
# Atualiza todos os repositórios com o novo backend de download paralelo (ZYPP_CURL2)
sudo env ZYPP_PCK_PRELOAD=1 ZYPP_CURL2=1 zypper refresh || handle_error "Falha ao atualizar repositórios!"

echo -e "${CYAN}\n===== ATUALIZANDO O SISTEMA =====${NC}"
# Realiza uma atualização completa do sistema
sudo env ZYPP_PCK_PRELOAD=1 zypper dup -y || handle_error "Falha ao atualizar o sistema!"
echo -e "${GREEN}Sistema atualizado com sucesso.${NC}"

# --- Adiciona Repositório do Visual Studio Code e Instala ---

echo -e "${CYAN}\n===== ADICIONANDO REPOSITÓRIO E INSTALANDO VISUAL STUDIO CODE =====${NC}"
# Importa a chave GPG da Microsoft
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || handle_error "Falha ao importar chave GPG da Microsoft."

# Adiciona a configuração do repositório VS Code
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/zypp/repos.d/vscode.repo > /dev/null || handle_error "Falha ao configurar repositório do VS Code."

# Atualiza os repositórios após adicionar o repositório do VS Code
sudo env ZYPP_PCK_PRELOAD=1 zypper refresh || handle_error "Falha ao atualizar repositórios após adicionar VS Code!"

# Instala o Visual Studio Code
sudo env ZYPP_PCK_PRELOAD=1 zypper install -y code || handle_error "Falha ao instalar Visual Studio Code!"
echo -e "${GREEN}Visual Studio Code instalado com sucesso.${NC}"

# --- Opcional: Adiciona Repositório X11:COSMIC:Next ---

echo -e "${CYAN}\n===== ADICIONANDO REPOSITÓRIO X11:COSMIC:Next (OPCIONAL) =====${NC}"
read -r -p "$(echo -e "${YELLOW}Deseja adicionar o repositório X11:COSMIC:Next? (Pode ser útil para componentes relacionados, mas não essencial para Hyprland minimal) [s/N]: ${NC}")" add_cosmic_repo
if [[ ${add_cosmic_repo,,} =~ ^(s|sim)$ ]]; then
    sudo env ZYPP_PCK_PRELOAD=1 zypper addrepo --refresh https://download.opensuse.org/repositories/X11:COSMIC:Next/openSUSE_Factory/X11:COSMIC:Next.repo || handle_error "Falha ao adicionar repositório X11:COSMIC:Next!"
    sudo env ZYPP_PCK_PRELOAD=1 zypper refresh || handle_error "Falha ao atualizar repositórios após adicionar X11:COSMIC:Next!"
    echo -e "${GREEN}Repositório X11:COSMIC:Next adicionado e atualizado.${NC}"
else
    echo -e "${YELLOW}Repositório X11:COSMIC:Next não adicionado.${NC}"
fi

# --- Opcional: Instala Drivers NVIDIA ---

read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" nvidia
if [[ ${nvidia,,} =~ ^(s|sim)$ ]]; then
    echo -e "${CYAN}\n===== INSTALANDO DRIVERS NVIDIA =====${NC}"
    # Lista de pacotes de drivers NVIDIA
    NVIDIA_PACKAGES=(
        libnvidia-egl-gbm1
        libnvidia-egl-wayland1
        nvidia-common-G06
        nvidia-compute-G06
        nvidia-compute-utils-G06
        nvidia-driver-G06-kmp-default
        nvidia-gl-G06
        nvidia-libXNVCtrl
        nvidia-modprobe
        nvidia-persistenced
        nvidia-settings
        nvidia-video-G06
    )
    # Instala os pacotes NVIDIA
    sudo env ZYPP_PCK_PRELOAD=1 zypper install  "${NVIDIA_PACKAGES[@]}" || handle_error "Falha ao instalar drivers NVIDIA!"
    echo -e "${GREEN}Drivers NVIDIA instalados com sucesso.${NC}"

    echo -e "${CYAN}\n===== RECRIANDO INITRAMFS =====${NC}"
    # Recria o initramfs para garantir que os módulos NVIDIA sejam incluídos
    sudo dracut -f --regenerate-all || handle_error "Falha ao recriar initramfs!"
    echo -e "${GREEN}Initramfs recriado com sucesso.${NC}"
else
    echo -e "${YELLOW}Drivers NVIDIA não instalados.${NC}"
fi

# --- Instala Hyprland Minimal e Utilitários ---

echo -e "${CYAN}\n===== INSTALANDO HYPRLAND MINIMAL E UTILITÁRIOS =====${NC}"
# Lista de pacotes essenciais do Hyprland e utilitários
HYPRLAND_PACKAGES=(
    hyprland         # Pacote principal do Hyprland (já que hyprland-devel pode ser apenas a versão de desenvolvimento)
    fuzzel           # Lançador de aplicativos
    kitty            # Emulador de terminal
    git              # Sistema de controle de versão
    flatpak          # Sistema de pacotes universal
    fastfetch        # Ferramenta de informações do sistema
    swaybg           # Definidor de papel de parede para Wayland
    nwg-look         # Ferramenta de configuração de tema GTK
    nwg-displays     # Ferramenta de configuração de tela para Wayland
    pop-icon-theme   # Tema de ícones
    fish             # Shell interativo amigável
    zsh              # Z shell
)
sudo env ZYPP_PCK_PRELOAD=1 zypper install -y "${HYPRLAND_PACKAGES[@]}" || handle_error "Falha ao instalar Hyprland e utilitários!"
echo -e "${GREEN}Hyprland e utilitários instalados com sucesso.${NC}"

# Removido: Instalação do HyprPanel (conforme solicitado)

# --- Instala Nautilus (Gerenciador de Arquivos) ---

echo -e "${CYAN}\n===== INSTALANDO NAUTILUS (SEM RECOMENDAÇÕES) =====${NC}"
# Instala Nautilus sem pacotes recomendados para uma configuração mínima
sudo env ZYPP_PCK_PRELOAD=1 zypper install -y nautilus --no-recommends || handle_error "Falha ao instalar Nautilus!"
echo -e "${GREEN}Nautilus instalado com sucesso.${NC}"


# --- Instala Dependências do Waypaper e Waypaper via pipx ---

echo -e "${CYAN}\n===== INSTALANDO DEPENDÊNCIAS PARA WAYPAPER =====${NC}"
# Usando pacotes python3-devel genéricos onde possível para maior compatibilidade
WAYPAPER_DEPS=(
    python3-pycairo-devel
    python3-gobject-devel
    python3-pip
    python3-pipx
    python3-imageio
    python3-imageio-ffmpeg
    python3-screeninfo
    python3-platformdirs
)
sudo env ZYPP_PCK_PRELOAD=1 zypper install -y "${WAYPAPER_DEPS[@]}" || handle_error "Falha ao instalar dependências do Waypaper!"
echo -e "${GREEN}Dependências do Waypaper instaladas com sucesso.${NC}"

echo -e "${CYAN}\n===== INSTALANDO WAYPAPER VIA PIPX =====${NC}"
# Garante que o pipx esteja inicializado para o usuário atual
if ! pipx ensurepath; then
    echo -e "${YELLOW}Caminho do Pipx não configurado. Tentando configurar...${NC}"
    # Adiciona pipx ao PATH se ainda não estiver lá (para a sessão atual do shell)
    export PATH="$HOME/.local/bin:$PATH"
    pipx ensurepath || handle_error "Falha ao configurar o PATH do pipx. Verifique se o pipx está instalado corretamente."
fi

pipx install waypaper || handle_error "Falha ao instalar Waypaper via pipx!"
echo -e "${GREEN}Waypaper instalado com sucesso.${NC}"

# --- Configura Flatpak e Instala Aplicativos ---

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || handle_error "Falha ao adicionar repositório Flathub."
echo -e "${GREEN}Repositório Flathub adicionado.${NC}"

# Lista de aplicativos Flatpak
FLATPAK_APPS=(
    com.github.tchx84.Flatseal      # Gerenciador de permissões para aplicativos Flatpak
    app.zen_browser.zen             # Zen Browser
    dev.vencord.Vesktop             # Cliente Discord
    org.nickvision.tubeconverter    # Baixador de vídeos do YouTube
)
flatpak install -y flathub "${FLATPAK_APPS[@]}" || handle_error "Falha ao instalar aplicativos Flatpak!"
echo -e "${GREEN}Aplicativos Flatpak instalados com sucesso.${NC}"

# --- Mensagem Final ---

echo -e "${GREEN}\n✅ Instalação concluída!${NC}"
echo -e "${YELLOW}Por favor, reinicie o sistema para aplicar todas as alterações e usar o Hyprland.${NC}"
echo -e "${YELLOW}Após reiniciar, selecione 'Hyprland' na tela de login (seu gerenciador de exibição).${NC}"
