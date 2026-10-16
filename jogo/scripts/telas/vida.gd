extends TelaBase
## Vida fora de campo: dinheiro, patrocínio (anúncio diegético), relações,
## sonhos (alguns compráveis com o dinheiro da carreira) e o rival.


func construir() -> void:
	if not Jogo.tem_carreira():
		Tela.ir.call_deferred("res://cenas/menu.tscn")
		return
	var c := Jogo.carreira
	cabecalho("VIDA", "", "Fora de campo também se joga")
	var chips := UI.hbox(10)
	chips.add_child(Componentes.chip_dinheiro())
	chips.add_child(Componentes.chip_moedas())
	conteudo.add_child(chips)
	var rol := UI.rolagem()
	conteudo.add_child(rol)
	var col := UI.vbox(16)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(col)

	# patrocínio
	var pat := Componentes.secao("Patrocínio", "dinheiro", UI.VERDE)
	var disp := Jogo.patrocinio_disponivel()
	var tem_contrato: bool = c["flags"].has("patrocinador") or float(c["status"]["fama"]) >= 10.0
	if tem_contrato:
		pat[1].add_child(UI.paragrafo("A %s paga para você gravar um comercial rápido. Ganhe %s por gravação (%d restantes hoje)." % [c["patrocinador"], UI.formatar_dinheiro(Jogo.valor_patrocinio()), disp], 22, UI.TEXTO))
		var b := UI.botao("Gravar comercial", "anuncio", "anuncio", 80)
		b.disabled = disp <= 0
		b.pressed.connect(func() -> void:
			if await Anuncios.recompensado("patrocinio"):
				var v := Jogo.receber_patrocinio()
				Audio.tocar("moeda")
				Tela.aviso("Comercial gravado! +%s" % UI.formatar_dinheiro(v), "dinheiro", UI.VERDE)
				Tela.ir("res://cenas/vida.tscn"))
		pat[1].add_child(b)
	else:
		pat[1].add_child(UI.paragrafo("Ganhe fama (10+) para atrair patrocinadores.", 22))
	col.add_child(pat[0])

	# relações
	var rel := Componentes.secao("Relações", "coracao", UI.VERMELHO)
	var nomes := {"familia": ["Família (%s)" % c["mae"], "familia"], "tecnico": ["Técnico (%s)" % c["tecnico"], "esporte"],
		"torcida": ["Torcida", "festa"], "amigo": ["Amizade (%s)" % c["amigo"], "grupo"]}
	for k in ["familia", "tecnico", "torcida", "amigo"]:
		var v := float(c["rel"][k])
		rel[1].add_child(UI.linha_status(nomes[k][1], nomes[k][0], v, UI.VERDE if v >= 60 else (UI.OURO if v >= 35 else UI.VERMELHO)))
	rel[1].add_child(UI.paragrafo("A relação com o técnico pesa na escalação. A família e os amigos sustentam sua confiança.", 19, UI.TEXTO3))
	col.add_child(rel[0])

	# sonhos
	var son := Componentes.secao("Sonhos", "estrela")
	for id in Dados.SONHOS:
		var s: Dictionary = Dados.SONHOS[id]
		var ok: bool = c["sonhos"].get(id, false)
		var linha := UI.hbox(12)
		linha.add_child(UI.icone(s["icone"], 32, UI.OURO if ok else UI.TEXTO3))
		var v := UI.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.paragrafo(s["nome"], 22, UI.TEXTO if not ok else UI.OURO))
		var detalhe := "Realizado!" if ok else "+%d moedas" % int(s["moedas"] / 2)
		if s.has("preco") and not ok:
			detalhe = "%s • %s" % [UI.formatar_dinheiro(s["preco"]), detalhe]
		v.add_child(UI.rotulo(detalhe, 19, UI.TEXTO2))
		linha.add_child(v)
		if s.has("preco") and not ok:
			var b := UI.botao("Comprar", "", "verde" if float(c["dinheiro"]) >= float(s["preco"]) else "normal", 64)
			b.custom_minimum_size.x = 160
			b.size_flags_horizontal = Control.SIZE_SHRINK_END
			b.disabled = float(c["dinheiro"]) < float(s["preco"])
			var sid: String = id
			b.pressed.connect(func() -> void:
				if Jogo.comprar_sonho(sid):
					Audio.tocar("sucesso")
					await Tela.recompensa("Sonho realizado!", [Dados.SONHOS[sid]["nome"]])
					Tela.ir("res://cenas/vida.tscn"))
			linha.add_child(b)
		elif ok:
			linha.add_child(UI.icone("ok", 32, UI.VERDE))
		son[1].add_child(linha)
	col.add_child(son[0])

	# rival
	var r: Dictionary = c["rival"]
	var riv := Componentes.secao("Rival: " + r["nome"], "fogo", UI.VERMELHO)
	riv[1].add_child(UI.paragrafo("Joga no %s. Overall %d • %d gols na carreira • %d títulos." % [Jogo.nome_clube(r["clube"]), int(r["overall"]), int(r["gols"]), int(r["titulos"])], 22, UI.TEXTO))
	col.add_child(riv[0])
	col.add_child(UI.espaco(10))

	var nav := Componentes.navegacao("vida")
	add_child(nav)
	nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	nav.grow_vertical = Control.GROW_DIRECTION_BEGIN
	(conteudo.get_parent() as MarginContainer).add_theme_constant_override("margin_bottom", 112)
