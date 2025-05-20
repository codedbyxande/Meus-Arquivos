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
    read -r -p "$(echo -e "${YELLOW}Deseja remover o diretório existente e recriá-lo? (s/N): ${NC}")" confirm_overwrite
    if [[ ${confirm_overwrite,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_info "Removendo diretório existente: $INSTALLER_DIR"
        rm -rf "$INSTALLER_DIR" || log_error "Falha ao remover o diretório '$INSTALLER_DIR'."
    else
        log_info "Operação cancelada. Não sobrescrevendo o diretório existente."
        exit 0
    fi
fi

log_info "Criando a estrutura de diretórios para '$INSTALLER_DIR'..."
mkdir -p "$INSTALLER_DIR/modules" || log_error "Falha ao criar diretório 'modules'."
mkdir -p "$INSTALLER_DIR/utils" || log_error "Falha ao criar diretório 'utils'."
log_success "Estrutura de diretórios criada."

log_info "Criando arquivos e preenchendo com o conteúdo..."

# Arquivo: my_desktop_installer/install_desktop.sh
# NOTA: O conteúdo abaixo é o que será ESCRITO no arquivo, não executado por este script.
cat << 'EOF_INSTALL_DESKTOP_SH' > "$INSTALLER_DIR/install_desktop.sh"
#!/bin/bash

# =============================================================================
# Script de Instalação Minimalista de Desktop (KDE/GNOME) v2.3.0
#
# Este script unificado detecta a distribuição e oferece opções para instalar
# um ambiente de desktop minimalista (KDE Plasma ou GNOME) com Kitty Terminal,
# Flatpak e suporte opcional a drivers NVIDIA (com configuração de KMS).
#
# Distribuições Suportadas:
# - Fedora
# - openSUSE Tumbleweed
# - Debian Sid
# - Arch Linux
# - CachyOS
# =============================================================================

# Define a versão do script
SCRIPT_VERSION="2.3.0"

# Carrega funções comuns e utilitários
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/utils/common_functions.sh"

# --- Variáveis Globais ---
DETECTED_DISTRO=""
CHOSEN_DE=""
INSTALL_NVIDIA="n" # Padrão para não instalar NVIDIA

# --- Funções de Detecção e Seleção ---

detect_distro() {
    log_msg "step" "Detectando sua distribuição..."
    if grep -q "ID=fedora" /etc/os-release; then
        DETECTED_DISTRO="fedora"
        log_msg "info" "Distribuição detectada: Fedora"
    elif grep -q "ID=opensuse-tumbleweed" /etc/os-release; then
        DETECTED_DISTRO="opensuse"
        log_msg "info" "Distribuição detectada: openSUSE Tumbleweed"
    elif grep -q "ID=debian" /etc/os-release && grep -q "VERSION_CODENAME=sid" /etc/os-release; then
        DETECTED_DISTRO="debian-sid"
        log_msg "info" "Distribuição detectada: Debian Sid"
    elif grep -q "ID=arch" /etc/os-release; then
        DETECTED_DISTRO="arch"
        log_msg "info" "Distribuição detectada: Arch Linux"
    elif grep -q "ID=cachyos" /etc/os-release; then
        DETECTED_DISTRO="cachyos"
        log_msg "info" "Distribuição detectada: CachyOS"
    else
        log_msg "error" "Distribuição não suportada ou não detectada. Saindo."
        exit 1
    fi
}

select_desktop_environment() {
    log_msg "step" "Selecione o Ambiente de Desktop"
    echo -e "${YELLOW}Qual ambiente de desktop você gostaria de instalar?${NC}"
    echo "  1) KDE Plasma Minimal"
    echo "  2) GNOME Minimal"
    echo ""
    read -r -p "Digite o número da sua escolha (1 ou 2): " de_choice

    case "$de_choice" in
        1) CHOSEN_DE="kde" ;;
        2) CHOSEN_DE="gnome" ;;
        *)
            log_msg "error" "Opção inválida. Por favor, digite '1' para KDE ou '2' para GNOME."
            exit 1
            ;;
    esac
    log_msg "info" "Ambiente de Desktop selecionado: $(echo $CHOSEN_DE | tr 'a-z' 'A-Z') Minimal"
}

ask_nvidia_drivers() {
    log_msg "step" "Configuração de Drivers NVIDIA"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar os drivers NVIDIA? (s/N): ${NC}")" install_nvidia_choice
    if [[ ${install_nvidia_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        INSTALL_NVIDIA="y"
        log_msg "info" "Drivers NVIDIA selecionados para instalação (incluindo configuração de KMS)."
    else
        INSTALL_NVIDIA="n"
        log_msg "info" "Instalação de drivers NVIDIA ignorada."
    fi
}

# --- Função Principal de Execução ---

run_installation() {
    clear
    show_welcome_banner

    # 1. Verificar privilégios de root
    check_root

    # 2. Detectar a distribuição
    detect_distro

    # 3. Selecionar o ambiente de desktop
    select_desktop_environment

    # 4. Perguntar sobre drivers NVIDIA
    ask_nvidia_drivers

    # 5. Confirmar e iniciar a instalação
    echo -e "\n${CYAN}${BOLD}============================================================${NC}"
    echo -e "${CYAN}${BOLD}   Resumo da Instalação:${NC}"
    echo -e "${CYAN}${BOLD}     Distribuição: ${DETECTED_DISTRO}${NC}"
    echo -e "${CYAN}${BOLD}     Desktop:      ${CHOSEN_DE} Minimal${NC}"
    echo -e "${CYAN}${BOLD}     Drivers NVIDIA: $(if [ "$INSTALL_NVIDIA" == "y" ]; then echo "SIM (com KMS automático)"; else echo "NÃO"; fi)${NC}"
    echo -e "${CYAN}${BOLD}============================================================${NC}"
    read -r -p "$(echo -e "${YELLOW}Deseja prosseguir com esta configuração? [S/n]: ${NC}")" final_choice

    if [[ -z "$final_choice" || ${final_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "step" "Iniciando a instalação..."
        local module_path="$SCRIPT_DIR/modules/${DETECTED_DISTRO}_${CHOSEN_DE}_minimal.sh"

        if [ -f "$module_path" ]; then
            log_msg "info" "Carregando módulo: $module_path"
            # Passa a variável INSTALL_NVIDIA para o módulo
            INSTALL_NVIDIA="$INSTALL_NVIDIA" bash "$module_path"
            log_msg "success" "Instalação do $CHOSEN_DE Minimal em $DETECTED_DISTRO concluída com sucesso!"
            show_final_recommendations
        else
            log_msg "error" "Módulo de instalação para ${DETECTED_DISTRO} com ${CHOSEN_DE} Minimal não encontrado: $module_path"
            exit 1
        fi
    else
        log_msg "info" "Instalação cancelada pelo usuário."
        exit 0
    fi
}

# --- Execução ---
run_installation
EOF_INSTALL_DESKTOP_SH
chmod +x "$INSTALLER_DIR/install_desktop.sh" || log_error "Falha ao dar permissão de execução a install_desktop.sh"

# Arquivo: my_desktop_installer/utils/common_functions.sh
cat << 'EOF_COMMON_FUNCTIONS_SH' > "$INSTALLER_DIR/utils/common_functions.sh"
#!/bin/bash

# =============================================================================
# Funções Comuns e Variáveis para Scripts de Instalação
# =============================================================================

# Cores para o terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Função para exibir mensagens com formatação
log_msg() {
    local type=$1
    local msg=$2
    local date_str=$(date '+%H:%M:%S')

    case $type in
        "info")     echo -e "[${BLUE}INFO${NC}] ${date_str} - ${msg}" ;;
        "success")  echo -e "[${GREEN}OK${NC}] ${date_str} - ${msg}" ;;
        "warning")  echo -e "[${YELLOW}AVISO${NC}] ${date_str} - ${msg}" ;;
        "error")    echo -e "[${RED}ERRO${NC}] ${date_str} - ${msg}" ; exit 1 ;; # Exit on error
        "step")     echo -e "\n${CYAN}${BOLD}=== $msg ===${NC}" ;;
    esac
}

# Função para verificar se o script está sendo executado como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_msg "error" "Este script precisa ser executado como root. Use 'sudo ./install_desktop.sh'."
    fi
}

