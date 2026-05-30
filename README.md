# Velora Shell

Projeto Quickshell da Velora.

## Integrações pywal16

Quando um wallpaper é aplicado por `Velora Shell/scripts/velora-wallpaper-apply`, a paleta `~/.cache/wal/colors.json` é reaproveitada para:

- Velora Shell (`themes/pywal16.json`);
- mouse/cursor, Dolphin e Thunar (`velora-desktop-theme.py`);
- Zen Browser (`velora-zen-theme.py`);
- Code / VS Code / Code - OSS (`velora-vscode-theme.py`);
- Obsidian (`velora-obsidian-theme.py`);
- Spotify via Spicetify (`velora-spotify-theme.py`);
- Discord / BetterDiscord (`velora-discord-theme.py`).

O tema de mouse gera um Hyprcursor local chamado `VeloraPywalCursor`, aplica ao Hyprland com `hyprctl setcursor` e deixa fallback Xcursor via Adwaita para toolkits que ainda não leem Hyprcursor. Dolphin recebe um esquema KDE local `VeloraPywal16`; Thunar recebe um tema GTK local `VeloraPywal16` em `~/.local/share/themes`.

O Obsidian recebe um snippet CSS chamado `velora-pywal16` no vault `~/Documentos/Obsidian Vault`. O gerador copia o wallpaper atual para dentro de `.obsidian/velora-wallpaper/`, ativa o snippet em `.obsidian/appearance.json` e usa painéis translúcidos com a paleta pywal16 para manter o fundo visível sem perder legibilidade.

O Spotify Flatpak usa tema por CSS do usuário com `replace_colors=0`, porque o diretório `/var/lib/flatpak/.../spotify` é somente leitura. Quando o Spotify está aberto, o gerador pode reiniciar o app via Flatpak/systemd para carregar a nova paleta sem manter watcher persistente em segundo plano. Esse comportamento é controlado nas Settings da Velora pelo botão `Spotify auto ON/OFF`; em `OFF`, o tema é gerado, mas o Spotify só muda na próxima abertura.
