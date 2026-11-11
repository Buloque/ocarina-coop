# Plano de testes e aceite

Estado: testes planejados, não executados nesta entrega documental. Inspeção estática não comprova jogo, Steam, save ou mod funcionando.
Relatórios futuros devem distinguir PASS, FAIL, BLOCKED, NOT RUN e limitação upstream reproduzida; nunca marcar como PASS por existir um documento.

## Ambiente e evidência

Baseline upstream e candidato no mesmo hardware/configuração; registrar commit, build, submódulos, SO, GPU, modo de janela/DPI, protocolo, seed/regras, mods/hashes, versão do analisador e capacidades.
Usar duas máquinas e duas contas Steam independentes, uma host e outra convidada; trocar papéis. Adicionar três clientes no gate multi-peer. Windows é alvo inicial; Linux/Steam Deck conforme matriz de suporte da release. Não inferir equivalência de teste mock e Steam real.
Fixtures sintéticas/licenciadas para OTR/O2R, skin criança/adulto, voz e HD; sem ROM ou assets protegidos em CI. Testes reais usam ROM legal suportada de cada testador, fora do repositório.
Antes de rodar: cópias de saves pessoais e data/story do host. Capturar logs sanitizados, vídeo dos dois lados, hashes de estado/arquivo quando aplicável e passos reproduzíveis. Não publicar Steam tokens, IPs privados, caminhos pessoais ou ROM.
Toda mudança funcional roda baseline correspondente; falha já presente é registrada separadamente, não escondida.

## Ferramentas existentes a preservar

- [tools/coop-test/README.md](../tools/coop-test/README.md), cenários smoke, single_player, catchup_persist, items, dungeon, cutscenes, timetravel e sync_gaps.
- [tools/steamlink/README.md](../tools/steamlink/README.md): stream_test, e2e_test e launch_test; mocks testam transporte local, não políticas/infraestrutura Valve.
- `tools/coop-test/unit/story_progress_test.cpp`: base para regressão de regras de progresso.
Executar comandos conforme os READMEs e ambiente preparado; esta entrega não compilou nem iniciou clientes.

## Matriz funcional

| ID | Cenário / passos essenciais | Resultado esperado |
| --- | --- | --- |
| BASE-01 | Vanilla upstream: host Steam, convidar/join, criar party Story Co-op | Sessão e controles funcionam sem abrir porta manual no fluxo suportado |
| BASE-02 | Steam indisponível; usar conexão TCP por endereço | Alternativa existente preservada, erro Steam compreensível |
| SAVE-01 | A obtém item/song/medalhão/chave; B entra depois | Catch-up conforme regras upstream, sem copiar consumíveis/equipamento pessoal indevidamente |
| SAVE-02 | Mudar water level/toggle, sair/reentrar; membro offline retorna | Resultado comparado à auditoria upstream; limitação de união antiga registrada |
| SAVE-03 | Salvar, fechar host limpo, reiniciar com mesmo nickname/team code | Progresso persistente recuperado |
| SAVE-04 | Cópia de save do time truncada/checksum inválido; backup bom | Recuperação conforme upstream sem crash, original protegido |
| SAVE-05 | Trocar slot/ir ao título durante snapshot pendente | Snapshot não aplicado ao save errado |
| SAVE-06 | Dois clientes compartilham opcionalmente ammo/HP/rupees | Política ligada/desligada preservada; bottle contents/regras pessoais auditadas |
| ERA-01 | Votos Master Sword, cancelar, desconectar durante voto; título/file select | Sem espera permanente; idade desconhecida não conta indevidamente |
| CUT-01 | Cutscene/diálogo de história na mesma cena e em outra cena | Sync/retenção de controle conforme upstream; quem está longe não é puxado |
| MOUSE-01 | Mouse seleciona item e atribui a cada destino habilitado | Mesma regra/estado que controle, sem escrever inventário por fora |
| MOUSE-02 | Equipar espada/escudo/túnica/botas; tentar item inválido | Válidos aplicam; idade/posse/estado inválidos rejeitam |
| MOUSE-03 | Mapa regiões/andares/abas, roda e cancelamento | Alvos reais e contexto correto, sem teleporte ou ação dupla |
| MOUSE-04 | Alternar controle/mouse/teclado, jitter, clique mantido, transição | Sem roubo de foco por jitter, duplicação ou clique fantasma |
| MOUSE-05 | 4:3/16:9/ultrawide, resize, DPI 100/150/200%, fullscreen | Hit-test coincide com geometria visível |
| MOUSE-06 | Overlay Steam/ImGui, alt-tab, perda de foco e reconnect de pad | Entrada capturada pela camada certa, câmera não salta |
| MOUSE-07 | Feature desligada e navegação tradicional | Baseline preservado |
| MOD-01 | A HD 4K, B vanilla; repetir com packs estilizados diferentes | Fingerprint de gameplay compatível; mundo de B permanece próprio |
| MOD-02 | Colisão/script/dano/seed/regra de chefe divergentes | Bloqueio antes de sync de save, com categoria da diferença |
| MOD-03 | Pacote misto skin+mapa, UNKNOWN, falso nome texture.o2r | Não ganha isenção cosmética; subset só se dependências fecharem |
| MOD-04 | Ordem de mods diferente com override efetivo diferente | Diferença de gameplay detectada, quando relevante |
| MOD-05 | Mesmo descritor serializado em Windows/Linux | Mesmo hash canônico; mudança relevante muda hash |
| SKIN-01 | A modelo+voz, B Link; trocar host/convidado | Ambos veem/ouvem emissor correto, sem alterar B |
| SKIN-02 | A e B skins/vozes distintas; adicionar C | Sem contaminação entre instâncias, inclusive sons simultâneos |
| SKIN-03 | Criança/adulto, mãos, armas, escudos, primeira pessoa/cutscene | Rig/recursos corretos; idade ausente usa fallback seguro |
| SKIN-04 | Trocar skin durante download, sair da sala, reconnect | Generation antiga ignorada; sem ponteiro inválido ou som antigo |
| SKIN-05 | Só modelo pronto, áudio recusado; mute remoto | Modelo válido + voz padrão/mute; BGM/NPCs intactos |
| NET-01 | Aprovar envio e recebimento de fixture autorizada | Somente objetos aprovados transferidos e ativados após validação |
| NET-02 | Recusar no remetente ou receptor; licença unknown/denied | Zero bytes de asset não autorizado; Link/voz padrão permite jogar |
| NET-03 | Reentrar com mesmo hash em cache; alterar versão/bytes | Sem download redundante válido; versão nova revalida autorização |
| NET-04 | Cortar conexão no meio e retomar | Blocos verificados, digest final igual; parcial não montado |
| NET-05 | Peer sai, host fecha, disco cheio, timeout | Cancelar e fallback sem corromper cache/save |
| LEGACY-01 | Cliente/relay antigo e versão nova | Sem enviar packet desconhecido; modo legado explícito sem garantia cosmética |
| BOSS-01 | Gohma: A atordoa/B ataca; atacar olho fechado | Dano válido conta uma vez; inválido rejeitado, HP/fase convergem |
| BOSS-02 | Gohma larvas/ovos, morte, coração/warp, reentrada/restart | Spawns seguros; conclusão/recompensa/clear persistentes sem duplicação |
| BOSS-03 | Repetir matriz por todos os bosses de BOSS_COOP | Cada um tem evidência própria de fases, dano, alvo e conclusão |
| BOSS-04 | Late join, disconnect de authority, evento tardio | Ownership/epoch único; sem ressuscitar boss ou repetir recompensa |

