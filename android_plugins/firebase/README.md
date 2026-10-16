# Plugin Android: Firebase (Analytics, Crashlytics, Remote Config)

Plugin Godot (Android plugin v2) usado por `jogo/scripts/servicos/analytics.gd` através do singleton `MinhaHistoriaFirebase`.

## Compilar
Requisitos: JDK 17 e Android SDK (API 35).
```bash
gradle wrapper --gradle-version 8.11.1
./gradlew assembleRelease
```
Copie `build/outputs/aar/minha-historia-firebase-release.aar` para `jogo/addons/minha_historia_firebase/bin/`.

## API (GDScript)
| Método | Descrição |
|---|---|
| `inicializar(app_id, api_key, project_id)` | Inicia o Firebase sem precisar de `google-services.json` |
| `logEvent(nome, params_json)` | Evento do Analytics |
| `setUserProperty(nome, valor)` | Propriedade de usuário |
| `recordError(mensagem)` | Erro não fatal no Crashlytics |
| `fetchRemoteConfig(padroes_json)` | Busca a configuração e emite o sinal `remote_config_fetched(json)` |
