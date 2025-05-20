#!/bin/bash

# =============================================================================
# Script para Criar a Estrutura e Arquivos do Instalador de Desktop Minimalista
#
# Este script cria a hierarquia de diretórios e preenche cada arquivo .sh
# com o conteúdo fornecido, garantindo a estrutura correta para o instalador.
# =============================================================================

# Cores para o terminal (usadas apenas por este script criador)
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Funções de log para ESTE SCRIPT CRIADOR
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCESSO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERRO]${NC} $1"
    exit 1
}

log_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Diretório principal onde a estrutura será criada
INSTALLER_DIR="my_desktop_installer"

# Verifica se o diretório já existe para evitar sobrescrita acidental
if [ -d "$INSTALLER_DIR" ]; then
    log_warning "O diretório '$INSTALLER_DIR' já existe."
    read -r -p "$(echo -e "${YELLOW}Deseja remover o diretório existente e recriá-lo? (s/N): ${NC}")" confirm_remove
    if [[ ${confirm_remove,,} =~ ^(s|sim)$ ]]; then
        log_info "Removendo diretório existente..."
        rm -rf "$INSTALLER_DIR" || log_error "Falha ao remover o diretório existente."
    else
        log_error "Operação cancelada pelo usuário. Não foi possível prosseguir com a criação da estrutura."
    fi
fi

log_info "Criando estrutura de diretórios para o instalador..."
mkdir -p "$INSTALLER_DIR/common" || log_error "Falha ao criar diretório 'common'."
mkdir -p "$INSTALLER_DIR/modules" || log_error "Falha ao criar diretório 'modules'."
chmod 755 "$INSTALLER_DIR" "$INSTALLER_DIR/common" "$INSTALLER_DIR/modules" || log_error "Falha ao definir permissões."
log_success "Estrutura de diretórios criada com sucesso."

# =============================================================================
# CONTEÚDO DOS ARQUIVOS SH
# =============================================================================

# common/common_functions.sh
# =============================================================================
log_info "Criando common/common_functions.sh..."
cat << 'EOF_COMMON_FUNCTIONS_SH' > "$INSTALLER_DIR/common/common_functions.sh"
#!/bin/bash

# Cores para o terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Variáveis globais para pacotes comuns
COMMON_PACKAGES_CORE="htop neofetch fastfetch git curl wget nano vim locales bash-completion man-db"
COMMON_PACKAGES_DESKTOP="fonts-recommended qt5-gtk2-plugin qt5ct kvantum-qt5" # Ajuste conforme necessário

# Função para exibir mensagens com formatação
log_msg() {
    local type=$1
    local msg=$2
    local date_str=$(date '+%H:%M:%S')

    case $type in
        "info")     echo -e "[${BLUE}INFO${NC}] ${date_str} - ${msg}" ;;\
        "success")  echo -e "[${GREEN}OK${NC}] ${date_str} - ${msg}" ;;\
        "warning")  echo -e "[${YELLOW}AVISO${NC}] ${date_str} - ${msg}" ;;\
        "error")    echo -e "[${RED}ERRO${NC}] ${date_str} - ${msg}" ;;\
        "step")     echo -e "\n${CYAN}${BOLD}=== $msg ===${NC}" ;;\
    esac
}

# Função para verificar se o script está sendo executado como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_msg "error" "Este script precisa ser executado como root. Use 'sudo ./$(basename "$0")'."
        exit 1
    fi
}

# Função para configurar Flatpak e instalar aplicativos comuns
setup_flatpak_common() {
    local desktop_env=$1 # 'kde' ou 'gnome'
    log_msg "step" "Configurando Flatpak e instalando aplicativos essenciais"

    log_msg "info" "Adicionando repositório Flathub..."
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || { log_msg "error" "Falha ao adicionar Flathub."; return 1; }

    log_msg "info" "Instalando aplicativos Flatpak..."
    FLATPAK_APPS=""

    case "$desktop_env" in
        "gnome")
            FLATPAK_APPS="com.github.tchx84.Flatseal com.mattjakeman.ExtensionManager app.zen_browser.zen dev.vencord.Vesktop org.nickvision.tubeconverter"
            ;;
        "kde")
            FLATPAK_APPS="app.zen_browser.zen dev.vencord.Vesktop org.nickvision.tubeconverter"
            ;;
        *)
            log_msg "warning" "Ambiente de desktop '$desktop_env' não reconhecido para seleção de Flatpaks específicos. Instalando apenas os comuns."
            FLATPAK_APPS="app.zen_browser.zen dev.vencord.Vesktop org.nickvision.tubeconverter"
            ;;
    esac

    if [ -n "$FLATPAK_APPS" ]; then
        flatpak install -y flathub $FLATPAK_APPS || log_msg "warning" "Falha ao instalar alguns aplicativos Flatpak. Pode tentar novamente manualmente."
    else
        log_msg "info" "Nenhum Flatpak específico para o ambiente '$desktop_env' definido para instalação automática."
    fi

    log_msg "success" "Flatpak configurado e aplicativos instalados (se disponíveis)."
}

# Função para finalizar a instalação (mensagens genéricas)
finalize_installation() {
    log_msg "step" "Finalizando a instalação"
    log_msg "success" "Instalação da base do sistema e ambiente de desktop concluída!"
}

# Função para mostrar informações finais
show_final_info() {
    log_msg "info" "Por favor, reinicie o sistema para aplicar todas as alterações."
    log_msg "info" "Após reiniciar, na tela de login, selecione o ambiente 'Plasma' ou 'GNOME' (conforme sua escolha)."
    log_msg "info" "Você pode reiniciar agora executando: sudo reboot"
    echo ""
}
EOF_COMMON_FUNCTIONS_SH
chmod +x "$INSTALLER_DIR/common/common_functions.sh" || log_error "Falha ao dar permissão de execução a common_functions.sh"
log_success "common/common_functions.sh criado."

# main.sh
# =============================================================================
log_info "Criando main.sh..."
cat << 'EOF_MAIN_SH' > "$INSTALLER_DIR/main.sh"
#!/bin/bash
# =============================================================================
# My Desktop Installer - Script Principal
# =============================================================================

# Carrega as funções comuns
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/common/common_functions.sh"

# Configurações globais
set -e # Encerra o script se qualquer comando falhar
SCRIPT_VERSION="1.0.0"

