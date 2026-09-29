#!/usr/bin/env python3
"""Root-owned, polkit-scoped Fan+ helper. Install outside the writable checkout."""

import json
from pathlib import Path
import subprocess
import sys

DMI_ROOT = Path("/sys/class/dmi/id")
EXPECTED = {"product_name": "83NS", "product_version": "IdeaPad Slim 3 15IRH10",
            "board_name": "LNVNB161216"}
STATE = Path("/run/velora-fanplus-state")
OLD_SERVICE = Path("/etc/systemd/system/ideapad-fan-max.service")
OLD_BINARIES = (Path("/usr/local/bin/ideapad-fan-max"), Path("/usr/local/bin/ideapad-fan-auto"))
METHOD = r"\_SB.PC00.LPCB.EC0.MBEY"
ON = ["/usr/bin/ec_probe", "acpi_call", METHOD, "0xEF", "0x61", "0x3F"]
OFF = ["/usr/bin/ec_probe", "acpi_call", METHOD, "0xEF", "0x63", "0x03"]


def emit(state, error=""):
    print(json.dumps({"state": state, "supported": state != "unsupported",
                      "enabled": state == "active", "busy": False,
                      "error": error, "targetRpm": 6300}))
    return 0 if not error else 1


def main(args):
    if len(args) != 1 or args[0] not in ("on", "off", "status"):
        return emit("error", "Operação Fan+ inválida")
    try:
        if any((DMI_ROOT / key).read_text().strip() != value
               for key, value in EXPECTED.items()):
            return emit("unsupported", "Indisponível neste dispositivo")
    except OSError:
        return emit("unsupported", "DMI indisponível")
    try:
        active = STATE.read_text().strip() == "active"
    except FileNotFoundError:
        active = False
    except OSError as exc:
        return emit("error", str(exc))
    if args[0] == "status":
        return emit("active" if active else "off")
    if args[0] == "on" and (OLD_SERVICE.exists() or any(path.exists() for path in OLD_BINARIES)):
        return emit("error", "Remova o serviço antigo de fan máxima")
    if not Path("/proc/acpi/call").exists():
        try:
            modprobe = subprocess.run(["/usr/bin/modprobe", "acpi_call"],
                                      capture_output=True, text=True, check=False, timeout=10)
        except (OSError, subprocess.TimeoutExpired):
            return emit("error", "Não foi possível carregar acpi_call")
        if modprobe.returncode != 0 or not Path("/proc/acpi/call").exists():
            return emit("error", "Não foi possível carregar acpi_call")
    try:
        proc = subprocess.run(ON if args[0] == "on" else OFF,
                              capture_output=True, text=True, check=False, timeout=10)
    except (OSError, subprocess.TimeoutExpired) as exc:
        return emit("error", str(exc))
    if proc.returncode != 0 or proc.stdout.strip().lower() != "0xac":
        return emit("error", "O EC não confirmou o comando (esperado 0xac)")
    next_state = "active" if args[0] == "on" else "off"
    try:
        STATE.write_text(next_state + "\n")
        STATE.chmod(0o644)
    except OSError as exc:
        return emit("error", "Comando confirmado, mas estado não salvo: " + str(exc))
    return emit(next_state)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
