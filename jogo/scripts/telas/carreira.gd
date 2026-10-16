extends TelaBase
## Carreira: atributos (com explicação do que cada um faz no lance), tabela da
## liga com calendário e o histórico de temporadas e títulos.

var _aba := "atributos"
var _corpo: VBoxContainer
var _botoes_aba := {}


func construir() -> void:
	if not Jogo.tem_carreira():
		Tela.ir.call_deferred("res://cenas/menu.tscn")
		return
	var j: Dictionary = Jogo.carreira["jogador"]
	cabecalho(j["apelido"].to_upper(), "", "%s • %s • %d anos • OVR %d" % [j["posicao"], Jogo.nome_clube(Jogo.carreira["clube"]), int(j["idade"]), Jogo.overall()])
	var abas := UI.hbox(10)
	for a in [["atributos", "Atributos"], ["tabela", "Tabela"], ["contrato", "Contrato"], ["historia", "História"]]:
		var b := UI.botao(a[1], "", "normal", 64)
		b.pressed.connect(_trocar.bind(a[0]))
		_botoes_aba[a[0]] = b
		abas.add_child(b)
	conteudo.add_child(abas)
	var rol := UI.rolagem()
	conteudo.add_child(rol)
	_corpo = UI.vbox(16)
	_corpo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(_corpo)
	var nav := Componentes.navegacao("carreira")
	add_child(nav)
	nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	nav.grow_vertical = Control.GROW_DIRECTION_BEGIN
	(conteudo.get_parent() as MarginContainer).add_theme_constant_override("margin_bottom", 112)
	_trocar("atributos")


func _trocar(aba: String) -> void:
	_aba = aba
	for k in _botoes_aba:
		_botoes_aba[k].modulate = UI.OURO.lightened(0.3) if k == aba else Color(1, 1, 1, 0.7)
	for c in _corpo.get_children():
		c.queue_free()
	match aba:
		"atributos":
			_atributos()
		"tabela":
			_tabela()
		"contrato":
			_contrato()
		_:
			_historia()


func _atributos() -> void:
	var pot := float(Jogo.carreira["jogador"]["potencial"])
	var sec := Componentes.secao("Atributos", "estrela")
	var estrelas_pot := clampi(int((pot - 70.0) / 5.0) + 1, 1, 5)
	var lp := UI.hbox(8)
	lp.add_child(UI.rotulo("Potencial estimado:", 21, UI.TEXTO2, "forte"))
	lp.add_child(Componentes.estrelas(estrelas_pot, 5, 22))
	sec[1].add_child(lp)
	for a in Dados.ATRIBUTOS:
		var v := Jogo.atributo(a)
		var cor := UI.VERDE if v >= 75 else (UI.OURO if v >= 60 else (UI.LARANJA if v >= 48 else UI.VERMELHO))
		sec[1].add_child(UI.linha_status(Dados.ICONES_ATRIBUTOS[a], Dados.NOMES_ATRIBUTOS[a], v, cor))
		if Dados.DESCRICAO_ATRIBUTOS.has(a):
			sec[1].add_child(UI.paragrafo(Dados.DESCRICAO_ATRIBUTOS[a], 19, UI.TEXTO3))
	_corpo.add_child(sec[0])
	var e: Dictionary = Jogo.carreira["estat"]
	var est := Componentes.secao("Carreira", "grafico", UI.AZUL)
	var jogos := maxi(1, int(e["jogos"]))
	for d in [["Jogos", e["jogos"]], ["Gols", e["gols"]], ["Assistências", e["assist"]], ["Títulos", e["titulos"]],
			["Média geral", "%.2f" % (float(e["notas_soma"]) / jogos) if int(e["jogos"]) > 0 else "-"],
			["Jogos pela Seleção", e["selecao_jogos"]], ["Gols pela Seleção", e["selecao_gols"]]]:
		var l := UI.hbox(8)
		var n := UI.rotulo(str(d[0]), 22, UI.TEXTO2, "forte")
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_child(n)
		l.add_child(UI.rotulo(str(d[1]), 24, UI.TEXTO, "titulo"))
		est[1].add_child(l)
	_corpo.add_child(est[0])


