# Liquid glass no Kitty

O plugin nativo `velora-blur` 0.17.7 acrescenta uma lente suave ao corpo e às bordas de
todas as janelas transparentes do Kitty. Funciona em janelas lado a lado,
flutuantes, no VeLyrics e com Infinite Desk desativado. O material acompanha
a geometria atual da janela; a composição original do Hyprland continua
responsável pelo texto, imagens Kitty, cantos, opacidade e animações.

A região central agora refrata o fundo com uma lente contínua, compensada pela
proporção da janela. Só o ponto focal fica parado; o restante do corpo amplia
suavemente a cena. Tanto o fundo nítido quanto o borrado seguem o mesmo raio.
Na borda, o deslocamento padrão é de até 8 pixels, com uma faixa de 48 pixels,
reduzida proporcionalmente em terminais compactos. O deslocamento é limitado
pela largura da faixa e a intensidade satura gradualmente acima do padrão.
Isso evita o esticamento excessivo da versão 0.17.2. O reflexo também é mais
discreto, concentrado em uma linha fina em vez de um brilho largo.

## Controle

**Kitty acompanha a barra** faz o terminal herdar o material independente da barra,
preservando a barra escolhida: cor, alpha efetivo, Nítido/Fosco, blur, reflexos e
refração de 0 a 10×. A lente usa o mesmo GLSL da barra; sua borda acompanha o
retângulo real do terminal. As cores visíveis continuam dependendo da cena atrás
da janela e de sua posição. O modo não fixa um azul ou rosa sobre outro wallpaper.

A chave `appearance.terminalFollowBar` tem default false. O controle fica em
**Configurações → Barra → Material e avatar**, junto de **Liquid glass no Kitty**.
Este último continua ligando/desligando o efeito. A intensidade própria do Kitty
fica guardada enquanto **Refração da barra** governa o material herdado.
**Kitty e barras iguais** continua fazendo as barras acompanharem o Kitty;
ativar uma direção desativa a outra, sem mudar as preferências próprias da barra.

O tema gerenciado recebe a cor e a opacidade exatas da superfície, sem o limite
de 40% do tema independente. Por exemplo, barra Liquid com opacidade 55,762973%
usa tint de 16,728892%; 4,592747× aparece como 4,6×. Alterações na superfície são
agrupadas por 220 ms, gravam o tema e enviam SIGUSR1 somente aos processos Kitty.
Ao desligar, o gerador volta ao tratamento independente. Fontes e atalhos são
preservados. Janelas já abertas só mudam sua opacidade ao recarregar se foram
iniciadas com `dynamic_background_opacity yes`; abra uma nova janela para obter
a primeira aplicação. O fragmento do modo herdado habilita isso para as próximas.

Para evitar a cor aplicada duas vezes, o backdrop compensa a mistura do shader
de superfície instalado do Hyprland, incluindo o fundo premultiplicado de 8 bits
do Kitty. Um intermediário RGBA16F preserva valores fora de 0–1 necessários a essa
compensação; o framebuffer final recebe a cor esperada. O shader original continua
desenhando texto, imagens, cantos e fades. Overrides particulares de cor/opacidade
por janela não são sincronizados; podem divergir do material gerenciado.
**Brilho do Kitty** permite um ajuste de 80% a 120% somente no fundo do
terminal; **Redefinir** volta a 100%, que conserva o material exato da barra.
Salvo em `appearance.terminalBarBrightness` (default 1). O dispatcher opcional
`terminal-brightness` valida esse intervalo antes de aplicar.

**Brilho da barra** controla a luminosidade comum de 20% a 120%, com
**Redefinir** em 100% (`bar.brightness`). Quando o Kitty acompanha a barra,
esse ganho é aplicado antes da compensação do cliente, preservando a mesma
cor final do material. **Brilho do Kitty** permanece um ganho adicional e sua
escolha é preservada. Texto e imagens opacas do terminal continuam intactos.
Requer a capability `bar-brightness`, disponível desde o plugin 0.17.15.

O modo aguarda a capability `terminal-follow-bar`; plugin antigo não recebe o
dispatcher nem provoca a troca automática do tema para esse material.

Em **Configurações → Barra → Material e avatar**, use **Liquid glass no Kitty** para ligar ou
desligar e **Refração do Kitty** para escolher a intensidade entre 0 e 3.
A intensidade escolhida é mantida ao desligar. Os dois valores são salvos em
`appearance.terminalLiquidEnabled` e `appearance.terminalRefraction` no
`config.json` do Velora e reaplicados após reabrir o shell ou recarregar o plugin.