# Função para exibir banner de boas-vindas
show_welcome_banner() {
    echo -e "${CYAN}${BOLD}"
    echo "=============================================================="
    echo "       SCRIPT DE INSTALAÇÃO MINIMALISTA DE DESKTOP"
    echo "             (KDE Plasma / GNOME) v${SCRIPT_VERSION}"
    echo "=============================================================="
    echo -e "${NC}"
    echo "Este script irá ajudá-lo a instalar um ambiente de desktop"
    echo "minimalista em sua distribuição Linux preferida."
    echo ""
    echo -e "${YELLOW}Por favor, leia atentamente as opções antes de prosseguir.${NC}"
    echo ""
    sleep 2
}

# Função para exibir informações finais
show_final_recommendations() {
    log_msg "success" "Instalação básica concluída!"
    echo -e "\n${GREEN}${BOLD}============================================================${NC}"
    echo -e "${GREEN}${BOLD}             INSTALAÇÃO CONCLUÍDA COM SUCESSO!            ${NC}"
    echo -e "${GREEN}${BOLD}============================================================${NC}"
    echo -e "${YELLOW}Recomendações pós-instalação:${NC}"
    echo "  - Reinicie o sistema para aplicar todas as alterações:"
    echo "    ${BLUE}sudo reboot${NC}"
    echo "  - Na tela de login (SDDM/GDM), certifique-se de selecionar"
    echo "    o ambiente 'Plasma' ou 'GNOME' antes de logar."
    echo "  - Se instalou drivers NVIDIA, 'nvidia_drm.modeset=1' foi configurado"
    echo "    para um melhor suporte a Wayland. Certifique-se de que o GRUB/Bootloader"
    echo "    está atualizado."
    echo "  - Seu terminal padrão é o Kitty."
    echo "  - Verifique o Flatpak para instalar seus aplicativos favoritos."
    echo -e "${BOLD}Obrigado por usar o script!${NC}\n"
}

# Pacotes essenciais comuns a todos os DEs/Distros
COMMON_PACKAGES_CORE="git flatpak kitty"

# Aplicativos Flatpak comuns para ambos os DEs (KDE e GNOME)
COMMON_FLATPAK_APPS_BASE="app.zen_browser.zen dev.vencord.Vesktop org.nickvision.tubeconverter"

# Aplicativos Flatpak específicos para GNOME (além dos comuns)
GNOME_FLATPAK_APPS_ADDITIONAL="com.github.tchx84.Flatseal com.mattjakeman.ExtensionManager io.github.vikdevelop.SaveDesktop"

# Função para instalar Flatpak e aplicativos Flatpak
setup_flatpak_common() {
    local desktop_env=$1 # Recebe "gnome" ou "kde" como argumento

    log_msg "step" "Configurando Flatpak e instalando aplicativos essenciais (Flatpak)"
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || log_msg "warning" "Falha ao adicionar Flathub remote."
    
    log_msg "info" "Instalando aplicativos Flatpak base: ${COMMON_FLATPAK_APPS_BASE}"
    flatpak install -y flathub $COMMON_FLATPAK_APPS_BASE || log_msg "warning" "Alguns aplicativos Flatpak base podem não ter sido instalados."

    if [ "$desktop_env" == "gnome" ]; then
        log_msg "info" "Instalando aplicativos Flatpak específicos para GNOME: ${GNOME_FLATPAK_APPS_ADDITIONAL}"
        flatpak install -y flathub $GNOME_FLATPAK_APPS_ADDITIONAL || log_msg "warning" "Alguns aplicativos Flatpak específicos para GNOME podem não ter sido instalados."
    fi
    # Para KDE, apenas os COMMON_FLATPAK_APPS_BASE são instalados por enquanto, conforme a solicitação.

    log_msg "success" "Configuração do Flatpak concluída."
}

# Função para adicionar nvidia_drm.modeset=1 ao GRUB (se aplicável)
add_nvidia_modeset_grub() {
    log_msg "info" "Adicionando 'nvidia_drm.modeset=1' ao GRUB para KMS antecipado da NVIDIA."
    if grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
        log_msg "info" "'nvidia_drm.modeset=1' já está presente no GRUB."
    else
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' /etc/default/grub || log_msg "warning" "Falha ao adicionar nvidia_drm.modeset=1 ao GRUB."
    fi
    log_msg "info" "Atualizando GRUB..."
    if command -v update-grub &> /dev/null; then
        sudo update-grub || log_msg "warning" "Falha ao atualizar GRUB. Verifique manualmente."
    elif command -v grub-mkconfig &> /dev/null; then
        sudo grub-mkconfig -o /boot/grub/grub.cfg || log_msg "warning" "Falha ao atualizar GRUB. Verifique manualmente."
    else
        log_msg "warning" "Comando para atualizar GRUB não encontrado. Pode ser necessário atualizar manualmente."
    fi
}
EOF_COMMON_FUNCTIONS_SH
chmod +x "$INSTALLER_DIR/utils/common_functions.sh" || log_error "Falha ao dar permissão de execução a common_functions.sh"

# Arquivo: my_desktop_installer/modules/arch_gnome_minimal.sh
cat << 'EOF_ARCH_GNOME_MINIMAL_SH' > "$INSTALLER_DIR/modules/arch_gnome_minimal.sh"
#!/bin/bash

# =============================================================================
# Arch Linux GNOME Minimal Installation Module
# =============================================================================

# Carrega funções comuns e variáveis
source "$(dirname "$0")/../utils/common_functions.sh"

log_msg "step" "Iniciando instalação do GNOME Minimal no Arch Linux"

# Otimizar Pacman e configurar mirrors
log_msg "step" "Otimizando Pacman e configurando mirrors"
sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf || log_msg "warning" "Não foi possível otimizar ParallelDownloads."
sudo pacman -Sy reflector --noconfirm || log_msg "warning" "Reflector não pôde ser instalado."
sudo reflector --country Brazil --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist || log_msg "warning" "Não foi possível atualizar mirrorlist."
sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf || log_msg "warning" "Não foi possível habilitar multilib."

# Atualizar sistema
log_msg "step" "Atualizando o sistema"
sudo pacman -Syu --noconfirm || log_msg "error" "Falha ao atualizar o sistema."

# Instalar AUR helper (paru)
log_msg "step" "Instalando Paru (AUR Helper)"
if ! command -v paru &> /dev/null; then
    temp_dir=$(mktemp -d)
    log_msg "info" "Usando diretório temporário: $temp_dir"
    sudo pacman -S --needed base-devel git --noconfirm || log_msg "error" "Falha ao instalar base-devel ou git."
    git clone https://aur.archlinux.org/paru.git "$temp_dir/paru" || log_msg "error" "Falha ao clonar repositório paru."
    (cd "$temp_dir/paru" && makepkg -si --noconfirm) || log_msg "error" "Falha ao compilar e instalar paru."
    rm -rf "$temp_dir" # Remove o diretório temporário após a instalação
    log_msg "success" "Paru instalado com sucesso."
