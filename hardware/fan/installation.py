"""Optional Fan+ provisioning from the CLI installer, never from QML."""

import os
from pathlib import Path
import platform
import re
import shlex
import shutil
import subprocess
import sys

from .lenovo_ideapad_15irh10 import LenovoIdeaPad15IRH10Provider as Provider


def run(command):
    try:
        return subprocess.run(command, capture_output=True, text=True, timeout=15, check=False)
    except (OSError, subprocess.TimeoutExpired) as error:
        return subprocess.CompletedProcess(command, 1, "", str(error))


def arch_system():
    try:
        release = platform.freedesktop_os_release()
        return bool({release.get("ID", ""), *release.get("ID_LIKE", "").split()} & {"arch", "cachyos"})
    except OSError:
        return False


def dependency_plan():
    """Check actual binaries/module; never guess another kernel's headers."""
    issues, packages = [], []
    for binary, package in (("pkexec", "polkit"), ("modprobe", "kmod"), ("modinfo", "kmod")):
        if not os.access("/usr/bin/" + binary, os.X_OK):
            issues.append(binary + " ausente")
            packages.append(package)
    ec_missing = not os.access("/usr/bin/ec_probe", os.X_OK)
    if ec_missing:
        issues.append("ec_probe ausente (fornecido pelo nbfc-linux usado neste notebook)")
    kernel = platform.release()
    if run(["/usr/bin/modinfo", "-k", kernel, "acpi_call"]).returncode != 0:
        issues.append("acpi_call indisponível para o kernel " + kernel)
        packages.extend(["dkms", "acpi_call-dkms"])
        try:
            pkgbase = (Path("/usr/lib/modules") / kernel / "pkgbase").read_text().strip()
        except OSError:
            pkgbase = ""
        if re.fullmatch(r"linux(?:-[a-zA-Z0-9]+)*", pkgbase):
            packages.append(pkgbase + "-headers")
        else:
            issues.append("Instale os headers correspondentes ao kernel em execução; pkgbase não identificado")
    return issues, list(dict.fromkeys(packages)), ec_missing


def privileged(command):
    if os.geteuid() != 0:
        if not shutil.which("sudo"):
            print("Fan+: sudo indisponível. Execute como administrador: " + shlex.join(command))
            return False
        # An unattended shell install must never hang waiting for a password.
        command = ["sudo", *([] if sys.stdin.isatty() else ["-n"]), *command]
    print("Fan+: " + shlex.join(command), flush=True)
    try:
        return subprocess.run(command, check=False).returncode == 0
    except OSError as error:
        print("Fan+: " + str(error))
        return False


def installed_copy(source, target, mode):
    try:
        info = target.lstat()
        return (not target.is_symlink() and target.is_file() and info.st_uid == 0
                and info.st_gid == 0 and info.st_mode & 0o7777 == mode
                and source.read_bytes() == target.read_bytes())
    except OSError:
        return False


def setup(root, *, check_only=False, install_dependencies=False, provider=None):
    provider = provider or Provider()
    if not provider.supported:
        print("Fan+: indisponível neste dispositivo; instalação ignorada.")
        return True
    legacy = [provider.OLD_SERVICE, provider.OLD_SERVICE_LINK, *provider.OLD_BINARIES]
    if any(path.exists() or path.is_symlink() for path in legacy):
        print("Fan+: instalação pendente. Retorne a ventoinha para AUTO e remova o serviço ideapad-fan-max antigo primeiro.")
        return False
    issues, packages, ec_missing = dependency_plan()
    if issues:
        print("Fan+: dependências pendentes:\n- " + "\n- ".join(issues))
        arch = arch_system()
        if packages and arch:
            command = ["/usr/bin/pacman", "-S", "--needed", *packages]
            print("Pacotes dos repositórios: sudo " + shlex.join(command))
            if install_dependencies and not check_only:
                if not privileged(command):
                    print("Fan+: instalação dos pacotes não concluída.")
                    return False
        elif packages:
            print("Instale acpi_call para o kernel atual, headers correspondentes, kmod e Polkit pelo gerenciador da distribuição.")
        if ec_missing:
            print("ec_probe: este notebook foi validado com nbfc-linux-git. Instale esse pacote pela fonte que você revisou; ele pode não existir nos repositórios do pacman. Não habilite o serviço NBFC.")
            if arch:
                aur_helper = shutil.which("paru") or shutil.which("yay")
                if aur_helper:
                    print("Instalação manual, como usuário normal, revisando o pacote: "
                          + shlex.join([aur_helper, "-S", "--needed", "nbfc-linux-git"]))
        issues, _, _ = dependency_plan()
        if issues:
            print("Fan+: indisponível até resolver as dependências. Execute novamente scripts/install-fanplus; use --install-deps para os pacotes dos repositórios Arch/CachyOS.")
            return False
    files = [
        (root / "hardware/fan/privileged_helper.py", provider.HELPER, 0o755),
        (root / "hardware/fan/org.velora.fanplus.policy", provider.POLICY, 0o644),
    ]
    for source, destination, mode in files:
        if installed_copy(source, destination, mode):
            continue
        command = ["/usr/bin/install", "-D", "-o", "root", "-g", "root", "-m", format(mode, "04o"), str(source), str(destination)]
        if check_only:
            print("Fan+: arquivo ausente, desatualizado ou com permissões incorretas: " + str(destination))
            print("Instalar: sudo " + shlex.join(command))
            return False
        if not privileged(command) or not installed_copy(source, destination, mode):
            print("Fan+: helper/política pendentes. Execute: sudo " + shlex.join(command))
            return False
    loaded = Path("/proc/acpi/call").exists()
    print("Fan+: dependências, helper e política conferidos. "
          + ("acpi_call carregado." if loaded else "acpi_call será carregado pelo helper quando solicitado."))
    print("Fan+: nenhuma alteração no controle da ventoinha, no perfil de energia ou no boot.")
    return True
