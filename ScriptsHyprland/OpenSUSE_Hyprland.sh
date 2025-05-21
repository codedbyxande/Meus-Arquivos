#!/bin/bash
# Hyprland Minimal Installation Script for openSUSE

# This script automates the minimal installation of Hyprland,
# along with essential utilities and applications, on openSUSE.
# It includes options for NVIDIA drivers and the COSMIC repository.

# Colors for the terminal output
GREEN='\033[1;32m' # Success messages
CYAN='\033[1;36m'  # Section headers
YELLOW='\033[1;33m' # Warnings and prompts
RED='\033[1;31m'   # Error messages
NC='\033[0m'      # No Color - Resets text color

# --- Script Configuration and Error Handling ---

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# The return value of a pipeline is the status of the last command to exit with a non-zero status,
# or zero if all commands in the pipeline exit successfully.
set -o pipefail

# Function to display error messages and exit
handle_error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}Este script precisa ser executado com privilégios de root (sudo).${NC}"
    handle_error "Execute o script com 'sudo bash <nome_do_script>.sh'"
fi

# --- System Optimization and Update ---

echo -e "${CYAN}\n===== OTIMIZANDO ZYPPER =====${NC}"
# Set maximum concurrent connections for faster downloads
# Using 'grep -q' to check if the line exists before adding/modifying
if grep -q "^download\.max_concurrent_connections" /etc/zypp/zypp.conf; then
    sudo sed -i "s/^download\.max_concurrent_connections.*/download.max_concurrent_connections = 5/" /etc/zypp/zypp.conf || handle_error "Falha ao otimizar zypper (sed)."
else
    echo "download.max_concurrent_connections = 5" | sudo tee -a /etc/zypp/zypp.conf > /dev/null || handle_error "Falha ao otimizar zypper (tee)."
fi
echo -e "${GREEN}Zypper otimizado para 5 conexões simultâneas.${NC}"

echo -e "${CYAN}\n===== ATUALIZANDO REPOSITÓRIOS =====${NC}"
# Refresh all repositories
sudo zypper refresh || handle_error "Falha ao atualizar repositórios!"

echo -e "${CYAN}\n===== ATUALIZANDO O SISTEMA =====${NC}"
# Perform a full system upgrade
sudo zypper dup -y || handle_error "Falha ao atualizar o sistema!"
echo -e "${GREEN}Sistema atualizado com sucesso.${NC}"

# --- Add Visual Studio Code Repository and Install ---

echo -e "${CYAN}\n===== ADICIONANDO REPOSITÓRIO E INSTALANDO VISUAL STUDIO CODE =====${NC}"
# Import Microsoft GPG key
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || handle_error "Falha ao importar chave GPG da Microsoft."

# Add VS Code repository configuration
echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/zypp/repos.d/vscode.repo > /dev/null || handle_error "Falha ao configurar repositório do VS Code."

# Refresh repositories after adding VS Code repo
sudo zypper refresh || handle_error "Falha ao atualizar repositórios após adicionar VS Code!"

# Install Visual Studio Code
sudo zypper install -y code || handle_error "Falha ao instalar Visual Studio Code!"
echo -e "${GREEN}Visual Studio Code instalado com sucesso.${NC}"

# --- Optional: Add X11:COSMIC:Next Repository ---

echo -e "${CYAN}\n===== ADICIONANDO REPOSITÓRIO X11:COSMIC:Next (OPCIONAL) =====${NC}"
read -r -p "$(echo -e "${YELLOW}Deseja adicionar o repositório X11:COSMIC:Next? (Pode ser útil para componentes relacionados, mas não essencial para Hyprland minimal) [s/N]: ${NC}")" add_cosmic_repo
if [[ ${add_cosmic_repo,,} =~ ^(s|sim)$ ]]; then
    sudo zypper addrepo --refresh https://download.opensuse.org/repositories/X11:COSMIC:Next/openSUSE_Factory/X11:COSMIC:Next.repo || handle_error "Falha ao adicionar repositório X11:COSMIC:Next!"
    sudo zypper refresh || handle_error "Falha ao atualizar repositórios após adicionar X11:COSMIC:Next!"
    echo -e "${GREEN}Repositório X11:COSMIC:Next adicionado e atualizado.${NC}"
else
    echo -e "${YELLOW}Repositório X11:COSMIC:Next não adicionado.${NC}"
fi

# --- Optional: Install NVIDIA Drivers ---

read -r -p "$(echo -e "${YELLOW}Instalar drivers NVIDIA? [s/N]: ${NC}")" nvidia
if [[ ${nvidia,,} =~ ^(s|sim)$ ]]; then
    echo -e "${CYAN}\n===== INSTALANDO DRIVERS NVIDIA =====${NC}"
    # List of NVIDIA driver packages
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
    # Install NVIDIA packages
    sudo zypper install -y "${NVIDIA_PACKAGES[@]}" || handle_error "Falha ao instalar drivers NVIDIA!"
    echo -e "${GREEN}Drivers NVIDIA instalados com sucesso.${NC}"

    echo -e "${CYAN}\n===== RECRIANDO INITRAMFS =====${NC}"
    # Recreate initramfs to ensure NVIDIA modules are included
    sudo dracut -f --regenerate-all || handle_error "Falha ao recriar initramfs!"
    echo -e "${GREEN}Initramfs recriado com sucesso.${NC}"
