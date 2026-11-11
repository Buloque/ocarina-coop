# Skins 3D e vozes individuais

Estado: contrato futuro. Reaproveitar PlayerSkin, PlayerPuppetController e skinconv; validar as lacunas antes de prometer compatibilidade com qualquer mod convencional.

## Experiência desejada

A instala skin Miku + voz e texturas 4K; B mantém Link e mundo padrão. A vê sua Miku e o Link de B, com seu mundo 4K. B vê Miku em A e seu próprio Link, mantendo mundo padrão. Cada um ouve a voz associada ao emissor correto.
Se B escolher outra skin, o comportamento é simétrico; host não tem skin privilegiada. Terceiro jogador pode escolher outro pacote.
Modelo/voz da Miku é o exemplo solicitado, não asset incluído nem pacote já aprovado: [GameBanana 637761](https://gamebanana.com/mods/637761). A página identifica modelo + voz, mas licença e dependências dessa versão precisam de verificação humana antes de transferência. Não presumir permissão por ser download público.

## Importação de mods convencionais

1. Usuário escolhe arquivos habilitados .otr/.o2r; analisar contêiner e todos os recursos, sem executar scripts.
2. Detectar modelo, esqueleto/limbs, display lists, materiais, texturas, olhos/boca, mãos, equipamentos, primeira pessoa, animações e amostras de voz.
3. Validar rig/limb count, hierarquia, limites, referências, idade criança/adulto e pressupostos das animações upstream. Geometria visual diferente não muda cápsula, colisão, hurtbox, alcance ou dano.
4. Construir grafo de dependências. Referências não incluídas só podem apontar para base permitida; proibir escapes para outros pacotes/contextos e recursos de gameplay.
5. Gerar derivado em namespace por hash, mantendo fonte original intacta. Converter referências internas de maneira tipada; não apenas prefixar strings arbitrárias.
6. Aplicar somente ao actor escolhido e pré-visualizar localmente. Pacote que exige hook nativo, rig incompatível ou banco global não suportado é recusado com motivo.
7. Vozes e modelo podem ser objetos separados no manifesto, mas associação é explícita. Falha em áudio permite modelo válido com voz padrão; pacote visual inválido não ganha aprovação pela voz válida.

`skinconv.py` já move recursos para namespace e reescreve referências. Isso é ponto de partida, não prova de isolamento completo ou classificador seguro. Seu readme legado descreve configuração de skins no servidor e HTTP. A seleção livre por jogador deve evoluir sem quebrar essas skins preexistentes.

## Manifesto canônico proposto

Exemplo ilustrativo, não arquivo aceito por runtime atual:

```json
{
  "schemaVersion": 1,
  "packageId": "sha256:<hash-do-manifesto-canonico-sem-packageId>",
  "displayName": "Minha skin",
  "source": {"url": "https://exemplo.invalid/mod", "author": "Autor"},
  "rights": {
    "redistribution": "unknown",
    "evidenceUrl": "",
    "licenseId": "",
    "conversionAllowed": false
  },
  "compatibility": {
    "analyzerVersion": 1,
    "rigProfile": "oot-link-supported-v1",
    "ages": ["child", "adult"]
  },
  "objects": [
    {"sha256": "<hash>", "bytes": 12345, "kind": "player-model", "namespace": "skin/<hash>"}
  ],
  "dependencies": [],
  "voiceMapVersion": 1
}
```

Definir serialização canônica antes da implementação; excluir packageId do próprio digest evita circularidade. Objetos têm hashes dos bytes exatos transferidos; hash do pacote original e hash do derivado são campos distintos no registro de proveniência.
Campos de licença são declarações acompanhadas de evidência verificável; remetente não pode liberar conteúdo alheio com uma flag. Valores `unknown` ou `denied` proíbem transferência. Exibir autor/licença/atribuição no gerenciador.
Manifestos limitados e sem caminhos absolutos, comandos, URL de execução ou dados pessoais. URLs servem como referência para instalação manual; nunca download arbitrário automático por manifesto.

## Registro e resolução por instância

Chave de associação: sessão + ID de jogador atribuído pela sessão + generation de seleção. Chave de recurso: hash do pacote + idade + recurso + variante de equipamento. Não usar displayName como identidade.
Estados: vanilla → anunciado → aguardando consentimento/cache → validando → pronto → ativo; erro/cancelamento → fallback.
Aplicar troca completa no início de frame seguro, atualizar esqueleto e tabelas de mãos/primeira pessoa juntos e preservar estado de animação compatível. Se necessário, adiar até sair de cutscene/transformação. Não manter ponteiros para pacote descarregado.
Resolver local e puppet remoto usam o mesmo contrato, para que a skin não funcione apenas na câmera de quem instalou.
Fora do contexto do actor, recursos remotos são invisíveis. Não montar no diretório comum de mods nem deixar nomes vanilla globais ativos.
Fallback: recurso ausente ou idade não suportada usa vanilla dessa idade; pacote estruturalmente inválido é rejeitado inteiro. Nunca misturar rig incompatível parcialmente. UI mostra o motivo.

## Voz e eventos

O netcode já possui caminhos de SFX, pitch e representação remota. Auditar esses pontos antes de adicionar mensagens para não duplicar som.
Enviar eventos semânticos, não streaming de voz: `PlayerVoiceEvent(session, playerId, generation, sequence, action, variant, age, position, tick)`.
Ações permitidas incluem pulo, ataque, esforço, dano e morte; inventário de IDs deve ser mapeado ao áudio existente e versionado. Nada de caminhos de arquivo ou comandos enviados a cada evento.
Receptor resolve action/variant no mapa do emissor; distância/volume/atenuação locais, clamp de pitch e duração. Volume de vozes remotas configurável, com mute/fallback por jogador.
Banco/amostra customizada deve ter handle por contexto; não substituir globalmente o ID de som vanilla, que pode ser usado por outros actors.
Separar voz de Link, armas, NPCs, BGM e ambiente. Pacote que só oferece banco global exige conversão tipada validada; se isso não puder ser provado, áudio fica não suportado.
Sequência deduplica retransmissão e eco local. Som próprio não toca novamente via relay. Descartar evento de geração antiga, jogador ausente ou ID inválido; limitar taxa para evitar spam.
Ao terminar download, não reproduzir fila antiga de gritos. Troca de idade muda mapa/fallback de forma atômica; som já em reprodução mantém referência válida até terminar.

## Cache, privacidade e licença

Armazenar somente objetos autorizados, imutáveis e validados por hash; manter atribuição e evidência de licença vinculadas aos bytes/derivado. Sem direito de adaptação, conversão pode ser proibida mesmo se download for permitido.
Não reenviar conteúdo recebido a terceiro por padrão; autorização original não implica redistribuição transitiva.
Ao sair da sessão, desassociar actors e liberar handles; cache pode persistir dentro da quota, com opção de limpar. Conteúdo fixado por render/áudio não é apagado até liberação.
Seleções/preferências são locais, independentes do save cooperativo. Não enviar caminhos de instalação nem lista de todos os mods do PC.

## Aceite

Dois e três jogadores, skins distintas, criança/adulto, todas as mãos/equipamentos e primeira pessoa; voz simultânea de A/B com identidade correta; mundo de cada PC preservado; sem efeito sobre NPC/BGM.
Teste com arquivos sintéticos ou autorização registrada. Miku real só após conferir licença/compatibilidade. Transferência recusada ou proibida mantém partida e Link/voz padrão. [STEAM_TRANSFER](STEAM_TRANSFER.md) e [TEST_PLAN](TEST_PLAN.md) detalham rede e segurança.
