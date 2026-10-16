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
	for a in [["atributos", "Atributos"], ["tabela", "Tabela"], ["historia", "História"]]:
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
