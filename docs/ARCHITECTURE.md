# Arquitetura técnica proposta

Estado: planejamento; nenhuma funcionalidade deste documento foi implementada por esta entrega.
Base inspecionada em 11/11/2026: `cranebeaker/ocarina-coop:story-coop`,
commit [7b912675f2e0627fb5c9a7e4a5ae937e574160f1](https://github.com/cranebeaker/ocarina-coop/commit/7b912675f2e0627fb5c9a7e4a5ae937e574160f1).
Nomes novos de componentes e mensagens abaixo são contratos propostos, não APIs existentes.

## 1. Decisões e invariantes

1. Um único fork de Ocarina Co-op. Manter netcode ZeldaOnline/ShipwrightOnline, OOTServer, protocolo de progresso e OOTSteamLink; não substituir por uma implementação Anchor.
2. Steam continua sendo lobby/convite/transporte até o servidor local do host. P2P não elimina autoridade nem persistência do servidor.
3. Mouse altera somente interação local com menus. Não transmitir cursor, hover, layout ou configurações de controle.
4. Skins e vozes pertencem a uma instância de jogador, nunca a uma substituição global compartilhada.
5. Gameplay compatível é obrigatório; apresentação cosmética validada pode divergir.
6. Nenhum download cosmético bloqueia o loop do jogo, altera save, modifica executável, ou habilita pacote global.
7. Todas as extensões têm opção de desligamento e negociação de capacidades. Não enviar pacotes novos a clientes antigos sem suporte.
8. Esta entrega modifica README e documentação; preservar fontes, submódulos, scripts, workflows e histórico upstream.

## 2. Mapa do código real e evidências

Os caminhos são relativos à base fixada acima. Consulte os arquivos nessa revisão antes de alterar contratos.

| Caminho existente | Papel observado | Uso futuro |
| --- | --- | --- |
| `tools/steamlink/ootsteamlink.c` e seu README | Relay TCP via Steam; launchers host/join, lobby e keep-alive | Preservar e negociar canal cosmético isolado |
| `server/src/Party.hpp`, `Party.cpp`, `StoryProgress.hpp` | Party, progresso e persistência do time, votos de era | Regressão obrigatória; não guardar assets no save |
| `soh/soh/Network/ZeldaOnline/ZeldaOnlineStoryCoop.cpp` | Aplicação de progresso, história e viagem no tempo no cliente | Preservar sem reescrever |
| `ZeldaOnlineClient.cpp`, `PartySettings.hpp`, `ZeldaOnlineRoomWindow.hpp` no mesmo diretório | Cliente, opções e interface de party | Negociação e UX futura |
| `soh/soh/Enhancements/PlayerSkin/PlayerSkin.cpp` | `PlayerSkin_Get`, reroot de recursos por nome, fallback para vanilla | Evoluir para identidade por conteúdo e contexto |
| `soh/soh/Network/ZeldaOnline/ActorControllers/PlayerPuppetController.cpp` | Skin da instância remota, pedido de arquivos, apresentação e som | Integrar registro por jogador e eventos de voz |
| `soh/soh/Network/ZeldaOnline/ResourceDownloader.cpp` | HTTP apenas; nomes restritos, limite de 64 MiB, temporários e timeout | Não confundir com P2P seguro já pronto |
| `tools/skinconv/skinconv.py` e `mpq.py` | Conversão OTR/O2R para namespace e reescrita de referências | Base para importador, após validação e isolamento |
| `soh/soh/Enhancements/controls/Mouse.cpp` | Mouse para câmera, escudo, primeira pessoa e quickspin | Compartilhar entrada sem capturar cliques de menu |
| `soh/src/overlays/misc/ovl_kaleido_scope/` | Inventário, equipamento, mapa, coleção e máquina de estados da pausa | Alvos reais de hit-test e ações semânticas |
| `soh/soh/Network/ZeldaOnline/AbstractBossController.hpp` | Propriedades de câmera, música, título, luz e ambiente | Preservar integração com controllers específicos |
| `tools/coop-test/`, `tools/steamlink/test/` | Harness e cenários upstream | Base da matriz de regressão |

A pasta `Network/Anchor` também existe na árvore. Isso não significa que o Story Co-op utilize o mesmo protocolo, adapters ou servidor do OOT True Co-op. A base ativa aqui é ZeldaOnline; compatibilidade binária com Anchor não é requisito assumido.

O downloader atual considera arquivo já existente por nome como disponível e trabalha com HTTP. Ele não comprova identidade por SHA-256, licença, isolamento por jogador ou autorização P2P. `skinconv` remapeia recursos amplamente, incluindo raízes como scenes/overlays/audio; portanto conversão não equivale à classificação de segurança.
O pitch existente não comprova suporte seguro a qualquer pacote de voz completo.

## 3. Componentes propostos

| Componente | Entrada / saída e responsabilidade |
| --- | --- |
| MouseMenuController | Eventos de ponteiro + contexto da tela → ações semânticas já validadas pelo menu |
| ModAnalyzer | Arquivos habilitados e dependências → inventário tipado, grafo de referências, classificação e razões |
| CompatibilityService | Conteúdo efetivo e regras → gameplay fingerprint + relatório de diferenças |
| CosmeticImporter | Subconjunto permitido → pacote imutável com namespace por hash, manifesto e mapa de dependências |
| PlayerCosmeticRegistry | session/player ID + geração → handles de modelo/voz e estado de prontidão |
| ScopedResourceResolver | Contexto mundo/jogador/áudio → recurso permitido ou fallback |
| CosmeticTransferService | Ofertas autorizadas + cache → bytes validados, sem executar conteúdo |
| CosmeticCache | SHA-256 e versão do validador → objeto imutável, quota, LRU, remoção segura |
| BossSyncAudit | Instrumentação de controllers existentes e cenários → divergências reproduzíveis; adaptações graduais |

Não criar um segundo resource manager concorrente sem verificar libultraship. Primeira prova técnica: dois conjuntos de skin/voz coexistirem em um processo sem alterar recursos globais. Só depois conectar a rede.

## 4. Fluxos e limites de confiança

```text
Instalação local → ModAnalyzer → gameplay fingerprint → negociação da party
                          └→ importador → manifesto cosmético → autorização
Cliente convidado ↔ OOTSteamLink ↔ Steam ↔ OOTSteamLink host ↔ OOTServer local
                                                            
Oferta cosmética → consentimento → transferência limitada → quarentena
→ hash + análise + licença → cache imutável → registro por jogador → render/voz

Mouse → coordenadas do viewport → hit-test da página ativa → ação do menu
→ regras originais → efeito normal de equipamento/progresso → netcode existente
```

Pacotes de rede, metadados, nomes, manifestos e arquivos recebidos são não confiáveis mesmo de amigos. O host não pode autorizar download em nome do receptor. SHA-256 prova integridade/identidade de bytes, não segurança ou autoria. SteamID autentica a conexão Steam dentro das garantias da API; não certifica o conteúdo.

## 5. Recursos por contexto

- `BaseResources`: recursos extraídos localmente da ROM suportada; nunca compartilhar.
- `LocalCosmetics`: texturas de mundo/HUD/música validadas, só nesta máquina.
- `LocalPlayerCosmetics`: seleção explícita do jogador local.
- `RemotePlayerCosmetics[playerId, generation]`: skin/voz remota em namespace isolado por conteúdo.
- `GameplayResources`: recursos efetivos de simulação, cobertos pelo fingerprint, sem resolução cosmética.

Mundo: LocalCosmetics → BaseResources.
Jogador com skin: skin explícita → fallback vanilla validado. Um pacote HD local pode melhorar recursos de personagem não substituídos apenas se o recurso continuar identificado como vanilla e a política de fallback o permitir; nunca sobrescreve a skin remota explícita.
Áudio: mapa de voz da instância emissora → voz vanilla daquela idade. Música e sons de mundo usam contexto local independente.
Colisão, hitbox, velocidade, alcance e scripts nunca são escolhidos pelo resolver cosmético.

Cache de recursos precisa incluir contexto/hash, não somente caminho vanilla. Evitar trocar tabelas globais temporariamente durante draw: chamadas intercaladas, callbacks e áudio assíncrono tornam isso vulnerável a contaminação. Handles devem permanecer válidos até o fim do frame/áudio, com liberação diferida. Troca de skin é transacional em ponto seguro; não recarregar esqueleto no meio da animação.

## 6. Save e sessão

Preservar regras descritas em [STORY_COOP.md](story-coop/STORY_COOP.md) e [auditoria de save](story-coop/STORY_COOP_SYNC_AUDIT.md): progresso do time, consumíveis conforme configuração, equipamento/botões pessoais, votos de era, cutscenes e catch-up. União/max não se aplicam indiscriminadamente a chaves consumidas, toggles ou valores last-writer-wins. Há limitação upstream documentada de estado antigo reintroduzido por membro offline; registrar e reproduzir, não prometer resolução nesta etapa.

O servidor mantém save do time, versão/checksum, escrita temporária/rename, backups e recuperação. Não migrar formato sem necessidade. Skins, hashes de cache e preferências não entram em StoryProgress. Antes de testes/migrações futuras, backup dos saves pessoais e do time; oferecer slot/cópia cooperativa sem sobrescrever save pessoal silenciosamente. Esse UX de cópia é proposta, não função confirmada da base.
Ao sair o host, encerramento limpo e retomada pelo team code/nickname existentes. Migração automática de host fica fora do MVP.
Ao desconectar, preservar o último progresso confirmado; não usar assets pendentes como motivo para reverter estado.

## 7. Protocolo e manutenção

Separar `gameplayProtocolVersion`, `cosmeticProtocolVersion`, `analyzerVersion` e `manifestSchemaVersion`. Negociar capacidades antes de mensagens novas; desconhecido obrigatório rejeita com motivo, cosmético opcional cai para Link/voz padrão.
Associação de jogador é validada pelo servidor/sessão, não pelo ID escolhido pelo pacote. Mensagens incluem session nonce e generation para impedir estado de sessão antiga.
Antes de introduzir fingerprint, auditar o handshake real e registrar quais verificações já existem; esta proposta não afirma que upstream compara todos os mods atualmente.

PRs futuros pequenos por módulo, flags locais independentes, sem atualizar submódulos junto de feature. Rebase/merge upstream com revisão de protocolo/save e execução do baseline. [ROADMAP](ROADMAP.md) define gates; [TEST_PLAN](TEST_PLAN.md) define evidências.
