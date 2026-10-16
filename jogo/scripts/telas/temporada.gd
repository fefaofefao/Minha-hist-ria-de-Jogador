extends TelaBase
## Fim de temporada: balanço, prêmios, evolução, rival, recompensa (dobrável
## com anúncio), aposentadoria opcional e propostas para a próxima temporada.

var resumo: Dictionary
var _col: VBoxContainer


func construir() -> void:
	if not Jogo.tem_carreira():
		Tela.ir.call_deferred("res://cenas/menu.tscn")
		return
	if not Jogo.temporada_acabou():
		Tela.ir.call_deferred("res://cenas/hub.tscn")
		return
	Audio.musica(true)
	resumo = Jogo.fim_de_temporada()
	cabecalho("FIM DA TEMPORADA %d" % int(resumo["ano"]), "", "%s • %s • %d anos" % [resumo["clube"], resumo["categoria"], int(Jogo.carreira["jogador"]["idade"]) - 1])
	var rol := UI.rolagem()
	conteudo.add_child(rol)
	_col = UI.vbox(16)
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(_col)
	_numeros()
	_conquistas()
	_evolucao()
	_rival()
	_recompensa()


func _numeros() -> void:
	var grade := GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 10)
	for d in [["Jogos", str(int(resumo["jogos"]))], ["Gols", str(int(resumo["gols"]))], ["Assist.", str(int(resumo["assist"]))],
			["Média", "%.1f" % float(resumo["media"]) if int(resumo["jogos"]) > 0 else "-"]]:
		var c := UI.cartao(UI.CARTAO, 18, 14)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(0)
		var n := UI.titulo(d[1], 46, UI.OURO if d[0] != "Média" else UI.cor_nota(float(resumo["media"])))
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(n)
		var l := UI.rotulo(d[0].to_upper(), 18, UI.TEXTO2, "titulo")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		c.add_child(v)
		grade.add_child(c)
	_col.add_child(grade)
	var pos := UI.paragrafo("Campanha: %dº lugar • Campeão: %s" % [int(resumo["posicao"]), resumo["campeao"]], 23, UI.TEXTO)
	_col.add_child(pos)


func _conquistas() -> void:
	var itens: Array = []
	for t in resumo["titulos"]:
		itens.append(["trofeu", "Campeão: " + t, UI.OURO])
	for p in resumo["premios"]:
		itens.append(["medalha", p, UI.OURO])
	var o: Dictionary = resumo.get("objetivo", {})
	if not o.is_empty():
		itens.append(["ok" if resumo["objetivo_ok"] else "fechar", "Objetivo: %s" % o["texto"], UI.VERDE if resumo["objetivo_ok"] else UI.TEXTO3])
	if itens.is_empty():
		return
	var sec := Componentes.secao("Conquistas", "trofeu")
	for it in itens:
		var l := UI.hbox(10)
		l.add_child(UI.icone(it[0], 30, it[2]))
		var t := UI.paragrafo(it[1], 23, UI.TEXTO)
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_child(t)
		sec[1].add_child(l)
	_col.add_child(sec[0])
	if not resumo["titulos"].is_empty():
		Audio.tocar("gol", 0.7)


func _evolucao() -> void:
	var ev: Dictionary = resumo.get("evolucao", {})
	var sec := Componentes.secao("Overall %d" % Jogo.overall(), "estrela")
	if ev.is_empty():
		sec[1].add_child(UI.paragrafo("Seus atributos ficaram estáveis nesta temporada.", 21))
	for a in ev:
		var d := float(ev[a])
		sec[1].add_child(UI.linha_status(Dados.ICONES_ATRIBUTOS[a], "%s  %s%.1f" % [Dados.NOMES_ATRIBUTOS[a], "+" if d > 0 else "", d],
			Jogo.atributo(a), UI.VERDE if d > 0 else UI.VERMELHO, str(int(Jogo.atributo(a)))))
	if int(Jogo.carreira["jogador"]["idade"]) >= 30:
		sec[1].add_child(UI.paragrafo("Depois dos 30, o físico começa a cair. A experiência (visão, frieza, passe) segura melhor.", 20, UI.TEXTO3))
	_col.add_child(sec[0])


func _rival() -> void:
	var r: Dictionary = resumo["rival"]
	var sec := Componentes.secao("E o seu rival?", "fogo", UI.VERMELHO)
	sec[1].add_child(UI.paragrafo("%s joga no %s. Overall %d • %d gols na carreira." % [r["nome"], r["clube"], int(r["overall"]), int(r["gols"])], 22, UI.TEXTO))
	var voce := Jogo.overall()
	var msg := "Você está à frente dele!" if voce > int(r["overall"]) else ("Empate técnico. A disputa segue." if voce == int(r["overall"]) else "Ele está à frente... por enquanto.")
	sec[1].add_child(UI.rotulo(msg, 22, UI.OURO, "forte"))
	_col.add_child(sec[0])


