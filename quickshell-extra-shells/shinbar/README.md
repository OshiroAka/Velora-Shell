# shinbar

Config Quickshell da barra Shinbar.

## Entrada

- `shell.qml`: raiz da config; registra IPC `shinbar` e monta a barra, notificacoes e workspaces expandidos.
- `qmldir`: registro dos singletons e componentes usados pela config.

## Estado e tema

- `ShinPopup.qml`: estado global de popups, foco e navegacao por teclado.
- `ShinConfig.qml`: valores base da barra.
- `ShinData.qml`: carrega e salva `savedata.json`.
- `ShinColors.qml`: cores do pywal com fallback local.

## Componentes principais

- `ShinBar.qml`: layout da barra e foco visual.
- `ShinClock.qml`, `ShinWeather.qml`, `ShinMedia.qml`, `ShinNotifications.qml`: modulos grandes.
- `ShinSettings.qml`: painel de ajustes.
- `ShinWorkspaces.qml` e `ShinWorkspacesExpanded.qml`: workspaces e painel expandido.

## Scripts

Scripts ativos ficam em `scripts/`. Eles alimentam clima, notificacoes, audio, wallpapers, persistencia e metricas do sistema.

## Backups externos

- Backups antigos arquivados em `/home/shira/.config/quickshell/shinbar-archived-backups-20260430-224416`.
- Snapshot limpo antes das correcoes em `/home/shira/.config/quickshell/shinbar-clean-snapshot-20260430-224429`.
