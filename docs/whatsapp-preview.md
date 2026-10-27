# WhatsApp no menu direito

O WhatsApp usa a superfície liquid existente, com a coluna vertical de contatos fundida
ao painel, sem margens externas, molduras ou divisores. Nas telas menores,
os contatos ficam em uma coluna à esquerda dentro do painel. O recorte no topo e no fim da coluna usa
um fade durante a rolagem. As etiquetas de hover dos contatos foram removidas.
Os demais botões também não exibem etiquetas; seus nomes acessíveis continuam
disponíveis para navegação por teclado e leitores de tela.
As páginas de Media/Lyrics, seus serviços e ondulações continuam independentes.

A abertura espera o morph do painel principal (1,1 s), revela o conteúdo com
slide lateral e fade (600 ms) e só então monta a área de contatos. A coluna
nasce da topbar, aumentando largura e altura durante 820 ms; os avatares entram
com slide para baixo e fade de 340 ms. A coluna externa tem até 84 × 448 px,
com rolagem vertical. Em telas menores, a coluna interna segue
a mesma ordem. A saída desliza o conteúdo de volta e recolhe os contatos.
Movimento reduzido pula essa sequência. Não há faixa horizontal de contatos.

O painel permanece aberto ao clicar, rolar ou usar outro aplicativo fora dele,
inclusive ao abrir os demais controles da barra. Seu teclado usa foco sob
demanda, permitindo alternar normalmente entre a conversa e os aplicativos.
O botão de fechar, Escape e o acionador do WhatsApp continuam fechando o painel.

Uma área invisível de 44 px logo abaixo da coluna permite arrastá-la para cima
para ocultar contatos e grupos. O contorno acompanha o arrasto e termina de
recolher suavemente ao soltar. Para restaurar, basta puxar para baixo a mesma
área, que fica sob a topbar quando a coluna está oculta. Gestos pequenos são
ignorados. O mecanismo também funciona na coluna interna das telas menores;
a seleção, o rascunho e a rolagem da coluna são preservados. Reabrir o painel
mantém a coluna recolhida durante a mesma sessão do shell. A alça não desenha
fundo, linha ou etiqueta e permite alternar pelo teclado e acessibilidade.

## Conta e conversas reais

O cliente local original usa Baileys como dependência; não inclui o código,
os comandos ou as respostas automáticas do Takeshi. O pareamento alterna entre
QR Code e código pelo número completo, incluindo o país. A sessão existente
é retomada após reiniciar o serviço. O usuário confirmou o login por QR e o
recebimento de mensagens na sessão real em 13/10/2026.

Fotos de contatos e grupos são buscadas antes de selecionar uma conversa,
com dois pedidos simultâneos e cache. Grupos de anúncio de comunidade podem
usar a capa da comunidade principal quando não possuem foto própria. Quando
a conta não tem acesso a uma foto, o avatar usa a inicial, sem imagem fictícia.
Mensagens recebidas mostram o avatar do remetente. Nos grupos, nome e foto
identificam a pessoa: o histórico sincronizado usa `participant` na mensagem,
enquanto mensagens novas também podem usar `key.participant/participantAlt`.
As identidades de telefone e LID são conciliadas no cache.

O compositor permite escrever, enviar pelo botão ou Enter e inserir uma
quebra de linha com Shift+Enter. Ctrl+V aceita texto, imagens e arquivos locais
oferecidos pelo clipboard Wayland. Arquivos também podem ser escolhidos pelo
botão de anexar. Os anexos ficam em prévia e só são enviados por uma ação
explícita; há um limite de dez arquivos e 100 MB por arquivo. Falhas de envio
preservam o conteúdo pendente. Não há respostas automáticas ou execução de
comandos recebidos. Chamadas e novas conversas ainda não são implementadas.

Imagens e figurinhas recentes da conversa selecionada são baixadas para um
cache privado. Imagens abrem no painel; vídeos são baixados ao abrir e usam
Qt Multimedia, com play/pause e busca. Áudios usam um único player compartilhado
pelos balões, com play/pause e progresso. Documentos baixados abrem pelo aplicativo
do sistema. Mídias antigas indisponíveis podem falhar; a interface permite tentar
o download novamente. A disponibilidade dos codecs depende do Qt Multimedia
instalado.

A lista atualiza os itens individualmente para manter a rolagem quando fotos
ou mídias chegam. Ao enviar, ela segue a última mensagem. A seta flutuante
aparece ao rolar para cima e leva ao final. A seleção de conversa e de grupos
é persistida para não mudar com a recarga do serviço.
Os balões seguem a largura do texto, remetente e horário, com espaços internos
menores. Seus fundos são opacos, com tons escuros para mensagens recebidas e
verdes para enviadas, derivados suavemente da paleta do wallpaper. O material
liquid permanece no painel. Áudios sem legenda usam balões de até 176 px de
largura e cerca de 64 px de altura nos grupos, com reprodução, progresso e
duração em uma linha de 24 px. Play/pause e busca no áudio são preservados.

## Emojis, figurinhas e movimento

O botão do rosto abre um seletor com abas de emojis e figurinhas. Emojis são
inseridos na posição do cursor como Unicode, sem alterar o texto ou enviar
automaticamente. A fonte Noto Color Emoji acompanha o projeto com a licença
OFL, é carregada pelo shell e fornece os glifos coloridos sem instalar fontes
no sistema. A origem e a revisão estão em `assets/fonts/SOURCE-NotoEmoji.md`.

