# P1 — auditoria inicial e ambiente Windows

Data: 11/11/2026. **P1 parcial; nenhum gate funcional aprovado.**

## Revisões e preparação

- Checkout inicial vazio; clone de `Buloque/ocarina-coop:story-coop`, HEAD `820be7c7554338c633c72ca40fca6dde49c9fa42`, sem alterações locais preexistentes.
- Branch de trabalho: `chore/p1-baseline-graphify`.
- HEAD upstream consultado por `git fetch https://github.com/cranebeaker/ocarina-coop.git story-coop`: `7b912675f2e0627fb5c9a7e4a5ae937e574160f1`.
- Fork: quatro commits à frente, nenhum atrás; diferenças em dez arquivos de documentação, sem diferenças de runtime.
- Submódulos inicializados recursivamente, sem atualizar pins: OTRExporter `32e088e28c8cdd055d4bb8f3f219d33ad37963f3`, ZAPDTR `ee3397a365c5f350a60538c88f0643f155944836`, libultraship `62e973aeb4a53ad4d22bb91e2d9373ecdfcd246c`.
- README e documentos de planejamento consultados antes das alterações. Aplicada a política de reutilização; nenhum sistema de runtime duplicado ou modificado.

## Graphify local

`uv 0.13.1`; instalação oficial `graphifyy 0.9.106` em ambiente de ferramenta uv com CPython 3.12.15. A primeira tentativa com o Python 3.15 selecionado automaticamente falhou ao compilar tree-sitter por ausência de MSVC. Repetir com `uv tool install --python 3.12 graphifyy` resolveu sem instalar compilador nem extras.

Integração executada com `graphify install --project --platform codex`. Gerou `AGENTS.md`, `.codex/skills/graphify/` e `.codex/hooks.json`. Não havia AGENTS versionado. Revisão do hook: comando `graphify hook-check`, no-op declarado pelo instalador; a orientação efetiva está no AGENTS. Não foi instalado MCP, serviço, GitHub Action, hook Git ou alterado config.toml global.

AGENTS foi ajustado para consultar o grafo antes de buscas amplas, permitir leitura direta necessária, conferir inferências e manter resultados ignorados. `.graphifyignore` exclui arquivos pessoais, ROMs, archives, saves, binários, assets e submódulos. Dependências de submódulos ficam fora desta primeira cobertura: inspeção direta continua necessária.

`graphify .` nesta versão equivale à extração completa e terminou com erro por ausência de chave LLM para documentos/imagens; nenhum backend foi configurado. A indexação aceita foi exclusivamente local:

```powershell
graphify extract . --code-only --no-cluster --max-workers 2
graphify query "How are player skins selected and applied to remote players?"
graphify query "ResourceDownloader RequestSkinDownload" --seed RequestSkinDownload --depth 1
graphify query "Gohma boss synchronization" --seed BossGomaController --depth 1
graphify query "team save persistence" --seed SelectStorySave --depth 1
graphify update . --no-cluster
```

No terminal atual foi necessário chamar o executável por caminho absoluto em `%USERPROFILE%\.local\bin\graphify.exe`; terminais novos devem incluir esse diretório no PATH. A CLI funciona; descoberta automática da skill pelo aplicativo após recarregar ainda não foi verificada.

Após atualização: **34.112 nós e 123.494 arestas**. `graphify diagnose multigraph --max-examples 1` encontrou zero endpoints ausentes/dangling e zero duplicatas exatas, mas cinco self-loops. A simulação do diagnóstico informa risco de colapso de 112 arestas em grafo simples dirigido e 313 em não dirigido; não são perdas comprovadas da extração original. Usar com cautela relações múltiplas entre os mesmos símbolos, sem tratar o grafo como prova completa.

Primeira extração: **2.298 arquivos, 34.110 nós, 123.492 arestas**; `graphify-out/graph.json` gerado e consultas retornaram código 0. Sem clustering, rótulos semânticos, relatório de comunidades ou HTML. Não se afirma grafo completo: 56 arquivos tiveram erros de sintaxe, 593 não produziram símbolos e 42 entradas não foram classificadas. Headers com macros e arquivos de dados podem ficar parciais. A consulta ampla encontra ruído (por exemplo RemoteBombchu); preferir seeds explícitos e profundidade 1. O grafo distinguiu EXTRACTED de INFERRED em RequestSkinDownload → ResourceDownloader::Request; a chamada foi conferida no código. A atualização após adicionar baseline.ps1 também foi executada.

## Mapa conferido no código

Todos os caminhos abaixo são relativos à raiz; a presença do código não equivale a teste em jogo.