func _tabela() -> void:
	var temp: Dictionary = Jogo.carreira["temp"]
	var sec := Componentes.secao(temp["liga"], "ranking")
	var cab := UI.hbox(6)
	for t in [["#", 40], ["Time", 0], ["J", 44], ["SG", 56], ["P", 56]]:
		var l := UI.rotulo(t[0], 19, UI.TEXTO3, "titulo")
		if t[1] > 0:
			l.custom_minimum_size.x = t[1]
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		else:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cab.add_child(l)
	sec[1].add_child(cab)
	var ordem := Jogo.classificacao()
	for i in ordem.size():
		var id: String = ordem[i]
		var t: Dictionary = temp["tabela"][id]
		var meu: bool = id == Jogo.carreira["clube"]
		var linha := UI.hbox(6)
		var bg := UI.cartao(Color(UI.OURO, 0.12) if meu else Color(0, 0, 0, 0), 10, 6)
		bg.add_child(linha)
		var pos := UI.rotulo(str(i + 1), 22, UI.OURO if i < 2 else UI.TEXTO2, "titulo")
		pos.custom_minimum_size.x = 40
		pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		linha.add_child(pos)
		var c := Jogo.clube(id)
		linha.add_child(Componentes.Brasao.novo(c, 30))
		var n := UI.rotulo(c["nome"], 21, UI.TEXTO if meu else UI.TEXTO2, "forte")
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		linha.add_child(n)
		for v in [[str(int(t["j"])), 44], [str(int(t["gp"]) - int(t["gc"])), 56], [str(int(t["pts"])), 56]]:
			var l := UI.rotulo(v[0], 22, UI.TEXTO, "titulo")
			l.custom_minimum_size.x = v[1]
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			linha.add_child(l)
		sec[1].add_child(bg)
	sec[1].add_child(UI.paragrafo("Os 2 primeiros disputam a final.", 19, UI.TEXTO3))
	_corpo.add_child(sec[0])
	var cal := Componentes.secao("Seus jogos", "calendario", UI.AZUL)
	for j in temp["calendario"]:
		var l := UI.hbox(10)
		var adv := Jogo.clube(j["adv"])
		l.add_child(Componentes.Brasao.novo(adv, 30))
		var n := UI.rotulo(("%s  " % ("(C)" if j.get("casa", true) else "(F)")) + adv["nome"], 21, UI.TEXTO2, "forte")
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		n.clip_text = true
		l.add_child(n)
		if j["jogado"]:
			var pl: Array = j.get("placar", [0, 0])
			var cor := UI.VERDE if int(pl[0]) > int(pl[1]) else (UI.OURO if int(pl[0]) == int(pl[1]) else UI.VERMELHO)
			l.add_child(UI.rotulo("%d x %d" % [int(pl[0]), int(pl[1])], 22, cor, "titulo"))
			var nota := float(j.get("nota", 0.0))
			if nota > 0:
				l.add_child(UI.chip("estrela", "%.1f" % nota, UI.cor_nota(nota), Color(1, 1, 1, 0.05)))
		else:
			l.add_child(UI.rotulo(j["tipo"].to_upper() if j["tipo"] != "liga" else "—", 20, UI.TEXTO3, "titulo"))
		cal[1].add_child(l)
	_corpo.add_child(cal[0])


