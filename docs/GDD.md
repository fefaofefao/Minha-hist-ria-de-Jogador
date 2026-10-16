# Minha História de Jogador: Documento de Design (v1.1)

> Simulação de carreira de futebol com **decisões em primeira pessoa**. Godot 4.5, 3D low-poly, Android, retrato, sessões curtas.

## 1. Pilares
1. **Ler o jogo é a habilidade.** Não há controle de habilidade motora: o jogador olha ao redor, interpreta e decide.
2. **Ver pelos próprios olhos.** Cada decisão é executada em primeira pessoa, com coração, pressão e visão em túnel.
3. **A vida decide a carreira.** Família, técnico, amigo, empresário e rival mudam o que acontece em campo.
4. **Do bairro ao mundo.** O cenário evolui junto com a carreira: várzea, depois o CT da base, depois o estádio, depois a Seleção.

## 2. Loop de jogo
**Semana (2 a 4 min):** agenda com 2 atividades, depois um acontecimento da vida (carta com escolhas) e por fim a partida. Na partida, de 1 a 4 momentos decisivos, seguidos do relatório.

**Temporada:** liga em turno único (8 ou 10 times). Os 2 primeiros fazem a final. Pode haver convocação para a Seleção. No fim: balanço, prêmios, evolução, rival e propostas.

**Carreira:** dos 15 anos (Sub-15, Sub-17, Sub-20) ao profissional, ao exterior (9 países fictícios) e à aposentadoria (dos 33 aos 39 anos). Depois vem o legado e a Nova Geração (o filho herda talento).

## 3. Momento decisivo ("Escolha e Veja")
| Fase | O que acontece |
|---|---|
| Plano de TV | Mostra a situação ("88' • Final"); a câmera entra nos olhos do jogador |
| Leitura | Tempo em câmera lenta. **Arrastar o dedo vira a cabeça.** O timer depende de Frieza e pressão |
| Pontos de interesse | Olhar ~0,45 s para um POI **revela uma opção escondida** (companheiro livre, goleiro adiantado, pernas abertas do zagueiro, leitura do goleiro no pênalti) |
| Instinto | Com Visão ≥ 55, cada opção mostra uma sensação: Arriscado, Possível, Boa ou Ótima |
| Talento | Opções escondidas aparecem sozinhas se o atributo for alto (ex.: Drible ≥ 72 libera a caneta) |
| Execução | A jogada acontece em primeira pessoa (chute, drible, passe, cabeceio, pênalti, falta) |
| Comemoração | Depois do gol, você escolhe como comemorar; cada comemoração tem efeito na carreira |
| "E se...?" | Se errar, pode **reviver o lance** (anúncio, ficha ou VIP), uma vez por partida, sabendo o que vai acontecer |
| Replay | Câmera de TV (ou atrás do gol no pênalti), que pode ser pulada |

**6 situações procedurais:** chance na área, mano a mano, contra-ataque, cruzamento (a bola congela no ar), falta com barreira e pênalti. A posição do jogador muda a frequência de cada uma.

**Chance de cada opção** = base + atributos × peso − pressão × (1 − Frieza) − (força do adversário − overall) + confiança.

**Desfechos:** gol, assistência, defesa, trave, fora, perdeu a bola, interceptado e "quase". A nota do lance soma na nota da partida.

## 4. Progressão
- **8 atributos:** Finalização, Passe, Drible, Cabeceio, Velocidade, Físico, Visão, Frieza. O overall é ponderado pela posição (Atacante, Ponta, Meia).
- **XP** vem de treinos e dos lances; o ganho diminui com a idade e perto do potencial (de 80 a 92, mais herança).
- **Envelhecimento:** depois dos 30, Velocidade e Físico caem mais rápido; Visão, Frieza e Passe aguentam melhor.
- **Escalação:** depende de overall, forma (média recente), relação com o técnico e energia, comparados com a força do clube. Pode dar titular, reserva (entra no 2º tempo) ou fora da lista.
- **Lesões:** o risco sobe com energia baixa. Há tratamento por anúncio ou moedas.
- **Contrato (aba Contrato da Carreira):** salário, validade, valor de mercado e salário de mercado, mais a relação com a **Diretoria**.
  - **Renegociar salário:** pedir +10%, +25% ou +50%. A chance depende de quanto o pedido passa do mercado, da relação com a diretoria, da forma e da fama. O empresário dá um palpite antes ("tá tranquilo", "vai ser duro"). Resultado: aceito, contraproposta (aceitar ou recusar) ou recusado. Pedido exagerado irrita a diretoria e pode vazar na imprensa. Uma tentativa por temporada.
  - **Pedir para sair:** quatro motivos (falta de minutos, clube maior, jogar no exterior, problema com o técnico). Se a diretoria libera, as propostas do fim de temporada aumentam e excluem o próprio clube. Se recusa, dá para **forçar a saída**: você é afastado do time titular, a torcida e a diretoria ficam contra, e o mercado desconfia (propostas menores). Dá para voltar atrás.
  - Eventos ligados: renovação antecipada, sondagem de clube grande e cobrança do presidente.

