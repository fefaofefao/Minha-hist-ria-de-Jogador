# Minha História de Jogador — Documento de Design (rascunho v0.1)

> Documento vivo. Tudo aqui é proposta para discussão; marque com ✅ o que for aprovado.

## 1. Visão geral

- **Gênero:** simulação de carreira de futebol com narrativa e decisões, com partidas jogadas em "momentos decisivos".
- **Plataforma:** Android (Google Play). iOS pode vir depois.
- **Público:** fãs de futebol de 13 anos ou mais, que jogam em sessões curtas de 3 a 10 minutos.
- **Modelo:** gratuito, com anúncios e compras no app.
- **Pitch:** *"Do campinho do bairro à Copa do Mundo: cada lance e cada escolha escrevem a sua história."*

## 2. Prólogo: a final do bairro

O jogo começa com o jogador já em campo, na **final do campeonato do bairro** (ex.: "Copa da Vila"). Há olheiros na arquibancada.

### 2.1 Antes do apito (cerca de 1 minuto)
- Criação rápida do personagem: nome, apelido, aparência, **posição** (atacante, meia, zagueiro, goleiro) e pé dominante.
- Uma cena curta de contexto: a mãe/o pai na torcida, o técnico do time do bairro, o amigo de infância e o rival do outro bairro.

### 2.2 A partida (de 3 a 5 minutos): ✅ mecânica "Escolha e Veja"
- A partida corre em ritmo acelerado (placar e lances narrados). Nos **6 a 8 momentos decisivos**, o jogo **para** e mostra as opções.
- O jogador **escolhe** (ex.: "Chutar cruzado", "Tocar pro Neguinho na esquerda", "Driblar o zagueiro") e **assiste à jogada em primeira pessoa**, pelos olhos do personagem.
- O resultado depende das escolhas, dos atributos, do estado mental e de um pouco de sorte.
- Ao final o jogador recebe uma **nota de 0 a 10**, que soma as escolhas certas, os gols/assistências e um bônus "clutch" pelos lances decisivos no fim do jogo.
- Os detalhes estão na seção 3.

### 2.3 O resultado define o caminho

| Desempenho | Resultado |
|---|---|
| Nota ≥ 8 **ou** decisivo no título | Convite de **clube grande** de base (escolher entre 2 propostas) |
| Nota de 6 a 7,9 | Convite de **clube médio** |
| Nota < 6 | **Peneira** num clube médio: uma segunda chance, com um minijogo de treino |

- Escolhas no prólogo também contam, por exemplo: comemorar provocando o rival ou abraçar o técnico. Elas definem atributos iniciais de **personalidade** (humildade, carisma, temperamento).
- **Ideia de retenção:** perder a final não é *game over*. A história do "azarão" que veio da peneira é um caminho tão bom quanto o outro, só que diferente.

## 3. Mecânica central: "Escolha e Veja" (primeira pessoa)

### 3.1 Fluxo de um momento decisivo
1. **Aviso:** a câmera entra nos olhos do jogador, o som da torcida abafa e o coração acelera.
2. **Olhar ao redor:** o tempo fica em câmera lenta. O jogador **arrasta o dedo para virar a cabeça** e procurar companheiros livres, o goleiro adiantado ou o marcador chegando. Olhar custa tempo.
3. **Escolha:** de 2 a 4 opções com timer. Se o tempo acabar, o personagem decide sozinho (e geralmente mal).
4. **Execução em primeira pessoa:** a jogada acontece pelos olhos do jogador, num clipe de 3 a 6 segundos que pode ser pulado.
5. **Replay:** uma câmera de TV mostra o lance de fora, com a narração do locutor.

### 3.2 Inovações que se apoiam na mecânica
- **"Leitura de jogo" revela opções:** um jogador iniciante vê só 2 opções óbvias. Com o atributo *Visão* evoluído, aparecem opções escondidas (lançamento em profundidade, cavadinha, passe de calcanhar). A evolução fica **visível dentro da cena**, não só nos números.
- **O estado mental muda o que você vê:**
  - Nervoso numa final: visão em túnel (bordas borradas), menos opções, tempo menor.
  - Confiante: campo mais claro e uma opção extra.
  - Cansado: a imagem treme e o tempo encurta.
- **Vozes do campo:** companheiros gritam "Tô livre!" (às vezes mentindo), o técnico grita da beira do campo e a torcida reage. Isso dá **informação por áudio**, e é preciso escolher em quem confiar.
- **Escolhas com consequência fora de campo:** chutar em vez de passar para o amigo livre faz o relacionamento cair. Simular falta pode render o pênalti, ou um cartão e fama de "cai-cai" na imprensa.
- **Vibração (háptico):** batida do coração, contato físico e a rede balançando.
- **Momentos de memória:** gols e lances marcantes ficam num **álbum da carreira**. Clipes curtos em primeira pessoa podem ser **exportados para TikTok/Reels**, o que funciona como marketing orgânico.
- **Rival recorrente:** o rival da final do bairro reaparece ao longo da carreira (base, profissional, seleção) e se lembra dos seus lances contra ele.
- **Flashback no fim de carreira:** na aposentadoria, uma montagem em primeira pessoa com os momentos do álbum, desde o campinho do bairro.

