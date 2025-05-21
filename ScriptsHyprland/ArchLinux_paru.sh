
echo -e "${CYAN}\n===== INSTALANDO PARU (AUR HELPER) =====${NC}"
temp_dir=$(mktemp -d)
echo "Usando diretório temporário: $temp_dir"
pacman -S --needed base-devel git --noconfirm
git clone https://aur.archlinux.org/paru.git "$temp_dir/paru"
(cd "$temp_dir/paru" && makepkg -si --noconfirm)
rm -rf "$temp_dir"