func _contrato() -> void:
	var c: Dictionary = Jogo.carreira["contrato"]
	var id: String = Jogo.carreira["clube"]
	var card := UI.cartao_borda(UI.CARTAO, Color(Jogo.clube(id)["cor"], 0.6), 24, 22, 2)
	var col := UI.vbox(14)
	card.add_child(col)
	col.add_child(Componentes.cabecalho_clube(id, "%s • %s" % [Jogo.carreira["categoria"], c.get("papel", "")]))
	var ano_fim := int(Jogo.carreira["ano"]) + int(c.get("ate", Jogo.carreira["temporada"])) - int(Jogo.carreira["temporada"])
	var salario := float(c.get("salario", 0.0))
	var justo := Jogo.salario_mercado()
	for d in [["dinheiro", "Salário", UI.formatar_dinheiro(salario) + " / semana", UI.VERDE],
			["calendario", "Contrato até", "fim de %d" % ano_fim, UI.TEXTO],
			["grafico", "Valor de mercado", UI.formatar_dinheiro(Jogo.valor_mercado()), UI.OURO],
			["aperto", "Salário de mercado", UI.formatar_dinheiro(justo) + " / semana", UI.AZUL]]:
		var l := UI.hbox(10)
		l.add_child(UI.icone(d[0], 28, d[3]))
		var n := UI.rotulo(d[1], 22, UI.TEXTO2, "forte")
		n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_child(n)
		l.add_child(UI.rotulo(d[2], 23, UI.TEXTO, "titulo"))
		col.add_child(l)
	var leitura := "Você ganha bem abaixo do mercado: é hora de pedir aumento." if justo > salario * 1.25 else (
		"Seu salário está na média do mercado." if justo > salario * 0.9 else "Você já ganha acima do mercado. Pedir mais é arriscado.")
	col.add_child(UI.paragrafo(leitura, 21, UI.TEXTO3))
	_corpo.add_child(card)

	var rel := Componentes.secao("Relação com o clube", "escudo", UI.AZUL)
	var dir := Jogo.rel_diretoria()
	rel[1].add_child(UI.linha_status("escudo", "Diretoria", dir, UI.VERDE if dir >= 55 else (UI.OURO if dir >= 35 else UI.VERMELHO)))
	var tec := float(Jogo.carreira["rel"]["tecnico"])
	rel[1].add_child(UI.linha_status("esporte", "Técnico (%s)" % Jogo.carreira["tecnico"], tec, UI.VERDE if tec >= 55 else (UI.OURO if tec >= 35 else UI.VERMELHO)))
	var tor := float(Jogo.carreira["rel"]["torcida"])
	rel[1].add_child(UI.linha_status("festa", "Torcida", tor, UI.VERDE if tor >= 55 else (UI.OURO if tor >= 35 else UI.VERMELHO)))
	_corpo.add_child(rel[0])

	var acoes := Componentes.secao("Conversar com a diretoria", "aperto", UI.OURO)
	var saida: String = c.get("pedido_saida", "")
	if saida == "aceito":
		acoes[1].add_child(UI.chip("aviao", "Saída combinada para o fim da temporada", UI.OURO, Color(UI.OURO, 0.12)))
		var fica := UI.botao("Desistir de sair", "desfazer", "normal", 76)
		fica.pressed.connect(func() -> void:
			var ef := Jogo.cancelar_saida()
			await Tela.dialogo("Você fica!", "A diretoria comemorou a decisão.\n\n" + "   ".join(ef), [["Continuar", "ok", "primario"]], "escudo", UI.VERDE)
			_trocar("contrato"))
		acoes[1].add_child(fica)
	elif saida == "forcado":
		acoes[1].add_child(UI.chip("bloqueio", "Você forçou a saída: afastado até o fim da temporada", UI.VERMELHO, Color(UI.VERMELHO, 0.12)))
	else:
		var motivo := Jogo.motivo_sem_negociacao()
		var neg := UI.botao("Renegociar salário", "dinheiro", "verde" if motivo == "" else "normal", 84)
		neg.disabled = motivo != ""
		neg.pressed.connect(_renegociar)
		acoes[1].add_child(neg)
		if motivo != "":
			acoes[1].add_child(UI.paragrafo(motivo, 20, UI.TEXTO3))
		var sair := UI.botao("Pedir para sair do clube", "aviao", "perigo", 84)
		sair.pressed.connect(_pedir_saida)
		acoes[1].add_child(sair)
		acoes[1].add_child(UI.paragrafo("Saídas valem a partir do fim da temporada, quando chegam as propostas.", 19, UI.TEXTO3))
	_corpo.add_child(acoes[0])


func _palpite(ch: float) -> String:
	if not Jogo.carreira["flags"].has("empresario"):
		return ""
	var s := Situacoes.sensacao(ch)
	return "  (%s)" % s[0]


func _renegociar() -> void:
	var opcoes := [[0.10, "Pedir +10% (seguro)"], [0.25, "Pedir +25% (firme)"], [0.50, "Pedir +50% (ousado)"]]
	var botoes: Array = []
	for o in opcoes:
		botoes.append([o[1] + _palpite(Jogo.chance_renegociar(o[0])), "dinheiro", "normal"])
	botoes.append(["Cancelar", "fechar", "fantasma"])
	var dica := "Seu empresário avalia as chances de cada pedido." if Jogo.carreira["flags"].has("empresario") else "Sem empresário, você negocia no escuro. Desempenho, fama e a relação com a diretoria pesam."
	var r := await Tela.dialogo("Renegociar salário", "Salário atual: %s por semana.\n%s" % [UI.formatar_dinheiro(Jogo.carreira["contrato"]["salario"]), dica], botoes, "dinheiro", UI.VERDE)
	if r < 0 or r >= opcoes.size():
		return
	var res := Jogo.renegociar(opcoes[r][0])
	match res["resultado"]:
		"aceito":
			Audio.tocar("sucesso")
			await Tela.dialogo("Aumento aprovado!", "Novo salário: %s por semana. O contrato foi estendido em 1 temporada.\n\n%s" % [UI.formatar_dinheiro(res["novo"]), "   ".join(res["efeitos"])],
				[["Show!", "ok", "primario"]], "dinheiro", UI.VERDE)
		"contraproposta":
			var c2 := await Tela.dialogo("Contraproposta", "A diretoria não chega lá, mas oferece %s por semana." % UI.formatar_dinheiro(res["contraproposta"]),
				[["Aceitar", "ok", "verde"], ["Recusar", "fechar", "perigo"]], "aperto", UI.OURO)
			var ef := Jogo.responder_contraproposta(c2 == 0, res["contraproposta"])
			if c2 != 0 and not ef.is_empty():
				Tela.aviso("A diretoria não gostou: " + ", ".join(ef), "escudo", UI.VERMELHO)
		_:
			Audio.tocar("falha")
			var txt := "\"Não temos como pagar isso agora.\""
			if res.get("vazou", false):
				txt += "\n\nPior: o pedido vazou na imprensa. A torcida não gostou."
			await Tela.dialogo("Pedido recusado", txt + "\n\n" + "   ".join(res["efeitos"]), [["Entendi", "ok", "primario"]], "escudo", UI.VERMELHO)
	_trocar("contrato")


