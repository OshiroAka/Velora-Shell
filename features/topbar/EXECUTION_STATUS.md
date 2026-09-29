# Status central de execução

`ExecutionIndicator.qml` recebe eventos de `ExecutionStatusService.qml` pelo
IPC do Quickshell, target `execution`. Não há detecção automática do Codex:
o produtor da tarefa deve informar seu estado real. Sem eventos, fica oculto.

Métodos: `update(document: string) → bool`, `clear(id: string) → bool`,
`status() → JSON`. O documento de `update` contém:

- `id`: identificador estável da tarefa (1–128 caracteres).
- `agent`: nome real do agente/processo (1–48 caracteres).
- `phase`: `running`, `waiting`, `completed`, `failed` ou `cancelled`.
- `label`: estado curto opcional (até 96 caracteres).
- `detail`: etapa opcional (até 160 caracteres).
- `progress`: fração real entre 0 e 1; omitir quando desconhecida.
- `ttlMs`: validade entre 1.000 e 120.000 ms; padrão 30.000 ms.

O produtor pode chamar `qs -p /path/to/Velora-Shell ipc call execution update`
com o JSON como **um argumento**, usando uma lista de argumentos de subprocesso,
sem concatenar comandos de shell. Deve renovar o evento antes do TTL e enviar
a fase terminal ao terminar. Conclusões ficam visíveis por 1,6 s antes da
contração. Eventos expirados são ocultados; não viram falhas inventadas.

Uma tarefa em primeiro plano é mostrada por vez: um novo evento ativo substitui
o anterior. Conclusões e `clear` de outro ID são rejeitados. O estado é efêmero,
sem gravação de conteúdo ou restauração após reiniciar o shell. Não enviar
segredos, argumentos completos de comandos ou conteúdo privado de prompts.

O indicador fica centralizado na borda inferior da top bar e não captura
mouse/teclado. Os workspaces permanecem na seção original, com motion interno.
O componente compartilha o fill/stroke da barra por uma segunda geometria opcional
no shader conectado, eliminando a emenda. Os popovers mantêm geometria e motion
anteriores. Glass usa o blur do compositor pela forma alfa. No modo liquid,
a refração nativa prioriza o menu quando ambos estão visíveis; não foi alterado
o plugin nativo nesta etapa.


## Notificações

A notificação recebida pelo servidor existente ocupa temporariamente a mesma
superfície central. A execução reaparece após o toast, se ainda estiver ativa.
As notificações usam tempos 2,8 vezes maiores (expansão de 588 ms, conteúdo
após 378 ms entrando em 420 ms, fechamento de 532 ms). Clicar dispensa o toast;
histórico, sons e prazo de exibição continuam sendo controlados pelo shell.
O toast antigo fica oculto somente quando a top bar de referência está ativa.