# Menu principal
main_menu() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "============================================================="
    echo "          MY DESKTOP INSTALLER v${SCRIPT_VERSION}"
    echo "============================================================="
    echo -e "${NC}"
    echo "Escolha a distribuição e o ambiente de desktop para instalar:"
    echo ""
    echo "  Debian / Ubuntu:"
    echo "    1) Debian Sid - KDE Plasma Ultra-Minimal"
    echo "    2) Debian Sid - GNOME Minimal"
    echo ""
    echo "  Fedora:"
    echo "    3) Fedora - KDE Plasma Minimal"
    echo "    4) Fedora - GNOME Minimal"
    echo ""
    echo "  openSUSE:"
    echo "    5) openSUSE Tumbleweed - KDE Plasma Minimal"
    echo ""
    echo "  Arch Linux / Derivados (Ex: EndeavourOS, ArcoLinux):"
    echo "    6) Arch Linux - KDE Plasma Minimal"
    echo "    7) Arch Linux - GNOME Minimal"
    echo ""
    echo "  Outros:"
    echo "    8) siduction - KDE Plasma Minimal"
    echo "    0) Sair"
    echo ""

    read -r -p "Digite sua escolha: " choice
    echo ""

    case "$choice" in
        1) "$SCRIPT_DIR/modules/debian_sid_kde_minimal.sh" ;;
        2) "$SCRIPT_DIR/modules/debian_sid_gnome_minimal.sh" ;;
        3) "$SCRIPT_DIR/modules/fedora_kde_minimal.sh" ;;
        4) "$SCRIPT_DIR/modules/fedora_gnome_minimal.sh" ;;
        5) "$SCRIPT_DIR/modules/opensuse_kde_minimal.sh" ;;
        6) "$SCRIPT_DIR/modules/arch_kde_minimal.sh" ;;
        7) "$SCRIPT_DIR/modules/arch_gnome_minimal.sh" ;;
        8) "$SCRIPT_DIR/modules/siduction_kde_minimal.sh" ;;
        0) log_msg "info" "Saindo do instalador. Até mais!" ; exit 0 ;;
        *) log_msg "error" "Opção inválida. Por favor, tente novamente." ; sleep 2 ; main_menu ;;
    esac
}

# Inicia o menu
main_menu
EOF_MAIN_SH
chmod +x "$INSTALLER_DIR/main.sh" || log_error "Falha ao dar permissão de execução a main.sh"
log_success "main.sh criado."

# modules/debian_sid_kde_minimal.sh
# =============================================================================
log_info "Criando modules/debian_sid_kde_minimal.sh..."
cat << 'EOF_DEBIAN_KDE_MINIMAL_SH' > "$INSTALLER_DIR/modules/debian_sid_kde_minimal.sh"
#!/bin/bash
# =============================================================================
# Debian Sid KDE Plasma Ultra-Minimal - Instalação com suporte NVIDIA
# =============================================================================

# Carrega as funções comuns
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../common/common_functions.sh"

# Configurações
set -e # Encerra o script se qualquer comando falhar
SCRIPT_VERSION="1.0.0"

# Funções de instalação
check_system() {
    log_msg "step" "Verificando o sistema"
    check_root
    if ! grep -q "sid" /etc/apt/sources.list; then
        log_msg "error" "Este script é para Debian Sid. Seu sources.list não aponta para 'sid'."
        exit 1
    fi
    log_msg "success" "Sistema verificado: Debian Sid."
}

setup_repositories() {
    log_msg "step" "Configurando repositórios"
    log_msg "info" "Fazendo backup de /etc/apt/sources.list..."
    sudo cp /etc/apt/sources.list{,.bak} || log_msg "warning" "Falha ao fazer backup de sources.list."

    log_msg "info" "Ajustando sources.list para Debian Sid (main, contrib, non-free, non-free-firmware)..."
    sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://deb.debian.org/debian sid main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian sid main contrib non-free non-free-firmware
EOF
    log_msg "success" "Repositórios configurados."
}

update_system() {
    log_msg "step" "Atualizando o sistema"
    log_msg "info" "Atualizando lista de pacotes..."
    sudo apt update || log_msg "error" "Falha ao atualizar a lista de pacotes."
    log_msg "info" "Executando full-upgrade..."
    sudo apt full-upgrade -y || log_msg "error" "Falha ao realizar full-upgrade."
    log_msg "success" "Sistema atualizado."
}

install_kde_minimal() {
    log_msg "step" "Instalando KDE Plasma Ultra-Minimal e SDDM"
    local KDE_PACKAGES="plasma-desktop sddm dolphin kate dolphin-plugins kitty ark git flatpak"
    log_msg "info" "Instalando pacotes do KDE: $KDE_PACKAGES"
    sudo apt install -y $KDE_PACKAGES || log_msg "error" "Falha ao instalar KDE Plasma Minimal."

    log_msg "info" "Reconfigurando SDDM como padrão..."
    sudo dpkg-reconfigure sddm || log_msg "warning" "Falha ao reconfigurar SDDM. Pode precisar de ativação manual."
    log_msg "success" "KDE Plasma Ultra-Minimal e SDDM instalados."
}