func _pedir_saida() -> void:
	var ids := Jogo.MOTIVOS_SAIDA.keys()
	var botoes: Array = []
	for k in ids:
		botoes.append([Jogo.MOTIVOS_SAIDA[k], "seta_dir", "normal"])
	botoes.append(["Cancelar", "fechar", "fantasma"])
	var r := await Tela.dialogo("Pedir para sair", "Qual é o motivo? A diretoria pode aceitar e negociar você no fim da temporada... ou bater o pé.", botoes, "aviao", UI.VERMELHO)
	if r < 0 or r >= ids.size():
		return
	var res := Jogo.pedir_saida(ids[r])
	if res["aceito"]:
		Audio.tocar("revela")
		await Tela.dialogo("Saída aceita", "A diretoria vai te negociar. No fim da temporada, chegam mais propostas, e o %s não fará oferta de renovação.\n\n%s" % [Jogo.nome_clube(Jogo.carreira["clube"]), "   ".join(res["efeitos"])],
			[["Combinado", "ok", "primario"]], "aviao", UI.OURO)
	else:
		Audio.tocar("falha")
		var e := await Tela.dialogo("A diretoria recusou", "\"Você tem contrato e é importante para nós. Daqui você não sai.\"\n\n%s" % "   ".join(res["efeitos"]),
			[["Aceitar e seguir no clube", "ok", "normal"], ["Forçar a saída", "bloqueio", "perigo"]], "escudo", UI.VERMELHO)
		if e == 1:
			var conf := await Tela.dialogo("Forçar a saída?", "Você fica afastado do time titular até o fim da temporada, a torcida e o técnico vão se irritar, mas a saída fica garantida.",
				[["Forçar mesmo assim", "bloqueio", "perigo"], ["Voltar atrás", "voltar", "fantasma"]], "info", UI.VERMELHO)
			if conf == 0:
				var ef := Jogo.forcar_saida()
				await Tela.dialogo("Crise aberta", "A notícia explodiu. Você está fora dos planos até o fim da temporada.\n\n" + "   ".join(ef), [["Continuar", "ok", "primario"]], "jornal", UI.VERMELHO)
	_trocar("contrato")


func _historia() -> void:
	var h: Array = Jogo.carreira.get("historico", [])
	var sec := Componentes.secao("Temporadas", "historico")
	if h.is_empty():
		sec[1].add_child(UI.paragrafo("Sua primeira temporada ainda está em andamento.", 22))
	for t in h:
		var c := UI.cartao(UI.CARTAO2, 16, 14)
		var col := UI.vbox(4)
		c.add_child(col)
		col.add_child(UI.rotulo("%d • %d anos • %s (%s)" % [int(t["ano"]), int(t["idade"]), t["clube"], t["categoria"]], 22, UI.TEXTO, "forte"))
		col.add_child(UI.rotulo("%d jogos • %d gols • %d assist. • média %.1f" % [int(t["jogos"]), int(t["gols"]), int(t["assist"]), float(t["media"])], 20, UI.TEXTO2))
		for ti in t.get("titulos", []):
			col.add_child(UI.chip("trofeu", str(ti), UI.OURO, Color(UI.OURO, 0.1)))
		sec[1].add_child(c)
	_corpo.add_child(sec[0])
	var tit := Componentes.secao("Títulos (%d)" % Jogo.carreira["titulos"].size(), "trofeu")
	for t in Jogo.carreira["titulos"]:
		tit[1].add_child(UI.rotulo("%d • %s (%s)" % [int(t["ano"]), t["nome"], t["clube"]], 21, UI.TEXTO2, "forte"))
	_corpo.add_child(tit[0])
