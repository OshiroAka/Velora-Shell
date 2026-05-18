# Velora Shell

Configuracao Quickshell para Hyprland com sidebar soft-glass, popups laterais, seletor de wallpapers, temas, pywal16, Zen Browser sync e visualizer CAVA.

## Pastas

A pasta fonte do Git fica aqui:

```sh
~/Velora-Shell/Velora\ Shell/
```

A pasta ativa do Quickshell fica aqui:

```sh
~/.config/quickshell/velora-shell/
```

## Atualizar o Git a partir do Quickshell ativo

Quando voce mexer direto na pasta ativa e quiser salvar tudo no repo:

```sh
cp -a ~/.config/quickshell/velora-shell/. ~/Velora-Shell/Velora\ Shell/
```

O ponto em `velora-shell/.` copia o conteudo da pasta. O `Velora\ Shell` usa barra invertida porque o nome tem espaco.

Depois confira:

```sh
cd ~/Velora-Shell
git status
git diff --stat
```

## Instalar do Git para o Quickshell

Para copiar a versao do Git para a pasta ativa:

```sh
cp -a ~/Velora-Shell/Velora\ Shell/. ~/.config/quickshell/velora-shell/
qs kill -c velora-shell --any-display
qs -d -c velora-shell
```

Tambem da para usar o instalador:

```sh
cd ~/Velora-Shell
./install.sh --skip-hypr --validate --start
```

Sem `--skip-hypr`, o instalador tambem escreve as regras de blur do Hyprland.

## Aplicar so o visualizer CAVA novo

Se voce quiser copiar apenas a mudanca das barras soltas:

```sh
cp ~/Velora-Shell/Velora\ Shell/shell.qml ~/.config/quickshell/velora-shell/shell.qml
cp ~/Velora-Shell/Velora\ Shell/components/VeloraBarV2.qml ~/.config/quickshell/velora-shell/components/VeloraBarV2.qml
qs kill -c velora-shell --any-display
qs -d -c velora-shell
```

Essa versao usa 48 barras CAVA e remove o trilho/container em volta delas.

## Validar

```sh
timeout 8s qs -p ~/Velora-Shell/Velora\ Shell --no-color --log-times
```

O resultado esperado contem:

```text
Configuration Loaded
```

## Dependencias

Base:

```text
quickshell
hyprland
python3
rsync
```

Recursos opcionais:

```text
playerctl
cava
pywal16
awww
mpvpaper
linux-wallpaperengine
wpctl / wireplumber
nmcli / NetworkManager
makoctl / mako
easyeffects + calf + lsp-plugins-lv2 + zam-plugins-lv2
```

`easyeffects` e os plugins LV2 sao usados pelo painel de midia expandido para aplicar EQ, grave, agudo, surround e boost de verdade no PipeWire. No Arch/CachyOS:

```sh
sudo pacman -S --needed easyeffects calf lsp-plugins-lv2 zam-plugins-lv2
```