else
    log_msg "info" "Paru já está instalado."
fi

# Instalação de drivers NVIDIA (se selecionado)
if [ "$INSTALL_NVIDIA" == "y" ]; then
    log_msg "step" "Instalando drivers NVIDIA"
    # nvidia-dkms inclui suporte a Wayland e GBM no Arch
    paru -S nvidia-dkms nvidia-utils nvidia-settings cuda libnvidia-egl-wayland --noconfirm || log_msg "warning" "Falha ao instalar drivers NVIDIA."
    
    # Adiciona nvidia_drm.modeset=1 ao GRUB
    add_nvidia_modeset_grub
    
    sudo mkinitcpio -P || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
    log_msg "success" "Drivers NVIDIA instalados."
else
    log_msg "info" "Instalação de drivers NVIDIA ignorada."
fi

# Instalar GNOME Minimal e GDM
log_msg "step" "Instalando GNOME Minimal e GDM"
GNOME_PACKAGES="gnome-shell gdm nautilus kitty gnome-tweaks gnome-shell-extensions" # Adicionado kitty e ferramentas GNOME
sudo pacman -S --noconfirm $GNOME_PACKAGES || log_msg "error" "Falha ao instalar GNOME Minimal."

log_msg "info" "Habilitando GDM"
sudo systemctl enable gdm || log_msg "warning" "Falha ao habilitar GDM. Pode precisar de ativação manual."

# Pacotes essenciais e Flatpak
log_msg "step" "Instalando pacotes essenciais e configurando Flatpak"
sudo pacman -S --noconfirm $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns pacotes essenciais."
setup_flatpak_common "gnome" # Passa "gnome" para a função de configuração do Flatpak

