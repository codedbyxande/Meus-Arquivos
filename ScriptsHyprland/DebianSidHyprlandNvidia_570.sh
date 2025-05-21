#!/usr/bin/env bash
# Instalação com Hyprland e driver NVIDIA específico (570.153.02) no Debian/Ubuntu
# Baseado em script para "Instalação Minimalista do KDE" mas focado em Hyprland.

# Cores para o terminal
GREEN='\033[1;32m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

# --- Configurações do Driver NVIDIA ---
NVIDIA_DRIVER_URL="https://us.download.nvidia.com/XFree86/Linux-x86_64/570.153.02/NVIDIA-Linux-x86_64-570.153.02.run"
NVIDIA_DRIVER_FILENAME=$(basename "${NVIDIA_DRIVER_URL}")
NVIDIA_DRIVER_VERSION_FROM_URL=$(echo "$NVIDIA_DRIVER_FILENAME" | sed -n 's/NVIDIA-Linux-x86_64-\([0-9.]*\)\.run/\1/p')
DOWNLOAD_DIR="/tmp/nvidia_driver_download_$$" # Usar PID para diretório temporário único

# Função de limpeza para o driver baixado
cleanup_nvidia_download() {
    if [ -d "${DOWNLOAD_DIR}" ]; then
        echo -e "${CYAN}Limpando arquivos de download do driver NVIDIA...${NC}"
        sudo rm -rf "${DOWNLOAD_DIR}"
    fi
}
# Registrar a função de limpeza para ser chamada na saída do script
trap cleanup_nvidia_download EXIT

echo -e "${CYAN}\n===== CONFIGURANDO REPOSITÓRIOS (DEBIAN SID) =====${NC}"
echo -e "${YELLOW}Atenção: Configurando para usar os repositórios Debian Sid (unstable).${NC}"
echo -e "${YELLOW}Faça backup de /etc/apt/sources.list se desejar reverter.${NC}"
sudo cp /etc/apt/sources.list{,.bak_$(date +%F_%T)} # Backup with timestamp
sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://deb.debian.org/debian sid main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian sid main contrib non-free non-free-firmware
EOF

echo -e "${CYAN}\n===== ATUALIZANDO O SISTEMA =====${NC}"
sudo apt update && sudo apt full-upgrade -y

echo -e "${CYAN}\n===== INSTALANDO VISUAL STUDIO CODE =====${NC}"
sudo apt-get install -y wget gpg apt-transport-https
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo mkdir -p /etc/apt/keyrings # Ensure the directory exists
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo apt update
sudo apt install -y code

echo -e "${CYAN}\n===== INSTALANDO HYPRLAND, UTILITÁRIOS E NAUTILUS =====${NC}"
sudo apt install -y hyprland fuzzel kitty git flatpak
sudo apt install -y nautilus --no-install-recommends

read -r -p "$(echo -e "${YELLOW}Você possui uma GPU NVIDIA e deseja instalar os drivers v${NVIDIA_DRIVER_VERSION_FROM_URL} (baixando de ${NVIDIA_DRIVER_URL})? [s/N]: ${NC}")" nvidia_choice

if [[ ${nvidia_choice,,} =~ ^(s|sim)$ ]]; then
    echo -e "${CYAN}\n===== PREPARANDO PARA INSTALAÇÃO DO DRIVER NVIDIA v${NVIDIA_DRIVER_VERSION_FROM_URL} =====${NC}"
    
    nvidia_driver_path="" # Inicializa vazio

    echo -e "${CYAN}Baixando o driver NVIDIA ${NVIDIA_DRIVER_VERSION_FROM_URL} de ${NVIDIA_DRIVER_URL}...${NC}"
    mkdir -p "${DOWNLOAD_DIR}"
    if wget --progress=bar:force:noscroll -P "${DOWNLOAD_DIR}" "${NVIDIA_DRIVER_URL}"; then
        nvidia_driver_path="${DOWNLOAD_DIR}/${NVIDIA_DRIVER_FILENAME}"
        echo -e "${GREEN}Driver baixado com sucesso para: ${nvidia_driver_path}${NC}"
    else
        echo -e "${RED}Falha ao baixar o driver NVIDIA. Verifique a URL e sua conexão com a internet.${NC}"
        echo -e "${RED}URL: ${NVIDIA_DRIVER_URL}${NC}"
        read -r -p "$(echo -e "${YELLOW}Deseja pular a instalação do driver NVIDIA e continuar com o restante do script? [S/n]: ${NC}")" skip_on_fail
        if [[ ${skip_on_fail,,} == "n" ]]; then
            echo -e "${RED}Saindo do script.${NC}"
            exit 1
        fi
        # nvidia_driver_path permanecerá vazio, pulando a instalação
    fi

    if [[ -n "${nvidia_driver_path}" && -f "${nvidia_driver_path}" ]]; then
        echo -e "${CYAN}\n===== INSTALANDO DEPENDÊNCIAS PARA O DRIVER NVIDIA =====${NC}"
        sudo apt install -y build-essential pkg-config libglvnd-dev libgl1-mesa-dev dkms linux-headers-amd64 gcc make

        echo -e "${CYAN}\n===== DESABILITANDO DRIVER NOUVEAU (BLACKLIST) =====${NC}"
        echo -e "${YELLOW}Isso criará um arquivo para colocar o driver 'nouveau' na blacklist.${NC}"
        sudo tee /etc/modprobe.d/blacklist-nouveau.conf > /dev/null <<EOF