A aba de figurinhas lista até 32 figurinhas reais recebidas ou enviadas, com
deduplicação e downloads limitados a dois simultâneos. Selecionar uma adiciona
a prévia ao compositor; o envio acontece somente pelo botão/Enter. Também é
possível importar WebP, PNG, JPG ou GIF: o `sharp` já utilizado por Baileys
prepara WebP de 512 × 512 px, preservando transparência e animação. Figurinhas
WebP compatíveis são reutilizadas sem recodificar; os limites são 100 KB para
estáticas e 500 KB/10 segundos para animadas. Arquivos preparados e cópias de
envio ficam no cache privado. Os favoritos/pacotes salvos somente no telefone
não são importados por essa lista.
Para exibição, o cache prepara PNG de até 512 px e GIF animado de até 256 px
uma única vez, usando os formatos básicos do Qt. Isso evita depender do plugin
WebP opcional que não está instalado nesta máquina. A prévia é limitada a
10 MB, permanece privada e nunca substitui o WebP original no envio.

Os balões ganham realce, elevação de 2 px e escala discreta no hover. Mensagens
recebidas entram pela esquerda em 440 ms; enviadas entram pela direita em
360 ms, com fade, slide e escala. A confirmação do envio pulsa o botão; um
indicador animado acompanha o estado real de envio/download. A rolagem rápida
produz deslocamento limitado a 5 px e deformação leve dos balões, invertendo
a direção ao subir/descer. A altura dos itens não muda e as animações não
reposicionam a conversa; o histórico inicial não reaparece com animações de
mensagens novas.

O seletor usa slide, escala e fade de 320 ms na abertura/180 ms no fechamento;
trocar abas usa fade de 180 ms. Avatares, botões, anexos, menu da conta, seta
para o fim e visualizador de mídia também têm transições curtas. Figurinhas
animadas reproduzem no balão, no seletor e no visualizador, com decodificação
limitada ao tamanho exibido. Movimento reduzido pula as entradas, elimina a
deformação na rolagem e pausa as figurinhas animadas.

## Instalação e estado

Requer Node >= 22.13, npm, os módulos Qt já usados pelo shell e `wl-clipboard`.
Baileys, pino, qrcode e sharp têm versões fixadas no `package-lock.json`.

```sh
./scripts/install-whatsapp-bridge
./scripts/velora-whatsapp --check
```

O serviço é iniciado pelo `WhatsAppService.qml`. `VELORA_VALIDATE=1` desativa
esse processo nas verificações que não devem conectar uma conta.

Credenciais, chaves Signal, contatos, mensagens e cache de mídia ficam em
`$XDG_STATE_HOME/velora-shell/whatsapp`, normalmente
`~/.local/state/velora-shell/whatsapp`. O diretório usa modo 0700 e o banco/arquivos
usam 0600. Chaves e credenciais não são exportadas para QML. Um lock de processo
impede duas instâncias de tomar a mesma sessão. Reconectar preserva o banco;
“Sair da conta” encerra o vínculo e limpa os dados locais. A cópia do projeto
para a Legacy não inclui esses dados nem `node_modules`.

Falhas temporárias de conexão, incluindo erros WebSocket/stream que o Baileys
classifica como `badSession` (500), retomam a sessão salva com tentativas
progressivamente espaçadas. Elas não apagam credenciais, conversas ou mídia.
Um novo login só é solicitado quando não existe uma conta vinculada ou quando
o servidor confirma o encerramento do vínculo (`loggedOut`, 401). A identidade
inicial é gravada antes de abrir o socket e cada `creds.update` é incorporado
e persistido imediatamente, inclusive antes de retomar uma conexão.

## Arquivos principais e verificação

- `integrations/whatsapp/{client,store,model,media,main}.mjs`: conexão, sessão,
  cache, perfis, mídia, clipboard e envio manual.
- `services/WhatsAppService.qml`: estado reativo e comandos do compositor.
- `components/VeloraEdgeWhatsAppPanel.qml`: conversa, anexos, lista e navegação.
- `components/VeloraWhatsApp{Pairing,Contacts,ContactsHandle,Avatar,Media,MediaViewer,Audio,EmojiPicker,MessageMotion,Button}.qml`:
  pareamento, contatos, fotos, reprodução, seletor e animações.
- `VeloraWhatsAppPreview.qml`: fixture visual, sem acesso à rede; não fornece
  dados de demonstração quando a conta real está conectada.

```sh
python3 -m unittest discover -s tests -p test_whatsapp_bridge.py
python3 -m unittest discover -s tests -p test_edge_media.py
```

Os testes usam sessões temporárias e sockets simulados. Cobrem os dois modos
de pareamento, retomada da sessão QR, chaves Signal, deduplicação, grupos/LID,
pré-carregamento de fotos, capas de comunidade, remetentes do histórico,
envio explícito, clipboard, cache de mídia e cancelamento de resultados antigos.
A fixture QML verifica foco, Ctrl+V, layout, rolagem e decodificação de arquivos
de áudio/vídeo gerados para o teste, sem enviar mensagens para pessoas reais.
Também verifica os glifos coloridos no seletor/compositor, seleção de figurinha,
WebP preparado pelo SDK, conversão de GIF, prévia animada compatível com Qt,
preservação de anexos ao trocar de conversa e estados intermediários de
hover, rolagem, seletor e entrada de mensagens enviadas/recebidas.
Os testes do painel incluem cliques e rolagem fora dele, convivência com outros
controles, arrastos reais da alça nas duas direções, animação após soltar,
reabertura com a coluna oculta e a adaptação à coluna interna. A reprodução
e a busca são verificadas com um áudio local gerado para o teste; as dimensões
compactas e a opacidade dos balões também são conferidas.

Abrir/fechar o painel na sessão local:

```sh
velora whatsapp
```
