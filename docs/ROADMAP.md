# Roadmap e critérios de entrega

Revisão inicial: 11/11/2026. Estado: planejamento publicado, funcionalidades não implementadas.
Base: Ocarina Co-op story-coop @ 7b912675f2e0627fb5c9a7e4a5ae937e574160f1.
Não há promessa de prazo; estimativas dependem das provas de isolamento de recursos e do baseline em dois PCs.

## Escopo consolidado

Um fork, preservando Steam/lobbies/convites, servidor local, save de equipe, cutscenes, viagem no tempo e netcode de combate existentes.
Adicionar navegação real por mouse; skins 3D/vozes por jogador; cosméticos locais independentes; classificação e compatibilidade de gameplay; transferência autorizada opcional; melhorias de boss auditadas com OOT True Co-op como referência.
Não criar outro Anchor, hospedar ROMs, substituir OOTServer, exigir texturas idênticas, instalar automaticamente pacote arbitrário ou prometer suporte universal a mods.
Migração automática de host, mod workshop, rebalanceamento de chefes, editor de skins, voz em tempo real e formatos com código executável ficam fora do MVP.

## Fases com dependências e gates

| Fase | Entregáveis futuros | Dependências | Aceite de saída |
| --- | --- | --- | --- |
| P0 — Planejamento | Fork, README e oito especificações; base e fontes fixadas | Nenhuma | Diff só de documentação; fontes upstream preservadas |
| P1 — Baseline e auditoria | Build reproduzível, mapa de handshake/recursos, relatório de save/combate/input, corpus sintético | P0 | Host/join em dois PCs e duas contas; save/reconnect/era/cutscene baseline registrado |
| P2 — Mouse MVP | Hit-test de inventário/equipamento/mapa; arbitragem de input; feature flag | P1 | Todas as ações suportadas por mouse e controle, resoluções/DPI e overlay aprovados |
| P3 — Classificador e compatibilidade | ModAnalyzer, relatório, fingerprint canônico e negociação de versão | P1 | Vanilla + HD local conectam; lógica/colisão/UNKNOWN não passam como cosmético |
| P4 — Isolamento local | Importador de skin/voz, resolver contextual, registry e cache local sem rede | P3 | Duas skins e vozes coexistem num processo, sem afetar mundo/outro jogador |
| P5 — Transferência Steam | Consentimento/licença, protocolo limitado, sandbox, cache/retomada, UX | P3 e P4 | Transferência autorizada em dois PCs; recusa/corrupção/disco cheio usam fallback; gameplay preservado |
| P6 — Marco integrado MVP | Mouse + skins/voz + HD local + regressão de save/Steam | P2 e P5 | Cenário A skin+voz+4K / B Link+padrão aprovado; controle continua funcionando |
| P7 — Combate e chefes | Auditoria, Gohma vertical, depois adapters/correções por boss | P1; integração testa P6 | Cada boss aprovado individualmente; dano/fase/recompensa/clear consistentes |
| P8 — Hardening e distribuição | Segurança, documentação de usuário, builds licenciados, revisão Steam/ROM | P6 e conjunto de bosses declarado de P7 | Matriz completa do escopo distribuído, rollback e direitos verificados |

P2 e P3 podem ocorrer independentemente após baseline, mas não iniciar transferência antes de provar isolamento em P4.
Coleção/missões, seleção de saves e diálogos com mouse estendem P2 após os três menus principais; manter aceite separado.
Três ou mais jogadores entram após P5 de dois PCs, com quotas de banda e consentimento simétrico. Não inferir suporte a qualquer tamanho de party a partir de dois clientes.

## Marco principal demonstrável

PC A instala skin de modelo+voz autorizada e textura HD; PC B usa Link/padrão.
Ambos entram pela Steam na mesma aventura, veem A e B com aparências individuais e ouvem vozes corretas; só A tem mundo HD.
A atribui item e troca equipamento pelo mouse; B usa controle normalmente. Após obter item, viajar no tempo, salvar, desconectar e reiniciar host, progresso do time continua conforme baseline.
Miku do GameBanana só é usada se licença, adaptação e redistribuição forem verificadas; fixtures licenciadas/sintéticas validam o mesmo contrato sem depender dessa autorização.
Esse marco comprova MVP de menus/cosméticos; não certifica todos os chefes.

## Riscos e respostas

| Risco | Impacto | Resposta / decisão |
| --- | --- | --- |
| Recursos globais contaminam outros players | Skin/voz de A troca B/NPCs | P4 é gate; handles contextuais, caches por hash e testes simultâneos |
| Falso cosmético em pacote misto | Desync ou alteração de gameplay | Allowlist inicial, grafo de dependências, UNKNOWN fail-closed |
| Parser/codec recebe pacote malicioso | Crash/execução/negação de serviço | Quarentena, processo restrito, limites, fuzzing; não habilitar auto-recebimento sem contenção validada |
| Licença desconhecida | Redistribuição/adaptação indevida | Não transferir; origem manual e fallback |
| Download disputa banda | Combate/cutscenes atrasam | Filas separadas, quotas, pausa adaptativa e medição sob carga |
| Regressão de save/era | Perda de progresso ou bloqueio | Baseline/backup, testes de restart/catch-up, sem migração de formato desnecessária |
| Rig/animação incompatível | Crash/visual inválido | Perfis suportados e fallback por idade; rejeitar estrutura inválida |
| Steam/AppID 480 muda ou é inadequado para release | Falha de integração/distribuição | Preservar alternativa TCP; gate de autorização/AppID/runtime antes de build público |
| Mudanças upstream/submódulos | Conflitos e protocolo incompatível | Pin de revisão, PRs pequenos, revisão de save/protocolo a cada atualização |
| Autoridade dupla em boss | Dano/recompensa duplicados | Epoch/ownership, dedupe e teste de disconnect por boss |
| Escopo universal de mods | Prazo indefinido | Matriz de formatos/perfis suportados e rejeição explícita do desconhecido |

## Processo de implementação posterior

Cada PR funcional declara componente, versão de protocolo/analisador, migração (se houver), feature flag, testes e rollback. Não juntar atualização de submódulos com mudança de gameplay sem necessidade.
Preservar créditos e avisos upstream; verificar licenças por componente antes de reutilizar código/redistribuir binários. A árvore inspecionada não apresentou licença geral na raiz; não atribuir licença nova ao código herdado.
Revisão de código, segurança e teste em dois PCs são gates de publicação funcional. Não publicar ROM/assets/skin de terceiro como fixture.
Rollback desliga extensão por flag e mantém build/save recuperável. Migrações futuras devem oferecer backup e compatibilidade explicitamente documentados; não fazer downgrade destrutivo.

## Definição de pronto

- Código atende contrato e casos de [TEST_PLAN](TEST_PLAN.md), com evidências reais e limitações declaradas.
- Nenhum cosmético modifica simulação nem requer que amigos instalem textura de mundo igual.
- Recusa/licença/arquivo inválido nunca impede sessão de gameplay compatível.
- Controle e menus tradicionais continuam disponíveis.
- Steam, servidor local e save preservados; nenhum segredo/ROM/asset proibido nos artefatos.
- Builds só anunciam bosses e formatos efetivamente aprovados.
