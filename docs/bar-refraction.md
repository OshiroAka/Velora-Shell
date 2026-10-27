# Refração da barra

Em **Configurações → Barra → Material e avatar**, selecione **Liquid Glass**
ou **Liquid Ass** (o material anterior). O novo modelo é descrito em
[liquid-glass.md](liquid-glass.md).
O controle **Refração da barra** vai de **0 a 10×** e salva a escolha
automaticamente. **Redefinir**, ao lado do título, volta somente esse valor
ao padrão **1×**.

- **0×** remove a distorção do fundo, mantendo cor, transparência e reflexos.
- **1×** conserva a intensidade padrão da lente.
- Valores maiores ampliam a refração no corpo das barras, molduras e menus
  conectados. O intervalo até 10× permite uma distorção bem mais pronunciada.

O controle é independente de **Refração do Kitty**. Quando **Kitty e barras
iguais** está ligado, prevalece a lente compartilhada e o ajuste independente
fica desativado, com uma explicação na tela. Desligar esse modo restaura o valor
próprio da barra. Redefinir a barra não altera o Kitty, a opacidade ou as cores.

**Nítido** usa o fundo nítido do compositor. **Fosco** utiliza o blur do
Hyprland no Liquid Ass e o gaussiano próprio no novo Liquid Glass.
A seleção Nítido não deve refratar somente uma
textura já desfocada, que escondia detalhes e enfraquecia o efeito percebido.

**Brilho da barra**, na mesma seção, ajusta o material entre **20% e 120%**.
**Redefinir** restaura 100%. Barras, menus conectados e molduras compartilham
esse ganho; com **Kitty acompanha a barra**, o fundo do terminal também o
recebe. O ajuste não muda opacidade, refração ou os ícones/textos. O brilho
próprio do Kitty continua disponível como ajuste adicional.

## Implementação e ativação

O plugin `velora-blur` **0.17.5** oferece a capability opcional
`bar-refraction`. A preferência `bar.refractionStrength` do Liquid Ass é limitada a 0–10 e
reaplicada ao carregar a configuração, após alteração ou recarga do plugin.
O dispatcher `velora-blur:bar-refraction` recebe um número finito nessa faixa;
o transporte Lua oferece a mesma operação. O status JSON expõe `barRefraction`.
Plugins anteriores continuam compatíveis, mas precisam ser atualizados para
aplicar o novo controle.

O novo Liquid Glass requer 0.17.20 e `optical-glass`, com intensidade
independente em `bar.opticalRefractionStrength`, também de 0–10 e padrão 1×.

O fallback nativo é `plugin:velora-blur:bar_refraction_strength`, padrão 1.
Na sessão, a preferência do shell prevalece sobre esse fallback.

Para compilar e carregar sem reiniciar o shell:

```sh
python3 scripts/native-blur build ~/.cache/velora-shell/build/bar-refraction/hyprland --jobs 2
./scripts/load-native-blur ~/.cache/velora-shell/build/bar-refraction/hyprland/velora-blur.so
```

O primeiro trecho do intervalo reduz o perfil óptico existente até zero.
Acima de 1×, uma lente contínua em coordenadas da saída amplifica a refração no
corpo, em vez de esticar dez vezes a estreita borda de uma barra fina. A nova
transformação mantém suas derivadas positivas em todo o intervalo e compartilha
o campo óptico entre os passes da moldura e os painéis conectados. A cobertura
e o conteúdo QML não são deformados. Não há captura CPU/PNG, passe ou timer novo
na renderização do aplicativo.

Na versão **0.17.16**, a região preparada pelo blur inclui também o alcance
dos raios da lente. A margem cresce com a intensidade e o tamanho da saída,
incluindo borda, movimento óptico e dispersão. Ela amplia somente a amostragem;
o desenho mantém o contorno e o scissor originais. Isso evita que a refração
forte leia pixels pretos ou antigos fora da região calculada, sem limitar os
10×. O teste EGL reproduz um buffer válido só perto de uma atualização parcial:
o controle sem margem apresenta a falha; o caminho corrigido coincide com o
fundo completo em 1×, 6,2× e 10×.

O brilho usa `bar.brightness` (default 1), a capability `bar-brightness` e o
dispatcher de mesmo nome. É aplicado à cor final do material, após tint/reflexo
e antes da compensação do cliente Kitty. O status expõe `barBrightness`.
O plugin **0.17.15** ou superior deve estar carregado para o controle funcionar.
Testes cobrem RGB, alpha preservado, redefinição e persistência do slider.

## Verificação

```sh
python3 -m unittest discover -s tests -p test_bar_material.py -v
python3 -m unittest discover -s tests -p test_settings_rebuild.py -v
python3 -m unittest discover -s tests -p test_terminal_glass.py -v
python3 -m unittest discover -s tests -p test_native_blur.py -v
```

