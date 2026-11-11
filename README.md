# Ocarina Co-op — planejamento do fork

Este fork de [cranebeaker/ocarina-coop](https://github.com/cranebeaker/ocarina-coop), branch `story-coop`, registra o planejamento técnico solicitado para mouse nos menus, skins 3D/vozes individuais, compatibilidade cosmética, transferência autorizada via Steam e melhorias de chefes.

**Estado em 11/11/2026: somente documentação. Nenhuma funcionalidade nova foi implementada ou testada em jogo nesta entrega.** Código, histórico, submódulos, scripts e workflows upstream foram preservados.
Base inspecionada: [7b912675f2e0627fb5c9a7e4a5ae937e574160f1](https://github.com/cranebeaker/ocarina-coop/commit/7b912675f2e0627fb5c9a7e4a5ae937e574160f1).

## Regra obrigatoria de reutilizacao do upstream

**Antes de implementar qualquer melhoria, auditar e reutilizar os sistemas existentes do Ocarina Co-op.** Em especial, estender `PlayerSkin`, `PlayerPuppetController`, `ResourceDownloader`, fluxo de audio, `OOTSteamLink` e netcode existentes; nao recriar gerenciador de skins, downloader ou multiplayer sem justificativa tecnica demonstrada. Consultar a [politica de reutilizacao do upstream](docs/UPSTREAM_REUSE_POLICY.md) e registrar as evidencias em cada PR.

## Planejamento técnico

| Documento | Conteúdo |
| --- | --- |
| [ROADMAP](docs/ROADMAP.md) | Fases, dependências, entregáveis, riscos e gates |
| [ARCHITECTURE](docs/ARCHITECTURE.md) | Código real inspecionado, módulos propostos, save e limites de confiança |
| [MOUSE_MENUS](docs/MOUSE_MENUS.md) | Inventário, equipamento e mapa por mouse; controles preservados |
| [SKIN_AUDIO_SYNC](docs/SKIN_AUDIO_SYNC.md) | Importação .otr/.o2r, modelo/voz por jogador, namespace e fallback |
| [MOD_COMPATIBILITY](docs/MOD_COMPATIBILITY.md) | Classificação, gameplay fingerprint e texturas HD somente locais |
| [STEAM_TRANSFER](docs/STEAM_TRANSFER.md) | P2P opcional, consentimento/licença, hashing, cache, sandbox e Spacewar |
| [BOSS_COOP](docs/BOSS_COOP.md) | Auditoria de combate existente e estudo de OOT True Co-op |
| [TEST_PLAN](docs/TEST_PLAN.md) | Matriz de testes e evidências necessárias para aceite |

## Resultado pretendido

A usa skin de personagem com voz e mundo 4K; B usa Link e texturas padrão. Ambos veem/ouvem cada personagem com sua própria seleção, enquanto cada PC mantém suas texturas do mundo.
Compartilhar somente recursos autorizados do personagem, mediante consentimento, licença e validação. Download recusado, proibido ou inválido usa Link/voz padrão.
Mouse interage com os elementos reais dos menus, com teclado/controle funcionando. Steam co-op, servidor local e save de equipe continuam sendo os existentes.

Skins convencionais podem substituir caminhos globais; isolamento e classificação ainda precisam ser desenvolvidos e provados. Não há promessa de compatibilidade universal. Não falsificar mods como originais: comparar gameplay separadamente de cosméticos validados.
[Hatsune Miku Model + Voice Pack](https://gamebanana.com/mods/637761) é referência de uso; nenhum arquivo foi incluído e sua licença de adaptação/redistribuição permanece pendente de verificação.
[OOT True Co-op](https://github.com/bghill95/OOT-True-Co-op) é referência conceitual/de testes; não copiar diretamente sua camada Anchor para este netcode ZeldaOnline.

## Restrições

Cada jogador precisa de ROM própria suportada obtida legalmente. Não enviar ROM nem assets originais extraídos pela rede ou pelo repositório.
O upstream utiliza Spacewar/AppID 480 no helper Steam. A Valve documenta Spacewar como [aplicativo de exemplo](https://partner.steamgames.com/doc/sdk/api/example); isso não constitui autorização para distribuir um produto sob essa identidade. Builds futuras exigem revisão das condições aplicáveis, runtime e AppID autorizado ou transporte alternativo.
Preservar créditos e avisos de cada componente; não atribuir licença nova ao código herdado.

---

## README upstream preservado

O conteúdo abaixo foi mantido integralmente como referência da base. Ele descreve o upstream, não certifica funcionalidades novas do planejamento.

# Ocarina of Time Story Co-op

**Play the whole of Ocarina of Time with a friend: one shared story, one team save, and you time travel together.**

[![Support me on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/cranebeaker)





Story Co-op is a party mode for [Ship of Harkinian](https://github.com/HarbourMasters/Shipwright) (the PC port of
Ocarina of Time) built on the online netcode of [ShipwrightOnline](https://github.com/lukegrahamSydney/ShipwrightOnline)
by lukegrahamSydney. Two or more players go through the adventure together as one playthrough.

## How to play!

1. Download the latest zip from [Releases](https://github.com/cranebeaker/ocarina-coop/releases/latest) and extract it.
   You need your own supported Ocarina of Time ROM (no game files are included; on the first start the game builds
   its assets from your ROM, see Quick Start below).
2. **Host:** double-click `Host over Steam.bat`. It starts the server, opens a friends-only Steam lobby and starts
   your game.
3. **Join:** your friend double-clicks `Join over Steam.bat`; it finds you on their friends list by itself (with it
   open, right-click you in Steam and Join Game works too). Then the host creates a party in the online window with **Story Co-op** turned on and invites
   them.

No IP addresses or port forwarding: the connection goes through Steam's relay network (Valve's free "Spacewar" app).
Both players need Steam running. You can also run `OOTServer.exe` yourself and connect by address as in
ShipwrightOnline.

**Linux and Steam Deck:** download the `linux.tar.gz` instead. The game is `soh.appimage` (nothing to install), and
`Host over Steam.sh` / `Join over Steam.sh` take the place of the `.bat` files. For Steam Deck Game Mode, add
`Join over Steam.sh` (or `Host over Steam.sh`) to Steam as a non-Steam game: in Desktop Mode, Steam > Games > Add a
Non-Steam Game > Browse, with the file type set to All Files. The README.txt in the download has the details.

https://github.com/user-attachments/assets/fedb77e0-4b35-44a7-9120-dce0d7005fcd

<img width="1073" height="803" alt="image" src="https://github.com/user-attachments/assets/9d737741-d8ca-4d7c-bf03-0547e75d3ab9" />



## What is shared

- **Items and progress:** weapons, items, songs, medallions, stones, heart containers and pieces, magic, upgrades,
  story flags, Gold Skulltulas, Big Poe points, scarecrow songs, map progress. One player finds the Hookshot, everyone
  has it.
- **Kept per player:** rupees, ammo and health (a party setting shares them too), bottle contents, one-time NPC gifts.
- **Dungeons:** keys, switches, chests, cleared rooms and pickups update live for everyone in the dungeon, and are
  saved for the team. The Water Temple water level and the Forest Temple elevator are shared like in single player.
- **Story cutscenes together:** when a story cutscene starts for one player, everyone in the same area watches it at
  the same moment. Area intros still play on your own first visit if you were elsewhere.
- **Time travel together:** pulling the Master Sword puts you on hold ("Waiting for the others") until every player
  has pulled it, then the whole party travels. The party is always in the same era.
- **Team save on the server:** survives server restarts, keeps backups, and recovers from a damaged file. Late
  joiners and reconnects catch up straight away. Every Story Co-op party has a team code shown in the party window.
- **Enemies and bosses** are synced by the ShipwrightOnline netcode: everyone fights the same enemy.

## How it works

- The client sends a compact progress snapshot; the server merges it into the party's team save and sends the result
  back. Merges are unions and maximums, so nobody loses progress.
- Story cutscenes are caught where the game starts them (a cutscene script, or a transition into a scene's cutscene
  layer) and started for the party members in the same scene.
- The Master Sword pedestal runs a party vote on the server before anyone changes era.
- `OOTSteamLink.exe` relays the game's TCP connection through Steam

## Part of Co-op Anything

This mod is part of [Co-op Anything](https://github.com/cranebeaker/coop-anything)

## Credits

- [ShipwrightOnline](https://github.com/lukegrahamSydney/ShipwrightOnline) by lukegrahamSydney: the online netcode,
  enemy and boss sync, parties and skins this mod is built on.
- [Ship of Harkinian](https://github.com/HarbourMasters/Shipwright) by HarbourMasters: the PC port.
- Steam relay: Steamworks.NET's `steam_api64.dll` (Valve's Steamworks runtime).

---