blacklist nouveau
options nouveau modeset=0
EOF
        echo -e "${YELLOW}Atualizando initramfs... Isso pode levar um momento.${NC}"
        sudo update-initramfs -u

        echo -e "\n${YELLOW}********************************************************************************${NC}"
        echo -e "${YELLOW}* ${RED}RECOMENDAÇÃO CRÍTICA:${NC} ${YELLOW}                                                    *${NC}"
        echo -e "${YELLOW}* Uma REINICIALIZAÇÃO é ALTAMENTE RECOMENDADA neste ponto para garantir        *${NC}"
        echo -e "${YELLOW}* que o driver 'nouveau' seja completamente desabilitado antes de instalar o   *${NC}"
        echo -e "${YELLOW}* driver NVIDIA.                                                               *${NC}"
        echo -e "${YELLOW}********************************************************************************${NC}"
        read -r -p "$(echo -e "${YELLOW}Deseja REINICIAR O SISTEMA AGORA? (Altamente Recomendado: S) [S/n]: ${NC}")" reboot_now_choice
        
        if [[ -z "${reboot_now_choice}" || ${reboot_now_choice,,} == "s" || ${reboot_now_choice,,} == "sim" ]]; then
            echo -e "${GREEN}O sistema será reiniciado. Após reiniciar, você precisará executar o instalador NVIDIA manualmente.${NC}"
            echo -e "${GREEN}O driver baixado está em: ${nvidia_driver_path}${NC}"
            echo -e "${GREEN}Instruções para instalação manual do driver NVIDIA após a reinicialização:${NC}"
            echo -e "${GREEN}  1. Abra um terminal.${NC}"
            echo -e "${GREEN}  2. Torne o instalador executável: sudo chmod +x \"${nvidia_driver_path}\"${NC}"
            echo -e "${GREEN}  3. Execute o instalador: sudo \"${nvidia_driver_path}\" --accept-license --dkms --no-cc-version-check --no-install-compat32-libs --ui=none ${NC}"
            echo -e "${YELLOW}Saindo do script para permitir a reinicialização. Se o sistema não reiniciar automaticamente, execute 'sudo reboot'.${NC}"
            # A limpeza do driver baixado será feita pelo trap EXIT, mas não se o usuário reiniciar manualmente.
            # Para garantir, podemos remover aqui se ele não for mais necessário.
            # No entanto, é melhor deixar para o usuário caso ele precise do arquivo após o reboot.
            exit 0 
        else
            echo -e "${YELLOW}Continuando sem reiniciar AGORA. A instalação do driver NVIDIA PODE FALHAR se 'nouveau' ainda estiver ativo.${NC}"
            if lsmod | grep -q nouveau; then
                echo -e "${YELLOW}Driver 'nouveau' detectado. Tentando descarregar...${NC}"
                if sudo modprobe -rf nouveau; then 
                    echo -e "${GREEN}'nouveau' descarregado (ou não estava carregado).${NC}"
                else
                    echo -e "${RED}Falha ao descarregar 'nouveau'. A instalação do driver NVIDIA provavelmente falhará.${NC}"
                    echo -e "${RED}É ALTAMENTE RECOMENDADO REINICIAR e seguir as instruções manuais fornecidas anteriormente.${NC}"
                fi
            else
                echo -e "${GREEN}Driver 'nouveau' não parece estar carregado. Prosseguindo com a instalação.${NC}"
            fi
        fi
        
        echo -e "${CYAN}\n===== INSTALANDO DRIVER NVIDIA DO ARQUIVO BAIXADO (${NVIDIA_DRIVER_FILENAME}) =====${NC}"
        sudo chmod +x "${nvidia_driver_path}"
        NVIDIA_INSTALL_CMD="sudo \"${nvidia_driver_path}\" --accept-license --dkms --no-cc-version-check --no-install-compat32-libs --ui=none"
        echo -e "${YELLOW}Executando o instalador NVIDIA com o comando:${NC}"
        echo -e "${CYAN}${NVIDIA_INSTALL_CMD}${NC}"
        echo -e "${YELLOW}Isso pode levar algum tempo. Por favor, aguarde e siga quaisquer instruções na tela se aparecerem.${NC}"
        
        if ${NVIDIA_INSTALL_CMD}; then 
            echo -e "${GREEN}\nInstalação do driver NVIDIA parece ter sido concluída com sucesso.${NC}"
            echo -e "${YELLOW}UMA REINICIALIZAÇÃO FINAL É ABSOLUTAMENTE NECESSÁRIA para que o novo driver entre em vigor.${NC}"
        else
            echo -e "${RED}\nA instalação do driver NVIDIA falhou, foi interrompida ou retornou um erro.${NC}"
            echo -e "${YELLOW}Verifique a saída acima para mensagens de erro.${NC}"
            echo -e "${YELLOW}Você pode precisar executar o instalador manualmente com mais opções ou verificar os logs.${NC}"
            echo -e "${YELLOW}Comando sugerido para tentativa manual: sudo \"${nvidia_driver_path}\" (para ver a interface TUI do instalador)${NC}"
            echo -e "${YELLOW}Logs do instalador NVIDIA geralmente são encontrados em: /var/log/nvidia-installer.log${NC}"
        fi
    elif [[ -n "${nvidia_driver_path}" && ! -f "${nvidia_driver_path}" ]]; then
        # Este caso ocorre se o download falhou e o usuário optou por continuar
        echo -e "${YELLOW}\nDownload do driver NVIDIA falhou ou foi pulado.${NC}"
        echo -e "${YELLOW}Instalação do driver NVIDIA pulada.${NC}"
    else
        # Este caso ocorre se nvidia_driver_path nunca foi preenchido (download falhou e usuário pulou)
        echo -e "${YELLOW}\nInstalação do driver NVIDIA pulada devido a falha no download ou escolha do usuário.${NC}"
    fi
