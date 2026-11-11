# Transferência cosmética opcional via Steam

Estado: desenho futuro, sem alterações no relay ou transferência implementada nesta entrega.

## Transporte existente e restrições

[OOTSteamLink upstream](../tools/steamlink/README.md) mantém o jogo falando TCP com OOTServer (porta padrão 21050), encaminhando streams por Steam. Host inicia servidor local e lobby friends-only; join abre relay local e configura `OOT_SERVER`. Não remover servidor, saves, team code, convites ou entrada direta por endereço.

A documentação upstream reserva canal 0 para streams confiáveis ordenados (blocos de até 16000 bytes) e canal 1 para keep-alive/goodbye; descreve heartbeat de 1 s e timeout de 20 s. Preservar framing/IDs/close/reconnect; canais são comportamento existente a confirmar no código ao implementar.
Proposta: canal cosmético negociado adicional (candidato 2, condicionado à auditoria de uso), baixa prioridade e filas/orçamentos separados. Não inserir arquivos no stream de combate/save e não reaproveitar canal de keep-alive.
Canal separado ainda compartilha link e pode causar congestionamento; precisa scheduler e backpressure, não apenas outro número.
Evitar expor porta pública adicional; IPC local helper↔cliente autenticado por nonce efêmero e restrito a loopback/usuário da sessão. Auditar integração e ameaças antes de escolher pipe/socket final.

Steam transporta entre membros da mesma sala autorizada. No MVP, topologia host↔convidados preservada: oferta de convidado para outro convidado pode usar encaminhamento opaco e limitado pelo host, somente após consentimento de ambos; host não passa a ser proprietário/licenciante. Começar com dois PCs; três jogadores é gate separado.
Se infraestrutura não suportar transferência isolada sem prejudicar gameplay, manter instalação manual e fallback. Modo TCP direto continua jogável sem depender de Steam nem de download novo.

## Consentimento e direitos

Desligado por padrão para enviar e receber. Mostrar antes dos bytes: remetente, skin/voz, autor, origem, licença/evidência, tamanho total e espaço disponível.
Opções separadas: compartilhar minha seleção; receber de amigos autorizados; reproduzir vozes remotas; manter texturas locais; cancelar/limpar cache. Autorizar uma sessão ou política persistente explícita por amigo; novo hash/licença requer reavaliação.
Consentimento do host não vale pelo receptor. Sem licença verificável para redistribuição e eventual conversão: não transferir. Mostrar origem para instalação manual pelo usuário e usar fallback; não contornar bloqueios ou baixar página automaticamente.
Cache existente não dispensa política de uso/licença/versão do validador. Não distribuir ROMs, arquivos base extraídos, bancos de áudio originais ou packs HD inteiros.

## Protocolo proposto

Mensagens novas têm envelope com magic, versão, tamanho, session nonce, peer autenticado, transferId, sequence e tipo. Limites são verificados antes de alocar.
Tipos candidatos:
- `CAPABILITIES`: versão, limites, feature bits; não alterar protocolo legado sem negociação.
- `COSMETIC_OFFER`: manifesto/hash, conteúdo e direitos; sem bytes do arquivo.
- `ACCEPT/DECLINE`: decisão do receptor vinculada ao hash, sessão e prazo.
- `REQUEST_OBJECT`: hash e ranges ausentes somente dos objetos autorizados.
- `CHUNK`: hash, offset, comprimento, número e digest do bloco.
- `ACK/WINDOW`: ranges verificados, crédito e backpressure.
- `COMPLETE`: objeto inteiro recebido; não significa ativo até validação.
- `CANCEL/ERROR`: razão limitada e sanitizada; terminar sem afetar save.

Máquina de estados: OFFERED → AUTHORIZED → RECEIVING → HASHED → ANALYZED → CACHED → READY → ACTIVE.
Qualquer falha leva a CANCELLED/REJECTED e fallback. READY/ACTIVE são locais; o remetente não ordena montagem.
Peer só pode anunciar seleção própria. Validar membership, associação playerId, nonce e generation; rejeitar mensagens de quem saiu ou de sessão anterior.
Um hash idêntico pode atender vários actors com referências independentes. Um transferId não pode mudar hash/tamanho após autorização.

## Limites iniciais a validar em protótipo

