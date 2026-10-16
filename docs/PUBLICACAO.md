# Guia de publicação na Google Play

Este guia leva o jogo do APK de teste até a loja, com anúncios (AdMob), compras (Google Play Billing) e Firebase de verdade.

> **Estado atual:** o jogo está 100% jogável. Anúncios, compras e analytics rodam em **modo simulado** (marcados como "modo de teste") até os plugins nativos serem instalados. O código já detecta os plugins sozinho: instalou, passou a funcionar de verdade.

---

## 1. Ferramentas no seu computador

1. **Godot 4.5.1** (versão padrão, não a .NET): https://godotengine.org/download
2. **Android Studio** (só para o SDK): instale e, no SDK Manager, marque:
   - Android SDK Platform 35 e Build-Tools 35
   - Android SDK Command-line Tools
   - NDK (Side by side), na versão que o Godot pedir no primeiro build
3. **JDK 17**
4. No Godot: *Editor → Configurações do Editor → Exportar → Android*, aponte o **Android SDK Path** e o **Java SDK Path**.
5. No Godot: *Editor → Gerenciar Modelos de Exportação → Baixar e instalar*.

## 2. Chave de assinatura (upload key)

Crie uma vez e **guarde em local seguro** (sem ela você não atualiza o app):

```bash
keytool -genkeypair -v -keystore upload.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000
```

No Godot, em *Projeto → Exportar → "Android Play (AAB)"*, preencha a seção **Keystore → Release** com o arquivo, o alias e a senha. Esses dados ficam em `.godot/export_credentials.cfg` e **não vão para o Git**.

Na Play Console, ative o **Play App Signing**: o Google guarda a chave final e você assina só com a upload key.

## 3. AdMob (anúncios)

1. Crie a conta em https://admob.google.com e cadastre o app Android `com.fefaofefao.minhahistoriadejogador`.
2. Crie 2 blocos de anúncio:
   - **Premiado (Rewarded)**: usado no "E se...?", nos comerciais do patrocinador, na massagem do fisio, no tratamento, em dobrar o bônus da temporada e em tentar de novo o Lance do Dia.
   - **Intersticial**: aparece só entre partidas, com regras de frequência.
3. Instale o plugin **Poing Studios AdMob**: no Godot, aba **AssetLib**, busque "AdMob", instale e ative em *Projeto → Configurações → Plugins*. Siga o guia Android do plugin; ele baixa as dependências pelo menu *Projeto → Ferramentas → AdMob Manager*.
4. Em `jogo/config/servicos.cfg`, troque os IDs de teste pelos seus:
   ```ini
   app_id_android="ca-app-pub-XXXXXXXX~YYYYYYYY"
   recompensado_android="ca-app-pub-XXXXXXXX/ZZZZZZZZ"
   intersticial_android="ca-app-pub-XXXXXXXX/WWWWWWWW"
   ```
5. O consentimento de privacidade (LGPD/GDPR) já é pedido via UMP (`scripts/servicos/anuncios.gd`). Configure a mensagem em *AdMob → Privacidade e mensagens*.

> Nunca clique nos seus próprios anúncios reais. Para testar, use os IDs de teste (os que já estão no arquivo) ou cadastre seu aparelho como dispositivo de teste.

**Regras de frequência**, já implementadas e ajustáveis em `servicos.cfg` ou pelo Remote Config:
- nenhum intersticial antes da 3ª partida;
- no máximo 1 a cada 2 partidas, com intervalo mínimo de 3 minutos;
- nunca para quem comprou "Remover anúncios" ou "Craque VIP";
- nunca no meio de um lance.

## 4. Compras no app (Google Play Billing)

1. Baixe o plugin oficial **GodotGooglePlayBilling** (godot-sdk-integrations/godot-google-play-billing), versão para Godot 4.2+, e copie a pasta do addon para `jogo/addons/`. Ative-o em *Plugins*.
2. Na Play Console, em *Monetizar → Produtos → Produtos no app*, crie os produtos **com estes IDs exatos**:

| ID | Tipo | Preço sugerido | O que entrega |
|---|---|---|---|
| `pacote_iniciante` | Único | R$ 6,90 | 1.000 moedas + Chuteira Relâmpago + 5 fichas (oferta única, 48 h após o prólogo) |
| `remover_anuncios` | Único | R$ 12,90 | Sem intersticiais |
| `craque_vip` | Único | R$ 29,90 | Sem anúncios + 1 "E se...?" grátis por partida + moedas x2 no Lance do Dia + Chuteira Dourada |
| `moedas_500` | Consumível | R$ 4,90 | 500 moedas |
| `moedas_1200` | Consumível | R$ 9,90 | 1.200 moedas (+20%) |
| `moedas_3000` | Consumível | R$ 19,90 | 3.000 moedas (+50%) |

3. O jogo consulta os preços reais na loja (com a moeda local) e faz o consumo e o reconhecimento das compras (`scripts/servicos/compras.gd`). O botão "Restaurar compras" está em Loja e em Configurações.