else
    echo -e "${CYAN}\nInstalação do driver NVIDIA (v${NVIDIA_DRIVER_VERSION_FROM_URL}) pulada conforme sua escolha.${NC}"
    echo -e "${YELLOW}Se você possui uma GPU NVIDIA e não instalou drivers, o desempenho gráfico pode ser limitado ou podem ocorrer problemas com Hyprland.${NC}"
    echo -e "${YELLOW}Você pode instalar os drivers NVIDIA recomendados do repositório Debian com:${NC}"
    echo -e "${YELLOW}sudo apt install nvidia-driver libnvidia-egl-wayland1 firmware-misc-nonfree linux-headers-\$(uname -r)${NC}"
fi

echo -e "${CYAN}\n===== CONFIGURANDO FLATPAK E APPS =====${NC}"
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    com.github.tchx84.Flatseal \
    app.zen_browser.zen \
    dev.vencord.Vesktop \
    org.nickvision.tubeconverter

echo -e "${GREEN}\n✅ Script de instalação (parcialmente) concluído! ${NC}"
echo -e "${YELLOW}LEMBRE-SE: Uma reinicialização é provavelmente necessária, especialmente se os drivers NVIDIA foram instalados ou atualizados.${NC}"
echo -e "${YELLOW}Após reiniciar, você poderá precisar configurar Hyprland (configurar ~/.config/hypr/hyprland.conf) e outros aplicativos.${NC}"
echo -e "${YELLOW}Verifique se há mensagens de erro acima para quaisquer problemas que possam ter ocorrido.${NC}"

# A função cleanup_nvidia_download será chamada automaticamente ao sair do script.
