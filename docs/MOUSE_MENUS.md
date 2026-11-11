# Menus com mouse sem regressão de controles

Estado: especificação futura. Meta: interação direta com o menu original do jogo, não apenas mover um cursor ImGui ou emular repetidamente o analógico.

## Escopo e comportamento

| Tela | Comportamento esperado |
| --- | --- |
| Inventário | Hover destaca item real; clique seleciona; ação de atribuir abre escolha dos slots/botões habilitados; clique no destino confirma |
| Equipamentos | Clique em espada, escudo, túnica ou botas possuídos usa a regra original de equipar; rejeita idade/estado incompatível |
| Mapa | Clique seleciona região ou andar existente; roda percorre andares quando disponíveis; abas/setas mudam página |
| Coleção/missões | Seleção de músicas/itens e execução das ações já permitidas; sem inventar teleporte ou obtenção |
| Save/select | Seleção de slot, copiar, apagar e voltar por hit-test; operações destrutivas mantêm confirmação explícita padrão |
| Diálogos | Clique avança somente quando permitido; opções são alvos explícitos, sem selecionar resposta por hover |

Inventário/equipamentos/mapa são gate do MVP. Coleção, saves e diálogos vêm depois, conforme [ROADMAP](ROADMAP.md), e não ficam implicitamente prometidos como já prontos.
Botão direito cancela/volta. Roda atua no contexto visível (andar/lista; caso contrário página), com uma ação por notch e debounce. Não repetir confirmação enquanto botão está pressionado.
Drag-and-drop para botões é melhoria posterior; a opção clicar item → clicar destino deve funcionar completamente sem arrastar. Duplo clique não é necessário para equipar nem pode consumir duas ações.
Itens não possuídos/inativos podem mostrar informação, mas não executar ação. Hover nunca equipa.

## Integração com código existente

Entrada/captura: `soh/soh/Enhancements/controls/Mouse.cpp`.
Menus: `soh/src/overlays/misc/ovl_kaleido_scope/z_kaleido_item.c`, `z_kaleido_equipment.c`, `z_kaleido_map_PAL.c`, `z_kaleido_collect.c`, `z_kaleido_scope_PAL.c` e `z_kaleido_prompt.c`.
Seleção de saves: `soh/src/overlays/gamestates/ovl_file_choose/`.
Esses são pontos reais de investigação; MouseMenuController é nome proposto.

1. Expor retângulos/polígonos interativos a partir do layout efetivamente desenhado e da página corrente.
2. Converter posição de janela para framebuffer considerando DPI; subtrair offset do viewport e letterbox; aplicar inversa da transformação usada para desenhar o menu.
3. Em menus com perspectiva/rotação, projetar quads desenhados ou usar coordenadas já transformadas. Não supor uma grade fixa 320x240 para toda resolução.
4. Hit-test retorna ID semântico (item/slot/andar/aba), estado enabled e ação; nunca ponteiro arbitrário.
5. Aplicar seleção coerente (`cursorPoint`, `cursorX/Y`, item e slot relacionados) por helper central, respeitando estados da pausa. Executar rotina normal de confirmação/equipamento.
6. Bloquear entrada em transições, animação de troca de página, carregamento, cutscene e prompt modal incompatível. Revalidar alvo no momento do clique, mesmo após hover válido.
7. Não escrever inventário/save diretamente para contornar regras. Equipamentos pessoais continuam pessoais; aquisição de itens segue sync upstream.

## Arbitragem de entrada

Estados propostos: gameplay com mouse relativo; menu com ponteiro absoluto; overlay externo; janela sem foco.
Pausa libera captura relativa, mostra ponteiro e restaura posição válida; retorno ao jogo restaura captura conforme preferência sem salto de câmera. Limpar deltas e botões pendentes nas transições.
Menu consome clique antes de bindings de ataque/câmera; overlay Steam, ImGui, remapeamento de controles e janela modal têm prioridade. Entrada consumida não chega duas vezes ao jogo.
Quando ImGui captura mouse/teclado, não enviar ações ao menu de jogo. Ao perder foco, cancelar drag/pressed, limpar fila e não confirmar nada; ao voltar exigir novo press.
O último dispositivo que fez entrada significativa controla o foco visual: movimento de mouse acima de limiar ativa hover; analógico/D-pad ativa navegação tradicional. Jitter não rouba seleção do controle. Uma única ação de confirmação por frame, com regra determinística (modal → dispositivo ativo → fila).
Teclado e controle mantêm atalhos existentes. Mouse desligável por preferência local independente de EnableMouse para câmera. Não depender do Steam Input para fazer hit-test.
Preservar lançamento separado do helper antes da inicialização Steam conforme upstream, para não reintroduzir a regressão de controle associada ao AppID 480.

## UX e acessibilidade

Indicar foco, hover e seleção com símbolos além de cor. Tooltip mostra nome, restrição e ação; destino de botão usa nome/mapeamento atual, sem fixar teclas de um controle específico.
Esc e botão de cancelar continuam equivalentes ao direito. Escala do cursor e alvos, sensibilidade da roda e opção mouse menus configuráveis localmente. Menus originais continuam visualmente reconhecíveis.
Mapa permite somente ações já existentes; zoom/pan novos não entram no MVP. No online a pausa mantém a semântica upstream: abrir inventário não congela arbitrariamente a sessão de todos.

## Aceite e testes

- Com controle desconectado, abrir inventário pelo teclado e selecionar/atribuir todos os tipos de item habilitados pelo mouse; equipar e desequipar onde o jogo permite.
- Trocar equipamento, abas, região/andar do mapa e cancelar sem erro; itens inválidos produzem feedback normal.
- Alternar mouse, teclado e controle durante seleção e animação; nenhuma ação duplicada, cursor preso ou ataque após fechar.
- 4:3, 16:9, ultrawide, janela redimensionada, fullscreen, DPI 100/150/200%: alvo visual coincide com alvo clicado, inclusive bordas.
- Steam overlay, alt-tab, reconectar gamepad, Steam Deck trackpad: recuperação sem clique fantasma.
- Dois jogadores online: menu de A não move foco/equipamento pessoal de B; progresso compartilhado permanece correto.
- Feature desligada reproduz baseline de controles. Registrar vídeo e matriz por tela; testes detalhados em [TEST_PLAN](TEST_PLAN.md).
