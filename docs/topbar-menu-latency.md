# Investigação da troca rápida de menus — 15/10/2026

O atraso relatado ao alternar rapidamente os menus da topbar foi reproduzido
com os componentes reais de controle e animação, em uma janela isolada com Qt
software. A lateral começa a passagem entre painéis imediatamente; a topbar
reinicia a espera de hover e a sequência que oculta e revela o conteúdo.

## Evidência

Foi aberto um menu e, em seguida, enviados cinco destinos com intervalo de
70 ms. A janela usou `TopBarController`, `MorphPopover` e duas instâncias de
`VeloraRailPopover` de produção. Conteúdo simplificado isolou a lógica de
troca; não havia compositor, blur, processos de rede ou serviços reais no teste.

| Entrada | Resultado observado |
| --- | --- |
| Hover na lateral | 5 trocas durante a sequência; 0–1 ms entre o evento e a abertura. |
| Hover na topbar | 0 trocas durante a sequência; somente o último destino abriu, 110 ms depois de entrar nele. |
| Cliques na topbar | 5 mudanças de destino aceitas; conteúdo oculto e interação desabilitada nas 5 amostras. A interação voltou cerca de 246 ms após o último clique. |

Esses tempos medem a resposta lógica dos componentes. Não são uma medição de
FPS, uso da GPU ou travamento da thread principal da sessão. O teste demonstra
que o comportamento percebido existe mesmo sem o custo do liquid glass.
Perfil de quadros na GPU física continua necessário para atribuir eventuais
quedas de FPS a um custo específico de renderização.

O fixture e o log deste diagnóstico estão em
`/tmp/velora-topbar-investigation-ch67vvxc/`. Não participam da sessão ativa.

## Causas confirmadas no código

1. **Espera reiniciada em cada ícone da topbar.** `TopBarController.enter()`
   executa `openDelay.restart()` mesmo quando outro menu já está aberto.
   `leave()` para esse timer. O intervalo vem de `Motion.intent`, 110 ms.
   Passar por ícones em menos de 110 ms cancela os destinos intermediários.
2. **Passagem imediata na lateral.** `VeloraRailPopover.updatePresence()`
   chama `open()` diretamente quando `handoffSource.opened` é verdadeiro.
   `open()` guarda largura, altura e posição atuais, fecha a superfície
   anterior e anima o novo destino a partir dessa pose. A espera de intenção
   fica para a primeira abertura.
3. **Reinício da sequência de conteúdo na topbar.** Cada alteração de destino
   chama `MorphPopover.synchronize()`, que para os timers/animações e inicia
   novamente a troca. Há saída de conteúdo de 65 ms, espera de entrada de
   120 ms e entrada de 150 ms. Novos destinos podem reiniciar essa espera antes
   de o conteúdo voltar a aparecer.
4. **Interação condicionada ao fim de todas as geometrias.**
   `MorphPopover.interactive` exige destino apresentado igual ao desejado,
   revelação suficiente, ausência de troca e nenhuma animação de posição,
   largura da âncora, largura ou altura. As quatro geometrias usam animações
   independentes de 240 ms. A troca rápida prolonga o período sem controles
   utilizáveis e recomeça as curvas de movimento.

## Trabalho adicional identificado, ainda sem custo medido

`BarPanelContent` é um único `Loader` cujo `sourceComponent` depende do tipo.
`MicroToolsPanel` contém outro `Loader`. Mudar entre componentes diferentes
recria controles e layouts durante a transição; não há pré-carregamento ou cache
por tipo nem `asynchronous` configurado nesses loaders. Painéis como monitor
iniciam consultas ao serem construídos. A duração das construções e das respostas
dessas consultas não foi medida neste diagnóstico; isso é uma possível pressão
adicional sobre as trocas, sem evidência de ser a causa principal.

Os dois caminhos usam o mesmo plugin nativo e os mesmos tokens centrais de
movimento. A lateral já funciona com esse material. O envio da geometria da
topbar é agrupado por `FrameAnimation`; seu dispatcher atualiza o formato sem
iniciar um timer contínuo de redraw. Nada dessa leitura comprova um gargalo de
GPU exclusivo da topbar.

## Correção aplicada

- Manter a intenção de hover na primeira abertura e iniciar a troca imediata
  quando outro menu da mesma topbar já estiver aberto.
- Redirecionar a superfície a partir da pose corrente, preservando a sequência
  em andamento em vez de reiniciar todos os timers a cada destino.
- Coordenar troca de conteúdo e interação para evitar sucessivas janelas vazias.
- Medir construção/layout dos painéis reais antes de escolher pré-carregamento
  ou cache, que também têm custo de memória e ciclo de vida de serviços.

