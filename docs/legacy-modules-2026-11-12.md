# Menus antigos removidos — 12/11/2026

O usuário revisou as 13 capturas e confirmou a exclusão de todos os menus
exibidos e dos arquivos deles. A remoção é do código e de seus hosts; não há
flags mantendo essas telas ocultas.

## Telas removidas

1. Dashboard de sistema.
2. Dashboard de mídia e equalizador.
3. Settings antigas (`VeloraSettingsPanel`).
4. Central `QuickSettingsView`.
5. Central `SettingsQuickView`.
6. Wi-Fi antigo, incluindo a variante duplicada.
7. Bluetooth antigo, incluindo a variante duplicada.
8. Brilho antigo.
9. Busca antiga (`VeloraSearchPopup`).
10. Detalhes de relógio/temporizador antigos.
11. Painel antigo de desenho (`leftPaint`).
12. Detalhes antigos de wallpaper.
13. Popover de mídia sem acesso atual.

## Arquivos apagados nesta confirmação

- `components/VeloraDashboard.qml`
- `components/VeloraSettingsPanel.qml`
- `components/VeloraLeftDetailPanel.qml`
- `components/VeloraRailMediaPopover.qml`
- `components/VeloraMediaPanel.qml` (conteúdo exclusivo do popover removido)
- `components/VeloraLeftOverview.qml` (host exclusivo dos detalhes antigos)
- `components/popups/VeloraSearchPopup.qml`
- `scripts/velora-audio-control` (equalizador e presets exclusivos)
- `tests/fixtures/tst_media_panel.qml` (fixture exclusiva do painel apagado)

Os testes exclusivos desse painel saíram de `tests/test_media.py`; os testes de
letras, cache e bridge Spotify permanecem. O teste de Settings deixou de montar
seu wrapper antigo e continua exercitando o backend atual.

`VeloraSidePopup.qml` contém outros menus além dos aprovados. Foram apagados
os seis loaders e as definições de QuickSettings, SettingsQuick, Wi-Fi (duas
variantes), Bluetooth (duas variantes) e Brilho, mais os helpers exclusivos:
cartões, botões, consultas/polling de áudio/rede/Bluetooth/brilho, comandos de
rede e Bluetooth, estado e classificação da busca antiga, presets e tráfego.
Relógio, agenda, clima, arquivos, browser, bateria e filtro de visibilidade
que não foram apresentados para exclusão permanecem no monólito.

`ShellController.qml` perdeu os hosts completos dos dashboards/detalhes, o host
alternativo de Settings, suas máscaras, superfícies, desenho e foco. Caches de
popups foram reduzidos. Identificadores antigos de Settings/busca e os atalhos de
controle público chegam aos recursos atuais; não há fallback para as telas apagadas.

O serviço de mídia e sua biblioteca são compartilhados com os painéis atuais e
permanecem. O status de áudio/contador de notificações/bateria usado pela barra
também permanece, sem consultas ao equalizador removido. As versões atuais de
Wi-Fi, Bluetooth, volume, brilho, notificações, Settings e mídia não foram apagadas.
O seletor alternativo de wallpapers solicitado anteriormente foi preservado;
o que foi removido é o seletor interno do painel de detalhes antigo.

## Exclusões anteriores, mantidas

A tela Som antiga, seu visualizador decorativo e a Central de notificações
antiga já tinham sido apagados. `VeloraNotificationsPopup.qml` e
`VeloraPopupCard.qml` continuam ausentes.
