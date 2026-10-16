extends TelaBase
## Loja: ofertas (Pacote do Moleque, VIP, remover anúncios), moedas e
## cosméticos (chuteiras, comemorações, cores de cabelo) e fichas "E se...?".

var _lbl_oferta: Label


func construir() -> void:
	var tem := Jogo.tem_carreira()
	cabecalho("LOJA", "" if tem else "res://cenas/menu.tscn")
	var chips := UI.hbox(10)
	chips.add_child(Componentes.chip_moedas())
	chips.add_child(UI.chip("replay", "%d fichas" % int(Jogo.perfil.get("fichas", 0)), UI.ROXO))
	if Compras.backend == "simulado":
		chips.add_child(UI.expansor())
		chips.add_child(UI.chip("info", "modo de teste", UI.TEXTO3, Color(1, 1, 1, 0.05)))
	conteudo.add_child(chips)
	var rol := UI.rolagem()
	conteudo.add_child(rol)
	var col := UI.vbox(16)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(col)
	Analytics.evento("loja_aberta", {"carreira": tem})

	if Jogo.oferta_iniciante_ativa():
		col.add_child(_oferta_iniciante())
	if not Jogo.vip():
		col.add_child(_vip())
	if not Jogo.tem_compra("remover_anuncios"):
		col.add_child(_produto_simples("remover_anuncios", "bloqueio", UI.AZUL))
	col.add_child(_moedas())
	col.add_child(_fichas())
	col.add_child(_chuteiras())
	col.add_child(_comemoracoes())
	col.add_child(_cabelos())
	var rest := UI.botao("Restaurar compras", "historico", "fantasma", 72)
	rest.pressed.connect(func() -> void: Compras.restaurar())
	col.add_child(rest)
	col.add_child(UI.espaco(10))
	if tem:
		var nav := Componentes.navegacao("loja")
		add_child(nav)
		nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		nav.grow_vertical = Control.GROW_DIRECTION_BEGIN
		(conteudo.get_parent() as MarginContainer).add_theme_constant_override("margin_bottom", 112)


func _process(_d: float) -> void:
	if _lbl_oferta and Engine.get_process_frames() % 30 == 0:
		var resta := int(Jogo.perfil.get("oferta_iniciante_ate", 0)) - int(Time.get_unix_time_from_system())
		_lbl_oferta.text = "Termina em %02d:%02d:%02d" % [maxi(resta, 0) / 3600, (maxi(resta, 0) % 3600) / 60, maxi(resta, 0) % 60]


func _comprar(id: String) -> void:
	var ok := await Compras.comprar(id)
	if ok:
		Audio.tocar("sucesso")
		var p: Dictionary = Compras.PRODUTOS[id]
		await Tela.recompensa("Obrigado!", [p["nome"], p["descricao"]])
		Tela.ir("res://cenas/loja.tscn")


func _oferta_iniciante() -> PanelContainer:
	var card := UI.cartao_borda(Color("2a1f05"), UI.OURO, 26, 24, 3)
	var col := UI.vbox(12)
	card.add_child(col)
	var topo := UI.hbox(10)
	topo.add_child(UI.icone("presente", 48, UI.OURO))
	var t := UI.vbox(0)
	t.add_child(UI.titulo("PACOTE DO MOLEQUE", 40, UI.OURO))
	_lbl_oferta = UI.rotulo("", 20, UI.VERMELHO, "forte")
	t.add_child(_lbl_oferta)
	topo.add_child(t)
	col.add_child(topo)
	for item in ["1.000 moedas", "Chuteira Relâmpago (exclusiva)", "5 fichas \"E se...?\""]:
		var l := UI.hbox(8)
		l.add_child(UI.icone("ok", 26, UI.VERDE))
		l.add_child(UI.rotulo(item, 23, UI.TEXTO, "forte"))
		col.add_child(l)
	col.add_child(UI.rotulo("Valor de mais de R$ 25 por %s" % Compras.preco("pacote_iniciante"), 20, UI.TEXTO2))
	var b := UI.botao(Compras.preco("pacote_iniciante"), "loja", "primario", 84)
	b.pressed.connect(_comprar.bind("pacote_iniciante"))
	col.add_child(b)
	return card