A opção **Kitty e barras iguais** faz as barras usarem a mesma função de lente,
refração, mistura de blur e reflexo do terminal. Cor e transparência acompanham
`background` e `background_opacity` do tema do Kitty gerenciado pelo Velora,
com atualização quando esse arquivo muda. O material da barra passa a Liquid
glass; o seletor Nítido/Fosco fica oculto e a opacidade mostra o valor do Kitty.
A intensidade é compartilhada, inclusive quando só o liquid do Kitty está
temporariamente desligado. O controle do terminal permanece independente.

Com o modo compartilhado desligado, **Refração da barra** controla as barras e
molduras separadamente, entre 0 e 10×, com **Redefinir** para voltar a 1×.
O valor do Kitty é preservado. Veja [Refração da barra](bar-refraction.md).

Ao desligar a opção, retornam material, estilo, blur e opacidade anteriores da
barra. Escolher Sólido ou Translúcido também desativa o modo compartilhado.
As preferências próprias da barra são preservadas; a geração do tema do terminal
consome a cor independente para evitar uma realimentação de cores/opacidade.
A chave salva é `bar.matchKittyMaterial` (default false). O tema gerenciado fica
em `kitty/velora-pywal.conf` no diretório de configuração original do usuário;
overrides particulares por janela do Kitty não são publicados ao shell.

Na mesma aba, **Barra do Infinite Desk** controla a transformação especial ao
pressionar Super+Z. Desativada, o canvas continua ativo, com a barra normal,
barras laterais e molduras preservadas. Não carrega os controles especiais nem
inicia o recolhimento da moldura. O comportamento padrão continua disponível
quando ligada. Salvo em `bar.infiniteDesktopTopbarEnabled` (default true).

Com o shell em execução, os mesmos controles estão disponíveis no terminal:

```sh
velora liquid off
velora liquid on
velora liquid toggle
velora liquid strength 2
velora liquid status
```

Sem argumento, `velora liquid` alterna o estado. O retorno inclui o estado
salvo e se o compositor oferece o controle desta versão. Ao desligar, o plugin
libera os buffers do material; ao ligar, prepara novamente o fundo e agenda o
redesenho. Os demais materiais do shell têm seus próprios controles.

O efeito combina o fundo nítido com a textura de blur que o Hyprland já
preparou. O corpo conserva parte do desfoque e refrata a cena; a borda revela
mais detalhes e recebe um reflexo fino. Distorcer somente a textura borrada,
como em 0.17.0, tornava a mudança visual fraca nos wallpapers desfocados.

Há um framebuffer de material reutilizável por saída e um passe adicional
na região danificada. Para janelas que usam o blur pré-calculado, o fundo
nítido é guardado antes dos aplicativos, com uma cópia GPU por atualização
desse blur, compartilhada entre as janelas. Isso evita refratar texto antigo
que o compositor pode reter atrás de células opacas. Janelas com blur ao vivo
usam diretamente a textura da cena disponível naquele momento.
O cache por saída evita realocações ao alternar entre monitores de tamanhos
diferentes; os recursos de saídas removidas são liberados.
Com um recorte explícito do compositor, prepara a região da janela que esse
recorte pode desenhar, evitando partes antigas de outra janela no buffer.
Não usa captura CPU/PNG, janela sobreposta, segunda execução do blur ou timer
de animação. O custo e a aparência na GPU física precisam de avaliação ao vivo;
os testes EGL usam renderização por software.

Janelas com classe `kitty` são reconhecidas diretamente. Para `kitty --class`
personalizado, a identificação do executável é consultada uma vez por janela
e guardada com uma referência fraca, incluindo a retirada de processos/janelas
antigos. Popups, subsuperfícies e outros aplicativos seguem o renderer original.
Se o blur estiver desativado, o fundo for opaco, o shader falhar ou não houver
textura de blur disponível, o desenho normal do compositor é preservado.

## Instalação e ativação

O build/instalador existente inclui o novo shader ao compilar o plugin. Os
defaults ativam o material para todas as janelas do Kitty. A geração de temas
continua mantendo `background_opacity` abaixo de 1; só o fundo fica transparente.
[A opção do Kitty](https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.background_opacity)
aplica-se às células com a cor padrão de fundo.

Para compilar e carregar pelo checkout, sem encerrar o shell:

```sh
python3 scripts/native-blur build ~/.cache/velora-shell/build/kitty-liquid-glass/hyprland --jobs 2
./scripts/load-native-blur ~/.cache/velora-shell/build/kitty-liquid-glass/hyprland/velora-blur.so
```

O loader verifica o ABI antes de substituir qualquer plugin e solicita a
ressincronização dos materiais do shell. A capability opcional é
`terminal-glass`; plugins antigos continuam compatíveis com o verificador.
`hyprctl -j velora-blur-status` inclui `terminalGlass.enabled`, `strength`,
`draws`, `sharpDraws`, `desktopCopies`, `shaderFailed`, `barMatch`, `barMatchDraws`,
`followsBar` e `followBarDraws`. Após redesenhar um
Kitty, `draws` confirma execução e `sharpDraws` confirma uso do fundo nítido.
Só `draws` aumentando não confirma uma mudança visual suficiente.
Saídas com rotação ou fontes com formatos/espaços de cor incompatíveis usam
o fundo desfocado e o reflexo como fallback.

