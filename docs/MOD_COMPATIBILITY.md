# Compatibilidade de mods e gameplay fingerprint

Estado: política e algoritmo propostos. Não falsificar arquivos ou declarar instalação modificada como original. Separar o que muda simulação do que muda apresentação, com evidência verificável.

## 1. Descoberta e classificação

Analisar apenas arquivos habilitados e suas dependências, ordem de montagem e substituições efetivas. Extensão .otr/.o2r, nome, thumbnail ou afirmação do autor não provam conteúdo cosmético.
Detectar contêiner por assinatura e versão; inventariar entradas por tipo real, tamanho e caminho canônico; construir grafo de referências e identificar recurso efetivamente substituído.
Normalizar comparação conforme lookup real, inclusive case-insensitive; caminhos duplicados, colisões de normalização e recursos de tipo inesperado geram erro/ambiguidade. Preservar pacote original; produzir importação derivada separada.

| Classe proposta | Critério mínimo | Política |
| --- | --- | --- |
| LOCAL_TEXTURE_ONLY | Somente texels/paletas e metadados de textura permitidos; nenhuma lógica, colisão ou dependência desconhecida | Local, não transferir, fora do hash de gameplay |
| LOCAL_UI / LOCAL_MUSIC | HUD/ícones ou trilha sem alterar regras/timing de simulação | Local após validação |
| PLAYER_SKIN | Recursos de representação do jogador e dependências compatíveis com rig/idade | Importar isolado, sem mudança de hitbox |
| PLAYER_AUDIO / PLAYER_SKIN_WITH_AUDIO | Amostras e mapeamentos de voz do emissor, sem substituir bancos globais | Isolar; transferência sujeita a permissão/licença |
| GAMEPLAY | Colisão, cenas/rooms estruturais, scripts, actors, lógica, dano, física, stats, regras | Incluir fingerprint; exigir mesma configuração suportada |
| MIXED | Mais de uma classe, dependências cruzadas | Dividir somente se fechamento de dependências for demonstrado |
| UNKNOWN / UNSUPPORTED | Formato/tipo/referência não compreendido, código nativo ou conteúdo ambíguo | Não liberar como cosmético; desabilitar ou exigir perfil explicitamente suportado |

Mod de cenário 3D é candidato posterior, não automaticamente textura local. Display lists e animações podem carregar referências ou alterar pressupostos do runtime; mesma aparência não prova mesma simulação.
Pacote misto com skin + colisão: nunca encaminhar tudo. Gerar subconjunto somente se referências ficarem fechadas em recursos permitidos e base conhecida. Caso contrário bloquear importação e explicar quais entradas impedem.
Pacotes não enumeráveis, dependências externas não resolvidas ou código executável não podem obter isenção cosmética. Executáveis/plugins não entram no sistema de compartilhamento.

## 2. Algoritmo de comparação proposto

`gameplayFingerprint = SHA256(canonicalGameplayDescriptor)`.
Descritor canônico versionado em UTF-8, chaves ordenadas, inteiros/unidades definidos e recursos ordenados por ID canônico; ausência e valor padrão explícitos devem ter semântica única.

Conteúdo:
- família/revisão de jogo e perfil de extração suportado, sem transmitir ROM;
- versão do build e perfil conhecido de código de simulação (executável modificado desconhecido não é certificado apenas por um rótulo de versão);
- protocolo de gameplay e versões dos adaptadores de combate;
- seed e configurações de randomizer, se ativo; modo vanilla explícito;
- regras de party que mudam simulação/progresso e CVars relevantes normalizadas;
- hashes dos recursos efetivos de colisão, scene/room, scripts, tabelas de actor, física, dano e outros recursos classificados de gameplay;
- ordem/resolução efetiva dos mods de gameplay e versão do analisador/política.

Não incluir resolução, DPI, textura HD, volume, HUD validado ou skin isolada. Manter `CosmeticManifest` separado para identidade/cache, sem obrigar cosméticos iguais.
O descritor deve derivar do conjunto realmente montado, não só dos nomes instalados. Referências de simulação não podem cair em camada cosmética. Se um recurso cosmético também alimentar colisão/algoritmo, deixa de ser isento.

Fluxo: inventário → resolver overrides → analisar dependências → classificar → construir descritor → hash → comparar antes de aplicar snapshot de time.
Hash diferente: relatório por categoria/ID com versão/regra/mod conflitante; não enviar saves ou arquivos protegidos para explicar diferença. Não tentar converter automaticamente ROMs entre revisões. Inicialmente aceitar apenas perfis de revisão explicitamente testados.
Hash igual reduz divergências por configuração; não prova ausência de bugs, fraude ou determinismo. Modelo de confiança do multiplayer não vira anti-cheat completo.

## 3. Política de conexão e legado

- Ambos suportam protocolo novo: fingerprint obrigatório igual ou equivalência explícita de perfis testados; qualquer divergência desconhecida bloqueia a sessão aprimorada.
- Cosméticos diferentes e validados: conectar; resolver aparência separadamente.
- Cliente antigo: caminho legado explícito, mantendo checagens upstream; extensões e transferência desligadas. Não anunciar compatibilidade de mods não verificada como comprovada.
- Regras mudam na sessão: pausa lógica de negociação em ponto seguro; revalidar e confirmar perfil antes de continuar. MVP pode exigir reiniciar a party.
- Mod local habilitado/desabilitado durante jogo: reanalisar; não permitir hot reload de recurso de gameplay.
- Erro de skin/voz/download: Link/voz padrão; não bloquear gameplay compatível.
- Colisão diferente: rejeitar ou exigir instalação local da mesma versão autorizada; nunca compartilhar assets base via protocolo.

## 4. Isolamento de texturas

A usa 4K/estilização; B usa padrão. Ambos conectam se a diferença se restringe a apresentação validada. Cada máquina desenha seu mundo com seus pacotes; não anunciar nem transferir o pacote HD.
Skin explícita de A tem prioridade somente no actor de A. Não modificar o Link de B, NPCs, áudio global nem configurações locais. Cache remoto não deve ser descoberto pelo scanner genérico de mods globais.
Se um pack HD contiver também alteração de colisão, tratar como MIXED/GAMEPLAY; resolução 4K no nome não concede exceção.

## 5. Diagnóstico, riscos e aceite

Relatório local mostra classe, confiança, versão de análise, recursos/dependências, conflitos e razão da decisão. Não inventar porcentagem de segurança. Metadados do autor ajudam UX, mas não substituem análise.
Reanalisar após atualização do validador; invalidar resultado de cache antigo. Mudança de bytes invalida hash e licença associada à versão derivada.
Riscos: falso cosmético, parser malformado, ordem de overrides diferente e builds divergentes. Mitigação: allowlist inicial estreita, fail-closed, corpus sintético, fuzzing e regressão de recursos efetivos.
Aceite: vanilla/4K conecta sem mudar B; dois HD diferentes conectam; colisão e lógica de chefe divergentes bloqueiam com motivo; UNKNOWN não recebe isenção; pacote misto não vaza conteúdo para transferência. Ver [TEST_PLAN](TEST_PLAN.md).