| Limite proposto | Valor inicial |
| --- | --- |
| Manifesto | 64 KiB, até 4096 entradas |
| Pacote comprimido por seleção | 64 MiB |
| Conteúdo expandido por seleção | 256 MiB |
| Razão de expansão | até 100:1, além do teto absoluto |
| Bloco cosmético | 12 KiB de payload; envelope dentro do limite auditado |
| Concorrência | 1 pacote por peer, no máximo 2 globais |
| Janela não confirmada | até 256 KiB por transferência |
| Banda inicial | até 256 KiB/s por peer e 512 KiB/s global, ajustável para baixo |
| Cache | 1 GiB por padrão, LRU de objetos não em uso |
| Timeout | 15 s sem progresso; orçamento total 10 min; sem retry infinito |

São decisões propostas, não limites garantidos pela Steam. Medir jitter/RTT e fila de gameplay; reduzir/suspender download ao ultrapassar orçamento de latência. Keep-alive e gameplay sempre têm prioridade. Rejeitar tamanho excedido em vez de elevar limite automaticamente.

## Integridade, sandbox e instalação

1. Receber em quarentena fora do scanner global, com nome gerado localmente e .part.
2. Checar hash SHA-256 por bloco para retomar e digest final dos bytes contra manifesto autorizado; tamanho exato, sem dados extras.
3. Hash não valida segurança: executar parser/analisador restrito, idealmente processo separado com baixo privilégio e limites de CPU/memória, sem rede, execução ou escrita fora da quarentena. Definir contenção de Windows/Linux e verificar com testes antes de habilitar automaticamente.
4. Rejeitar path traversal, absoluto, UNC, drive, ADS, nomes reservados, symlink/hardlink, colisões por case/Unicode, overflow, duplicatas e arquivos aninhados/bombas de compressão.
5. Não executar DLL/exe/script, hook, comando de metadados ou ferramenta enviada pelo peer. Recursos gráficos/áudio também são entrada não confiável; validar tamanhos, índices, ponteiros lógicos e codecs.
6. Fechar referências apenas no namespace do pacote e base permitida. Nenhuma escrita em mods locais, save, binário ou configuração do jogo.
7. Após análise e direitos aprovados, rename atômico para cache por hash e registrar versão do validador/proveniência. Ativar pelo resolver por instância em ponto seguro, nunca montar globalmente.
8. Cancelamento/falha remove parciais não retomáveis. Retomada revalida blocos e autorização; mudanças de sessão/hash não herdam consentimento automaticamente.

Proteção de transporte usa garantias da API Steam selecionada; não inventar criptografia caseira nem alegar que hash autentica autor. Logs guardam IDs abreviados, estado, bytes e razão, sem tokens, caminhos privados ou conteúdo.

## Falhas e compatibilidade

Sem Steam/API, disco cheio, licença incerta, versão antiga, hash incorreto, timeout, parser inválido, peer sai: manter Link/voz padrão e permitir jogar se gameplay for compatível.
Sem host migration no MVP. Saída do host termina sessão; salvar pelo caminho upstream e cancelar transferências sem corromper cache.
Downloader HTTP legado permanece preservado nesta entrega. Em implementação futura, não usar HTTP como fallback automático para escapar da política P2P. Importação manual e legado precisam passar pela mesma validação antes de receber isenção cosmética.

## ROM, distribuição e Spacewar

Cada jogador fornece sua própria ROM suportada obtida legalmente. Repositório, testes, logs e releases não podem incluir ROMs nem assets extraídos protegidos; CI usa fixtures sintéticas, hashes e código permitido.
O upstream usa AppID 480 e escreve steam_appid.txt. A Valve apresenta Spacewar como aplicativo de exemplo do Steamworks: [documentação oficial](https://partner.steamgames.com/doc/sdk/api/example).
Preservar o código atual não constitui autorização para publicar outro produto sob essa identidade. Não prometer disponibilidade permanente, aprovação Valve ou ausência de restrições.
Antes de distribuir build com integração alterada: verificar termos/licenças aplicáveis e autorização para AppID/runtime redistribuído; definir AppID autorizado ou transporte alternativo. Não incluir SDK/binários de terceiros sem direito de redistribuição.
Esta publicação contém somente planejamento e mantém as dependências upstream sem acrescentar runtime/ROM/assets.
