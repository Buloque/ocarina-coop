# Chefes e combate cooperativo

Estado: plano de auditoria e melhoria incremental. A base já possui sincronização de enemies/bosses; não apresentar isso como funcionalidade nova implementada por este fork.

## Base real e referência

Upstream tem `AbstractActorController`, `AbstractBossController.hpp`, `ActorControllerFactory.hpp` e controllers específicos em `soh/soh/Network/ZeldaOnline/ActorControllers/`: BossGoma, BossDodongo, Barinade, PhantomGanon, Volvagia, Morpha, BongoBongo, Twinrova, Ganondorf e Ganon, entre outros.
O controller abstrato de boss inspecionado transmite propriedades de BGM, câmera, título e ambiente/iluminação. Preservar essas integrações, investigando autoridade e damage flow por controller antes de mudar.

Referência consultada em 11/11/2026:
[OOT True Co-op / enemy-sync](https://github.com/bghill95/OOT-True-Co-op/tree/6cd4c47eb4ed9d30cba5b129275d2f91c94a44aa),
[README](https://github.com/bghill95/OOT-True-Co-op/blob/6cd4c47eb4ed9d30cba5b129275d2f91c94a44aa/README.md) e
[COOP-TEST-GUIDE](https://github.com/bghill95/OOT-True-Co-op/blob/6cd4c47eb4ed9d30cba5b129275d2f91c94a44aa/COOP-TEST-GUIDE.md).
Esses documentos descrevem autoridade de IA, validação de hits na lógica de dano do jogo, spawns dinâmicos e adapter inicial de Gohma. Também declaram limitações: alvo da IA no jogador autoritativo, SFX/partículas incompletos, Floormaster sem mirroring e fallback após falha.
São evidências documentais da referência, não resultados reproduzidos nesta entrega.

Estudar padrões e casos de teste. Não copiar diretamente EnemySync, packets, hooks ou relay Anchor para ZeldaOnline. Protocolos e ownership são diferentes; transposição direta pode duplicar IA/dano. Qualquer reutilização futura depende de revisão de licença/proveniência e adaptação explícita; ausência de licença clara não é permissão. Nenhum código da referência foi copiado aqui.

## Objetivo de autoridade

Antes de implementar, produzir tabela por actor: quem roda IA, quem valida acerto, como muda owner, quais propriedades são replicadas e como efeitos de morte chegam ao save.
Escolher uma única autoridade de simulação por boss/instância (preservar mecanismo upstream quando correto). Servidor coordena ownership/epoch; não assumir que simula toda IA C do jogo.
Réplicas desenham/interpolam estado, mas não decidem independentemente HP, vulnerabilidade, fase, spawn ou recompensa. Evitar duas IAs competindo com propriedades de rede.

Contrato proposto de instância: scene/room/dungeon instance + actor network ID + spawn generation + authority epoch.
Spawn dinâmico inclui tipo validado, parâmetros permitidos, transform, parent network ID e seed/estado necessário. Não transmitir ponteiros de memória. Despawn/respawn não pode reutilizar identidade antiga sem generation.
Ordenação e deduplicação cobrem intro, fase, spawn filho, dano, morte, recompensa e room-clear. Snapshot de entrada tardia restaura estado atual sem reexecutar recompensas ou sons históricos.

## Hits e combate de ambos os jogadores

- Cliente envia intenção de hit com eventId, playerId autenticado, actorId/generation, epoch, ataque permitido e tick/posição limitada.
- Autoridade valida janela de vulnerabilidade, hitbox/hurtbox vanilla, distância/tempo razoáveis, tipo de arma e i-frames usando o caminho de dano original.
- Duplicatas são idempotentes; hit rejeitado não reduz HP local. Predição pode mostrar feedback reversível, mas não efetivar morte/recompensa.
- Não confiar em dano numérico arbitrário enviado pelo cliente.
- Contato de inimigo e projéteis precisam de regra explícita por vítima, sem aplicar dano duas vezes via colisão local e evento remoto.
- Skin/voz jamais altera alcance, colisão, invulnerabilidade, ritmo de ataque ou fingerprint do combate.
- Friendly fire conserva opção/política upstream; não introduzir implicitamente.

## Alvos, fases e apresentação

Permitir escolher jogadores elegíveis na mesma instância, vivos e fora de transição; política de aggro determinística com hysteresis/cooldown evita troca a cada frame. Essa é melhoria futura, não capacidade confirmada para todos os controllers.
Sincronizar alvo por ID e tratar desconexão com novo alvo válido. Distância usa posições validadas; jogador em outra cena não recebe ataque.
Fases do boss e janelas críticas usam seq/tick/epoch para corrigir estado. Câmeras especiais/cutscenes preservam liberdade de quem está fora da cena conforme Story Co-op.
BGM/ambiente/título seguem controller existente; ao terminar cutscene/desconectar, restaurar câmera e ambiente sem prender controle.
SFX/partículas têm IDs de evento e dedupe, usando recurso de boss local; não confundir com vozes individuais. Réplica deve produzir feedback suficiente para reagir a ataques.

## Matriz por boss

Todos exigem baseline antes da alteração e teste nos dois sentidos (host/convidado atacando).

| Boss | Foco de auditoria/aceite |
| --- | --- |
| Gohma | A atordoa olho, B ataca; olho fechado rejeita; ovos/larvas têm parent seguro; uma morte e clear persistente |
| King Dodongo | Bombas ingeridas, janela de dano e rolamento consistentes |
| Barinade | Partes/filhos, ligações, eletricidade e transição de fase |
| Phantom Ganon | Cavalo/quadros e projétil rebatido sem hits duplicados |
| Volvagia | Buracos, formas e seleção de posição sincronizados |
| Morpha | Núcleo/tentáculos, captura e liberação correta do jogador |
| Bongo Bongo | Mãos/cabeça, chão, stun conjunto e vulnerabilidade |
| Twinrova | Entidades múltiplas, fusão, absorção/reflexo e fase |
| Ganondorf | Volley, plataformas, stun e cinematics |
| Ganon | Transição final, espada, morte e conclusão de história |

Mini-bosses e inimigos de split/merge (ex. Floormaster) entram em matriz própria; não presumir solução genérica.
Escala de HP/dificuldade é opcional posterior, desligada por padrão e parte do gameplay fingerprint. Não misturar rebalanceamento com correção de sincronização.

## Morte, recompensa e persistência

Autoridade emite conclusão única; servidor aplica efeitos persistentes segundo regras upstream. Coração/medalhão/boss key/clear/warp e flag de história devem respeitar modelo de progresso do time e pickups pessoais.
Reconectar após morte não recria boss nem dá prêmio duplicado. Reentrar e reiniciar servidor preserva clear confirmado. Snapshot antigo não pode ressuscitar boss desta instância por evento tardio.
Timeout de authority não deve promover duas autoridades simultâneas: election/epoch novo, snapshot confirmado e rejeição do epoch antigo. MVP pode pausar/encerrar encontro com mensagem se recuperação segura não existir; não prometer migração de host Steam.

## Entregáveis e gate

1. Auditoria comparativa upstream/referência por boss, com gaps reproduzidos e logs.
2. Corte vertical de Gohma em dois PCs, sem reescrever netcode; feature flag de rollback.
3. Estender por boss, sempre com regressão do anterior; nenhum gate de campanha completa baseado só em Gohma.
4. Zero divergência de HP/fase/clear/recompensa após convergência nos casos suportados; ambos jogadores conseguem causar hits válidos, inválidos são rejeitados.
5. Testes de latência, perda, late join, troca de sala, disconnect, reinício e derrota simultânea conforme [TEST_PLAN](TEST_PLAN.md).
Se desligado, retornar comportamento upstream; registrar limitações sem mascará-las com alegação de sync completo.
