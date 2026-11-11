# Politica obrigatoria de reutilizacao do Ocarina Co-op

> **Regra de engenharia (MUST):** antes de implementar qualquer funcionalidade descrita no roadmap, inspecionar a implementacao equivalente no Ocarina Co-op/ShipwrightOnline e priorizar sua reutilizacao, correcao incremental ou extensao. **Nao reescrever, substituir ou duplicar um sistema funcional sem demonstrar, com evidencias, por que a extensao e inviavel ou mais arriscada.**
>
> Documento normativo do planejamento; **nao representa funcionalidade implementada ou testada**.

## 1. Base e principios

- Fonte principal: [cranebeaker/ocarina-coop](https://github.com/cranebeaker/ocarina-coop), branch `story-coop`; o fork acompanha essa linhagem.
- Manter um unico fork. Preservar `ZeldaOnline`/ShipwrightOnline, `OOTServer`, `OOTSteamLink`, salas Steam, save de equipe, NPCs/inimigos e componentes de skins existentes.
- Tratar **reuso como padrao**, e novos modulos como adaptadores estreitos acoplados a interfaces ja existentes. Evitar uma segunda implementacao de skin, cliente de rede, servidor, cache de arquivos ou motor de renderizacao.
- Mudancas novas devem ser opcionais (feature flag), negociadas por capacidade quando afetam rede, reversiveis e isoladas para evitar conflitos no merge do upstream.
- Nenhuma alteracao funcional deve partir apenas da documentacao: revisar codigo no commit-base e novamente no HEAD upstream antes de abrir o PR.

## 2. Inventario inicial de componentes existentes

| Recurso ja existente | Onde consultar | Reutilizar para | Lacuna a estudar, sem reimplementar o existente |
| --- | --- | --- | --- |
| Registro, lookup e fallback de skins | [PlayerSkin.cpp](../soh/soh/Enhancements/PlayerSkin/PlayerSkin.cpp), [PlayerSkin.h](../soh/soh/Enhancements/PlayerSkin/PlayerSkin.h) | Esqueleto, display lists, texturas, hands/equipment por skin e fallback vanilla | Importar mods convencionais com caminhos globais para namespaces seguros por jogador |
| Aparencia individual de jogadores remotos | [PlayerPuppetController.cpp](../soh/soh/Network/ZeldaOnline/ActorControllers/PlayerPuppetController.cpp) | Associacao `m_skinRef`/`m_skinName` e `PlayerSkin_Get` ao actor remoto | Garantir que mod novo nao troque modelo/textura/voz de outro jogador ou NPC |
| Seletor de skin, estado e configuracao | [ZeldaOnlineRoomWindow.hpp](../soh/soh/Network/ZeldaOnline/ZeldaOnlineRoomWindow.hpp), [ZeldaOnlineClient.cpp](../soh/soh/Network/ZeldaOnline/ZeldaOnlineClient.cpp) | Selecionar e anunciar skin; receber aparencia sem duplicar UI/protocolo | Integrar classificador, consentimento, manifesto e estados de transferencia |
| Download de recursos e load de arquivos | [ResourceDownloader.cpp](../soh/soh/Network/ZeldaOnline/ResourceDownloader.cpp), [ZeldaOnlineClient.cpp](../soh/soh/Network/ZeldaOnline/ZeldaOnlineClient.cpp) | Fluxo de solicitacao, resposta, cache/download, tratamento de falhas | Adicionar transporte autorizado via Steam, hash/validacao forte e carregamento **nao global**; downloader atual e HTTP, nao P2P |
| Audio remoto e multiplicador de pitch | [AbstractActorSoundHelper.cpp](../soh/soh/Network/ZeldaOnline/AbstractActorSoundHelper.cpp), [PlayerPuppetController.cpp](../soh/soh/Network/ZeldaOnline/ActorControllers/PlayerPuppetController.cpp), [ZeldaOnlineClient.cpp](../soh/soh/Network/ZeldaOnline/ZeldaOnlineClient.cpp) | Eventos de efeitos sonoros remotos, posicionamento e pitch | Auditar cobertura de amostras customizadas do mod; ampliar resolver de voz por `playerId` sem substituir banco global |
| Gerenciamento de mods | [mod_menu.cpp](../soh/soh/Enhancements/mod_menu.cpp) | Identificar arquivos habilitados e ordem de montagem | Analisar recursos efetivos `.otr/.o2r`, classificar cosmético x gameplay e gerar manifestos |
| Conversao de skins, se compativel | [skinconv.py](../tools/skinconv/skinconv.py) | Reaproveitar conversor/reescrita de caminhos existentes | Validar rig, dependencias, limites de formatos, direitos de adaptacao e isolamento |
| Steam, party e save | [Steamlink](../tools/steamlink/), [ZeldaOnlineStoryCoop.cpp](../soh/soh/Network/ZeldaOnline/ZeldaOnlineStoryCoop.cpp), [Party.cpp](../server/src/Party.cpp) | Salas, relay TCP, party e persistencia | Adicionar canal de recursos com limites sem reescrever relay ou OOTServer |
| Mouse e boss sync | [Mouse.cpp](../soh/soh/Enhancements/controls/Mouse.cpp), [AbstractBossController.hpp](../soh/soh/Network/ZeldaOnline/AbstractBossController.hpp) | Eventos de mouse e controllers especificos de chefes | Extensoes pontuais para hit-test dos menus e regressao/correcao de bosses, inspiradas em OOT True Co-op |

**Observacao:** a tabela representa caminhos e comportamentos encontrados no upstream; versoes futuras podem mudar. Nao presumir que a existencia do caminho prova todos os casos de uso (por exemplo, ajustar o pitch **nao** e o mesmo que carregar amostras de voz personalizadas).

## 3. Decisoes especificas sobre skins e mods

1. **Nao criar um segundo SkinManager paralelo**. Evoluir `PlayerSkin` e o fluxo de puppet existente, ou um adaptador pequeno em torno deles.
2. Antes de importar uma skin do GameBanana, examinar `.otr/.o2r`, substituicoes globais, dependencias, rig e audio. O modelo de referencia e [Hatsune Miku Model + Voice Pack](https://gamebanana.com/mods/637761); sem garantia previa de compatibilidade/licenca.
3. Preservar o carregamento e download atuais como baseline funcional, mas **nao** reutilizar uma montagem global para pacotes recebidos quando ela causar alteracao em outros jogadores. Corrigir esse ponto em vez de substitui-lo por uma infraestrutura totalmente nova.
4. Usar identidade de pacote por hash, identidade do ator por sessao/`playerId`, fallback e cache validado. Transmitir apenas recursos permitidos do personagem e somente com consentimento e licenca de redistribuicao/adaptacao verificaveis.
5. Mods HD/4K, estilizados e HUD classificados como cosméticos permanecem locais. Compatibilidade deve comparar **gameplay fingerprint** e manifestos separadamente, sem falsificar origem, executavel ou arquivos.
6. Audio de personagem deve ser resolvido **por player**, evitando alterar SFX de NPCs, outro Link, BGM e ambiente. Reaproveitar envio de eventos e pitch atuais; nao retransmitir audio em streaming por frame.
7. Se um mod contiver logica, colisao, codigo, dados desconhecidos ou recursos mistos nao isolaveis, nao conceder excecao cosmetica; bloquear ou exigir perfil de gameplay equivalente validado.

## 4. Auditoria obrigatoria antes de cada implementacao/PR

O desenvolvedor deve registrar no PR, issue ou especificacao de implementacao:

- **Necessidade exata:** comportamento solicitado e cenario reproduzivel.
- **Busca no upstream:** caminhos/funcões ja existentes e comportamento observado, com links e commit SHA.
- **Gap real:** o que o codigo nao cobre, com teste, log ou reproducer; diferenciar hipotese de fato.
- **Opcao de menor mudanca:** demonstrar porque hooks/adaptadores/extensoes pequenas sao suficientes ou insuficientes.
- **Proposta:** arquivos tocados, contratos existentes preservados, negociacao de protocolo, feature flags, rollback, merge com upstream.
- **Testes:** offline/Steam, dois e tres jogadores conforme gate, skins distintas, voz distinta, mods HD locais, controle+mouse, boss sync, reconnect/save; perf, seguranca e licencas quando aplicaveis.
- **Revisao de duplicidade:** confirmar que nao existe segunda fonte da verdade para skin, audio, save ou networking.

Se for preciso substituir um mecanismo upstream, exigir justificativa comparativa, teste de regressao, plano de rollback e revisao explicita antes de iniciar.

## 5. Gates de aceite

- [ ] Foi identificada e documentada a funcionalidade nativa relevante e sua versao.
- [ ] Componentes existentes funcionais continuam sendo usados e testados.
- [ ] Nenhum protocolo, UI, cache, downloader ou manager paralelo foi introduzido sem necessidade provada.
- [ ] Miku/Link ou duas skins diferentes coexistem sem afetar NPCs, texturas do mundo e sons dos outros jogadores.
- [ ] Transferencia P2P nao sobrescreve arquivos locais e nao transfere ROM, assets-base nem mod sem permissao.
- [ ] A/B com texturas HD diferentes conectam quando o gameplay e compatível; alteracoes de colisao/logica nao passam como cosmético.
- [ ] Mouse nos menus nao quebra teclado/controle; combat/save/Steam continuam funcionais.
- [ ] Atualizacao do upstream foi analisada; divergencia do fork e documentada e minima.

Referencias complementares: [ROADMAP](ROADMAP.md), [ARCHITECTURE](ARCHITECTURE.md), [SKIN_AUDIO_SYNC](SKIN_AUDIO_SYNC.md), [MOD_COMPATIBILITY](MOD_COMPATIBILITY.md), [STEAM_TRANSFER](STEAM_TRANSFER.md) e [TEST_PLAN](TEST_PLAN.md).