func _vip() -> PanelContainer:
	var card := UI.cartao_borda(Color("221a3d"), UI.ROXO, 26, 24, 3)
	var col := UI.vbox(12)
	card.add_child(col)
	var topo := UI.hbox(10)
	topo.add_child(UI.icone("vip", 48, UI.OURO))
	topo.add_child(UI.titulo("CRAQUE VIP", 42, UI.OURO))
	col.add_child(topo)
	for item in ["Sem anúncios entre as partidas", "1 \"E se...?\" grátis em toda partida", "Moedas em dobro no Lance do Dia", "Chuteira Dourada exclusiva"]:
		var l := UI.hbox(8)
		l.add_child(UI.icone("ok", 26, UI.OURO))
		var tx := UI.paragrafo(item, 23, UI.TEXTO)
		tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.add_child(tx)
		col.add_child(l)
	var b := UI.botao("%s • para sempre" % Compras.preco("craque_vip"), "vip", "primario", 84)
	b.pressed.connect(_comprar.bind("craque_vip"))
	col.add_child(b)
	return card


func _produto_simples(id: String, nome_icone: String, cor: Color) -> PanelContainer:
	var p: Dictionary = Compras.PRODUTOS[id]
	var card := UI.cartao_borda(UI.CARTAO, Color(cor, 0.5), 22, 20, 2)
	var l := UI.hbox(14)
	card.add_child(l)
	l.add_child(UI.icone(nome_icone, 44, cor))
	var v := UI.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UI.rotulo(p["nome"], 26, UI.TEXTO, "titulo"))
	v.add_child(UI.paragrafo(p["descricao"], 20))
	l.add_child(v)
	var b := UI.botao(Compras.preco(id), "", "verde", 72)
	b.custom_minimum_size.x = 170
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	b.pressed.connect(_comprar.bind(id))
	l.add_child(b)
	return card


func _moedas() -> PanelContainer:
	var sec := Componentes.secao("Moedas", "moeda")
	var linha := UI.hbox(12)
	for id in ["moedas_500", "moedas_1200", "moedas_3000"]:
		var p: Dictionary = Compras.PRODUTOS[id]
		var c := UI.cartao_borda(UI.CARTAO2, UI.LINHA if id != "moedas_1200" else UI.OURO, 18, 14, 2)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(6)
		c.add_child(v)
		if id == "moedas_1200":
			var pop := UI.rotulo("POPULAR", 16, UI.OURO, "titulo")
			pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(pop)
		v.add_child(UI.icone("moeda", 44 + (8 if id == "moedas_1200" else (16 if id == "moedas_3000" else 0)), UI.OURO))
		var q := UI.titulo(str(p["moedas"]), 34, UI.TEXTO)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(q)
		var b := UI.botao(Compras.preco(id), "", "verde", 60)
		b.pressed.connect(_comprar.bind(id))
		v.add_child(b)
		linha.add_child(c)
	sec[1].add_child(linha)
	return sec[0]


func _fichas() -> PanelContainer:
	var sec := Componentes.secao("Fichas \"E se...?\"", "replay", UI.ROXO)
	sec[1].add_child(UI.paragrafo("Reviva um lance que deu errado, sem precisar assistir a um vídeo. Uma por partida.", 21))
	var b := UI.botao("5 fichas por 200 moedas", "moeda", "roxo", 76)
	b.pressed.connect(func() -> void:
		if Jogo.gastar_moedas(200, "fichas"):
			Jogo.perfil["fichas"] = int(Jogo.perfil.get("fichas", 0)) + 5
			Jogo.salvar_perfil()
			Audio.tocar("moeda")
			Tela.ir("res://cenas/loja.tscn")
		else:
			Tela.aviso("Moedas insuficientes.", "moeda", UI.VERMELHO))
	sec[1].add_child(b)
	return sec[0]


func _chuteiras() -> PanelContainer:
	var sec := Componentes.secao("Chuteiras", "chuteira")
	sec[1].add_child(UI.paragrafo("Você vê a chuteira nos seus pés em todo lance em primeira pessoa.", 20, UI.TEXTO3))
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	var equipada: String = Jogo.carreira.get("jogador", {}).get("chuteira", "preta")
	for id in Dados.CHUTEIRAS:
		var d: Dictionary = Dados.CHUTEIRAS[id]
		var tem := Jogo.tem_cosmetico("chuteiras", id)
		var c := UI.cartao_borda(UI.CARTAO2, UI.OURO if id == equipada else UI.LINHA, 18, 14, 2)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var l := UI.hbox(10)
		c.add_child(l)
		var am := UI.cartao(Color(d["cor"]), 14, 0)
		am.custom_minimum_size = Vector2(52, 52)
		l.add_child(am)
		var v := UI.vbox(4)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.rotulo(d["nome"], 21, UI.TEXTO, "forte"))
		var b: Button
		if tem:
			b = UI.botao("Equipada" if id == equipada else "Usar", "", "normal", 52)
			b.disabled = id == equipada or not Jogo.tem_carreira()
			b.pressed.connect(func() -> void:
				Jogo.carreira["jogador"]["chuteira"] = id
				Jogo.salvar_carreira()
				Tela.ir("res://cenas/loja.tscn"))
		elif int(d["preco"]) > 0:
			b = UI.botao("%d" % int(d["preco"]), "moeda", "primario", 52)
			b.pressed.connect(func() -> void:
				if Jogo.comprar_cosmetico("chuteiras", id, int(d["preco"])):
					Audio.tocar("moeda")
					if Jogo.tem_carreira():
						Jogo.carreira["jogador"]["chuteira"] = id
						Jogo.salvar_carreira()
					Tela.ir("res://cenas/loja.tscn")
				else:
					Tela.aviso("Moedas insuficientes.", "moeda", UI.VERMELHO))
		else:
			b = UI.botao(d.get("origem", ""), "cadeado", "fantasma", 52)
			b.disabled = true
		v.add_child(b)
		l.add_child(v)
		grade.add_child(c)
	sec[1].add_child(grade)
	return sec[0]


