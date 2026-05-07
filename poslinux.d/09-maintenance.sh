# shellcheck shell=bash
# Manutenção: codecs, limpeza e logs.

# ==========================================================
# Codecs
# ==========================================================

install_codecs() {
    local rpm_manager="$PKG_MANAGER"

    case "$PKG_MANAGER" in
        apt)
            run_cmd "sudo apt update && if apt-cache show ubuntu-restricted-extras >/dev/null 2>&1; then sudo apt install -y ubuntu-restricted-extras ffmpeg; else sudo apt install -y ffmpeg gstreamer1.0-libav gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly; fi"
            ;;
        dnf)
            if is_fedora_like && confirm_action "Deseja instalar codecs Fedora com suporte ao RPM Fusion?\n\nEsta opção pode habilitar RPM Fusion para instalar codecs mais completos."; then
                enable_fedora_rpmfusion || return
                if run_cmd "sudo dnf install -y ffmpeg-free gstreamer1-plugins-good gstreamer1-plugins-good-extras gstreamer1-plugins-bad-free gstreamer1-plugins-bad-free-extras gstreamer1-plugins-ugly-free gstreamer1-plugin-libav && { sudo dnf group install -y Multimedia || true; }"; then
                    show_msg "Codecs Fedora instalados.\n\nO Fedora mantém alguns codecs fora dos repositórios padrão por política/licenças. RPM Fusion melhora essa cobertura."
                fi
            elif run_cmd "sudo dnf install -y ffmpeg-free gstreamer1-plugins-good gstreamer1-plugins-good-extras gstreamer1-plugins-bad-free gstreamer1-plugins-bad-free-extras gstreamer1-plugins-ugly-free gstreamer1-plugin-libav || { echo 'Alguns pacotes extras de codec não estão disponíveis nesta versão. Tentando conjunto básico.'; sudo dnf install -y ffmpeg-free gstreamer1-plugins-good gstreamer1-plugins-bad-free; }"; then
                show_msg "Codecs livres instalados quando disponíveis.\n\nCodecs completos no Fedora podem exigir RPM Fusion."
            fi
            ;;
        yum)
            if run_cmd "sudo $rpm_manager install -y ffmpeg-free gstreamer1-plugins-good gstreamer1-plugins-good-extras gstreamer1-plugins-bad-free gstreamer1-plugins-bad-free-extras || { echo 'Alguns pacotes extras de codec não estão disponíveis nesta versão. Tentando conjunto básico.'; sudo $rpm_manager install -y ffmpeg-free gstreamer1-plugins-good gstreamer1-plugins-bad-free; }"; then
                show_msg "Codecs livres instalados quando disponíveis.\n\nCodecs completos em RHEL/CentOS podem exigir RPM Fusion/EPEL ou repositório equivalente."
            fi
            ;;
        pacman)
            run_pkg_install "ffmpeg gst-libav gst-plugins-good gst-plugins-bad gst-plugins-ugly"
            ;;
        zypper)
            if run_cmd "sudo zypper install -y ffmpeg gstreamer-plugins-good gstreamer-plugins-bad gstreamer-plugins-ugly || { echo 'Alguns pacotes extras de codec não estão disponíveis nesta versão. Tentando conjunto básico.'; sudo zypper install -y ffmpeg gstreamer-plugins-good; }"; then
                show_msg "Codecs livres instalados quando disponíveis.\n\nCodecs completos no openSUSE podem exigir o repositório Packman, conforme sua versão."
            fi
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

# ==========================================================
# Limpeza
# ==========================================================

clean_system() {
    case "$PKG_MANAGER" in
        apt)
            run_cmd "sudo apt autoremove -y && sudo apt autoclean"
            ;;
        dnf)
            run_cmd "sudo dnf autoremove -y && sudo dnf clean all"
            ;;
        yum)
            run_cmd "sudo yum clean all"
            ;;
        pacman)
            run_cmd "sudo pacman -Sc"
            ;;
        zypper)
            run_cmd "sudo zypper clean --all"
            ;;
        *)
            show_msg "Gerenciador de pacotes não suportado."
            ;;
    esac
}

# ==========================================================
# Logs
# ==========================================================

view_log() {
    ensure_log_dir || {
        show_msg "Não foi possível criar a pasta de logs."
        return 1
    }

    if [[ ! -f "$LOG_FILE" ]]; then
        echo "Log ainda não existe." > "$LOG_FILE"
    fi

    whiptail --title "Log de Execução" --textbox "$LOG_FILE" 25 90
}

clear_log() {
    if confirm_action "Deseja limpar o log?\n\n$LOG_FILE"; then
        ensure_log_dir || {
            show_msg "Não foi possível criar a pasta de logs."
            return 1
        }

        : > "$LOG_FILE"
        show_msg "Log limpo."
    fi
}