Configurações registradas no compositor:

| Chave | Default | Valores |
| --- | --- | --- |
| `plugin:velora-blur:kitty_glass` | 1 | 0 desativa; 1 ativa |
| `plugin:velora-blur:kitty_glass_strength` | 1 | 0–3; 0 mantém o backdrop original |

Esses valores nativos são o fallback antes da preferência do shell ser aplicada.
O novo dispatcher `terminal-glass-control` aceita `0|1 intensidade`, com
intensidade finita de 0 a 3; o transporte Lua oferece a mesma operação. `terminal-bar-match` aceita 0 ou 1 e aplica a lente comum
às barras. As capabilities são opcionais, para que um shell atualizado aguarde o plugin novo sem
enviar comandos desconhecidos à versão anterior.

## Validação

```sh
python3 -m unittest discover -s tests -p test_terminal_glass.py -v
```

O teste compila o GLSL exato de produção e o shader de superfície instalado do
Hyprland com blur/cantos habilitados. Verifica refração no corpo e na borda, ponto focal estável,
pixels opacos do conteúdo, recorte dos cantos, transformação de saída, strength
zero durante fades, reutilização/redimensionamento e atualização parcial sem
apagar pixels fora do dano. Usa a mesma projeção de textura da biblioteca
Hyprutils empregada pelo plugin.
Um caso com fonte borrada e opacidade de 56% reproduz a falta de diferença
visual ao omitir a fonte nítida. Com a fonte nítida, mede a diferença de pixels
na composição final e verifica que texto opaco continua intacto. O fixture
também altera a cena de trabalho depois de guardar o fundo: a lente deve usar
o fundo anterior ao aplicativo, preservando-se de pixels antigos do cliente.
Um mapa de coordenadas em texturas float expõe os raios do GLSL real para
verificar continuidade, direção e ausência de inversão/esticamento abrupto.
São 40 combinações de formato largo, alto e compacto, escala 1/2 e intensidade
0/0.25/1/2/3, com diferenças locais e determinante do mapa positivos. A refração
do corpo é medida além da faixa da borda; intensidade zero conserva a geometria.
Os testes também exercitam o parser do dispatcher. Testes de comandos
cobrem on/off/toggle/status, limites e a conservação da intensidade; os testes
reais de configurações verificam o botão, slider, busca e persistência após
reiniciar uma instância de teste isolada.

O fixture oferece exportação opcional de imagens em tamanho de desktop usando
`VELORA_TERMINAL_GLASS_PREVIEW=/caminho`. O diretório deve conter `scene.rgba`
e `blur.rgba` de 1200×800, `client.rgba` de 880×600, todos RGBA com linhas de
baixo para cima. Gera PPMs com blur original, lente padrão e intensidade máxima
usando o mesmo shader de superfície do compositor. Um `previous.frag` opcional
permite comparar com o GLSL de 0.17.2 e seus valores 28/56. Esses arquivos são
artefatos de teste offline; não participam da renderização do shell.

O fixture de barras compara pixels do material compartilhado com a lente do
Kitty nas intensidades 0/0.25/1/2/3, aplicando a mesma cor e alpha; também
confirma ausência de movimento óptico com tempos diferentes. Ambos expandem
a função GLSL comum da produção. Os testes QML leem um tema Kitty isolado,
conferem cor/opacidade, restauração do material, controles, busca e persistência
do modo compartilhado e da opção do Infinite Desk. O teste de transição
verifica canvas ativo com moldura/rail inteiros e sem barra especial.
O caso antigo de blur MultiEffect dos ícones é pulado quando GraphicsInfo
identifica o scene graph software, que não executa esse shader; os checks de
estado e Canvas continuam ativos. Os shaders nativos são testados separadamente
por EGL software, que executa GLSL.

A composição nativa segue a API do
[renderer OpenGL do Hyprland 0.56.2](https://github.com/hyprwm/Hyprland/blob/v0.56.2/src/render/gl/GLElementRenderer.cpp).
Acesso ao socket do compositor é necessário para ativação e revisão visual.

O teste do material herdado compara a saída final do shader real de cliente com
a barra em 96 combinações de alpha (2,4%/16,728892%/56%/96%), material
Translúcido/Liquid e refração 0/1/4,592747/10×, com tolerância de 1 nível RGB.
Inclui brilho de 96%/100%/104%, fundos claros, gradiente, texto opaco e cantos. Os controles negativos
retiram a compensação ou usam intermediário de 8 bits e precisam falhar.