## 5. Firebase (Analytics, Crashlytics, Remote Config)

1. Crie o projeto em https://console.firebase.google.com e adicione um app Android com o pacote `com.fefaofefao.minhahistoriadejogador`.
2. Compile o plugin nativo que está em `android_plugins/firebase`:
   ```bash
   cd android_plugins/firebase
   gradle wrapper && ./gradlew assembleRelease
   ```
   Copie o arquivo `build/outputs/aar/*-release.aar` para `jogo/addons/minha_historia_firebase/bin/minha-historia-firebase-release.aar`. O addon já está ativado e inclui o AAR e as dependências no build.
3. Em `servicos.cfg` → `[firebase]`, preencha `app_id`, `api_key` e `project_id` (você encontra esses dados em *Configurações do projeto → Seus apps*).
4. **Remote Config** (opcional, para ajustar sem atualizar o app): `intersticial_a_cada_partidas`, `intersticial_partidas_minimas`, `oferta_iniciante_horas`, `moedas_desafio_diario`, `bonus_patrocinio`.

**Funil de eventos que já são enviados:** `tutorial_inicio`, `prologo_inicio`, `tutorial_fim`, `clube_escolhido`, `partida_fim`, `evento_escolha`, `temporada_fim`, `transferencia`, `sonho`, `aposentadoria`, `nova_geracao`, `desafio_diario`, `loja_aberta`, `oferta_vista`, `compra_iniciada`, `purchase`, `compra_cancelada`, `anuncio_recompensado_pedido`, `anuncio_recompensado_ganho`, `anuncio_intersticial`, `moedas_ganhas`, `moedas_gastas`.

## 6. Gerar o AAB

1. No Godot: *Projeto → Instalar modelo de build Android*.
2. *Projeto → Exportar → "Android Play (AAB)" → Exportar projeto*. O resultado sai em `build/MinhaHistoriaDeJogador.aab`.
3. A cada nova versão, aumente `version/code` (1, 2, 3...) e `version/name` (1.0.1...) no preset.

> **Target SDK:** a Google Play exige uma API alvo recente (35 ou mais). O Godot 4.5 já usa a 35. Se a exigência subir, defina `gradle_build/target_sdk` no preset AAB.

## 7. Ficha da loja (Play Console)

- **Ícone 512×512:** `docs/loja/icone_512.png`
- **Gráfico de destaque 1024×500:** `docs/loja/destaque_1024x500.png`
- **Capturas de tela (retrato):** `docs/loja/capturas/`
- **Categoria:** Jogos → Esportes
- **Classificação indicativa:** responda ao questionário IARC. O jogo não tem violência, linguagem imprópria nem apostas com dinheiro real. Há compras no app e anúncios.
- **Público-alvo:** 13 anos ou mais. Isso evita as regras da Política de Famílias para anúncios.
- **Política de privacidade:** publique `docs/privacidade.html` (por exemplo com o GitHub Pages: *Settings → Pages → Deploy from branch → /docs*) e use o link em Configurações → Política de privacidade (`scripts/telas/config.gd`, constante `URL_PRIVACIDADE`).
- **Segurança dos dados:** declare que o app coleta o ID de publicidade (AdMob), dados de uso/diagnóstico (Firebase) e o histórico de compras (Google Play). Nada é vendido. Os dados são criptografados em trânsito.

**Texto curto sugerido (80 caracteres):**
> Do campinho do bairro ao Mundial. Escolha a jogada e viva o lance em 1ª pessoa.

**Descrição sugerida:**
> Tudo começa na final do campeonato do bairro. Os olheiros estão na arquibancada e a bola chega em você.
>
> Em MINHA HISTÓRIA DE JOGADOR você não aperta botões para correr: você LÊ O JOGO. Olhe ao redor, encontre o companheiro livre, perceba o goleiro adiantado e escolha a jogada. Então assista ao lance pelos olhos do seu jogador.
>
> - Momentos decisivos em primeira pessoa, com coração acelerado e visão em túnel
> - Olhar revela jogadas escondidas: caneta, cobertura, lançamento
> - Errou? "E se...?": reviva o lance e mude a história
> - Carreira completa: base, profissional, exterior e Seleção
> - Escolhas de vida: família, amigos, empresário, imprensa e rival
> - Sonhos: dar uma casa para a mãe, a Bola de Cristal, reformar o campinho
> - Álbum de memórias, Lance do Dia e Nova Geração: jogue com o filho da sua lenda
>
> Todos os clubes, ligas e jogadores são fictícios.

## 8. Checklist antes de enviar

- [ ] IDs reais de AdMob em `servicos.cfg` (e plugin AdMob instalado)
- [ ] Produtos criados na Play Console com os IDs exatos
- [ ] Plugin Billing instalado
- [ ] Firebase configurado (opcional, mas recomendado)
- [ ] URL da política de privacidade publicada
- [ ] `version/code` incrementado
- [ ] Testado no celular com o APK (`build/MinhaHistoriaDeJogador.apk`)
- [ ] Teste interno na Play Console antes da produção
