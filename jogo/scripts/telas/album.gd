extends TelaBase
## Álbum de memórias: cada lance marcante vira uma figurinha. As bloqueadas
## mostram a dica do que fazer (meta de curto prazo para o jogador).


func construir() -> void:
	if not Jogo.tem_carreira():
		Tela.ir.call_deferred("res://cenas/menu.tscn")
		return
	var mem: Dictionary = Jogo.carreira["memorias"]
	cabecalho("ÁLBUM", "", "%d de %d memórias • a cada 4: +50 moedas" % [mem.size(), Dados.MEMORIAS.size()])
	conteudo.add_child(UI.barra(float(mem.size()) / Dados.MEMORIAS.size(), UI.OURO, 12))
	var rol := UI.rolagem()
	conteudo.add_child(rol)
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 14)
	grade.add_theme_constant_override("v_separation", 14)
	grade.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(grade)
	var i := 0
	for id in Dados.MEMORIAS:
		var d: Dictionary = Dados.MEMORIAS[id]
		var tem := mem.has(id)
		var card := UI.cartao_borda(Color("2a1f05") if tem else UI.CARTAO, UI.OURO if tem else UI.LINHA, 20, 18, 3 if tem else 2)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.y = 230
		var col := UI.vbox(8)
		card.add_child(col)
		col.add_child(UI.icone("estrela" if tem else "cadeado", 46, UI.OURO if tem else UI.TEXTO3))
		var t := UI.titulo(d["titulo"] if tem else "???", 30, UI.OURO if tem else UI.TEXTO3)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(t)
		var p := UI.paragrafo(d["desc"], 19, UI.TEXTO2 if tem else UI.TEXTO3)
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(p)
		if tem:
			var m: Dictionary = mem[id]
			var info := UI.paragrafo("%d • %d anos\n%s vs %s, %d'" % [int(m["ano"]), int(m["idade"]), m["clube"], m["adversario"], int(m["minuto"])], 17, UI.TEXTO3)
			info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			col.add_child(info)
		grade.add_child(card)
		UI.aparecer(card, i * 0.03)
		i += 1
	var nav := Componentes.navegacao("album")
	add_child(nav)
	nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	nav.grow_vertical = Control.GROW_DIRECTION_BEGIN
	(conteudo.get_parent() as MarginContainer).add_theme_constant_override("margin_bottom", 112)