| Área | Evidência existente | Gap / menor extensão futura |
| --- | --- | --- |
| Modelos, esqueletos, texturas, mãos/equipamento | `soh/soh/Enhancements/PlayerSkin/PlayerSkin.cpp`: Reroot, Fill, BuildTableList, PlayerSkin_Get/Reload; caminhos prefixados por skin e fallback vanilla | Reutilizar o registro. Validar rig e fechamento de dependências; identidade por conteúdo ainda não demonstrada |
| Associação remota | `PlayerPuppetController.cpp`: ApplyAppearance lê m_skinRef, SplitSkinRef e PlayerSkin_Get; PuppetInit aplica esqueleto; draw usa tabelas da skin | Já existe skin individual; não criar SkinManager concorrente. Falta provar pacotes convencionais simultâneos e lifecycle seguro |
| Seleção local e anúncio | `ZeldaOnlineClient.cpp`: ChangeSkin, SendPacket_PlayerUpdate, RequestSkinDownload; `ZeldaOnlineRoomWindow.hpp` | Estender UI/protocolo existentes somente após P3/P4 |
| Voz e SFX | `AbstractActorSoundHelper.cpp`: contexto de actor e transmissão; `ZeldaOnlineClient.cpp` SERVER_PACKET_ACTOR_SOUND resolve networkID e SoundFrequencyMultiplier | Pitch individual existe; este caminho chama Audio_PlaySoundGeneral com ID global. Não demonstra amostra/banco de voz isolado por jogador |
| Download e montagem | `ResourceDownloader.cpp`: HTTP, nome restrito, 64 MiB, timeout de 15 s; NetworkHook no cliente usa AddArchive e ExtensionCache global | Montagem global confirmada. Hash, consentimento e isolamento P2P não são garantidos pelo downloader atual; estendê-lo sem habilitar pacotes arbitrários |
| Conversor | `tools/skinconv/skinconv.py`: read_otr/read_o2r, remap e rewrite_references; VANILLA_ROOTS inclui scenes, overlays e audio | Reaproveitar conversão; prefixar caminhos não prova que pacote é cosmético ou seguro |
| Mods locais | `soh/soh/Enhancements/mod_menu.cpp`: listas de habilitados/desabilitados, seleção e ordem | Gerenciamento já existe; classificação/fingerprint do planejamento ainda não implementados nesta base |
| Mouse/teclado/controle | `Enhancements/controls/Mouse.cpp`: posição absoluta/relativa, câmera, escudo, quickspin; `z_kaleido_item.c`: cursorPoint, stickRelX, D-pad e botões | Não localizado hit-test do inventário nesse caminho. P2 deve estender menus Kaleido e arbitragem existente; inventário/equipamento/mapa ainda exigem auditoria geométrica detalhada |
| Steam/TCP | `tools/steamlink/ootsteamlink.c`: relay para OOTServer, CHUNK 16000, AppID 480; testes mock já disponíveis | Preservar helper e servidor; transferência cosmética proposta não é função comprovada |
| Save/story | `server/src/Party.cpp`: SelectStorySave, LoadStorySave, WriteStorySave, checksum e backups; `ZeldaOnlineStoryCoop.cpp` e auditoria em docs/story-coop | Reutilizar e executar regressão existente. Não foi alterado protocolo/formato; limitação de progresso antigo reintroduzido permanece documentada |
| Chefes/inimigos | `AbstractBossController.hpp`: BGM, câmera, título, ambiente; `ActorControllers/BossGomaController.hpp`: tabela de ações, saúde, fases | Controller Gohma já existe em .hpp. Não há evidência nova de defeito de combate reproduzido; não alterar antes do baseline BOSS-01/02 |

## Verificações executadas e limites

| Verificação | Estado | Observação |
| --- | --- | --- |
| Clone, comparação upstream e pins | PASS | Revisões acima; checkout inicial limpo |
| Graphify versão, extração AST e consultas | PASS com cobertura parcial | Avisos acima; nenhuma inferência tratada como prova de comportamento |
| Parser PowerShell de baseline.ps1 | PASS | Sem erros sintáticos |
| Execução do preflight | BLOCKED (esperado no ambiente atual) | git e três checkouts encontrados; cmake e cl ausentes |
| Configuração cliente CMake | BLOCKED | `cmake` não reconhecido; nenhum build configurado |
| Compilação teste offline | BLOCKED | `cl` não reconhecido; teste não compilado nem executado |
| Cliente e servidor | NOT RUN | Sem CMake/MSVC disponíveis na sessão; não há alegação de build aprovado |
| Steamlink stream_test | NOT RUN | Requer helper e DLL mock compilados |
| smoke, single_player, catchup_persist, dungeon, cutscenes, timetravel, sync_gaps | NOT RUN | Requer builds e ROM/archive legal local fornecido pelo testador |
| Steam real, dois PCs/contas, controles e Gohma | NOT RUN | Ambiente de execução não disponível nesta etapa |

Não foram procurados arquivos pessoais/ROM fora do checkout nem iniciados clientes Steam. Não foi instalado Visual Studio automaticamente. Windows alvo; dados de GPU/DPI e hardware de jogo ainda não coletados.

## Primeira entrega e retomada

`tools/coop-test/baseline.ps1` faz preflight por padrão e retorna 2 quando bloqueado. Com `-Build`, configura/compila cliente e servidor e compila/executa o teste offline upstream em `build/baseline-unit`, sem extrair ROM nem tocar saves. Falha de comando interrompe a rotina; aprovação de pré-requisitos nunca é anunciada como aprovação de gameplay. O caminho de build ainda não pôde ser validado com toolchain real.

```powershell
# Em Developer PowerShell x64 do VS 2022, com CMake >= 3.26:
./tools/coop-test/baseline.ps1
./tools/coop-test/baseline.ps1 -Build
```

Próximos passos: preparar MSVC v143/SDK/CMake conforme BUILDING; executar rotina e registrar logs; executar cenários existentes com assets legais fora do Git; concluir host/join, save/reconnect/era/cutscene em dois PCs. Somente então abrir P2 (mouse MVP) e P3 (classificador). Sem alterações funcionais de jogo nesta entrega, sem nova flag/protocolo/migração necessários. Rollback remove apenas integração e runner; saves e runtime permanecem upstream.
