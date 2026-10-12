"""The only Fan+ hardware supported by this release."""

from pathlib import Path
import shutil
import subprocess


class LenovoIdeaPad15IRH10Provider:
    DMI = {
        "product_name": "83NS",
        "product_version": "IdeaPad Slim 3 15IRH10",
        "board_name": "LNVNB161216",
    }
    HELPER = Path("/usr/local/libexec/velora-fanplus")
    POLICY = Path("/usr/share/polkit-1/actions/org.velora.fanplus.policy")
    STATE = Path("/run/velora-fanplus-state")
    OLD_SERVICE = Path("/etc/systemd/system/ideapad-fan-max.service")
    OLD_SERVICE_LINK = Path("/etc/systemd/system/multi-user.target.wants/ideapad-fan-max.service")
    OLD_BINARIES = (Path("/usr/local/bin/ideapad-fan-max"), Path("/usr/local/bin/ideapad-fan-auto"))

    def __init__(self, dmi_root=Path("/sys/class/dmi/id")):
        self.dmi_root = Path(dmi_root)

    @property
    def supported(self):
        try:
            return all((self.dmi_root / key).read_text().strip() == value
                       for key, value in self.DMI.items())
        except OSError:
            return False

    def availability(self):
        if not self.supported:
            return False, "Indisponível neste dispositivo"
        if (self.OLD_SERVICE.exists() or self.OLD_SERVICE_LINK.exists()
                or self.OLD_SERVICE_LINK.is_symlink()
                or any(path.exists() for path in self.OLD_BINARIES)):
            return False, "Remova o serviço antigo de fan máxima"
        if not Path("/usr/bin/ec_probe").is_file():
            return False, "ec_probe não está instalado"
        if not Path("/proc/acpi/call").exists():
            if not shutil.which("modprobe") or not shutil.which("modinfo") or subprocess.run(
                    ["modinfo", "acpi_call"], capture_output=True, check=False
                    ).returncode != 0:
                return False, "acpi_call não está disponível"
        if not self.HELPER.is_file() or not self.POLICY.is_file():
            return False, "Helper Fan+ ainda não foi instalado"
        if not shutil.which("pkexec"):
            return False, "Polkit não está disponível"
        return True, ""
