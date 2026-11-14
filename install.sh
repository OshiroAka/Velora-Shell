#!/usr/bin/env bash
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export PYTHONDONTWRITEBYTECODE=1
# Bootstrap must work before Python is installed. Never invoke AUR builds as root.
if ! command -v python3 >/dev/null 2>&1; then
    install_deps=0
    non_interactive=0
    for argument in "$@"; do
        case "$argument" in
            --dry-run|--help|-h)
                printf '%s\n' 'INSTALLER: BLOCKED_MISSING_DEPENDENCIES' \
                    'Python ausente. Plano Arch: pacman -Syu --needed python sudo; depois dependências, Hyprland, yay/paru, Flatpak e backends.' \
                    'Execute ./install.sh --install-deps para preparar. --dry-run não instala nem grava.'
                exit 1 ;;
            --install-deps) install_deps=1 ;;
            --non-interactive) non_interactive=1 ;;
        esac
    done
    if ! command -v pacman >/dev/null 2>&1; then
        printf '%s\n' 'INSTALLER: BLOCKED_MISSING_DEPENDENCIES' 'Bootstrap automático exige Arch/derivado com pacman; instale Python >= 3.12 na sua distribuição.' >&2
        exit 1
    fi
    if (( EUID == 0 )); then
        printf '%s\n' 'Execute como usuário normal com sudo configurado, sem sudo ./install.sh.' >&2
        exit 1
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        printf '%s\n' 'sudo ausente. Como root: pacman -Syu --needed sudo python; configure sudoers e volte ao usuário normal.' >&2
        exit 1
    fi
    if (( ! install_deps )); then
        if (( non_interactive )) || [[ ! -t 0 ]]; then
            printf '%s\n' 'Python ausente. Use --install-deps para autorizar o bootstrap.' >&2
            exit 1
        fi
        read -r -p 'Atualizar Arch e instalar Python para continuar? [s/N] ' answer
        case "$answer" in s|S|sim|y|Y|yes) ;; *) exit 1 ;; esac
    fi
    sudo pacman -Syu --needed --noconfirm python
fi
exec python3 "$project_dir/scripts/install-session" "$@"
