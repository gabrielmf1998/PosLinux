# shellcheck shell=bash
# Ferramentas de desenvolvimento: Git, Python, Node.js, Docker e VS Code.

# ==========================================================
# Ferramentas Dev
# ==========================================================

install_dev_tools() {
    local choice

    choice=$(whiptail --title "Ferramentas Dev" \
        --checklist "Selecione as ferramentas:" \
        22 78 10 \
        "git" "Git" ON \
        "docker" "Docker" OFF \
        "nodejs" "Node.js" OFF \
        "python" "Python/pip/venv" ON \
        "vscode" "Visual Studio Code Flatpak" OFF \
        3>&1 1>&2 2>&3)

    [[ -z "$choice" ]] && return

    if echo "$choice" | grep -q "git"; then
        run_pkg_install "git"
    fi

    if echo "$choice" | grep -q "docker"; then
        install_docker_basic
    fi

    if echo "$choice" | grep -q "nodejs"; then
        install_nodejs
    fi

    if echo "$choice" | grep -q "python"; then
        install_python_tools
    fi

    if echo "$choice" | grep -q "vscode"; then
        install_flatpak_app "com.visualstudio.code"
    fi
}

install_python_tools() {
    case "$PKG_MANAGER" in
        apt)
            run_pkg_install "python3 python3-pip python3-venv"
            ;;
        dnf|yum)
            run_pkg_install "python3 python3-pip"
            ;;
        pacman)
            run_pkg_install "python python-pip"
            ;;
        zypper)
            run_pkg_install "python3 python3-pip"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

install_nodejs() {
    case "$PKG_MANAGER" in
        apt)
            run_pkg_install "nodejs npm"
            ;;
        dnf|yum)
            run_pkg_install "nodejs npm"
            ;;
        pacman)
            run_pkg_install "nodejs npm"
            ;;
        zypper)
            run_pkg_install "nodejs npm"
            ;;
        *)
            show_msg "Distro não suportada."
            ;;
    esac
}

install_docker_basic() {
    case "$PKG_MANAGER" in
        apt)
            run_cmd "sudo apt update && if apt-cache show docker-compose-v2 >/dev/null 2>&1; then sudo apt install -y docker.io docker-compose-v2; elif apt-cache show docker-compose >/dev/null 2>&1; then sudo apt install -y docker.io docker-compose; else sudo apt install -y docker.io; fi" || return
            ;;
        dnf)
            run_pkg_install "moby-engine docker-compose" || return
            ;;
        yum)
            show_msg "Em RHEL/CentOS antigos, Docker/Compose pode exigir repositórios extras como EPEL/CRB conforme a versão."
            run_pkg_install "moby-engine docker-compose" || return
            ;;
        pacman)
            run_pkg_install "docker docker-compose" || return
            ;;
        zypper)
            run_cmd "sudo zypper install -y docker docker-compose || { echo 'docker-compose não disponível nos repositórios desta versão. Tentando instalar somente docker.'; sudo zypper install -y docker; }" || return
            ;;
        *)
            show_msg "Distro não suportada."
            return
            ;;
    esac

    run_cmd "sudo systemctl enable --now docker" || return
    run_cmd "sudo usermod -aG docker $USER"
    show_msg "Docker instalado. Faça logout/login para aplicar o grupo docker ao usuário."
}