O teste EGL compila o GLSL de produção e compara 0/1/5/10× numa barra superior,
lateral e superfície de configurações, com opacidade de 8%. Mede deslocamento
visível sem saturação prematura, cobertura idêntica e preservação dos materiais
Translúcido e compartilhado com Kitty. Os testes QML verificam controle,
Redefinir, extremos, busca e persistência em outro processo. As capturas
offscreen e EGL são verificações isoladas; a aparência no compositor real
depende do carregamento da biblioteca atualizada.

## Junção do visualizer com a moldura — 0.17.9

A lateral, o menu direito e a onda inferior avaliam o mesmo contorno completo
antes de calcular a normal/refração. A separação entre as janelas do compositor
somente escolhe quem desenha cada pixel; não corta o campo de distâncias usado
pela lente. O intervalo de exclusão de 32 px junto ao menu foi substituído pela
franja real de antialias de 1,25 px, com desenho/scissor ampliados em 2 px para
que essa franja tenha um dono mesmo numa posição fracionária da lateral.

Os hosts superior e inferior capturam o fundo em etapas diferentes da composição.
O superior podia refratar uma onda já sombreada, criando uma linha/retângulo na
faixa inferior mesmo com cobertura opaca. A captura do desktop agora fica retida
por saída; perto da onda e da transferência inferior, ambos usam esse mesmo fundo
anterior ao material. A transição ocorre acima da onda, dentro do menu, preservando
o fundo das janelas atrás do restante do painel. O blur retido vem dos próprios
passes do Hyprland. A captura nítida existente troca de buffer; quando necessário,
uma cópia adicional por GPU retém o resultado de blur que seria sobrescrito pelo
passe superior. Não há leitura de pixels pela CPU nem captura PNG na renderização.

A curva, os 96 valores do espectro, a amplitude e a migração configurada não foram
limitados. O teste EGL verifica ondas altas, silêncio, uma única cobertura por
pixel, cor sem reflexo interno, a franja da lateral e fundos propositalmente
diferentes entre hosts para detectar a antiga emenda óptica.

## Morph de carregamento — 0.17.10

Todo morph ligado à barra é uma extensão da mesma superfície, incluindo o
carregamento sob a bateria. Cor, opacidade, blur, refração e contorno vêm da
composição da barra; não se acrescentam fundos ou gradientes próprios.
Essa regra também está no `AGENTS.md` local.

`ChargingMorph.qml` fornece somente geometria animada e texto. `TopBarHost`
inclui esse contorno na união de `ConnectedSurface` e na geometria nativa
`topbar-connected`, ao lado do menu e da notificação. A biblioteca 0.17.10
precisa estar carregada para que o caminho nativo conheça o novo contorno.
As oito coordenadas opcionais de carregamento seguem a geometria de status
existente; clientes antigos continuam aceitos. A junção não tem superfície,
borda, cor ou passagem óptica próprias.

Os testes verificam abertura, reversão e movimento reduzido. O teste EGL
renderiza simultaneamente menu, notificação e carregamento e compara cor e
opacidade da barra à junção. O teste QML equivalente valida o shader de fallback
quando há um backend gráfico capaz de executar `ShaderEffect`.

## Carregamento transitório e onda de cor — 0.17.11

Ao conectar, o morph abre por 6 segundos e recolhe mesmo que o carregador
continue ligado. A porcentagem só atualiza o preenchimento dos seis segmentos;
não reabre o morph nem estende o prazo. O corpo tem 120 × 42 px, com bateria
horizontal centralizada, sem número e sem legenda. Cada segmento preenchido
pulsa suavemente com glow em um ciclo de 2,2 segundos; ao recolher, essa
animação para. Movimento reduzido mantém os segmentos estáveis.

O gradiente azul, violeta e rosado é um campo de cor do mesmo shader da barra.
Nasce junto à bateria, avança em duas direções pelo contorno e perde intensidade
até desaparecer. Os dois parâmetros opcionais após a geometria de carregamento
são progresso e intensidade, ambos limitados a 0–1. O caminho QML usa o mesmo
campo; nenhum fundo extra, opacidade sobreposta ou passe de blur foi adicionado.

Com Spotify, Lyrics ou WhatsApp abertos na mesma saída, o evento de conexão
mantém somente a onda de cor na barra. O corpo da bateria não expande nem
permanece escondido atrás desses painéis. `fullHeightPanelActive` cobre a
entrada, a troca de página e a saída até o painel desmontar, sem mudar os
estados que controlam o visualizador. Se um painel abrir durante a apresentação,
a geometria da bateria some imediatamente e o gradiente continua no prazo
original. Fechar o painel não faz o morph reaparecer; uma nova conexão fora
dos painéis volta a permitir a apresentação normal.
As durações de saída da troca de página usam a página de origem capturada
antes da animação, evitando que mudar a página durante uma conclusão imediata
reavalie a própria duração e produza um ciclo de bindings.

## Continuidade do gradiente nos painéis — 0.17.12

