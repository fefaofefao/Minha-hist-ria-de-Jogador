extends TelaBase
## Legado da carreira encerrada + Hall da Fama + Nova Geração (jogar com o filho).


func construir() -> void:
	Audio.musica(true)
	var aposentado: bool = not Jogo.carreira.is_empty() and Jogo.carreira.get("fase", "") == "aposentado"
	cabecalho("LEGADO" if aposentado else "HALL DA FAMA", "res://cenas/menu.tscn")
	var rol := UI.rolagem()
	conteudo.add_child(rol)
	var col := UI.vbox(16)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(col)
	if aposentado:
		var l := Jogo.legado()
		var card := UI.cartao_borda(Color("2a1f05"), UI.OURO, 26, 26, 3)
		var c := UI.vbox(8)
		card.add_child(c)
		var ic := UI.icone("trofeu", 90, UI.OURO)
		c.add_child(ic)
		var t := UI.titulo(l["apelido"].to_upper(), 58, UI.TEXTO)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(t)
		var tt := UI.titulo(l["titulo"], 36, UI.OURO)
		tt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(tt)
		var pts := UI.rotulo("%d pontos de legado" % l["pontos"], 24, UI.TEXTO2, "forte")
		pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		c.add_child(pts)
		col.add_child(card)
		var grade := GridContainer.new()
		grade.columns = 3
		grade.add_theme_constant_override("h_separation", 10)
		grade.add_theme_constant_override("v_separation", 10)
		for d in [["Jogos", l["jogos"]], ["Gols", l["gols"]], ["Assist.", l["assist"]], ["Títulos", l["titulos"]],
				["Média", "%.2f" % float(l["media"])], ["Bolas de Cristal", l["bolas"]], ["Fãs", UI.formatar_numero(float(l.get("fas", 0)))]]:
			var cc := UI.cartao(UI.CARTAO, 16, 14)
			cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var v := UI.vbox(0)
			var n := UI.titulo(str(d[1]), 40, UI.OURO)
			n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(n)
			var lb := UI.rotulo(str(d[0]).to_upper(), 16, UI.TEXTO2, "titulo")
			lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(lb)
			cc.add_child(v)
			grade.add_child(cc)
		col.add_child(grade)
		var sonhos := Componentes.secao("Sonhos realizados", "estrela")
		for id in Dados.SONHOS:
			var ok: bool = Jogo.carreira["sonhos"].get(id, false)
			var linha := UI.hbox(10)
			linha.add_child(UI.icone("ok" if ok else "fechar", 26, UI.VERDE if ok else UI.TEXTO3))
			var tx := UI.paragrafo(Dados.SONHOS[id]["nome"], 22, UI.TEXTO if ok else UI.TEXTO3)
			tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			linha.add_child(tx)
			sonhos[1].add_child(linha)
		col.add_child(sonhos[0])
		var r: Dictionary = l["rival"]
		var riv := Componentes.secao("A rivalidade", "fogo", UI.VERMELHO)
		riv[1].add_child(UI.paragrafo("%s terminou com %d gols e %d títulos. Você: %d gols e %d títulos." % [r["nome"], int(r["gols"]), int(r["titulos"]), int(l["gols"]), int(l["titulos"])], 22, UI.TEXTO))
		riv[1].add_child(UI.rotulo("Você venceu a rivalidade!" if int(l["gols"]) + int(l["titulos"]) * 5 >= int(r["gols"]) + int(r["titulos"]) * 5 else "Ele levou a melhor... mas a história é sua.", 22, UI.OURO, "forte"))
		col.add_child(riv[0])
		var h := Jogo.heranca()
		var ng := UI.cartao_borda(UI.CARTAO2, UI.ROXO, 24, 22, 2)
		var nc := UI.vbox(12)
		ng.add_child(nc)
		nc.add_child(UI.titulo("NOVA GERAÇÃO", 40, UI.ROXO))
		nc.add_child(UI.paragrafo("Seu filho cresceu ouvindo as suas histórias. Ele herda: +5 em %s, potencial maior e um pouco de fama. A Vila Esperança espera um novo craque." % Dados.NOMES_ATRIBUTOS.get(h["melhor"], "talento"), 23, UI.TEXTO))
		var b := UI.botao("Jogar com o filho de %s" % l["apelido"], "familia", "primario", 92)
		b.pressed.connect(func() -> void:
			Jogo.perfil["heranca"] = h
			Jogo.salvar_perfil()
			Jogo.apagar_carreira()
			Analytics.evento("nova_geracao", {"geracao": h["geracao"]})
			Tela.ir("res://cenas/criacao.tscn"))
		nc.add_child(b)
		col.add_child(ng)
	var hall := Componentes.secao("Hall da Fama", "ranking")
	var lista: Array = Jogo.perfil.get("hall", []).duplicate()
	lista.sort_custom(func(a, b) -> bool: return int(a["pontos"]) > int(b["pontos"]))
	if lista.is_empty():
		hall[1].add_child(UI.paragrafo("Nenhuma lenda ainda. Sua história começa agora.", 22))
	for i in mini(lista.size(), 10):
		var e: Dictionary = lista[i]
		var linha := UI.hbox(12)
		linha.add_child(UI.titulo("%d" % (i + 1), 34, UI.OURO if i == 0 else UI.TEXTO2))
		var v := UI.vbox(0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UI.rotulo("%s  (geração %d)" % [e["apelido"], int(e.get("geracao", 1))], 24, UI.TEXTO, "forte"))
		v.add_child(UI.rotulo("%s • %d gols • %d títulos" % [e["titulo"], int(e["gols"]), int(e["titulos"])], 19, UI.TEXTO2))
		linha.add_child(v)
		linha.add_child(UI.rotulo("%d" % int(e["pontos"]), 26, UI.OURO, "titulo"))
		hall[1].add_child(linha)
	col.add_child(hall[0])
	var menu := UI.botao("Voltar ao menu", "casa", "fantasma", 80)
	menu.pressed.connect(func() -> void: Tela.ir("res://cenas/menu.tscn"))
	col.add_child(menu)