# --- Nova Função para Pop Shell ---
install_pop_shell() {
    log_msg "step" "Instalando Pop Shell (GNOME Extension)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar o Pop Shell (extensão GNOME)? (s/N): ${NC}")" install_pop_shell_choice
    if [[ ${install_pop_shell_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando dependências para Pop Shell..."
        # make, nodejs e npm são dependências de compilação
        sudo pacman -S --noconfirm make nodejs npm || log_msg "warning" "Falha ao instalar dependências para Pop Shell."

        local temp_dir_popshell=$(mktemp -d)
        log_msg "info" "Clonando Pop Shell para diretório temporário: $temp_dir_popshell"
        git clone https://github.com/pop-os/shell.git "$temp_dir_popshell/popshell" || log_msg "error" "Falha ao clonar repositório Pop Shell."

        log_msg "info" "Compilando e instalando Pop Shell..."
        (cd "$temp_dir_popshell/popshell" && make local-install) || log_msg "error" "Falha ao compilar ou instalar Pop Shell."

        log_msg "info" "Removendo diretório temporário: $temp_dir_popshell"
        rm -rf "$temp_dir_popshell" || log_msg "warning" "Falha ao remover diretório temporário do Pop Shell."

        log_msg "success" "Pop Shell instalado. Pode ser necessário habilitá-lo via GNOME Extensions."
    else
        log_msg "info" "Instalação do Pop Shell ignorada."
    fi
}

# Chamar a função do Pop Shell no final
install_pop_shell

log_msg "success" "Módulo Arch Linux GNOME Minimal concluído."
EOF_ARCH_GNOME_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/arch_gnome_minimal.sh" || log_error "Falha ao dar permissão de execução a arch_gnome_minimal.sh"

# Arquivo: my_desktop_installer/modules/arch_kde_minimal.sh
cat << 'EOF_ARCH_KDE_MINIMAL_SH' > "$INSTALLER_DIR/modules/arch_kde_minimal.sh"
#!/bin/bash

# =============================================================================
# Arch Linux KDE Minimal Installation Module
# =============================================================================

# Carrega funções comuns e variáveis
source "$(dirname "$0")/../utils/common_functions.sh"

log_msg "step" "Iniciando instalação do KDE Minimal no Arch Linux"

# Otimizar Pacman e configurar mirrors
log_msg "step" "Otimizando Pacman e configurando mirrors"
sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf || log_msg "warning" "Não foi possível otimizar ParallelDownloads."
sudo pacman -Sy reflector --noconfirm || log_msg "warning" "Reflector não pôde ser instalado."
sudo reflector --country Brazil --protocol https --latest 20 --sort rate --save /etc/pacman.d/mirrorlist || log_msg "warning" "Não foi possível atualizar mirrorlist."
sudo sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf || log_msg "warning" "Não foi possível habilitar multilib."

# Atualizar sistema
log_msg "step" "Atualizando o sistema"
sudo pacman -Syu --noconfirm || log_msg "error" "Falha ao atualizar o sistema."

# Instalar AUR helper (paru)
log_msg "step" "Instalando Paru (AUR Helper)"
if ! command -v paru &> /dev/null; then
    temp_dir=$(mktemp -d)
    log_msg "info" "Usando diretório temporário: $temp_dir"
    sudo pacman -S --needed base-devel git --noconfirm || log_msg "error" "Falha ao instalar base-devel ou git."
    git clone https://aur.archlinux.org/paru.git "$temp_dir/paru" || log_msg "error" "Falha ao clonar repositório paru."
    (cd "$temp_dir/paru" && makepkg -si --noconfirm) || log_msg "error" "Falha ao compilar e instalar paru."
    rm -rf "$temp_dir" # Remove o diretório temporário após a instalação
    log_msg "success" "Paru instalado com sucesso."
else
    log_msg "info" "Paru já está instalado."
fi

# Instalação de drivers NVIDIA (se selecionado)
if [ "$INSTALL_NVIDIA" == "y" ]; then
    log_msg "step" "Instalando drivers NVIDIA"
    # nvidia-dkms inclui suporte a Wayland e GBM no Arch
    paru -S nvidia-dkms nvidia-utils nvidia-settings cuda libnvidia-egl-wayland --noconfirm || log_msg "warning" "Falha ao instalar drivers NVIDIA."
    
    # Adiciona nvidia_drm.modeset=1 ao GRUB
    add_nvidia_modeset_grub
    
    sudo mkinitcpio -P || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
    log_msg "success" "Drivers NVIDIA instalados."
else
    log_msg "info" "Instalação de drivers NVIDIA ignorada."
fi

# Instalar KDE Plasma Minimal e SDDM
log_msg "step" "Instalando KDE Plasma Minimal e SDDM"
KDE_PACKAGES="plasma-desktop sddm dolphin ark kitty" # Adicionado kitty aqui
sudo pacman -S --noconfirm $KDE_PACKAGES || log_msg "error" "Falha ao instalar KDE Plasma Minimal."

log_msg "info" "Habilitando SDDM"
sudo systemctl enable sddm || log_msg "warning" "Falha ao habilitar SDDM. Pode precisar de ativação manual."

# Pacotes essenciais e Flatpak
log_msg "step" "Instalando pacotes essenciais e configurando Flatpak"
sudo pacman -S --noconfirm $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns pacotes essenciais."
setup_flatpak_common "kde" # Passa "kde" para a função de configuração do Flatpak

log_msg "success" "Módulo Arch Linux KDE Minimal concluído."
EOF_ARCH_KDE_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/arch_kde_minimal.sh" || log_error "Falha ao dar permissão de execução a arch_kde_minimal.sh"


# Arquivo: my_desktop_installer/modules/cachyos_gnome_minimal.sh
cat << 'EOF_CACHYOS_GNOME_MINIMAL_SH' > "$INSTALLER_DIR/modules/cachyos_gnome_minimal.sh"
#!/bin/bash

# =============================================================================
# CachyOS GNOME Minimal Installation Module
# =============================================================================

# Carrega funções comuns e variáveis
source "$(dirname "$0")/../utils/common_functions.sh"

log_msg "step" "Iniciando instalação do GNOME Minimal no CachyOS"

# Otimizar Pacman e atualizar o sistema (CachyOS já tem otimizações, mas reforçamos)
log_msg "step" "Otimizando Pacman e atualizando o sistema"
sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf || log_msg "warning" "Não foi possível otimizar ParallelDownloads."

# Atualizar sistema
sudo pacman -Syu --noconfirm || log_msg "error" "Falha ao atualizar o sistema."

# Instalar AUR helper (paru) - CachyOS geralmente já vem com ele, mas verificamos
log_msg "step" "Verificando e instalando Paru (AUR Helper)"
if ! command -v paru &> /dev/null; then
    temp_dir=$(mktemp -d)
    log_msg "info" "Usando diretório temporário: $temp_dir"
    sudo pacman -S --needed base-devel git --noconfirm || log_msg "error" "Falha ao instalar base-devel ou git."
    git clone https://aur.archlinux.org/paru.git "$temp_dir/paru" || log_msg "error" "Falha ao clonar repositório paru."
    (cd "$temp_dir/paru" && makepkg -si --noconfirm) || log_msg "error" "Falha ao compilar e instalar paru."
    rm -rf "$temp_dir" # Remove o diretório temporário após a instalação
    log_msg "success" "Paru instalado com sucesso."
else
    log_msg "info" "Paru já está instalado."
fi

# Instalação de drivers NVIDIA (se selecionado)
if [ "$INSTALL_NVIDIA" == "y" ]; then
    log_msg "step" "Instalando drivers NVIDIA para CachyOS"
    log_msg "info" "Tentando instalar nvidia-open-dkms para melhor suporte Wayland no CachyOS..."
    paru -S --noconfirm nvidia-open-dkms nvidia-utils nvidia-settings cuda libnvidia-egl-wayland || \
    (log_msg "warning" "nvidia-open-dkms falhou, tentando nvidia-dkms..." && \
     paru -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings cuda libnvidia-egl-wayland) || \
     log_msg "error" "Falha ao instalar drivers NVIDIA."
    
    # Adiciona nvidia_drm.modeset=1 ao GRUB
    add_nvidia_modeset_grub
    
    sudo mkinitcpio -P || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
    log_msg "success" "Drivers NVIDIA instalados."
else
    log_msg "info" "Instalação de drivers NVIDIA ignorada."
fi

# Instalar GNOME Minimal e GDM
log_msg "step" "Instalando GNOME Minimal e GDM no CachyOS"
GNOME_PACKAGES="gnome-shell gdm nautilus kitty gnome-tweaks gnome-shell-extensions" # Adicionado kitty e ferramentas GNOME
sudo pacman -S --noconfirm $GNOME_PACKAGES || log_msg "error" "Falha ao instalar GNOME Minimal."

log_msg "info" "Habilitando GDM"
sudo systemctl enable gdm || log_msg "warning" "Falha ao habilitar GDM. Pode precisar de ativação manual."

# Pacotes essenciais e Flatpak
log_msg "step" "Instalando pacotes essenciais e configurando Flatpak"
sudo pacman -S --noconfirm $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns pacotes essenciais."
setup_flatpak_common "gnome" # Passa "gnome" para a função de configuração do Flatpak

# --- Função para Pop Shell ---
install_pop_shell() {
    log_msg "step" "Instalando Pop Shell (GNOME Extension)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar o Pop Shell (extensão GNOME)? (s/N): ${NC}")" install_pop_shell_choice
    if [[ ${install_pop_shell_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando dependências para Pop Shell..."
        sudo pacman -S --noconfirm make nodejs npm || log_msg "warning" "Falha ao instalar dependências para Pop Shell."

        local temp_dir_popshell=$(mktemp -d)
        log_msg "info" "Clonando Pop Shell para diretório temporário: $temp_dir_popshell"
        git clone https://github.com/pop-os/shell.git "$temp_dir_popshell/popshell" || log_msg "error" "Falha ao clonar repositório Pop Shell."

        log_msg "info" "Compilando e instalando Pop Shell..."
        (cd "$temp_dir_popshell/popshell" && make local-install) || log_msg "error" "Falha ao compilar ou instalar Pop Shell."

        log_msg "info" "Removendo diretório temporário: $temp_dir_popshell"
        rm -rf "$temp_dir_popshell" || log_msg "warning" "Falha ao remover diretório temporário do Pop Shell."

        log_msg "success" "Pop Shell instalado. Pode ser necessário habilitá-lo via GNOME Extensions."
    else
        log_msg "info" "Instalação do Pop Shell ignorada."
    fi
}

# Chamar a função do Pop Shell no final
install_pop_shell

log_msg "success" "Módulo CachyOS GNOME Minimal concluído."
EOF_CACHYOS_GNOME_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/cachyos_gnome_minimal.sh" || log_error "Falha ao dar permissão de execução a cachyos_gnome_minimal.sh"


# Arquivo: my_desktop_installer/modules/cachyos_kde_minimal.sh
cat << 'EOF_CACHYOS_KDE_MINIMAL_SH' > "$INSTALLER_DIR/modules/cachyos_kde_minimal.sh"
#!/bin/bash

# =============================================================================
# CachyOS KDE Minimal Installation Module
# =============================================================================

# Carrega funções comuns e variáveis
source "$(dirname "$0")/../utils/common_functions.sh"

log_msg "step" "Iniciando instalação do KDE Minimal no CachyOS"

# Otimizar Pacman e atualizar o sistema (CachyOS já tem otimizações, mas reforçamos)
log_msg "step" "Otimizando Pacman e atualizando o sistema"
sudo sed -i 's/^#ParallelDownloads = 5/ParallelDownloads = 10/' /etc/pacman.conf || log_msg "warning" "Não foi possível otimizar ParallelDownloads."

# Atualizar sistema
sudo pacman -Syu --noconfirm || log_msg "error" "Falha ao atualizar o sistema."

# Instalar AUR helper (paru) - CachyOS geralmente já vem com ele, mas verificamos
log_msg "step" "Verificando e instalando Paru (AUR Helper)"
if ! command -v paru &> /dev/null; then
    temp_dir=$(mktemp -d)
    log_msg "info" "Usando diretório temporário: $temp_dir"
    sudo pacman -S --needed base-devel git --noconfirm || log_msg "error" "Falha ao instalar base-devel ou git."
    git clone https://aur.archlinux.org/paru.git "$temp_dir/paru" || log_msg "error" "Falha ao clonar repositório paru."
    (cd "$temp_dir/paru" && makepkg -si --noconfirm) || log_msg "error" "Falha ao compilar e instalar paru."
    rm -rf "$temp_dir" # Remove o diretório temporário após a instalação
    log_msg "success" "Paru instalado com sucesso."
else
    log_msg "info" "Paru já está instalado."
fi

# Instalação de drivers NVIDIA (se selecionado)
if [ "$INSTALL_NVIDIA" == "y" ]; then
    log_msg "step" "Instalando drivers NVIDIA para CachyOS"
    log_msg "info" "Tentando instalar nvidia-open-dkms para melhor suporte Wayland no CachyOS..."
    paru -S --noconfirm nvidia-open-dkms nvidia-utils nvidia-settings cuda libnvidia-egl-wayland || \
    (log_msg "warning" "nvidia-open-dkms falhou, tentando nvidia-dkms..." && \
     paru -S --noconfirm nvidia-dkms nvidia-utils nvidia-settings cuda libnvidia-egl-wayland) || \
     log_msg "error" "Falha ao instalar drivers NVIDIA."
    
    # Adiciona nvidia_drm.modeset=1 ao GRUB
    add_nvidia_modeset_grub
    
    sudo mkinitcpio -P || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
    log_msg "success" "Drivers NVIDIA instalados."
else
    log_msg "info" "Instalação de drivers NVIDIA ignorada."
fi

# Instalar KDE Plasma Minimal e SDDM
log_msg "step" "Instalando KDE Plasma Minimal e SDDM no CachyOS"
KDE_PACKAGES="plasma-desktop sddm dolphin ark kitty" # Adicionado kitty aqui
sudo pacman -S --noconfirm $KDE_PACKAGES || log_msg "error" "Falha ao instalar KDE Plasma Minimal."

log_msg "info" "Habilitando SDDM"
sudo systemctl enable sddm || log_msg "warning" "Falha ao habilitar SDDM. Pode precisar de ativação manual."

# Pacotes essenciais e Flatpak
log_msg "step" "Instalando pacotes essenciais e configurando Flatpak"
sudo pacman -S --noconfirm $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns pacotes essenciais."
setup_flatpak_common "kde" # Passa "kde" para a função de configuração do Flatpak

log_msg "success" "Módulo CachyOS KDE Minimal concluído."
EOF_CACHYOS_KDE_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/cachyos_kde_minimal.sh" || log_error "Falha ao dar permissão de execução a cachyos_kde_minimal.sh"

# Arquivo: my_desktop_installer/modules/debian_gnome_minimal.sh
cat << 'EOF_DEBIAN_GNOME_MINIMAL_SH' > "$INSTALLER_DIR/modules/debian_gnome_minimal.sh"
#!/bin/bash

# =============================================================================
# Debian Sid GNOME Minimal Installation Module
# =============================================================================

# Carrega funções comuns e variáveis
source "$(dirname "$0")/../utils/common_functions.sh"

log_msg "step" "Iniciando instalação do GNOME Minimal no Debian Sid"

# Backup e configuração de repositórios para Sid
log_msg "step" "Configurando repositórios para Debian Sid"
sudo cp /etc/apt/sources.list{,.bak} || log_msg "warning" "Falha ao fazer backup de sources.list."
sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://deb.debian.org/debian sid main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian sid main contrib non-free non-free-firmware
EOF
log_msg "success" "Repositórios configurados para Debian Sid."

# Atualização completa do sistema
log_msg "step" "Atualizando o sistema"
sudo apt update -y || log_msg "error" "Falha ao atualizar lista de pacotes."
sudo apt full-upgrade -y || log_msg "error" "Falha ao executar full-upgrade."

# Instalação do GNOME minimal + GDM
log_msg "step" "Instalando GNOME Minimal e GDM"
GNOME_PACKAGES="gnome-shell gdm nautilus kitty gnome-tweaks gnome-shell-extensions" # Adicionado kitty e ferramentas GNOME
sudo apt install -y $GNOME_PACKAGES || log_msg "error" "Falha ao instalar GNOME Minimal."

log_msg "info" "Reconfigurando GDM como padrão"
sudo dpkg-reconfigure gdm || log_msg "warning" "Falha ao reconfigurar GDM. Pode precisar de configuração manual."

# Instalação OPICIONAL de drivers NVIDIA
if [ "$INSTALL_NVIDIA" == "y" ]; then
    log_msg "step" "Instalando drivers NVIDIA"
    NVIDIA_PACKAGES="nvidia-driver libnvidia-egl-wayland1 firmware-misc-nonfree nvidia-settings nvidia-xconfig"
    sudo apt install -y $NVIDIA_PACKAGES || log_msg "warning" "Falha ao instalar drivers NVIDIA."
    
    # Adiciona nvidia_drm.modeset=1 ao GRUB
    add_nvidia_modeset_grub
    
    log_msg "info" "Gerando novo xorg.conf (opcional, pode falhar se não houver GPU NVIDIA)"
    sudo nvidia-xconfig || true # Permite que este comando falhe
    log_msg "success" "Drivers NVIDIA instalados."
else
    log_msg "info" "Instalação de drivers NVIDIA ignorada."
fi

# Pacotes essenciais e Flatpak
log_msg "step" "Instalando pacotes essenciais e configurando Flatpak"
sudo apt install -y $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns pacotes essenciais."
setup_flatpak_common "gnome" # Passa "gnome" para a função de configuração do Flatpak

# --- Função para Pop Shell ---
install_pop_shell() {
    log_msg "step" "Instalando Pop Shell (GNOME Extension)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar o Pop Shell (extensão GNOME)? (s/N): ${NC}")" install_pop_shell_choice
    if [[ ${install_pop_shell_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando dependências para Pop Shell..."
        sudo apt install -y make nodejs npm || log_msg "warning" "Falha ao instalar dependências para Pop Shell."

        local temp_dir_popshell=$(mktemp -d)
        log_msg "info" "Clonando Pop Shell para diretório temporário: $temp_dir_popshell"
        git clone https://github.com/pop-os/shell.git "$temp_dir_popshell/popshell" || log_msg "error" "Falha ao clonar repositório Pop Shell."

        log_msg "info" "Compilando e instalando Pop Shell..."
        (cd "$temp_dir_popshell/popshell" && make local-install) || log_msg "error" "Falha ao compilar ou instalar Pop Shell."

        log_msg "info" "Removendo diretório temporário: $temp_dir_popshell"
        rm -rf "$temp_dir_popshell" || log_msg "warning" "Falha ao remover diretório temporário do Pop Shell."

        log_msg "success" "Pop Shell instalado. Pode ser necessário habilitá-lo via GNOME Extensions."
    else
        log_msg "info" "Instalação do Pop Shell ignorada."
    fi
}

# Chamar a função do Pop Shell no final
install_pop_shell

log_msg "success" "Módulo Debian Sid GNOME Minimal concluído."
EOF_DEBIAN_GNOME_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/debian_gnome_minimal.sh" || log_error "Falha ao dar permissão de execução a debian_gnome_minimal.sh"

# Arquivo: my_desktop_installer/modules/debian_kde_minimal.sh
cat << 'EOF_DEBIAN_KDE_MINIMAL_SH' > "$INSTALLER_DIR/modules/debian_kde_minimal.sh"
#!/bin/bash

# =============================================================================
# Debian Sid KDE Minimal Installation Module
# =============================================================================

# Carrega funções comuns e variáveis
source "$(dirname "$0")/../utils/common_functions.sh"

log_msg "step" "Iniciando instalação do KDE Minimal no Debian Sid"

# Backup e configuração de repositórios para Sid
log_msg "step" "Configurando repositórios para Debian Sid"
sudo cp /etc/apt/sources.list{,.bak} || log_msg "warning" "Falha ao fazer backup de sources.list."
sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://deb.debian.org/debian sid main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian sid main contrib non-free non-free-firmware
EOF
log_msg "success" "Repositórios configurados para Debian Sid."

# Atualização completa do sistema
log_msg "step" "Atualizando o sistema"
sudo apt update -y || log_msg "error" "Falha ao atualizar lista de pacotes."
sudo apt full-upgrade -y || log_msg "error" "Falha ao executar full-upgrade."

# Instalação do KDE Plasma minimal + SDDM
log_msg "step" "Instalando KDE Plasma Minimal e SDDM"
KDE_PACKAGES="plasma-desktop sddm dolphin dolphin-plugins kate ark kitty" # Adicionado kitty aqui
sudo apt install -y $KDE_PACKAGES || log_msg "error" "Falha ao instalar KDE Plasma Minimal."

log_msg "info" "Reconfigurando SDDM como padrão"
sudo dpkg-reconfigure sddm || log_msg "warning" "Falha ao reconfigurar SDDM. Pode precisar de configuração manual."

# Instalação OPICIONAL de drivers NVIDIA
if [ "$INSTALL_NVIDIA" == "y" ]; then
    log_msg "step" "Instalando drivers NVIDIA"
    NVIDIA_PACKAGES="nvidia-driver libnvidia-egl-wayland1 firmware-misc-nonfree nvidia-settings nvidia-xconfig"
    sudo apt install -y $NVIDIA_PACKAGES || log_msg "warning" "Falha ao instalar drivers NVIDIA."
    
    # Adiciona nvidia_drm.modeset=1 ao GRUB
    add_nvidia_modeset_grub
    
    log_msg "info" "Gerando novo xorg.conf (opcional, pode falhar se não houver GPU NVIDIA)"
    sudo nvidia-xconfig || true # Permite que este comando falhe
    log_msg "success" "Drivers NVIDIA instalados."
else
    log_msg "info" "Instalação de drivers NVIDIA ignorada."
fi

# Pacotes essenciais e Flatpak
log_msg "step" "Instalando pacotes essenciais e configurando Flatpak"
sudo apt install -y $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns pacotes essenciais."
setup_flatpak_common "kde" # Passa "kde" para a função de configuração do Flatpak

log_msg "success" "Módulo Debian Sid KDE Minimal concluído."
EOF_DEBIAN_KDE_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/debian_kde_minimal.sh" || log_error "Falha ao dar permissão de execução a debian_kde_minimal.sh"

# Arquivo: my_desktop_installer/modules/fedora_gnome_minimal.sh
cat << 'EOF_FEDORA_GNOME_MINIMAL_SH' > "$INSTALLER_DIR/modules/fedora_gnome_minimal.sh"
#!/bin/bash

# =============================================================================
# Fedora GNOME Minimal Installation Module
# =============================================================================

# Carrega funções comuns e variáveis
source "$(dirname "$0")/../utils/common_functions.sh"

log_msg "step" "Iniciando instalação do GNOME Minimal no Fedora"

# Otimizar DNF
log_msg "step" "Otimizando DNF"
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf > /dev/null || log_msg "warning" "Falha ao otimizar max_parallel_downloads."
echo 'fastestmirror=true' | sudo tee -a /etc/dnf/dnf.conf > /dev/null || log_msg "warning" "Falha ao otimizar fastestmirror."

# Configurar repositórios RPM Fusion
log_msg "step" "Configurando repositórios RPM Fusion"
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || log_msg "error" "Falha ao configurar RPM Fusion."
sudo dnf update --refresh -y || log_msg "warning" "Falha ao atualizar DNF após adicionar RPM Fusion."

# Instalação de drivers NVIDIA (se selecionado)
if [ "$INSTALL_NVIDIA" == "y" ]; then
    log_msg "step" "Instalando drivers NVIDIA"
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda libnvidia-cuda-libs.i686 || log_msg "warning" "Falha ao instalar drivers NVIDIA."
    
    # Adiciona nvidia_drm.modeset=1 ao GRUB (Fedora usa dracut para GRUB)
    log_msg "info" "Adicionando 'nvidia_drm.modeset=1' ao GRUB para KMS antecipado da NVIDIA."
    if grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
        log_msg "info" "'nvidia_drm.modeset=1' já está presente no GRUB."
    else
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' /etc/default/grub || log_msg "warning" "Falha ao adicionar nvidia_drm.modeset=1 ao GRUB."
    fi
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg || log_msg "warning" "Falha ao atualizar grub.cfg no Fedora."
    
    sudo dracut -f --regenerate-all || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
    log_msg "success" "Drivers NVIDIA instalados."
else
    log_msg "info" "Instalação de drivers NVIDIA ignorada."
fi

# Instalar GNOME Minimal e GDM
log_msg "step" "Instalando GNOME Minimal e GDM"
GNOME_PACKAGES="gnome-shell gdm nautilus kitty gnome-tweaks gnome-extensions-app" # Adicionado kitty e ferramentas GNOME
sudo dnf install -y $GNOME_PACKAGES || log_msg "error" "Falha ao instalar GNOME Minimal."

log_msg "info" "Habilitando GDM"
sudo systemctl enable gdm || log_msg "warning" "Falha ao habilitar GDM. Pode precisar de ativação manual."

# Pacotes essenciais e Flatpak
log_msg "step" "Instalando pacotes essenciais e configurando Flatpak"
sudo dnf install -y $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns pacotes essenciais."
setup_flatpak_common "gnome" # Passa "gnome" para a função de configuração do Flatpak

# --- Função para Pop Shell ---
install_pop_shell() {
    log_msg "step" "Instalando Pop Shell (GNOME Extension)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar o Pop Shell (extensão GNOME)? (s/N): ${NC}")" install_pop_shell_choice
    if [[ ${install_pop_shell_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando dependências para Pop Shell..."
        sudo dnf install -y make nodejs npm || log_msg "warning" "Falha ao instalar dependências para Pop Shell."

        local temp_dir_popshell=$(mktemp -d)
        log_msg "info" "Clonando Pop Shell para diretório temporário: $temp_dir_popshell"
        git clone https://github.com/pop-os/shell.git "$temp_dir_popshell/popshell" || log_msg "error" "Falha ao clonar repositório Pop Shell."

        log_msg "info" "Compilando e instalando Pop Shell..."
        (cd "$temp_dir_popshell/popshell" && make local-install) || log_msg "error" "Falha ao compilar ou instalar Pop Shell."

        log_msg "info" "Removendo diretório temporário: $temp_dir_popshell"
        rm -rf "$temp_dir_popshell" || log_msg "warning" "Falha ao remover diretório temporário do Pop Shell."

        log_msg "success" "Pop Shell instalado. Pode ser necessário habilitá-lo via GNOME Extensions."
    else
        log_msg "info" "Instalação do Pop Shell ignorada."
    fi
}

# Chamar a função do Pop Shell no final
install_pop_shell

log_msg "success" "Módulo Fedora GNOME Minimal concluído."
EOF_FEDORA_GNOME_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/fedora_gnome_minimal.sh" || log_error "Falha ao dar permissão de execução a fedora_gnome_minimal.sh"

# Arquivo: my_desktop_installer/modules/fedora_kde_minimal.sh
cat << 'EOF_FEDORA_KDE_MINIMAL_SH' > "$INSTALLER_DIR/modules/fedora_kde_minimal.sh"
#!/bin/bash

# =============================================================================
# Fedora KDE Minimal Installation Module
# =============================================================================

# Carrega funções comuns e variáveis
source "$(dirname "$0")/../utils/common_functions.sh"

log_msg "step" "Iniciando instalação do KDE Minimal no Fedora"

# Otimizar DNF
log_msg "step" "Otimizando DNF"
echo 'max_parallel_downloads=10' | sudo tee -a /etc/dnf/dnf.conf > /dev/null || log_msg "warning" "Falha ao otimizar max_parallel_downloads."
echo 'fastestmirror=true' | sudo tee -a /etc/dnf/dnf.conf > /dev/null || log_msg "warning" "Falha ao otimizar fastestmirror."

# Configurar repositórios RPM Fusion
log_msg "step" "Configurando repositórios RPM Fusion"
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || log_msg "error" "Falha ao configurar RPM Fusion."
sudo dnf update --refresh -y || log_msg "warning" "Falha ao atualizar DNF após adicionar RPM Fusion."

# Instalação de drivers NVIDIA (se selecionado)
if [ "$INSTALL_NVIDIA" == "y" ]; then
    log_msg "step" "Instalando drivers NVIDIA"
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda libnvidia-cuda-libs.i686 || log_msg "warning" "Falha ao instalar drivers NVIDIA."
    
    # Adiciona nvidia_drm.modeset=1 ao GRUB (Fedora usa dracut para GRUB)
    log_msg "info" "Adicionando 'nvidia_drm.modeset=1' ao GRUB para KMS antecipado da NVIDIA."
    if grep -q "nvidia_drm.modeset=1" /etc/default/grub; then
        log_msg "info" "'nvidia_drm.modeset=1' já está presente no GRUB."
    else
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia_drm.modeset=1"/' /etc/default/grub || log_msg "warning" "Falha ao adicionar nvidia_drm.modeset=1 ao GRUB."
    fi
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg || log_msg "warning" "Falha ao atualizar grub.cfg no Fedora."
    
    sudo dracut -f --regenerate-all || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
    log_msg "success" "Drivers NVIDIA instalados."
else
    log_msg "info" "Instalação de drivers NVIDIA ignorada."
fi

# Instalar KDE Plasma Minimal e SDDM
log_msg "step" "Instalando KDE Plasma Minimal e SDDM"
KDE_PACKAGES="plasma-desktop sddm dolphin ark kitty" # Adicionado kitty aqui
sudo dnf install -y $KDE_PACKAGES || log_msg "error" "Falha ao instalar KDE Plasma Minimal."

log_msg "info" "Habilitando SDDM"
sudo systemctl enable sddm || log_msg "warning" "Falha ao habilitar SDDM. Pode precisar de ativação manual."

# Pacotes essenciais e Flatpak
log_msg "step" "Instalando pacotes essenciais e configurando Flatpak"
sudo dnf install -y $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns pacotes essenciais."
setup_flatpak_common "kde" # Passa "kde" para a função de configuração do Flatpak

log_msg "success" "Módulo Fedora KDE Minimal concluído."
EOF_FEDORA_KDE_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/fedora_kde_minimal.sh" || log_error "Falha ao dar permissão de execução a fedora_kde_minimal.sh"

# Arquivo: my_desktop_installer/modules/opensuse_gnome_minimal.sh
cat << 'EOF_OPENSUSE_GNOME_MINIMAL_SH' > "$INSTALLER_DIR/modules/opensuse_gnome_minimal.sh"
#!/bin/bash

# =============================================================================
# openSUSE Tumbleweed GNOME Minimal Installation Module
# =============================================================================

# Carrega funções comuns e variáveis
source "$(dirname "$0")/../utils/common_functions.sh"

log_msg "step" "Iniciando instalação do GNOME Minimal no openSUSE Tumbleweed"

# Otimizar Zypper e atualizar o sistema
log_msg "step" "Otimizando Zypper e atualizando o sistema"
# Configure maximum concurrent connections for downloads
# Adds the line if it doesn't exist, or modifies it if commented out.
sudo sed -i "s/^#\\?download\\.max_concurrent_connections.*/download.max_concurrent_connections = 10/; T; a download.max_concurrent_connections = 10" /etc/zypp/zypp.conf || log_msg "warning" "Falha ao otimizar download.max_concurrent_connections."
sudo sed -i "s/^#\\?solver\\.dup_allow_downgrade.*/solver.dup_allow_downgrade = true/; T; a solver.dup_allow_downgrade = true" /etc/zypp/zypp.conf || log_msg "warning" "Falha ao configurar solver.dup_allow_downgrade."

# Refresh repositories using curl2 media handler
sudo env ZYPP_CURL2=1 zypper ref || log_msg "warning" "Falha ao atualizar repositórios."

# Perform a full distribution upgrade with preloading
sudo env ZYPP_PCK_PRELOAD=1 zypper dup -y || log_msg "error" "Falha ao atualizar o sistema (zypper dup)."

# Instalação de drivers NVIDIA (se selecionado)
if [ "$INSTALL_NVIDIA" == "y" ]; then
    log_msg "step" "Instalando drivers NVIDIA"
    # Adiciona repositórios NVIDIA
    sudo zypper addrepo --refresh https://download.nvidia.com/opensuse/tumbleweed NVIDIA || log_msg "warning" "Falha ao adicionar repositório NVIDIA."
    sudo zypper --gpg-auto-import-keys refresh || log_msg "warning" "Falha ao importar chaves GPG para repositório NVIDIA."

    # Instala os pacotes recomendados para NVIDIA (G06 para placas mais recentes)
    # Incluído 'libnvidia-egl-wayland1' para suporte a Wayland e 'nvidia-video-G06' que abrange os drivers
    NVIDIA_PACKAGES="
        nvidia-gl-G06
        nvidia-gfxG06-kmp-default
        libnvidia-egl-wayland1
        nvidia-utils-G06
        nvidia-settings
        nvidia-config
        nvidia-compute-G06
        cuda" # Adicionado cuda
    sudo env ZYPP_PCK_PRELOAD=1 zypper install --no-confirm $NVIDIA_PACKAGES || log_msg "warning" "Falha ao instalar drivers NVIDIA. Tentando pacote 'open-gpu-driver'."

    # Fallback para o driver aberto da NVIDIA se o proprietário falhar
    if [ $? -ne 0 ]; then
        log_msg "warning" "A instalação dos drivers proprietários da NVIDIA falhou. Tentando instalar 'open-gpu-driver'."
        sudo env ZYPP_PCK_PRELOAD=1 zypper install --no-confirm open-gpu-driver || log_msg "error" "Falha ao instalar 'open-gpu-driver'. Drivers NVIDIA podem não ter sido instalados corretamente."
    fi
    
    # Adiciona nvidia_drm.modeset=1 ao GRUB
    add_nvidia_modeset_grub
    
    sudo dracut -f --regenerate-all || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
    log_msg "success" "Drivers NVIDIA com suporte Wayland instalados."
else
    log_msg "info" "Instalação de drivers NVIDIA ignorada."
fi

# Instalar GNOME Minimal e GDM
log_msg "step" "Instalando GNOME Minimal e GDM"
GNOME_PACKAGES="
    gnome-shell
    gdm
    nautilus
    kitty
    gnome-tweaks
    gnome-shell-extensions
    # Removidos: gnome-backgrounds gnome-control-center e gnome-calculator para minimalismo extremo
"
sudo env ZYPP_PCK_PRELOAD=1 zypper install --no-confirm $GNOME_PACKAGES || log_msg "error" "Falha ao instalar GNOME Minimal."

log_msg "info" "Habilitando GDM"
sudo systemctl enable gdm || log_msg "warning" "Falha ao habilitar GDM. Pode precisar de ativação manual."

# Pacotes essenciais e Flatpak
log_msg "step" "Instalando pacotes essenciais e configurando Flatpak"
sudo env ZYPP_PCK_PRELOAD=1 zypper install --no-confirm $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns pacotes essenciais."
setup_flatpak_common "gnome" # Passa "gnome" para a função de configuração do Flatpak

# --- Função para Pop Shell ---
install_pop_shell() {
    log_msg "step" "Instalando Pop Shell (GNOME Extension)"
    read -r -p "$(echo -e "${YELLOW}Deseja instalar o Pop Shell (extensão GNOME)? (s/N): ${NC}")" install_pop_shell_choice
    if [[ ${install_pop_shell_choice,,} =~ ^(s|sim|y|yes)$ ]]; then
        log_msg "info" "Instalando dependências para Pop Shell..."
        # Certifique-se de que nodejs e npm estão disponíveis. No openSUSE podem ser 'nodejs' e 'npm' ou 'node-npm'
        sudo env ZYPP_PCK_PRELOAD=1 zypper install --no-confirm make nodejs npm || \
        sudo env ZYPP_PCK_PRELOAD=1 zypper install --no-confirm make nodejs nodejs-npm || \
        log_msg "warning" "Falha ao instalar dependências para Pop Shell (make, nodejs, npm)."

        local temp_dir_popshell=$(mktemp -d)
        log_msg "info" "Clonando Pop Shell para diretório temporário: $temp_dir_popshell"
        git clone https://github.com/pop-os/shell.git "$temp_dir_popshell/popshell" || log_msg "error" "Falha ao clonar repositório Pop Shell."

        log_msg "info" "Compilando e instalando Pop Shell..."
        (cd "$temp_dir_popshell/popshell" && make local-install) || log_msg "error" "Falha ao compilar ou instalar Pop Shell."

        log_msg "info" "Removendo diretório temporário: $temp_dir_popshell"
        rm -rf "$temp_dir_popshell" || log_msg "warning" "Falha ao remover diretório temporário do Pop Shell."

        log_msg "success" "Pop Shell instalado. Pode ser necessário habilitá-lo via GNOME Extensions."
    else
        log_msg "info" "Instalação do Pop Shell ignorada."
    fi
}

# Chamar a função do Pop Shell no final
install_pop_shell

log_msg "success" "Módulo openSUSE GNOME Minimal concluído."
EOF_OPENSUSE_GNOME_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/opensuse_gnome_minimal.sh" || log_error "Falha ao dar permissão de execução a opensuse_gnome_minimal.sh"

# Arquivo: my_desktop_installer/modules/opensuse_kde_minimal.sh
cat << 'EOF_OPENSUSE_KDE_MINIMAL_SH' > "$INSTALLER_DIR/modules/opensuse_kde_minimal.sh"
#!/bin/bash

# =============================================================================
# openSUSE Tumbleweed KDE Minimal Installation Module
# =============================================================================

# Carrega funções comuns e variáveis
source "$(dirname "$0")/../utils/common_functions.sh"

log_msg "step" "Iniciando instalação do KDE Minimal no openSUSE Tumbleweed"

# Otimizar Zypper e atualizar o sistema
log_msg "step" "Otimizando Zypper e atualizando o sistema"
# Configure maximum concurrent connections for downloads
# Adds the line if it doesn't exist, or modifies it if commented out.
sudo sed -i "s/^#\\?download\\.max_concurrent_connections.*/download.max_concurrent_connections = 10/; T; a download.max_concurrent_connections = 10" /etc/zypp/zypp.conf || log_msg "warning" "Falha ao otimizar download.max_concurrent_connections."
sudo sed -i "s/^#\\?solver\\.dup_allow_downgrade.*/solver.dup_allow_downgrade = true/; T; a solver.dup_allow_downgrade = true" /etc/zypp/zypp.conf || log_msg "warning" "Falha ao configurar solver.dup_allow_downgrade."

# Refresh repositories using curl2 media handler
sudo env ZYPP_CURL2=1 zypper ref || log_msg "warning" "Falha ao atualizar repositórios."

# Perform a full distribution upgrade with preloading
sudo env ZYPP_PCK_PRELOAD=1 zypper dup -y || log_msg "error" "Falha ao atualizar o sistema (zypper dup)."

# Instalação de drivers NVIDIA (se selecionado)
if [ "$INSTALL_NVIDIA" == "y" ]; then
    log_msg "step" "Instalando drivers NVIDIA"
    # Adiciona repositórios NVIDIA
    sudo zypper addrepo --refresh https://download.nvidia.com/opensuse/tumbleweed NVIDIA || log_msg "warning" "Falha ao adicionar repositório NVIDIA."
    sudo zypper --gpg-auto-import-keys refresh || log_msg "warning" "Falha ao importar chaves GPG para repositório NVIDIA."

    # Instala os pacotes recomendados para NVIDIA (G06 para placas mais recentes)
    # Incluído 'libnvidia-egl-wayland1' para suporte a Wayland e 'nvidia-video-G06' que abrange os drivers
    NVIDIA_PACKAGES="
        nvidia-gl-G06
        libnvidia-egl-wayland1
        nvidia-utils-G06
        nvidia-settings
        nvidia-config
        nvidia-compute-G06
        cuda" # Adicionado cuda
    sudo env ZYPP_PCK_PRELOAD=1 zypper install --no-confirm $NVIDIA_PACKAGES || log_msg "warning" "Falha ao instalar drivers NVIDIA. Tentando pacote 'open-gpu-driver'."

    # Fallback para o driver aberto da NVIDIA se o proprietário falhar
    if [ $? -ne 0 ]; then
        log_msg "warning" "A instalação dos drivers proprietários da NVIDIA falhou. Tentando instalar 'open-gpu-driver'."
        sudo env ZYPP_PCK_PRELOAD=1 zypper install --no-confirm open-gpu-driver || log_msg "error" "Falha ao instalar 'open-gpu-driver'. Drivers NVIDIA podem não ter sido instalados corretamente."
    fi
    
    # Adiciona nvidia_drm.modeset=1 ao GRUB
    add_nvidia_modeset_grub
    
    sudo dracut -f --regenerate-all || log_msg "warning" "Falha ao regenerar initramfs após instalação NVIDIA."
    log_msg "success" "Drivers NVIDIA com suporte Wayland instalados."
else
    log_msg "info" "Instalação de drivers NVIDIA ignorada."
fi

# Instalar KDE Plasma Minimal e SDDM
log_msg "step" "Instalando KDE Plasma Minimal e SDDM"
KDE_PACKAGES="plasma-desktop sddm dolphin ark kitty" # Adicionado kitty aqui
sudo env ZYPP_PCK_PRELOAD=1 zypper install --no-confirm $KDE_PACKAGES || log_msg "error" "Falha ao instalar KDE Plasma Minimal."

log_msg "info" "Habilitando SDDM"
sudo systemctl enable sddm || log_msg "warning" "Falha ao habilitar SDDM. Pode precisar de ativação manual."

# Pacotes essenciais e Flatpak
log_msg "step" "Instalando pacotes essenciais e configurando Flatpak"
sudo env ZYPP_PCK_PRELOAD=1 zypper install --no-confirm $COMMON_PACKAGES_CORE || log_msg "warning" "Falha ao instalar alguns pacotes essenciais."
setup_flatpak_common "kde" # Passa "kde" para a função de configuração do Flatpak

log_msg "success" "Módulo openSUSE KDE Minimal concluído."
EOF_OPENSUSE_KDE_MINIMAL_SH
chmod +x "$INSTALLER_DIR/modules/opensuse_kde_minimal.sh" || log_error "Falha ao dar permissão de execução a opensuse_kde_minimal.sh"


# Finaliza o script de criação
log_success "Todos os arquivos foram criados e preenchidos no diretório '$INSTALLER_DIR'."
log_info "Para executar o instalador, navegue até '$INSTALLER_DIR' e execute './install_desktop.sh'."
log_info "Ex: cd $INSTALLER_DIR && sudo ./install_desktop.sh"