func _recompensa() -> void:
	var temp: Dictionary = Jogo.carreira["temp"]
	var moedas := int(resumo["moedas"])
	if temp.get("moedas_recebidas", false):
		_proximo_passo()
		return
	var card := UI.cartao_borda(Color("2a1f05"), UI.OURO, 24, 22)
	var col := UI.vbox(14)
	card.add_child(col)
	var l := UI.hbox(12)
	l.alignment = BoxContainer.ALIGNMENT_CENTER
	l.add_child(UI.icone("moeda", 56, UI.OURO))
	l.add_child(UI.titulo("+%d moedas" % moedas, 52, UI.OURO))
	col.add_child(l)
	var dobrar := UI.botao("Dobrar com um vídeo", "anuncio", "anuncio", 84)
	var receber := UI.botao("Receber", "ok", "primario", 84)
	col.add_child(dobrar)
	col.add_child(receber)
	_col.add_child(card)
	var feito := [false]
	dobrar.pressed.connect(func() -> void:
		if feito[0]:
			return
		if await Anuncios.recompensado("dobrar_temporada"):
			feito[0] = true
			_receber(moedas * 2, card))
	receber.pressed.connect(func() -> void:
		if feito[0]:
			return
		feito[0] = true
		_receber(moedas, card))


func _receber(qtd: int, card: Control) -> void:
	Jogo.ganhar_moedas(qtd, "temporada")
	Jogo.carreira["temp"]["moedas_recebidas"] = true
	Jogo.salvar_carreira()
	Audio.tocar("moeda")
	Tela.aviso("+%d moedas!" % qtd, "moeda", UI.OURO)
	card.queue_free()
	_proximo_passo()


func _proximo_passo() -> void:
	if Jogo.deve_aposentar():
		var b := UI.botao("Encerrar a carreira", "trofeu", "primario", 96)
		_col.add_child(UI.paragrafo("O corpo pediu: é hora de pendurar as chuteiras.", 24, UI.TEXTO))
		b.pressed.connect(_aposentar)
		_col.add_child(b)
		return
	if Jogo.pode_aposentar():
		var a := UI.botao("Pendurar as chuteiras", "trofeu", "fantasma", 80)
		a.pressed.connect(func() -> void:
			var r := await Tela.dialogo("Aposentar?", "Você encerra a carreira agora e vê seu legado. Depois, pode jogar com seu filho na Nova Geração.",
				[["Aposentar", "trofeu", "primario"], ["Seguir jogando", "bola", "fantasma"]], "trofeu", UI.OURO)
			if r == 0:
				_aposentar())
		_col.add_child(a)
	var sec := Componentes.secao("Propostas para %d" % int(Jogo.carreira["ano"]), "aperto", UI.VERDE)
	for o in Jogo.ofertas_temporada():
		sec[1].add_child(_cartao_oferta(o))
	_col.add_child(sec[0])
	_col.add_child(UI.espaco(20))


func _cartao_oferta(o: Dictionary) -> PanelContainer:
	var c := Jogo.clube(o["clube"])
	var atual: bool = o["clube"] == Jogo.carreira["clube"]
	var card := UI.cartao_borda(UI.CARTAO2, Color(c["cor"], 0.6) if not atual else UI.LINHA, 20, 18, 2)
	var col := UI.vbox(10)
	card.add_child(col)
	col.add_child(UI.rotulo(o["titulo"].to_upper(), 19, UI.OURO, "titulo"))
	col.add_child(Componentes.cabecalho_clube(o["clube"], "%s • %s" % [o.get("pais", "Brasil"), "Liga: " + Dados.PAISES.get(c["pais"], {"liga": "Nacional"})["liga"]]))
	var info := UI.hbox(10)
	info.add_child(UI.chip("dinheiro", UI.formatar_dinheiro(o["salario"]) + "/sem", UI.VERDE, Color(1, 1, 1, 0.06)))
	var cor_papel: Color = {"Titular": UI.VERDE, "Rodízio": UI.OURO, "Reserva": UI.VERMELHO, "Base": UI.AZUL}.get(o["papel"], UI.TEXTO2)
	info.add_child(UI.chip("pessoa", o["papel"], cor_papel, Color(1, 1, 1, 0.06)))
	info.add_child(Componentes.estrelas(int(c["tier"]), 5, 20))
	col.add_child(info)
	var b := UI.botao("Ficar" if atual else "Assinar", "ok", "primario" if not atual else "normal", 76)
	b.pressed.connect(func() -> void:
		Jogo.aceitar_oferta(o)
		Audio.tocar("sucesso")
		Tela.ir("res://cenas/hub.tscn"))
	col.add_child(b)
	return card


func _aposentar() -> void:
	Jogo.aposentar()
	Tela.ir("res://cenas/legado.tscn")
