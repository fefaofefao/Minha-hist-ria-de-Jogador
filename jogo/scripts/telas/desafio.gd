extends TelaBase
## Lance do Dia: o mesmo lance para todos os jogadores no dia (semente pela data).
## Sequência de dias seguidos aumenta a recompensa. Uma nova tentativa por vídeo.

const LANCE := preload("res://cenas/lance.tscn")

var _tentativa_extra := false


func construir() -> void:
	cabecalho("LANCE DO DIA", "res://cenas/menu.tscn", Jogo.hoje())
	if not Jogo.desafio_disponivel():
		conteudo.add_child(UI.paragrafo("Você já jogou o lance de hoje. Volte amanhã para manter a sequência!", 26, UI.TEXTO))
		return
	var seq := int(Jogo.perfil["desafio"].get("sequencia", 0))
	var card := UI.cartao_borda(Color("221a3d"), UI.ROXO, 26, 26, 3)
	var col := UI.vbox(14)
	card.add_child(col)
	col.add_child(UI.icone("hoje", 80, UI.ROXO))
	var t := UI.titulo("UM LANCE. UMA DECISÃO.", 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var p := UI.paragrafo("Todo mundo joga o mesmo lance hoje. Faça gol ou assistência e ganhe %d moedas%s." % [int(Analytics.remoto("moedas_desafio_diario")) * (2 if Jogo.vip() else 1), " (VIP x2)" if Jogo.vip() else ""], 24, UI.TEXTO)
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(p)
	var fogo := UI.hbox(8)
	fogo.alignment = BoxContainer.ALIGNMENT_CENTER
	fogo.add_child(UI.icone("fogo", 40, UI.LARANJA))
	fogo.add_child(UI.titulo("%d dia%s seguido%s" % [seq, "s" if seq != 1 else "", "s" if seq != 1 else ""], 34, UI.LARANJA))
	col.add_child(fogo)
	var trilha := UI.hbox(8)
	trilha.alignment = BoxContainer.ALIGNMENT_CENTER
	for dia in range(1, 8):
		var feito := dia <= seq
		var hoje := dia == seq + 1
		var bolinha := UI.cartao_borda(Color(UI.LARANJA, 0.25) if feito else UI.CARTAO2, UI.LARANJA if (feito or hoje) else UI.LINHA, 30, 0, 3 if hoje else 2)
		bolinha.custom_minimum_size = Vector2(64, 64)
		var nd := UI.titulo(str(dia), 28, UI.LARANJA if feito else (UI.TEXTO if hoje else UI.TEXTO3))
		nd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nd.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bolinha.add_child(nd)
		trilha.add_child(bolinha)
	col.add_child(trilha)
	col.add_child(UI.paragrafo("Bônus de sequência: +10 moedas por dia seguido (até 7). Perder um dia zera a sequência.", 20, UI.TEXTO2))
	conteudo.add_child(card)
	conteudo.add_child(UI.expansor())
	var b := UI.botao("Jogar o lance", "play", "primario", 100)
	b.pressed.connect(_jogar)
	conteudo.add_child(b)


func _jogar() -> void:
	var d := Jogo.contexto_desafio()
	var ctx: Dictionary = d["ctx"]
	if _tentativa_extra:
		ctx["semente"] = int(ctx["semente"]) + 7  # nova tentativa, novo sorteio
	var s := Situacoes.gerar(d["tipo"], ctx)
	visible = false
	Audio.musica(false)
	var l: Lance = LANCE.instantiate()
	get_parent().add_child(l)
	l.iniciar(s)
	var r: Dictionary = await l.terminou
	l.queue_free()
	Engine.time_scale = 1.0
	visible = true
	Audio.musica(true)
	var bom: bool = r["desfecho"] in ["gol", "assistencia"]
	if not bom and not _tentativa_extra:
		var esc := await Tela.dialogo("Quase!", "Quer tentar de novo assistindo a um vídeo?", [["Tentar de novo", "anuncio", "anuncio"], ["Receber prêmio de consolação", "moeda", "fantasma"]], "replay", UI.ROXO)
		if esc == 0 and await Anuncios.recompensado("desafio_retry"):
			_tentativa_extra = true
			_jogar()
			return
	var ganho := Jogo.registrar_desafio(bom)
	await Tela.recompensa("Lance do Dia", ["GOL!" if r["desfecho"] == "gol" else ("ASSISTÊNCIA!" if bom else "Não foi dessa vez."), "+%d moedas" % ganho,
		"Sequência: %d dia(s)" % int(Jogo.perfil["desafio"]["sequencia"])])
	Tela.ir("res://cenas/menu.tscn")