A topbar agora usa a mesma passagem da lateral: captura a pose atual e interpola
posição e dimensões com um único progresso, `handoffDuration` e `easeHandoff`
(240 ms / InOutCubic no ritmo padrão). Uma nova âncora redireciona esse movimento
a partir do ponto atual. Só a primeira abertura aguarda a intenção de hover.
A entrada do conteúdo continua durante a sequência de destinos, e os controles
voltam a aceitar entrada assim que ficam visíveis, sem aguardar toda a geometria.
Fechar, reabrir, bloquear o ícone recém-fechado e reduzir movimentos continuam
cobertos pelo teste de interação.

`tests/fixtures/topbar-handoff.qml` exercita cinco destinos a cada 70 ms com os
componentes reais, verificando aceitação imediata, continuidade da pose, conteúdo,
interação, fechamento e movimento reduzido. O teste de ciclo de vida anterior
também passa. Isso valida a resposta lógica; não mede FPS da sessão.

## Menus compactos e dicas de hover

O menu “Arch!” contém somente o campo persistente de foco, em 300 × 68 px.
O menu da bateria ocupa 300 × 164 px, com ícone/percentual, três seletores
visuais de energia e ícone de ventilação com chave Fan+. Os controles mantêm
ações, seleção, estados indisponíveis e nomes de acessibilidade. Cabeçalhos e
parágrafos de ajuda foram retirados. O fixture `topbar-compact.qml` verifica
limites reais de cada controle e clica nos três perfis e na chave de ventilação.

A compactação inicial da bateria foi revertida enquanto o novo conteúdo era
preparado; o layout completo foi aplicado somente após a prévia renderizada
caber nas dimensões finais. As etiquetas de hover foram removidas dos controles
de bateria, topbar, lateral, mídia e configurações, conforme preferência expressa
do usuário. Não adicionar novas etiquetas que apareçam ao parar sobre botões.

Os registros de validação e ativação estão em
`CHECKPOINT_TOPBAR_ANALISE_VISUALIZER_2026-10-15.md`.

## Caixa de ferramentas no canto esquerdo

O botão de nove pontos abre e recolhe uma caixa de 224 × 172 px junto ao canto
interno superior esquerdo. Usa o mesmo controlador e movimento dos menus da
topbar; abrir por hover continua desativado para esse botão. Clique, teclado e
Escape controlam a abertura. A busca da topbar permanece como ícone reservado.

O conteúdo tem somente seis ícones, em três colunas: conta-gotas, gravação,
temporizador, calendário, marcações e documentos. São espaços reservados sem
ações, textos visíveis ou etiquetas de hover. Os nomes de acessibilidade são
preservados, assim como a resposta visual ao pressionar e focar.

O corpo faz parte da composição nativa existente. O material estende o corpo
através da lateral e compartilha o campo de distância com os passes da moldura.
A lateral conserva a pintura dos seus controles; a topbar pinta a expansão
interna. Cada pixel tem um único dono, com o contorno completo antes de calcular
a refração. Isso remove a linha da borda antiga da lateral dentro da caixa.

O fixture `topbar-toolbox.qml` verifica abertura real pelo botão, teclado,
fechamento, encaixe dos seis ícones e ausência de ações. O teste de troca rápida
inclui a caixa entre os destinos. O teste EGL do material verifica cobertura,
cor e ausência da borda interna na junção com refração forte, além da remoção do
corpo ao fechar.

## Controles diretos e Monitores compactos

O ícone de controles abre as configurações diretamente, inclusive pelo teclado.
O menu intermediário foi removido. A busca mostra somente o ícone, sem ação nem
menu por clique ou hover. Esses dois itens deixam de registrar âncoras de menus;
as opções antigas de conteúdo também foram retiradas.

Monitores ocupa 320 × 272 px. Os três modos usam prévias visuais sem legendas;
monitor, resolução/frequência, escala e aplicação continuam presentes. Os nomes
de acessibilidade identificam os controles. O estado de confirmação e os erros
aparecem somente quando necessários, mantendo a reversão automática de 12 s.

As três prévias repetem seu movimento enquanto o painel está aberto, sem
depender do hover. Cada ciclo avança e retorna com pausas curtas. Fechar, ocultar
ou ativar movimento reduzido interrompe o loop e deixa a prévia estável. Arrastar
a escala ou abrir um seletor mantém a interação do menu ativa.

O fixture `monitor-compact.qml` usa monitores simulados e verifica encaixe,
seleção de modo, repetição sem hover, fechamento e movimento reduzido. O teste
dos acionadores exercita também configurações, busca e previsão conectada.