Coleção/missões, saves e diálogos com mouse recebem casos adicionais antes de anunciar suporte; copiar/apagar save preserva confirmação e backup. Uma flag de feature não substitui teste de regressão.

## Rede sob carga e desempenho

Executar baseline e candidato com RTT alvo 0/50/150/300 ms, jitter 0/30 ms, perda simulada 0/1/5% e desconexão abrupta, usando ferramenta de rede documentada e controlada pelo testador. Transporte confiável pode retransmitir: avaliar atraso e convergência, não só perda de pacotes.
Download de pacote no teto enquanto movimenta, luta, salva e inicia cutscene; medir p50/p95/p99 RTT/intervalo de updates, frame time, memória, fila de gameplay e bytes de transferência.
Orçamento inicial proposto: incremento p95 de latência de gameplay até 20 ms sobre baseline da mesma condição; sem timeout novo causado pelo download. Em rede já saturada, scheduler deve suspender cosméticos, não prometer latência impossível.
Verificar limites de banda, memória/expansão e cache de STEAM_TRANSFER. Sem crescimento ilimitado após 100 trocas de skin/entradas-saídas; handles não utilizados retornam ao patamar documentado. Reutilização de cache não faz novo download de bytes de asset.
Qualquer valor-alvo deve ter medição e hardware registrados; ajustar com decisão documentada, sem alterar requisito silenciosamente.

## Segurança e robustez

Corpus obrigatório: header truncado, tipo de contêiner falso, tamanho negativo/overflow, contagem gigante, referência fora do pacote, rig inválido, display list/índice inválido, áudio malformado/longo, pacote aninhado, bomba de compressão e hash incorreto.
Caminhos: ../, absoluto/UNC/drive, ADS, nome reservado Windows, symlink/hardlink, separadores mistos, case/Unicode colidente e duplicatas.
Rede: remetente fora da sala, playerId falsificado, nonce/epoch antigo, offer flood, chunks repetidos/fora de ordem/offset inválido, tamanho alterado, manifest gigante, cancel/retry infinito e desconexão após consentimento.
Licença: metadado permitido sem evidência, mudança de bytes após aprovação e tentativa de reenviar cache recebido.
Aceite: rejeição controlada, sem execução/rede do parser, sem escrita fora da quarentena/cache, sem montagem global, sem crash do jogo e sem corrupção de save. Fuzzing de parser em processo restrito e instrumentação de memória antes de habilitar recepção automática.
Provar limites da sandbox em Windows e Linux; contenção só declarada, sem teste, não autoriza feature auto-on.

## Gates de release e relatório

Cada gate do ROADMAP requer casos correspondentes PASS, evidência e riscos residuais aceitos explicitamente. Bloqueadores: perda de save, contaminação de skin/voz, bypass de licença/consentimento, UNKNOWN tratado como cosmético, dano/recompensa duplicados, controle inutilizado ou execução de conteúdo remoto.
Modelo de registro: ID, revisão, ambiente, pré-condições, passos, esperado, observado, status, evidência, issue e decisão. Não publicar artefatos protegidos.
P0 documental: conferir nove arquivos pedidos, links relativos, referências a caminhos reais, diferença restrita à documentação e commit publicado; nenhum teste funcional é exigido para afirmar somente esse resultado.