## 5. Vida fora de campo
- **33 eventos narrativos** com condições (idade, fama, flags, dinheiro, forma) e escolhas com risco. Exemplos: o amigo reprovado na peneira, o empresário Marcão, a festa na véspera, a promessa da casa para a mãe, o vídeo antigo vazado, a proposta suspeita de aposta.
- **Relações:** família, técnico, torcida, amigo e diretoria.
- **Sonhos (11):** primeiro contrato, carro, casa da mãe, Seleção, exterior, título, artilharia, 100 gols, Mundial, Bola de Cristal e reformar o campinho da Vila. Alguns são comprados com o dinheiro da carreira.
- **Rival:** nasce na final do bairro, evolui em paralelo, aparece nas notícias e nos clássicos, e é comparado com você no legado.
- **Álbum de memórias (16):** cada lance marcante vira uma figurinha. As bloqueadas mostram a dica do que fazer.

## 6. Retenção
| Sistema | Gancho |
|---|---|
| Prólogo forte | Final do bairro com tutorial embutido; a nota define o clube (grande, médio ou peneira) |
| Objetivo da temporada | Meta escolhida no início, com recompensa no fim |
| Lance do Dia | O mesmo lance para todos no dia; sequência de 7 dias com bônus crescente |
| Álbum e sonhos | Metas de curto e longo prazo sempre visíveis |
| Rival | Rivalidade pessoal contínua |
| Nova Geração | Meta-progressão infinita (o filho herda talento e fama) |
| Hall da Fama | Comparação entre gerações |

## 7. Monetização (ética e sem "pagar para vencer")
**Anúncios recompensados, sempre opcionais e diegéticos:**
- "E se...?" (reviver o lance que deu errado, o momento de maior emoção)
- Gravar comercial do patrocinador (dinheiro da carreira, até 3 por dia)
- Massagem do fisio (+30 de energia, 1 por semana)
- Tratamento intensivo (−1 semana de lesão)
- Dobrar o bônus da temporada
- Nova tentativa no Lance do Dia

**Intersticial:** só depois da partida. Nenhum antes da 3ª partida, no máximo 1 a cada 2 partidas, com intervalo de 3 min. Nunca para pagantes. Sem banners.

**Compras:** Pacote do Moleque (oferta única de 48 h, mostrada logo depois do prólogo), Craque VIP, Remover anúncios e 3 pacotes de moedas.

**Moedas (moeda premium):** usadas em cosméticos (chuteiras visíveis em primeira pessoa, comemorações, cores de cabelo), fichas "E se...?", treino com lenda e tratamento. Elas **não compram nota em campo**.

## 8. Tecnologia
- **Godot 4.5.1**, renderer Mobile, retrato 720×1280 com área segura (notch).
- **Tudo procedural:** cenários, jogadores, ícones de UI (Material Icons), **áudio sintetizado** (torcida, apito, coração, samba com cavaquinho em Karplus-Strong).
- **Gráficos (v1.1):** shaders próprios para gramado (listras de corte, linhas por SDF, desgaste perto do gol, campo de terra na várzea), céu com sol, nuvens e estrelas, torcida em silhueta animada (pula no gol, bandeiras, lanternas de celular à noite), rede em losango que balança no gol, bola com gomos e bandeirinhas tremulando. Jogadores com corpo torneado (cabeça com olhos, sobrancelhas, nariz, 6 cabelos), articulações de joelho e cotovelo, camisas com padrão de clube (lisa, listras, faixa, metade) e sombra de contato. Efeitos de lance: rastro da bola, grama ou poeira levantando no chute e câmera lenta no gol. Iluminação ACES, brilho (glow), névoa e luzes de estádio com refletores. Tudo agrupado em MultiMesh para rodar em celular.
- **Serviços com adaptadores:** AdMob (Poing), Google Play Billing (oficial) e Firebase (plugin próprio em `android_plugins/firebase`). Sem os plugins, rodam em modo simulado.
- **Testes:** `godot --headless --path jogo res://testes/testes.tscn` (compilação, situações, 6 carreiras completas, salvamento, compras, 30 lances 3D e telas).

## 9. Próximos passos sugeridos
- Posições de defesa e goleiro (situações próprias)
- Clássicos com narração especial e "jogo da vida" na final do Mundial
- Vestiário pré-jogo (discurso do técnico como escolha)
- Eventos sazonais (Copa, fim de ano) via Remote Config
- Localização (inglês e espanhol)
