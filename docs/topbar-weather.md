# Previsão na composição da barra

A previsão usa o mesmo TopBarController, MorphPopover e material conectado dos
outros menus da topbar. O acionador central mostra o ícone da condição real e a
temperatura. Clique ou hover abre; Esc, clique fora e troca de menu recolhem.
O painel anterior de 800 × 390 px e sua faixa invisível de hover deixam de ser
usados na aparência atual.

O corpo ocupa 368 × 354 px e contém somente o conteúdo. Não desenha fundo,
borda externa ou material óptico próprio. O host aplica a mesma cor,
transparência, blur, refração e contorno da barra. O conteúdo é revelado pelos
mesmos tokens de movimento dos outros menus, sem uma segunda entrada demorada.

A interface reúne cidade, unidade e atualização em uma linha; condição atual,
temperatura, sensação e extremos em um resumo; umidade, chuva e vento com
ícones; uma curva horária compacta; e até quatro dias com ícone e mínima/máxima.
Os seletores da curva também são ícones. Não há cartões de fundo nem etiquetas
de hover. Celsius/Fahrenheit e atualização continuam funcionando.

A curva mantém a posição corrente ao trocar rapidamente entre temperatura,
chuva e vento. Mouse e setas selecionam a observação, Home/End vão às pontas.
A seleção aparece em texto fixo junto aos controles. Valores ausentes
interrompem a curva; zero é uma leitura válida. Fechar interrompe a animação,
e movimento reduzido aplica o estado diretamente.

## Horas e condição real

O ponto “Agora” vem das condições atuais, incluindo a mesma temperatura do
resumo. A versão anterior renomeava a previsão da meia-noite como “Agora”. Os
próximos pontos são ordenados por data e horário e excluem intervalos passados,
mesmo ao atravessar a meia-noite.

A referência é a hora local da localização consultada. Quando o JSON omite
`localObsDateTime`, o helper resolve o fuso por `%Z`, opção documentada pelo
[wttr.in](https://github.com/chubin/wttr.in#one-line-output), e usa ZoneInfo da
biblioteca padrão. O fuso fica no cache e é reutilizado nas próximas consultas
da mesma localização. A consulta opcional tem limite de dois segundos; se a
referência temporal não puder ser determinada, preserva a observação atual e
os próximos dias, sem inventar uma sequência horária.

O cache passa ao esquema 3 e mantém o intervalo de quinze minutos. Caches
anteriores são atualizados pela consulta real. Chuva com trovoada, chuviscos,
neve e céu parcialmente nublado recebem seus ícones correspondentes.

## Validação

`python3 -m unittest tests.test_weather_panel tests.test_monitor_control tests.test_topbar tests.test_surface_geometry tests.test_composition`

O conjunto verifica encaixe, cliques, teclado, curva interrompida, zero e dados
ausentes, horas após a meia-noite, horário local, resposta sem hora local e
reutilização do fuso. As consultas de testes são simuladas. Uma prévia isolada
pode ser salva com `VELORA_WEATHER_PREVIEW=/tmp/previsao.png`.
