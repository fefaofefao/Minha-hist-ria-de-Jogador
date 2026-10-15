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

### 2.2 A partida (de 3 a 5 minutos)
- O jogador não controla o time inteiro. Ele vive de **6 a 8 "momentos decisivos"** do personagem:
  - **Chute:** deslizar o dedo para mirar e definir a força. O goleiro reage.
  - **Passe:** tocar no companheiro livre antes que o tempo acabe.
  - **Drible:** sequência de toques/deslizes no ritmo certo.
  - **Defesa/desarme:** tocar na hora certa (para zagueiros e goleiros, os momentos mudam conforme a posição).
- Entre os momentos aparece um placar narrado, em texto ("O rival empata aos 30'!").
- Ao final o jogador recebe uma **nota de 0 a 10**, calculada a partir dos acertos, gols/assistências e de um bônus de "clutch" pelos lances no fim do jogo.

### 2.3 O resultado define o caminho

| Desempenho | Resultado |
|---|---|
| Nota ≥ 8 **ou** decisivo no título | Convite de **clube grande** de base (escolher entre 2 propostas) |
| Nota de 6 a 7,9 | Convite de **clube médio** |
| Nota < 6 | **Peneira** num clube médio: uma segunda chance, com um minijogo de treino |

- Escolhas no prólogo também contam, por exemplo: comemorar provocando o rival ou abraçar o técnico. Elas definem atributos iniciais de **personalidade** (humildade, carisma, temperamento).
- **Ideia de retenção:** perder a final não é *game over*. A história do "azarão" que veio da peneira é um caminho tão bom quanto o outro, só que diferente.

## 3. Loop principal (pós-prólogo)

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
