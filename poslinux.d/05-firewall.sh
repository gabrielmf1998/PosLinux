# shellcheck shell=bash
# Firewall universal: UFW para apt/pacman e firewalld para dnf/yum/zypper.

# ==========================================================
# Firewall
# ==========================================================

install_firewall() {
    case "$PKG_MANAGER" in
        apt|pacman)
            run_pkg_install "ufw"
            ;;
        dnf|yum|zypper)
            run_pkg_install "firewalld"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

enable_firewall() {
    case "$PKG_MANAGER" in
        apt|pacman)
            run_cmd "sudo ufw enable"
            ;;
        dnf|yum|zypper)
            run_cmd "sudo systemctl enable --now firewalld"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

firewall_allow_ssh() {
    case "$PKG_MANAGER" in
        apt|pacman)
            run_cmd "sudo ufw allow ssh"
            ;;
        dnf|yum|zypper)
            run_cmd "sudo firewall-cmd --permanent --add-service=ssh && sudo firewall-cmd --reload"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

firewall_status() {
    case "$PKG_MANAGER" in
        apt|pacman)
            run_cmd_show_output "sudo ufw status verbose" "Status do Firewall"
            ;;
        dnf|yum|zypper)
            run_cmd_show_output "sudo firewall-cmd --state; echo; sudo firewall-cmd --list-all" "Status do Firewall"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}
