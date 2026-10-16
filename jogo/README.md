# Projeto Godot: Minha História de Jogador

## Abrir e jogar no computador
1. Instale o **Godot 4.5.1** (versão padrão): https://godotengine.org/download
2. Em *Importar*, selecione `jogo/project.godot`.
3. Aperte **F5**. No computador, arraste com o mouse para "olhar ao redor".

## Gerar o APK de teste (instalar direto no celular)
*Projeto → Exportar → "Android APK" → Exportar projeto.* Esse preset não precisa de Gradle. Para os pré-requisitos, veja `../docs/PUBLICACAO.md` (seção 1).

## Gerar o AAB para a Google Play
Veja `../docs/PUBLICACAO.md` (seções 2 a 6).

## Testes automáticos
```bash
godot --headless --path jogo res://testes/testes.tscn            # tudo
godot --headless --path jogo res://testes/testes.tscn -- carreira # só carreira
```
Modo demonstração, em que o jogo decide os lances sozinho: `godot --path jogo -- --auto`

## Estrutura
| Pasta | Conteúdo |
|---|---|
| `cenas/` | Uma cena por tela (raiz com script) |
| `scripts/nucleo/` | `jogo.gd` (estado, regras, simulação, salvamento) e `dados.gd` (clubes, eventos, sonhos...) |
| `scripts/lance/` | `situacoes.gd` (gerador de momentos decisivos) e `lance.gd` (motor 3D em primeira pessoa) |
| `scripts/mundo/` | Cenários 3D, jogador low-poly animado e vitrine dos menus |
| `scripts/telas/` | Menu, criação, partida, olheiros, semana, carreira, vida, álbum, loja, configurações, temporada, legado, Lance do Dia |
| `scripts/servicos/` | Anúncios (AdMob), compras (Billing), analytics (Firebase) e áudio sintetizado |
| `scripts/ui/` | Kit de interface, transições, diálogos e componentes |
| `config/servicos.cfg` | IDs de anúncios e produtos, regras de frequência e chaves do Firebase |
| `addons/minha_historia_firebase/` | Inclui o AAR do Firebase no build Gradle |
| `testes/` | Bateria de testes (não vai para o APK) |

## Onde mexer no equilíbrio
- Chances das jogadas: `scripts/lance/situacoes.gd` (`base` de cada opção e `_calcular_chances`)
- Evolução: `Jogo.dar_xp`, `Jogo.fator_idade`, `Jogo._envelhecer`
- Escalação: `Jogo.situacao_titular`
- Economia de moedas: `Jogo.fim_de_temporada`, `Jogo.registrar_desafio`, preços em `dados.gd`
- Anúncios: `config/servicos.cfg` → `[regras_anuncios]`