else
    echo -e "${YELLOW}Drivers NVIDIA não instalados.${NC}"
fi

# --- Install Hyprland Minimal and Utilities ---

echo -e "${CYAN}\n===== INSTALANDO HYPRLAND MINIMAL E UTILITÁRIOS =====${NC}"
# List of essential Hyprland packages and utilities
HYPRLAND_PACKAGES=(
    hyprland-devel # Main Hyprland Wayland compositor
    fuzzel         # Application launcher
    kitty          # Terminal emulator
    git            # Version control system
    flatpak        # Universal package system
    fastfetch      # System information tool
    swaybg         # Wayland wallpaper setter
    nwg-look       # GTK theme configuration tool
    nwg-displays   # Display configuration tool for Wayland
    pop-icon-theme # Icon theme
    fish           # Friendly interactive shell
    zsh            # Z shell
)
sudo zypper install -y "${HYPRLAND_PACKAGES[@]}" || handle_error "Falha ao instalar Hyprland e utilitários!"
echo -e "${GREEN}Hyprland e utilitários instalados com sucesso.${NC}"

# --- Install HyprPanel (Dashboard) ---

echo -e "${CYAN}\n===== INSTALANDO HYPRPANEL (DASHBOARD) =====${NC}"
HYPRPANEL_DIR="/tmp/HyprPanel"
if [ -d "$HYPRPANEL_DIR" ]; then
    echo -e "${YELLOW}Diretório $HYPRPANEL_DIR já existe. Removendo...${NC}"
    rm -rf "$HYPRPANEL_DIR" || handle_error "Falha ao remover diretório existente de HyprPanel."
fi

git clone https://github.com/Jas-SinghFSU/HyprPanel.git "$HYPRPANEL_DIR" || handle_error "Falha ao clonar repositório HyprPanel."
cd "$HYPRPANEL_DIR" || handle_error "Falha ao entrar no diretório HyprPanel."

# Check if meson is installed
if ! command -v meson &> /dev/null; then
    echo -e "${YELLOW}Meson não encontrado. Instalando...${NC}"
    sudo zypper install -y meson || handle_error "Falha ao instalar meson."
fi

meson setup build || handle_error "Falha ao configurar build do HyprPanel com meson."
meson compile -C build || handle_error "Falha ao compilar HyprPanel."
sudo meson install -C build || handle_error "Falha ao instalar HyprPanel."
cd ~ || handle_error "Falha ao retornar ao diretório home."
rm -rf "$HYPRPANEL_DIR" || handle_error "Falha ao limpar arquivos temporários do HyprPanel."
echo -e "${GREEN}HyprPanel instalado com sucesso.${NC}"

# --- Install Nautilus (File Manager) ---

echo -e "${CYAN}\n===== INSTALANDO NAUTILUS (SEM RECOMENDAÇÕES) =====${NC}"
# Install Nautilus without recommended packages for a minimal setup
sudo zypper install -y nautilus --no-recommends || handle_error "Falha ao instalar Nautilus!"
echo -e "${GREEN}Nautilus instalado com sucesso.${NC}"

# --- Install Waypaper Dependencies and Waypaper via pipx ---

echo -e "${CYAN}\n===== INSTALANDO DEPENDÊNCIAS PARA WAYPAPER =====${NC}"
# Using generic python3-devel packages where possible for broader compatibility
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
sudo zypper install -y "${WAYPAPER_DEPS[@]}" || handle_error "Falha ao instalar dependências do Waypaper!"
echo -e "${GREEN}Dependências do Waypaper instaladas com sucesso.${NC}"

echo -e "${CYAN}\n===== INSTALANDO WAYPAPER VIA PIPX =====${NC}"
# Ensure pipx is initialized for the current user
if ! pipx ensurepath; then
    echo -e "${YELLOW}Pipx path não configurado. Tentando configurar...${NC}"
    # Add pipx to PATH if not already there (for the current shell session)
    export PATH="$HOME/.local/bin:$PATH"
    pipx ensurepath || handle_error "Falha ao configurar o PATH do pipx. Verifique se o pipx está instalado corretamente."
fi

pipx install waypaper || handle_error "Falha ao instalar Waypaper via pipx!"
echo -e "${GREEN}Waypaper instalado com sucesso.${NC}"

# --- Configure Flatpak and Install Apps ---

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || handle_error "Falha ao adicionar repositório Flathub."
echo -e "${GREEN}Repositório Flathub adicionado.${NC}"

# List of Flatpak applications
FLATPAK_APPS=(
    com.github.tchx84.Flatseal      # Permissions manager for Flatpak apps
    app.zen_browser.zen             # Zen Browser
    dev.vencord.Vesktop             # Discord client
    org.nickvision.tubeconverter    # YouTube video downloader
)
flatpak install -y flathub "${FLATPAK_APPS[@]}" || handle_error "Falha ao instalar aplicativos Flatpak!"
echo -e "${GREEN}Aplicativos Flatpak instalados com sucesso.${NC}"

# --- Final Message ---

echo -e "${GREEN}\n✅ Instalação concluída!${NC}"
echo -e "${YELLOW}Por favor, reinicie o sistema para aplicar todas as alterações e usar o Hyprland.${NC}"
echo -e "${YELLOW}Após reiniciar, selecione 'Hyprland' na tela de login (seu gerenciador de exibição).${NC}"