install_nvidia_drivers() {
    log_msg "step" "Instalando drivers NVIDIA (Opcional)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar drivers NVIDIA? [S/n]: ${NC}")" nvidia_choice
    if [[ -z "$nvidia_choice" || ${nvidia_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando drivers NVIDIA e suporte Wayland..."
        sudo apt install -y \
            nvidia-driver \
            libnvidia-egl-wayland1 \
            firmware-misc-nonfree \
            nvidia-settings \
            nvidia-xconfig \
            || log_msg "warning" "Falha ao instalar drivers NVIDIA. Verifique a compatibilidade."

        log_msg "info" "(Opcional) Gerando novo xorg.conf..."
        sudo nvidia-xconfig || log_msg "warning" "Falha ao gerar xorg.conf. Pode precisar de configuração manual."

        log_msg "success" "Drivers NVIDIA com suporte Wayland instalados."
    else
        log_msg "info" "Instalação de drivers NVIDIA ignorada."
    fi
}

# Menu principal de instalação
run_installation() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "=============================================================="
    echo "     DEBIAN SID KDE ULTRA-MINIMAL - INSTALAÇÃO v${SCRIPT_VERSION}"
    echo "=============================================================="
    echo -e "${NC}"
    echo "Este script irá instalar uma versão ultra-minimalista do KDE Plasma"
    echo "com suporte opcional a drivers NVIDIA no Debian Sid."
    echo ""
    echo -e "${YELLOW}O script realizará as seguintes operações:${NC}"
    echo "  1. Verificar sistema (Debian Sid)"
    echo "  2. Configurar repositórios"
    echo "  3. Atualizar o sistema"
    echo "  4. Instalar KDE Plasma (versão ultra-minimalista)"
    echo "  5. Instalar drivers NVIDIA (opcional)"
    echo "  6. Configurar Flatpak e instalar aplicativos"
    echo ""

    read -r -p "Deseja prosseguir com a instalação? [S/n]: " choice
    if [[ -z "$choice" || ${choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        check_system
        setup_repositories
        update_system
        install_kde_minimal
        install_nvidia_drivers
        setup_flatpak_common "kde" # Passa "kde" para a função de configuração do Flatpak
        finalize_installation
        show_final_info
    else
        log_msg "info" "Instalação cancelada pelo usuário."
        exit 0
    fi
}

# Executa a instalação
run_installation
EOF_DEBIAN_KDE_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/debian_sid_kde_minimal.sh" || log_error "Falha ao dar permissão de execução a debian_sid_kde_minimal.sh"
log_success "modules/debian_sid_kde_minimal.sh criado."

# modules/debian_sid_gnome_minimal.sh
# =============================================================================
log_info "Criando modules/debian_sid_gnome_minimal.sh..."
cat << 'EOF_DEBIAN_GNOME_MINIMAL_SH' > "$INSTALLER_DIR/modules/debian_sid_gnome_minimal.sh"
#!/bin/bash
# =============================================================================
# Debian Sid GNOME Minimal - Instalação com suporte NVIDIA
# =============================================================================

# Carrega as funções comuns
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../common/common_functions.sh"

# Configurações
set -e # Encerra o script se qualquer comando falhar
SCRIPT_VERSION="1.0.0"

# Funções de instalação
check_system() {
    log_msg "step" "Verificando o sistema"
    check_root
    if ! grep -q "sid" /etc/apt/sources.list; then
        log_msg "error" "Este script é para Debian Sid. Seu sources.list não aponta para 'sid'."
        exit 1
    fi
    log_msg "success" "Sistema verificado: Debian Sid."
}

setup_repositories() {
    log_msg "step" "Configurando repositórios"
    log_msg "info" "Fazendo backup de /etc/apt/sources.list..."
    sudo cp /etc/apt/sources.list{,.bak} || log_msg "warning" "Falha ao fazer backup de sources.list."

    log_msg "info" "Ajustando sources.list para Debian Sid (main, contrib, non-free, non-free-firmware)..."
    sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://deb.debian.org/debian sid main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian sid main contrib non-free non-free-firmware
EOF
    log_msg "success" "Repositórios configurados."
}

update_system() {
    log_msg "step" "Atualizando o sistema"
    log_msg "info" "Atualizando lista de pacotes..."
    sudo apt update || log_msg "error" "Falha ao atualizar a lista de pacotes."
    log_msg "info" "Executando full-upgrade..."
    sudo apt full-upgrade -y || log_msg "error" "Falha ao realizar full-upgrade."
    log_msg "success" "Sistema atualizado."
}

install_gnome_minimal() {
    log_msg "step" "Instalando GNOME Minimal e GDM"
    local GNOME_PACKAGES="gnome-shell gdm nautilus kitty git flatpak"
    log_msg "info" "Instalando pacotes do GNOME: $GNOME_PACKAGES"
    sudo apt install -y $GNOME_PACKAGES || log_msg "error" "Falha ao instalar GNOME Minimal."

    log_msg "info" "Reconfigurando GDM como padrão..."
    sudo dpkg-reconfigure gdm || log_msg "warning" "Falha ao reconfigurar GDM. Pode precisar de ativação manual."
    log_msg "success" "GNOME Minimal e GDM instalados."
}

install_nvidia_drivers() {
    log_msg "step" "Instalando drivers NVIDIA (Opcional)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar drivers NVIDIA? [S/n]: ${NC}")" nvidia_choice
    if [[ -z "$nvidia_choice" || ${nvidia_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando drivers NVIDIA e suporte Wayland..."
        sudo apt install -y \
            nvidia-driver \
            libnvidia-egl-wayland1 \
            firmware-misc-nonfree \
            nvidia-settings \
            nvidia-xconfig \
            || log_msg "warning" "Falha ao instalar drivers NVIDIA. Verifique a compatibilidade."

        log_msg "info" "(Opcional) Gerando novo xorg.conf..."
        sudo nvidia-xconfig || log_msg "warning" "Falha ao gerar xorg.conf. Pode precisar de configuração manual."

        log_msg "success" "Drivers NVIDIA com suporte Wayland instalados."
    else
        log_msg "info" "Instalação de drivers NVIDIA ignorada."
    fi
}

# Menu principal de instalação
run_installation() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "=============================================================="
    echo "     DEBIAN SID GNOME MINIMAL - INSTALAÇÃO v${SCRIPT_VERSION}"
    echo "=============================================================="
    echo -e "${NC}"
    echo "Este script irá instalar uma versão minimalista do GNOME"
    echo "com suporte opcional a drivers NVIDIA no Debian Sid."
    echo ""
    echo -e "${YELLOW}O script realizará as seguintes operações:${NC}"
    echo "  1. Verificar sistema (Debian Sid)"
    echo "  2. Configurar repositórios"
    echo "  3. Atualizar o sistema"
    echo "  4. Instalar GNOME Minimal"
    echo "  5. Instalar drivers NVIDIA (opcional)"
    echo "  6. Configurar Flatpak e instalar aplicativos"
    echo ""

    read -r -p "Deseja prosseguir com a instalação? [S/n]: " choice
    if [[ -z "$choice" || ${choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        check_system
        setup_repositories
        update_system
        install_gnome_minimal
        install_nvidia_drivers
        setup_flatpak_common "gnome" # Passa "gnome" para a função de configuração do Flatpak
        finalize_installation
        show_final_info
    else
        log_msg "info" "Instalação cancelada pelo usuário."
        exit 0
    fi
}

# Executa a instalação
run_installation
EOF_DEBIAN_GNOME_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/debian_sid_gnome_minimal.sh" || log_error "Falha ao dar permissão de execução a debian_sid_gnome_minimal.sh"
log_success "modules/debian_sid_gnome_minimal.sh criado."


# modules/fedora_kde_minimal.sh
# =============================================================================
log_info "Criando modules/fedora_kde_minimal.sh..."
cat << 'EOF_FEDORA_KDE_MINIMAL_SH' > "$INSTALLER_DIR/modules/fedora_kde_minimal.sh"
#!/bin/bash
# =============================================================================
# Fedora KDE Minimal - Instalação minimalista do KDE Plasma com suporte NVIDIA
# =============================================================================

# Carrega as funções comuns
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../common/common_functions.sh"

# Configurações
set -e # Encerra o script se qualquer comando falhar
SCRIPT_VERSION="1.0.0"

# Funções de instalação
check_system() {
    log_msg "step" "Verificando o sistema"
    check_root
    if ! grep -q "Fedora" /etc/os-release; then
        log_msg "error" "Este script é para Fedora. Sistema não detectado como Fedora."
        exit 1
    fi
    log_msg "success" "Sistema verificado: Fedora."
}

optimize_dnf() {
    log_msg "step" "Otimizando DNF"
    log_msg "info" "Configurando downloads paralelos e espelho mais rápido..."
    echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
    echo 'fastestmirror=true' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
    log_msg "success" "DNF otimizado."
}

setup_repositories() {
    log_msg "step" "Configurando repositórios RPM Fusion"
    log_msg "info" "Instalando repositórios RPM Fusion Free e Non-free..."
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
        || log_msg "error" "Falha ao instalar repositórios RPM Fusion."
    log_msg "success" "Repositórios RPM Fusion configurados."
}

update_system() {
    log_msg "step" "Atualizando o sistema"
    log_msg "info" "Atualizando pacotes DNF..."
    sudo dnf upgrade --refresh -y || log_msg "error" "Falha ao atualizar o sistema."
    log_msg "success" "Sistema atualizado."
}

install_nvidia_drivers() {
    log_msg "step" "Instalando drivers NVIDIA (Opcional)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar drivers NVIDIA? [S/n]: ${NC}")" nvidia_choice
    if [[ -z "$nvidia_choice" || ${nvidia_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando akmod-nvidia e xorg-x11-drv-nvidia-cuda..."
        sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda || log_msg "error" "Falha ao instalar drivers NVIDIA."
        log_msg "info" "Regenerando initramfs..."
        sudo dracut -f --regenerate-all || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
        log_msg "success" "Drivers NVIDIA com suporte Wayland instalados."
    else
        log_msg "info" "Instalação de drivers NVIDIA ignorada."
    fi
}

install_kde_minimal() {
    log_msg "step" "Instalando KDE Plasma Minimal e SDDM"
    local KDE_PACKAGES="plasma-desktop sddm dolphin ark kitty git flatpak"
    log_msg "info" "Instalando pacotes do KDE: $KDE_PACKAGES"
    sudo dnf install -y $KDE_PACKAGES || log_msg "error" "Falha ao instalar KDE Plasma Minimal."

    log_msg "info" "Habilitando SDDM..."
    sudo systemctl enable sddm || log_msg "warning" "Falha ao habilitar SDDM. Pode precisar de ativação manual."
    log_msg "success" "KDE Plasma Minimal e SDDM instalados."
}

install_base_utilities() {
    log_msg "step" "Instalando utilitários básicos"
    log_msg "info" "Instalando pacotes comuns: $COMMON_PACKAGES_CORE"
    sudo dnf install -y $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns utilitários básicos."
    log_msg "success" "Utilitários básicos instalados."
}

# Menu principal de instalação
run_installation() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "============================================================"
    echo "          FEDORA KDE MINIMAL - INSTALAÇÃO v${SCRIPT_VERSION}"
    echo "============================================================"
    echo -e "${NC}"
    echo "Este script irá instalar uma versão minimalista do KDE Plasma"
    echo "com suporte opcional a drivers NVIDIA no Fedora."
    echo ""
    echo -e "${YELLOW}O script realizará as seguintes operações:${NC}"
    echo "  1. Otimizar configurações do DNF"
    echo "  2. Atualizar o sistema"
    echo "  3. Configurar repositórios adicionais (RPM Fusion)"
    echo "  4. Instalar drivers NVIDIA (opcional)"
    echo "  5. Instalar KDE Plasma (versão minimalista)"
    echo "  6. Instalar utilitários básicos"
    echo "  7. Configurar Flatpak e instalar aplicativos"
    echo ""

    read -r -p "Deseja prosseguir com a instalação? [S/n]: " choice
    if [[ -z "$choice" || ${choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        check_system
        optimize_dnf
        setup_repositories
        update_system
        install_nvidia_drivers
        install_kde_minimal
        install_base_utilities
        setup_flatpak_common "kde" # Passa "kde" para a função de configuração do Flatpak
        finalize_installation
        show_final_info
    else
        log_msg "info" "Instalação cancelada pelo usuário."
        exit 0
    fi
}

# Executa a instalação
run_installation
EOF_FEDORA_KDE_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/fedora_kde_minimal.sh" || log_error "Falha ao dar permissão de execução a fedora_kde_minimal.sh"
log_success "modules/fedora_kde_minimal.sh criado."

# modules/fedora_gnome_minimal.sh
# =============================================================================
log_info "Criando modules/fedora_gnome_minimal.sh..."
cat << 'EOF_FEDORA_GNOME_MINIMAL_SH' > "$INSTALLER_DIR/modules/fedora_gnome_minimal.sh"
#!/bin/bash
# =============================================================================
# Fedora GNOME Minimal - Instalação minimalista do GNOME com suporte NVIDIA
# =============================================================================

# Carrega as funções comuns
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../common/common_functions.sh"

# Configurações
set -e # Encerra o script se qualquer comando falhar
SCRIPT_VERSION="1.0.0"

# Funções de instalação
check_system() {
    log_msg "step" "Verificando o sistema"
    check_root
    if ! grep -q "Fedora" /etc/os-release; then
        log_msg "error" "Este script é para Fedora. Sistema não detectado como Fedora."
        exit 1
    fi
    log_msg "success" "Sistema verificado: Fedora."
}

optimize_dnf() {
    log_msg "step" "Otimizando DNF"
    log_msg "info" "Configurando downloads paralelos e espelho mais rápido..."
    echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
    echo 'fastestmirror=true' | sudo tee -a /etc/dnf/dnf.conf > /dev/null
    log_msg "success" "DNF otimizado."
}

setup_repositories() {
    log_msg "step" "Configurando repositórios RPM Fusion"
    log_msg "info" "Instalando repositórios RPM Fusion Free e Non-free..."
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
        || log_msg "error" "Falha ao instalar repositórios RPM Fusion."
    log_msg "success" "Repositórios RPM Fusion configurados."
}

update_system() {
    log_msg "step" "Atualizando o sistema"
    log_msg "info" "Atualizando pacotes DNF..."
    sudo dnf upgrade --refresh -y || log_msg "error" "Falha ao atualizar o sistema."
    log_msg "success" "Sistema atualizado."
}

install_nvidia_drivers() {
    log_msg "step" "Instalando drivers NVIDIA (Opcional)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar drivers NVIDIA? [S/n]: ${NC}")" nvidia_choice
    if [[ -z "$nvidia_choice" || ${nvidia_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando akmod-nvidia e xorg-x11-drv-nvidia-cuda..."
        sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda || log_msg "error" "Falha ao instalar drivers NVIDIA."
        log_msg "info" "Regenerando initramfs..."
        sudo dracut -f --regenerate-all || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
        log_msg "success" "Drivers NVIDIA com suporte Wayland instalados."
    else
        log_msg "info" "Instalação de drivers NVIDIA ignorada."
    fi
}

install_gnome_minimal() {
    log_msg "step" "Instalando GNOME Minimal e GDM"
    local GNOME_PACKAGES="gnome-shell gdm nautilus kitty git flatpak"
    log_msg "info" "Instalando pacotes do GNOME: $GNOME_PACKAGES"
    sudo dnf install -y $GNOME_PACKAGES || log_msg "error" "Falha ao instalar GNOME Minimal."

    log_msg "info" "Habilitando GDM..."
    sudo systemctl enable gdm || log_msg "warning" "Falha ao habilitar GDM. Pode precisar de ativação manual."
    log_msg "success" "GNOME Minimal e GDM instalados."
}

install_base_utilities() {
    log_msg "step" "Instalando utilitários básicos"
    log_msg "info" "Instalando pacotes comuns: $COMMON_PACKAGES_CORE"
    sudo dnf install -y $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns utilitários básicos."
    log_msg "success" "Utilitários básicos instalados."
}

# Menu principal de instalação
run_installation() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "============================================================"
    echo "          FEDORA GNOME MINIMAL - INSTALAÇÃO v${SCRIPT_VERSION}"
    echo "============================================================"
    echo -e "${NC}"
    echo "Este script irá instalar uma versão minimalista do GNOME"
    echo "com suporte opcional a drivers NVIDIA no Fedora."
    echo ""
    echo -e "${YELLOW}O script realizará as seguintes operações:${NC}"
    echo "  1. Otimizar configurações do DNF"
    echo "  2. Atualizar o sistema"
    echo "  3. Configurar repositórios adicionais (RPM Fusion)"
    echo "  4. Instalar drivers NVIDIA (opcional)"
    echo "  5. Instalar GNOME Minimal"
    echo "  6. Instalar utilitários básicos"
    echo "  7. Configurar Flatpak e instalar aplicativos"
    echo ""

    read -r -p "Deseja prosseguir com a instalação? [S/n]: " choice
    if [[ -z "$choice" || ${choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        check_system
        optimize_dnf
        setup_repositories
        update_system
        install_nvidia_drivers
        install_gnome_minimal
        install_base_utilities
        setup_flatpak_common "gnome" # Passa "gnome" para a função de configuração do Flatpak
        finalize_installation
        show_final_info
    else
        log_msg "info" "Instalação cancelada pelo usuário."
        exit 0
    fi
}

# Executa a instalação
run_installation
EOF_FEDORA_GNOME_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/fedora_gnome_minimal.sh" || log_error "Falha ao dar permissão de execução a fedora_gnome_minimal.sh"
log_success "modules/fedora_gnome_minimal.sh criado."

# modules/opensuse_kde_minimal.sh
# =============================================================================
log_info "Criando modules/opensuse_kde_minimal.sh..."
cat << 'EOF_OPENSUSE_KDE_MINIMAL_SH' > "$INSTALLER_DIR/modules/opensuse_kde_minimal.sh"
#!/bin/bash
# =============================================================================
# openSUSE Tumbleweed KDE Plasma Minimal - Instalação com suporte NVIDIA
# =============================================================================

# Carrega as funções comuns
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../common/common_functions.sh"

# Configurações
set -e # Encerra o script se qualquer comando falhar
SCRIPT_VERSION="1.0.0"

# Funções de instalação
check_system() {
    log_msg "step" "Verificando o sistema"
    check_root
    if ! grep -q "openSUSE Tumbleweed" /etc/os-release; then
        log_msg "error" "Este script é para openSUSE Tumbleweed. Sistema não detectado."
        exit 1
    fi
    log_msg "success" "Sistema verificado: openSUSE Tumbleweed."
}

optimize_zypper() {
    log_msg "step" "Otimizando Zypper"
    log_msg "info" "Configurando downloads paralelos e refresh de repositórios..."
    sudo sed -i "s/^#\\?download\\.max_concurrent_connections.*/download.max_concurrent_connections = 10/; T; a download.max_concurrent_connections = 10" /etc/zypp/zypp.conf
    sudo env ZYPP_CURL2=1 zypper ref || log_msg "warning" "Falha ao otimizar Zypper."
    log_msg "success" "Zypper otimizado."
}

update_system() {
    log_msg "step" "Atualizando o sistema"
    log_msg "info" "Executando full distribution upgrade..."
    sudo env ZYPP_PCK_PRELOAD=1 zypper dup -y || log_msg "error" "Falha ao atualizar o sistema."
    log_msg "success" "Sistema atualizado."
}

install_nvidia_drivers() {
    log_msg "step" "Instalando drivers NVIDIA (Opcional)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar drivers NVIDIA? [S/n]: ${NC}")" nvidia_choice
    if [[ -z "$nvidia_choice" || ${nvidia_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando drivers NVIDIA (G06) e dependências para Wayland..."
        sudo zypper install -y \
            kernel-firmware-nvidia \
            nvidia-gl-G06 \
            nvidia-gfxG06-kmp-default \
            nvidia-compute-G06 \
            libnvidia-egl-wayland1 \
            nvidia-settings \
            || log_msg "warning" "Falha ao instalar drivers NVIDIA. Verifique a compatibilidade."

        log_msg "info" "Regenerando initramfs..."
        sudo dracut -f --regenerate-all || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
        log_msg "success" "Drivers NVIDIA com suporte Wayland instalados."
    else
        log_msg "info" "Instalação de drivers NVIDIA ignorada."
    fi
}

install_kde_minimal() {
    log_msg "step" "Instalando KDE Plasma Minimal e SDDM"
    local KDE_PACKAGES="plasma-desktop sddm dolphin ark kitty git flatpak"
    log_msg "info" "Instalando pacotes do KDE: $KDE_PACKAGES"
    sudo env ZYPP_PCK_PRELOAD=1 zypper install -y $KDE_PACKAGES || log_msg "error" "Falha ao instalar KDE Plasma Minimal."

    log_msg "info" "Habilitando SDDM..."
    sudo systemctl enable sddm || log_msg "warning" "Falha ao habilitar SDDM. Pode precisar de ativação manual."
    log_msg "success" "KDE Plasma Minimal e SDDM instalados."
}

install_base_utilities() {
    log_msg "step" "Instalando utilitários básicos"
    log_msg "info" "Instalando pacotes comuns: $COMMON_PACKAGES_CORE"
    sudo env ZYPP_PCK_PRELOAD=1 zypper install -y $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns utilitários básicos."
    log_msg "success" "Utilitários básicos instalados."
}

# Menu principal de instalação
run_installation() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "=================================================================="
    echo "    OPENSUSE TUMBLEWEED KDE MINIMAL - INSTALAÇÃO v${SCRIPT_VERSION}"
    echo "=================================================================="
    echo -e "${NC}"
    echo "Este script irá instalar uma versão minimalista do KDE Plasma"
    echo "com suporte opcional a drivers NVIDIA no openSUSE Tumbleweed."
    echo ""
    echo -e "${YELLOW}O script realizará as seguintes operações:${NC}"
    echo "  1. Otimizar configurações do Zypper"
    echo "  2. Atualizar o sistema"
    echo "  3. Instalar drivers NVIDIA (opcional)"
    echo "  4. Instalar KDE Plasma (versão minimalista)"
    echo "  5. Instalar utilitários básicos"
    echo "  6. Configurar Flatpak e instalar aplicativos"
    echo ""

    read -r -p "Deseja prosseguir com a instalação? [S/n]: " choice
    if [[ -z "$choice" || ${choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        check_system
        optimize_zypper
        update_system
        install_nvidia_drivers
        install_kde_minimal
        install_base_utilities
        setup_flatpak_common "kde" # Passa "kde" para a função de configuração do Flatpak
        finalize_installation
        show_final_info
    else
        log_msg "info" "Instalação cancelada pelo usuário."
        exit 0
    fi
}

# Executa a instalação
run_installation
EOF_OPENSUSE_KDE_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/opensuse_kde_minimal.sh" || log_error "Falha ao dar permissão de execução a opensuse_kde_minimal.sh"
log_success "modules/opensuse_kde_minimal.sh criado."

# modules/arch_kde_minimal.sh
# =============================================================================
log_info "Criando modules/arch_kde_minimal.sh..."
cat << 'EOF_ARCH_KDE_MINIMAL_SH' > "$INSTALLER_DIR/modules/arch_kde_minimal.sh"
#!/bin/bash
# =============================================================================
# Arch Linux KDE Plasma Minimal - Instalação com suporte NVIDIA
# =============================================================================

# Carrega as funções comuns
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../common/common_functions.sh"

# Configurações
set -e # Encerra o script se qualquer comando falhar
SCRIPT_VERSION="1.0.0"

# Funções de instalação
check_system() {
    log_msg "step" "Verificando o sistema"
    check_root
    if ! grep -q "Arch Linux" /etc/os-release; then
        log_msg "error" "Este script é para Arch Linux. Sistema não detectado como Arch."
        exit 1
    fi
    log_msg "success" "Sistema verificado: Arch Linux."
}

setup_pacman() {
    log_msg "step" "Configurando Pacman e Mirrors"
    log_msg "info" "Habilitando downloads paralelos..."
    sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf || log_msg "warning" "Falha ao habilitar ParallelDownloads."

    log_msg "info" "Configurando reflector para mirrors do Brasil..."
    sudo pacman -Sy reflector --noconfirm || log_msg "error" "Falha ao instalar reflector."
    sudo reflector --country Brazil --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist || log_msg "error" "Falha ao configurar mirrors com reflector."

    log_msg "info" "Habilitando repositórios multilib (se necessário)..."
    sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf || log_msg "warning" "Falha ao habilitar multilib."
    log_msg "success" "Pacman configurado."
}

update_system() {
    log_msg "step" "Atualizando o sistema"
    log_msg "info" "Executando pacman -Syu..."
    sudo pacman -Syu --noconfirm || log_msg "error" "Falha ao atualizar o sistema."
    log_msg "success" "Sistema atualizado."
}

install_aur_helper() {
    log_msg "step" "Instalando Paru (AUR Helper)"
    log_msg "info" "Criando e entrando em um diretório temporário para a instalação do paru..."
    temp_dir=$(mktemp -d)
    log_msg "info" "Usando diretório temporário: $temp_dir"
    sudo pacman -S --needed base-devel git --noconfirm || log_msg "error" "Falha ao instalar base-devel e git."
    git clone https://aur.archlinux.org/paru.git "$temp_dir/paru" || log_msg "error" "Falha ao clonar repositório do Paru."
    (cd "$temp_dir/paru" && makepkg -si --noconfirm) || log_msg "error" "Falha ao compilar e instalar Paru."
    rm -rf "$temp_dir" # Remove o diretório temporário após a instalação
    log_msg "success" "Paru instalado."
}

install_nvidia_drivers() {
    log_msg "step" "Instalando drivers NVIDIA (Opcional)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar drivers NVIDIA? [S/n]: ${NC}")" nvidia_choice
    if [[ -z "$nvidia_choice" || ${nvidia_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando nvidia-dkms, nvidia-utils, nvidia-settings, cuda via paru..."
        paru -S nvidia-dkms nvidia-utils nvidia-settings cuda --noconfirm || log_msg "warning" "Falha ao instalar drivers NVIDIA via paru. Verifique AUR."
        log_msg "info" "Regenerando initramfs..."
        sudo mkinitcpio -P || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
        log_msg "success" "Drivers NVIDIA com suporte Wayland instalados."
    else
        log_msg "info" "Instalação de drivers NVIDIA ignorada."
    fi
}

install_kde_minimal() {
    log_msg "step" "Instalando KDE Plasma Minimal e SDDM"
    local KDE_PACKAGES="plasma-desktop sddm dolphin ark kitty git flatpak"
    log_msg "info" "Instalando pacotes do KDE: $KDE_PACKAGES"
    sudo pacman -S --noconfirm $KDE_PACKAGES || log_msg "error" "Falha ao instalar KDE Plasma Minimal."

    log_msg "info" "Habilitando SDDM..."
    sudo systemctl enable sddm || log_msg "warning" "Falha ao habilitar SDDM. Pode precisar de ativação manual."
    log_msg "success" "KDE Plasma Minimal e SDDM instalados."
}

install_base_utilities() {
    log_msg "step" "Instalando utilitários básicos"
    log_msg "info" "Instalando pacotes comuns: $COMMON_PACKAGES_CORE"
    sudo pacman -S --noconfirm $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns utilitários básicos."
    log_msg "success" "Utilitários básicos instalados."
}

# Menu principal de instalação
run_installation() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "==========================================================="
    echo "      ARCH LINUX KDE MINIMAL - INSTALAÇÃO v${SCRIPT_VERSION}"
    echo "==========================================================="
    echo -e "${NC}"
    echo "Este script irá instalar uma versão minimalista do KDE Plasma"
    echo "com suporte opcional a drivers NVIDIA no Arch Linux."
    echo ""
    echo -e "${YELLOW}O script realizará as seguintes operações:${NC}"
    echo "  1. Configurar Pacman e Mirrors"
    echo "  2. Atualizar o sistema"
    echo "  3. Instalar AUR Helper (Paru)"
    echo "  4. Instalar drivers NVIDIA (opcional)"
    echo "  5. Instalar KDE Plasma (versão minimalista)"
    echo "  6. Instalar utilitários básicos"
    echo "  7. Configurar Flatpak e instalar aplicativos"
    echo ""

    read -r -p "Deseja prosseguir com a instalação? [S/n]: " choice
    if [[ -z "$choice" || ${choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        check_system
        setup_pacman
        update_system
        install_aur_helper
        install_nvidia_drivers
        install_kde_minimal
        install_base_utilities
        setup_flatpak_common "kde" # Passa "kde" para a função de configuração do Flatpak
        finalize_installation
        show_final_info
    else
        log_msg "info" "Instalação cancelada pelo usuário."
        exit 0
    fi
}

# Executa a instalação
run_installation
EOF_ARCH_KDE_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/arch_kde_minimal.sh" || log_error "Falha ao dar permissão de execução a arch_kde_minimal.sh"
log_success "modules/arch_kde_minimal.sh criado."

# modules/arch_gnome_minimal.sh
# =============================================================================
log_info "Criando modules/arch_gnome_minimal.sh..."
cat << 'EOF_ARCH_GNOME_MINIMAL_SH' > "$INSTALLER_DIR/modules/arch_gnome_minimal.sh"
#!/bin/bash
# =============================================================================
# Arch Linux GNOME Minimal - Instalação com suporte NVIDIA
# =============================================================================

# Carrega as funções comuns
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../common/common_functions.sh"

# Configurações
set -e # Encerra o script se qualquer comando falhar
SCRIPT_VERSION="1.0.0"

# Funções de instalação
check_system() {
    log_msg "step" "Verificando o sistema"
    check_root
    if ! grep -q "Arch Linux" /etc/os-release; then
        log_msg "error" "Este script é para Arch Linux. Sistema não detectado como Arch."
        exit 1
    fi
    log_msg "success" "Sistema verificado: Arch Linux."
}

setup_pacman() {
    log_msg "step" "Configurando Pacman e Mirrors"
    log_msg "info" "Habilitando downloads paralelos..."
    sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf || log_msg "warning" "Falha ao habilitar ParallelDownloads."

    log_msg "info" "Configurando reflector para mirrors do Brasil..."
    sudo pacman -Sy reflector --noconfirm || log_msg "error" "Falha ao instalar reflector."
    sudo reflector --country Brazil --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist || log_msg "error" "Falha ao configurar mirrors com reflector."

    log_msg "info" "Habilitando repositórios multilib (se necessário)..."
    sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf || log_msg "warning" "Falha ao habilitar multilib."
    log_msg "success" "Pacman configurado."
}

update_system() {
    log_msg "step" "Atualizando o sistema"
    log_msg "info" "Executando pacman -Syu..."
    sudo pacman -Syu --noconfirm || log_msg "error" "Falha ao atualizar o sistema."
    log_msg "success" "Sistema atualizado."
}

install_aur_helper() {
    log_msg "step" "Instalando Paru (AUR Helper)"
    log_msg "info" "Criando e entrando em um diretório temporário para a instalação do paru..."
    temp_dir=$(mktemp -d)
    log_msg "info" "Usando diretório temporário: $temp_dir"
    sudo pacman -S --needed base-devel git --noconfirm || log_msg "error" "Falha ao instalar base-devel e git."
    git clone https://aur.archlinux.org/paru.git "$temp_dir/paru" || log_msg "error" "Falha ao clonar repositório do Paru."
    (cd "$temp_dir/paru" && makepkg -si --noconfirm) || log_msg "error" "Falha ao compilar e instalar Paru."
    rm -rf "$temp_dir" # Remove o diretório temporário após a instalação
    log_msg "success" "Paru instalado."
}

install_nvidia_drivers() {
    log_msg "step" "Instalando drivers NVIDIA (Opcional)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar drivers NVIDIA? [S/n]: ${NC}")" nvidia_choice
    if [[ -z "$nvidia_choice" || ${nvidia_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando nvidia-dkms, nvidia-utils, nvidia-settings, cuda via paru..."
        paru -S nvidia-dkms nvidia-utils nvidia-settings cuda --noconfirm || log_msg "warning" "Falha ao instalar drivers NVIDIA via paru. Verifique AUR."
        log_msg "info" "Regenerando initramfs..."
        sudo mkinitcpio -P || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
        log_msg "success" "Drivers NVIDIA com suporte Wayland instalados."
    else
        log_msg "info" "Instalação de drivers NVIDIA ignorada."
    fi
}

install_gnome_minimal() {
    log_msg "step" "Instalando GNOME Minimal e GDM"
    local GNOME_PACKAGES="gnome-shell gdm nautilus kitty git flatpak"
    log_msg "info" "Instalando pacotes do GNOME: $GNOME_PACKAGES"
    sudo pacman -S --noconfirm $GNOME_PACKAGES || log_msg "error" "Falha ao instalar GNOME Minimal."

    log_msg "info" "Habilitando GDM..."
    sudo systemctl enable gdm || log_msg "warning" "Falha ao habilitar GDM. Pode precisar de ativação manual."
    log_msg "success" "GNOME Minimal e GDM instalados."
}

install_base_utilities() {
    log_msg "step" "Instalando utilitários básicos"
    log_msg "info" "Instalando pacotes comuns: $COMMON_PACKAGES_CORE"
    sudo pacman -S --noconfirm $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns utilitários básicos."
    log_msg "success" "Utilitários básicos instalados."
}

# Menu principal de instalação
run_installation() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "============================================================"
    echo "      ARCH LINUX GNOME MINIMAL - INSTALAÇÃO v${SCRIPT_VERSION}"
    echo "============================================================"
    echo -e "${NC}"
    echo "Este script irá instalar uma versão minimalista do GNOME"
    echo "com suporte opcional a drivers NVIDIA no Arch Linux."
    echo ""
    echo -e "${YELLOW}O script realizará as seguintes operações:${NC}"
    echo "  1. Configurar Pacman e Mirrors"
    echo "  2. Atualizar o sistema"
    echo "  3. Instalar AUR Helper (Paru)"
    echo "  4. Instalar drivers NVIDIA (opcional)"
    echo "  5. Instalar GNOME Minimal"
    echo "  6. Instalar utilitários básicos"
    echo "  7. Configurar Flatpak e instalar aplicativos"
    echo ""

    read -r -p "Deseja prosseguir com a instalação? [S/n]: " choice
    if [[ -z "$choice" || ${choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        check_system
        setup_pacman
        update_system
        install_aur_helper
        install_nvidia_drivers
        install_gnome_minimal
        install_base_utilities
        setup_flatpak_common "gnome" # Passa "gnome" para a função de configuração do Flatpak
        finalize_installation
        show_final_info
    else
        log_msg "info" "Instalação cancelada pelo usuário."
        exit 0
    fi
}

# Executa a instalação
run_installation
EOF_ARCH_GNOME_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/arch_gnome_minimal.sh" || log_error "Falha ao dar permissão de execução a arch_gnome_minimal.sh"
log_success "modules/arch_gnome_minimal.sh criado."

# modules/siduction_kde_minimal.sh
# =============================================================================
log_info "Criando modules/siduction_kde_minimal.sh..."
cat << 'EOF_SIDUCTION_KDE_MINIMAL_SH' > "$INSTALLER_DIR/modules/siduction_kde_minimal.sh"
#!/bin/bash
# =============================================================================
# siduction KDE Plasma Minimal - Instalação com suporte NVIDIA
# =============================================================================

# Carrega as funções comuns
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/../common/common_functions.sh"

# Configurações
set -e # Encerra o script se qualquer comando falhar
SCRIPT_VERSION="1.0.0"

# Funções de instalação
check_system() {
    log_msg "step" "Verificando o sistema"
    check_root
    if ! grep -q "siduction" /etc/os-release; then
        log_msg "error" "Este script é para siduction. Sistema não detectado como siduction."
        exit 1
    fi
    log_msg "success" "Sistema verificado: siduction."
}

update_system() {
    log_msg "step" "Atualizando o sistema"
    log_msg "info" "Atualizando lista de pacotes e executando full-upgrade..."
    sudo apt update && sudo apt full-upgrade -y || log_msg "error" "Falha ao atualizar o sistema."
    log_msg "success" "Sistema atualizado."
}

install_kde_minimal() {
    log_msg "step" "Instalando KDE Plasma Minimal e SDDM"
    local KDE_PACKAGES="plasma-desktop sddm dolphin ark kitty git flatpak"
    log_msg "info" "Instalando pacotes do KDE: $KDE_PACKAGES"
    sudo apt install -y $KDE_PACKAGES || log_msg "error" "Falha ao instalar KDE Plasma Minimal."

    log_msg "info" "Habilitando SDDM..."
    sudo systemctl enable sddm || log_msg "warning" "Falha ao habilitar SDDM. Pode precisar de ativação manual."
    log_msg "success" "KDE Plasma Minimal e SDDM instalados."
}

install_nvidia_drivers() {
    log_msg "step" "Instalando drivers NVIDIA (Opcional)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar drivers NVIDIA? [S/n]: ${NC}")" nvidia_choice
    if [[ -z "$nvidia_choice" || ${nvidia_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando drivers NVIDIA e suporte Wayland..."
        sudo apt install -y nvidia-driver libnvidia-egl-wayland1 nvidia-settings || log_msg "warning" "Falha ao instalar drivers NVIDIA. Verifique a compatibilidade."
        log_msg "success" "Drivers NVIDIA com suporte Wayland instalados."
    else
        log_msg "info" "Instalação de drivers NVIDIA ignorada."
    fi
}

install_base_utilities() {
    log_msg "step" "Instalando utilitários básicos"
    log_msg "info" "Instalando pacotes comuns: $COMMON_PACKAGES_CORE"
    sudo apt install -y $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns utilitários básicos."
    log_msg "success" "Utilitários básicos instalados."
}

# Menu principal de instalação
run_installation() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "============================================================"
    echo "      SIDUCTION KDE MINIMAL - INSTALAÇÃO v${SCRIPT_VERSION}"
    echo "============================================================"
    echo -e "${NC}"
    echo "Este script irá instalar uma versão minimalista do KDE Plasma"
    echo "com suporte opcional a drivers NVIDIA no siduction."
    echo ""
    echo -e "${YELLOW}O script realizará as seguintes operações:${NC}"
    echo "  1. Verificar sistema (siduction)"
    echo "  2. Atualizar o sistema"
    echo "  3. Instalar KDE Plasma (versão minimalista)"
    echo "  4. Instalar drivers NVIDIA (opcional)"
    echo "  5. Instalar utilitários básicos"
    echo "  6. Configurar Flatpak e instalar aplicativos"
    echo ""

    read -r -p "Deseja prosseguir com a instalação? [S/n]: " choice
    if [[ -z "$choice" || ${choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        check_system
        update_system
        install_kde_minimal
        install_nvidia_drivers
        install_base_utilities
        setup_flatpak_common "kde" # Passa "kde" para a função de configuração do Flatpak
        finalize_installation
        show_final_info
    else
        log_msg "info" "Instalação cancelada pelo usuário."
        exit 0
    fi
}

# Executa a instalação
run_installation
EOF_SIDUCTION_KDE_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/siduction_kde_minimal.sh" || log_error "Falha ao dar permissão de execução a siduction_kde_minimal.sh"
log_success "modules/siduction_kde_minimal.sh criado."


log_success "Todos os scripts foram gerados com sucesso na pasta '$INSTALLER_DIR'!"
log_info "Para começar, entre na pasta '$INSTALLER_DIR' e execute o script 'main.sh':"
log_info "cd $INSTALLER_DIR"
log_info "sudo bash main.sh"