### 3.3 Riscos e cuidados
- **Passividade:** assistir demais cansa. Os clipes precisam ser curtos e puláveis, e o momento de "olhar ao redor" mantém o jogador ativo.
- **Repetição:** construir uma **biblioteca de jogadas** reaproveitáveis, com variação de estádio, uniformes, clima e adversários.
- **Custo de produção:** a primeira pessoa pede **3D**. A sugestão é usar 3D *low-poly* estilizado, que é barato, roda em celulares fracos e envelhece bem. As animações vêm de uma base de *motion capture* pronta (ex.: Mixamo).

## 3b. Loop principal (pós-prólogo)

**Semana a semana:**
1. **Agenda:** distribuir a energia da semana entre treinar, estudar, descansar, família/amigos e redes sociais.
2. **Evento/decisão:** cartas narrativas (ex.: "Um empresário quer te representar", "Seu amigo te chama pra uma festa na véspera do jogo").
3. **Jogo do fim de semana:** de 3 a 6 momentos decisivos, que viram nota e evolução.
4. **Resultado:** XP nos atributos, moral, fama e dinheiro.

### Atributos
- **Técnicos:** finalização, passe, drible, defesa (ou reflexo/posicionamento, para goleiros).
- **Físicos:** velocidade, resistência, força.
- **Mentais:** confiança, foco, liderança.
- **Vida:** saúde, felicidade, relacionamento com família/técnico/torcida, dinheiro e fama.

## 4. Fases da carreira

1. **Base:** Sub-15 → Sub-17 → Sub-20 (subir para o profissional ou ser dispensado).
2. **Profissional:** estreia, disputa por titularidade, empréstimos.
3. **Transferências:** clubes maiores e o exterior (ligas fictícias inspiradas em Europa, Ásia, EUA e Oriente Médio).
4. **Seleção:** convocações, Copa.
5. **Fim de carreira:** aposentadoria, seguido de uma tela de **legado** (troféus, recordes, "Hall da Fama"). A partir daí dá para começar de novo com outro personagem, ou com o **filho do jogador** (Nova Geração+).

## 5. Monetização (sem "pagar para ganhar" pesado)

**Anúncios**
- **Recompensados (os principais):** recuperar energia, refazer um momento decisivo, dobrar o salário da semana, ver a proposta de um clube secreto.
- **Intersticiais:** no máximo 1 a cada X partidas, e nunca no meio de um jogo.

**Compras no app**
- **Remover anúncios** (compra única).
- **Moedas/"Craque Coins":** cosméticos (chuteiras, visual, comemorações), itens de vida (carro, casa).
- **Passe de Temporada:** recompensas extras e eventos especiais.
- **Pacote Iniciante:** oferta única barata.

**Regra de ouro:** dinheiro compra **conveniência e estilo**, não nota em campo.

## 6. Pontos legais e da Google Play
- **Nada de clubes, ligas ou jogadores reais** (exige licença). Tudo deve ser fictício, com nomes e escudos próprios.
- **Anúncios:** AdMob com mediação, consentimento GDPR/LGPD (UMP SDK) e classificação etária correta.
- **Compras:** Google Play Billing.
- **Política de Família:** se o público incluir menores de 13 anos, as regras de anúncios ficam mais rígidas. A sugestão é mirar 13+.
- É preciso ter uma **política de privacidade** publicada.

## 7. Tecnologia (a decidir)

| Opção | Prós | Contras |
|---|---|---|
| **Godot 4** (recomendado) | Gratuito, leve, ótimo em 2D e UI, exporta AAB para Android | Plugins de AdMob/Billing são da comunidade |
| Unity | Muitos tutoriais, SDKs oficiais de anúncios e IAP | Mais pesado, licença/termos |
| Flutter + Flame | Ótimo para jogos com muita UI/menus | Menos ferramentas para animação de jogo |

Como o jogo é feito **principalmente de UI e narrativa, com minijogos 2D**, Godot 4 ou Flutter + Flame atendem bem.

## 8. MVP (primeira versão jogável)
1. Criação de personagem
2. Prólogo completo (final do bairro, com momentos de chute, passe e drible)
3. Escolha de clube de base (3 clubes fictícios)
4. Uma temporada Sub-15 (loop semanal com 10 eventos de cartas)
5. Salvamento local
6. Anúncio recompensado de teste + compra "remover anúncios"

## 9. Perguntas em aberto
- [ ] Visual: 2D cartoon, pixel art ou ilustrado?
- [ ] O jogador pode escolher a posição, ou ela é definida pelo desempenho?
- [ ] Ambientação: Brasil explícito (várzea, periferia), ou genérico?
- [ ] Haverá vida pessoal profunda (namoro, família, escola) ou foco no futebol?
- [ ] Engine: Godot, Unity ou Flutter?