func _comemoracoes() -> PanelContainer:
	var sec := Componentes.secao("Comemorações", "festa")
	sec[1].add_child(UI.paragrafo("Depois de cada gol você escolhe como comemorar. Cada comemoração tem um efeito na sua carreira.", 20, UI.TEXTO3))
	var equipada: String = Jogo.carreira.get("jogador", {}).get("comemoracao", "galera")
	for id in Dados.COMEMORACOES:
		var d: Dictionary = Dados.COMEMORACOES[id]
		var tem := Jogo.tem_cosmetico("comemoracoes", id)
		var l := UI.hbox(12)
		l.add_child(UI.icone(d["icone"], 36, UI.OURO if tem else UI.TEXTO3))
		var v := UI.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.rotulo(d["nome"], 23, UI.TEXTO, "forte"))
		var efe: Array = []
		for k in d["efeitos"]:
			efe.append("%s%d %s" % ["+" if d["efeitos"][k] > 0 else "", d["efeitos"][k], {"fama": "fama", "moral": "confiança", "rel_torcida": "torcida", "rel_familia": "família"}.get(k, k)])
		v.add_child(UI.rotulo(" • ".join(efe), 19, UI.TEXTO2))
		l.add_child(v)
		var b: Button
		if tem:
			b = UI.botao("Favorita" if id == equipada else "Favoritar", "", "normal", 56)
			b.disabled = id == equipada or not Jogo.tem_carreira()
			b.pressed.connect(func() -> void:
				Jogo.carreira["jogador"]["comemoracao"] = id
				Jogo.salvar_carreira()
				Tela.ir("res://cenas/loja.tscn"))
		else:
			b = UI.botao("%d" % int(d["preco"]), "moeda", "primario", 56)
			b.pressed.connect(func() -> void:
				if Jogo.comprar_cosmetico("comemoracoes", id, int(d["preco"])):
					Audio.tocar("moeda")
					Tela.ir("res://cenas/loja.tscn")
				else:
					Tela.aviso("Moedas insuficientes.", "moeda", UI.VERMELHO))
		b.custom_minimum_size.x = 170
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		l.add_child(b)
		sec[1].add_child(l)
	return sec[0]


func _cabelos() -> PanelContainer:
	var sec := Componentes.secao("Cores de cabelo", "brilho")
	var linha := UI.hbox(12)
	for i in [5, 6]:
		var tem := Jogo.tem_cosmetico("cores_cabelo", i)
		var c := UI.cartao_borda(UI.CARTAO2, UI.LINHA, 18, 14, 2)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var v := UI.vbox(8)
		c.add_child(v)
		var am := UI.cartao(Jogador3D.CORES_CABELO[i], 30, 0)
		am.custom_minimum_size = Vector2(0, 50)
		v.add_child(am)
		var b := UI.botao("Liberada" if tem else "120", "" if tem else "moeda", "normal" if tem else "primario", 56)
		b.disabled = tem
		b.pressed.connect(func() -> void:
			if Jogo.comprar_cosmetico("cores_cabelo", i, 120):
				Audio.tocar("moeda")
				if Jogo.tem_carreira():
					Jogo.carreira["jogador"]["cor_cabelo"] = i
					Jogo.salvar_carreira()
				Tela.ir("res://cenas/loja.tscn")
			else:
				Tela.aviso("Moedas insuficientes.", "moeda", UI.VERMELHO))
		v.add_child(b)
		linha.add_child(c)
	sec[1].add_child(linha)
	return sec[0]
