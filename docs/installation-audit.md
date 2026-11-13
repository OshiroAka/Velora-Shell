# Instalação limpa — revisão de 12/11/2026

O caminho automático é para Arch Linux e derivados com pacman. Um Linux recém
instalado precisa de rede funcionando, usuário normal e sudo autorizado. O
instalador não provisiona particionamento, drivers de GPU, bootloader nem sudoers.
Não é um instalador universal de distribuições. Git também é necessário para
clonar o projeto antes de executar install.sh; é incluído na preparação posterior.

## Problemas encontrados e correções

| Situação inicial | Comportamento anterior | Comportamento revisado |
| --- | --- | --- |
| Python ausente | Parava antes de instalar dependências | Bootstrap Bash oferece Python com atualização completa Arch |
| sudo ausente ou execução como root | Falha tardia/risco de arquivos com proprietário errado | Diagnóstico explícito; usuário configura sudo como root e retorna ao usuário normal |
| yay/paru ausentes | Não eram preparados | Ambos por padrão; seleção de um por `--aur-helper`; repositório oficial preferido, AUR compilado como usuário |
| Pacote fora dos repositórios oficiais | Tudo era enviado ao pacman | Consulta após atualização; fallback AUR restrito a yay, paru, mpvpaper, awww e quickshell |
| Flatpak ausente | Nenhuma preparação | Instala Flatpak e adiciona Flathub do usuário sem sobrescrever remoto existente |
| Pacotes implícitos do desktop | Podiam faltar Kitty, FFmpeg, mpvpaper e ferramentas PulseAudio | Verificações obrigatórias, com nomes de pacotes concretos |
| Sessão mínima | Portais, PipeWire, UPower, polkit e formatos Qt não eram garantidos | Pacotes incluídos; serviços inspecionados, ativação separada e autostart gerenciado do agente polkit |
| Fonte virtual `ttf-font` | Seleção dependente do provedor/prompt | `ttf-dejavu` concreto |
| Hyprland ainda não iniciado | Falha de runtime genérica | `PREPARED_RELOGIN_REQUIRED`; retomar após login |
| Atualização do compositor durante instalação | Binário/headers novos com sessão antiga | Compara versão/commit e pede novo login antes de aplicar integração |
| WhatsApp em sistema sem Node/npm | Helper isolado falhava em npm | `--install-whatsapp` prepara pacotes; helper exige Node >=22.13 antes de npm ci |
| Banco de pacotes antigo | `pacman -S` podia falhar após mudanças nos mirrors | Preparação autorizada faz `-Syu`, nunca `-Sy` isolado |

## Dependências e integrações

O inventário reproduzido de sistema sem ferramentas e com hardware Bluetooth
resultou em 68 pacotes diretos, além das dependências transitivas resolvidas pelo
pacman/makepkg. Inclui compilador C++23, CMake/pkgconf, Qt Quick/Multimedia/Wayland/
ShaderTools/SVG/5Compat, Quickshell, Hyprland, FFTW/libpulse, Pillow, Fontconfig,
backend de imagens, backend de vídeos, rede, captura, clipboard e utilitários.
Go/Rust e outras dependências de compilação dos helpers são resolvidas pelos
PKGBUILDs via makepkg -si após instalar base-devel e git.

Pywal16 permanece fixado e verificado em venv privado; Zen usa o artefato oficial
com SHA256; Pixelon vem da página do autor. Esses downloads precisam de rede e
podem bloquear por indisponibilidade, TLS/proxy ou hash/artefato incompatível.
O instalador revalida o preflight antes da compilação e não declara READY quando
um requisito obrigatório continua ausente/incompatível.

WhatsApp, Spicetify/Spotify, Fan+, cava/cmatrix e projetos linux-wallpaperengine
são integrações adicionais. WhatsApp tem uma opção integrada; os demais mantêm
seus próprios caminhos/requisitos. Não são instalados aplicativos pessoais do
Flathub nem instalados/controlados drivers ou serviços de ventilador.

## Simulação e verificações

- Probes de comandos/pacotes substituídos por ausentes para obter o plano limpo.
- Subprocessos de instalação interceptados nos testes: nenhuma chamada real a
  pacman, yay, paru, makepkg de pacotes AUR, Flatpak ou ativação de serviços.
- Casos de ausência de Python executam o Bash real com PATH temporário mínimo.
- Falhas de atualização, pacote desconhecido, helper incompatível, ausência de
  sudo, root, outra distribuição e gestor de rede concorrente são exercitadas.
- Pipeline testa instalação/rechecagem, execução sem sessão, dry-run e preservação
  de configuração, arquivos pessoais e biblioteca de wallpapers.
- Compilação real isolada dos módulos spectrum, visualizer e plugin Hyprland
  aprovada com os headers instalados de Hyprland 0.57.2. Nenhum plugin carregado.
- Configuração Lua gerada aceita pelo `Hyprland --verify-config` real. O mesmo
  binário 0.57.2 rejeita hyprlang; o teste confirma essa rejeição. O gerador legado
  permanece para versões antigas, sem afirmar validação física nessas versões.

O dry-run real da máquina atual encontrou `playerctl` ausente e acesso negado ao
socket IPC do probe Quickshell pelo sandbox, apesar do marcador de imports
carregados. Isso permanece um bloqueio de validação, sem alegar que Quickshell
está incompatível no desktop pessoal. Não foi feita nova medição de FPS.

Não houve instalação real em VM ou download/compilação real de yay/paru/mpvpaper.
A sandbox bloqueou a criação da rede isolada com bwrap. Portanto os testes de
provisionamento validam decisões, ordem e falhas; não comprovam mirrors, acesso
AUR, builds de terceiros, drivers, hardware ou o primeiro login de uma VM limpa.

## Como executar

```sh
./install.sh --dry-run
./install.sh --install-deps --install-pywal --install-zen --prepare-only
# Após entrar no Hyprland:
./install.sh --enable-session-services --enable-bluetooth
```

`--prepare-only` termina com status PREPARED_RELOGIN_REQUIRED e código 1 para
preservar a distinção entre dependências preparadas e desktop validado. `--dry-run`
não instala pacotes, adiciona remotos ou modifica configuração persistente.

A rede inicial não é criada pelo instalador: sem Internet não é possível baixar
pacotes. NetworkManager não substitui automaticamente networkd/ConnMan/iwd/dhcpcd.
PipeWire não substitui um PulseAudio ativo automaticamente. O include gerenciado inicia polkit no login, inclusive sem UWSM, preservando
agentes conhecidos já em execução. Portais são ativados pelo D-Bus da sessão.

Fontes oficiais consultadas:

- https://wiki.archlinux.org/title/Makepkg
- https://github.com/Jguer/yay#installation
- https://github.com/Morganamilo/paru#installation
- https://archlinux.org/packages/extra/x86_64/quickshell/
- https://archlinux.org/packages/extra/x86_64/awww/
- https://docs.flatpak.org/en/latest/using-flatpak.html
- https://wiki.hypr.land/useful-utilities/must-have/
- https://wiki.hypr.land/0.50.0/Hypr-Ecosystem/hyprpolkitagent/
