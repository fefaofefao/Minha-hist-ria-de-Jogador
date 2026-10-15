# Protótipo: o Momento Decisivo

Final da Copa da Vila, 88 minutos, **Vila 1 x 1 Jardim**. A bola chega em você.

1. **Olhe ao redor:** arraste o dedo (ou o mouse) para virar a cabeça. O tempo corre, o coração acelera e a visão vai fechando.
2. **Escolha:** *Chutar de longe* ou *Driblar o zagueiro*. Se você **olhar para a esquerda**, encontra o Neguinho livre e libera a opção *Tocar pro Neguinho*.
3. **Veja em primeira pessoa:** a jogada acontece pelos olhos do jogador.
4. **Replay:** na câmera da TV.
5. **Nota do lance:** mostra as consequências (amizade, confiança, fama) e o que os olheiros acharam.

Se o tempo acabar, o jogador trava e dá um chute desesperado.

## Como abrir
1. Instale o [Godot 4.5](https://godotengine.org/download) (versão padrão, não a .NET).
2. Em *Importar*, selecione `jogo/project.godot`.
3. Aperte **F5** para jogar.

## Como testar no celular Android
1. No Godot: *Editor → Gerenciar Modelos de Exportação → Baixar*.
2. Instale o Android SDK e o JDK 17 e configure os caminhos em *Editor → Configurações do Editor → Exportar → Android* ([guia oficial](https://docs.godotengine.org/pt-br/4.x/tutorials/export/exporting_for_android.html)).
3. Ative a depuração USB no celular, conecte o cabo e clique no ícone do Android no canto superior direito do editor.
4. Para a Google Play: *Projeto → Exportar → Android*. O preset já está configurado para gerar o **.aab**. A keystore de release **não** vai para o repositório.

## Teste automático
```bash
godot --headless --path jogo -- --teste
```
Esse comando roda as 4 situações (chute, drible, passe e tempo esgotado) sozinho e mostra o resultado de cada uma no terminal.

## Estrutura
- `cenas/lance.tscn`: a cena do lance.
- `scripts/lance.gd`: toda a lógica. O campo, os jogadores, a torcida e a interface são criados por código, sem assets externos.