A topbar, os painéis laterais e a moldura inferior usam o mesmo evento de
carregamento por monitor. A origem da cor é calculada em coordenadas do
framebuffer completo, sem o deslocamento da janela lateral que começa abaixo
da barra. O campo se propaga em duas dimensões, com alcance vertical crescente
e dissipação suave. Desse modo, a onda entra nos corpos de Spotify, Lyrics e
WhatsApp e atravessa a junção entre passes sem uma faixa de cor exclusiva da
topbar. Nenhum overlay ou passe de material adicional foi criado. O conteúdo
do terminal e dos demais aplicativos não recebe esse efeito.

## Alerta do temporizador — 0.17.13

Ao terminar a contagem, o temporizador emite ondas vermelhas pelo mesmo campo
de cor usado no carregamento, com ciclo suave de 2,6 segundos. O efeito parte
da posição real do temporizador e atravessa a barra e seus painéis conectados.
O carregamento mantém seu próprio progresso e pode ocorrer ao mesmo tempo.
Com movimento reduzido, o vermelho fica estático. Ao desligar ou adiar, a
intensidade volta a zero e a animação para.

Um morph de 220 × 52 px se expande logo abaixo do temporizador. Ele possui
duas cápsulas translúcidas: `Desligar`, vermelha, e `+10 min`, verde. O primeiro
encerra o alerta; o segundo inicia dez minutos e persiste o novo prazo. O corpo
usa a mesma união SDF e o mesmo material da barra, sem um fundo próprio.
Seu contorno tem um slot independente dos menus, notificações e carregamento,
que continuam disponíveis. Os temporizadores da lateral e da topbar compartilham
o mesmo serviço e prazo. Não são recriados os antigos alarmes agendados.

A conclusão permanece acionável até uma escolha, inclusive após recarregar o
shell. A notificação do sistema também oferece as duas ações; com a topbar
conectada, ela fica no histórico e não cria um segundo toast. O protocolo
`topbar-connected` aceita, após os campos de carregamento, oito valores de
geometria do alerta e três valores de luz (âncora, progresso e intensidade).
Clientes anteriores continuam válidos por omitirem esse bloco opcional.

## Onda da bateria com repetição e botões elásticos — 0.17.14

O alerta usa literalmente o mesmo campo `barLightColor` do carregamento,
com a mesma entrada, alcance, largura, atenuação vertical e dissipação. O
progresso avança de 0 a 1 em 6 segundos e a força é exatamente
`min(1, progresso × 10) × (1 − progresso)^1,4 × 0,62`, como no `ChargingMorph`.
A cor do temporizador é vermelha. A única diferença de comportamento é
reiniciar o ciclo após a onda anterior perder toda a força, enquanto o alerta
não for desligado ou adiado. Não há pulso de brilho separado, frentes
simultâneas ou acúmulo de intensidade. Movimento reduzido suprime o gradiente,
como na bateria, e conserva os botões acionáveis.

A conexão do morph foi alargada de 64 para 96 px, com união suave de 14 px.
Os botões preservam o vidro vermelho/verde e os rótulos. Ao clicar, uma peça
clara se estica pela cápsula e encolhe na outra ponta, conforme o vídeo de
referência enviado pelo usuário. A ação ocorre ao terminar esse movimento,
em 460 ms; o outro botão fica temporariamente indisponível. Movimento reduzido
executa a ação imediatamente, inclusive quando ativado durante a animação.
Cancelar ou ocultar o alerta interrompe qualquer confirmação pendente.

## Controles redondos do temporizador

Os botões agora são dois círculos translúcidos de 36 px, centralizados no
morph: `+10` verde e ícone de parar vermelho. O clique adia por dez minutos
ou encerra o alerta imediatamente. A peça deslizante e sua animação foram
removidas. Os nomes de acessibilidade continuam completos, sem etiquetas de
hover. O gradiente e a conexão larga do morph seguem a mesma composição.

Ao parar ou adiar, o morph recolhe e a ação é executada imediatamente, mas
a onda atual continua do mesmo ponto até dissipar. Apenas as repetições
seguintes são canceladas; não se corta nem se reinicia a cor nesse clique.

O corpo foi compactado de 220 para 124 × 52 px, preservando círculos de 36 px
e a ligação arredondada com a barra. Cada círculo tem glow da própria cor,
com respiração lenta de 2,8 segundos, realce ao passar o mouse e uma pequena
compressão ao pressionar. A animação para quando o botão fica oculto; com
movimento reduzido, o glow fica estático e as ações continuam imediatas.

Ao abrir outro menu da topbar ou um painel lateral, o corpo do alerta e sua
região de entrada são retirados da composição até a saída completa desse
menu. O temporizador permanece concluído e sua onda continua sem reiniciar.
Depois, os controles voltam pelo mesmo morph. Durante o alerta, passar ou
clicar no temporizador prioriza esses controles, evitando que o editor de
duração ocupe o mesmo lugar.
