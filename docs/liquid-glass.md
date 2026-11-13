# Liquid Glass e Liquid Ass

O seletor de material contém quatro opções: Sólido, Translúcido, Liquid Ass
e Liquid Glass. Liquid Ass é o material anterior; seu identificador salvo
continua `liquid`, preservando configurações e perfis existentes. O novo
Liquid Glass usa `liquid-glass` e o modo nativo 3, com a capability
`optical-glass` do plugin 0.17.20.

## Implementação própria

A referência de aparência é o [MacShell, revisão a05e0dc](https://github.com/0-ss/MacShell/tree/a05e0dc50a8978758d6660d728565b7ec6edf73d),
analisado antes desta alteração. Nenhum arquivo, função ou ativo desse
projeto foi incorporado ao Velora. A implementação foi escrita aqui a partir
da técnica óptica e dos parâmetros observados:

- Desfoque gaussiano no espaço da imagem de fundo, antes de refratá-la.
- Perfil convexo de seção superelíptica de ordem quatro para a borda.
- Refração com índice 1,5, espessura aparente e ampliação vertical de 12,8% a 1×.
- Pequena dispersão entre canais de cor e suavização residual da amostragem.
- Saturação de 1,25, pigmento neutro claro/escuro e opacidade multiplicada por 0,55.
- Luz principal superior esquerda, absorção interna, brilho fino e largo,
  segundo reflexo interno e granulação neutra estática de baixa intensidade.

O fundo vem diretamente da composição do Hyprland. O MacShell reconstrói esse
fundo por wallpaper e capturas de cada janela; essa infraestrutura não é
necessária para o renderer nativo já existente no Velora. O blur novo usa
dois passes gaussianos perpendiculares, com pesos calculados e pares de
amostras combinados por filtragem bilinear. Há dois buffers reutilizáveis
por saída. A região preparada inclui os raios da lente, a ampliação e a
margem do filtro, inclusive em atualizações parciais e refração de 10×.

Barra, moldura, ondas e morphs continuam avaliando o mesmo contorno completo
e as mesmas coordenadas da saída. A janela que desenha cada pixel não cria
uma borda óptica nova. O centro da lente vertical também é compartilhado
pela moldura; widgets independentes usam seu próprio centro. As ondas de
carregamento, temporizador e música entram no campo de cor do material.
O grão é fixo, sem animação temporal da refração no material novo.

## Controles e compatibilidade

Refração da barra permanece em 0–10×, com padrão 1×, mas é salva por material:

- `bar.refractionStrength`: Liquid Ass e os materiais anteriores.
- `bar.opticalRefractionStrength`: Liquid Glass novo.

A escolha de um não sobrescreve a intensidade do outro. Brilho e opacidade
continuam sendo os controles comuns da barra. Nítido usa o fundo nítido;
Fosco habilita o novo gaussiano. O material antigo conserva seu renderer.

Kitty e barras iguais mantém a lente anterior do Kitty, agora identificada
como Liquid Ass. Desativar esse modo restaura o material independente salvo.
Kitty acompanha a barra usa o material selecionado, incluindo o novo renderer
e seu gaussiano. Widgets configurados para acompanhar a barra também recebem
o novo material. Instalações com plugin anterior mostram Translúcido como
fallback para o novo modo até a capability ficar disponível.

## Verificação

Os testes EGL renderizam os dois modelos. Conferem refração distinta,
intensidade, brilho, modo claro, cobertura idêntica, grão estático e ausência
de linhas nas antigas divisões entre rail, toolbox, painel e ondas. Uma
textura parcial verifica a margem necessária para os raios de 1×, 6,2× e 10×.
O shader gaussiano de produção passa por duas direções reais na GPU e seu
resultado é comparado ao perfil analítico de uma faixa delta, preservando
cor constante e alpha. Fixtures QML verificam seleção, persistência e
intensidades independentes após outra execução do shell de teste.
