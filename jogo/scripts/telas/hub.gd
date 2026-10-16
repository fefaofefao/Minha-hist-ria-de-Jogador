extends TelaBase
## Semana da carreira: status, próximo jogo, agenda (2 atividades), eventos
## da vida e o botão para jogar a semana.

const PERSONAGENS := {
	"familia": ["familia", Color("ff8fb1"), "Família"], "amigo": ["grupo", Color("7fd1ff"), "Amigo"],
	"empresario": ["aperto", Color("ffc928"), "Empresário"], "imprensa": ["jornal", Color("b0bec5"), "Imprensa"],
	"medico": ["cura", Color("2ed47a"), "Departamento médico"], "tecnico": ["esporte", Color("ff9a3c"), "Técnico"],
	"patrocinador": ["dinheiro", Color("2ed47a"), "Patrocinador"], "torcida": ["festa", Color("a77bff"), "Torcida"],
	"rival": ["fogo", Color("ff5468"), "Rival"], "diretoria": ["escudo", Color("43a8ff"), "Diretoria"],
}

var selecionadas: Array = []
var _cartoes_agenda := {}
var _btn_jogar: Button
var _ocupado := false


func construir() -> void:
	if Jogo.carreira.is_empty() or Jogo.carreira["fase"] in ["prologo", "aposentado"]:
		Tela.ir.call_deferred("res://cenas/menu.tscn")
		return
	if Jogo.temporada_acabou():
		Tela.ir.call_deferred("res://cenas/temporada.tscn")
		return
	Audio.musica(true)
	Audio.torcida(0.0)
	var c := Jogo.carreira
	var j: Dictionary = c["jogador"]
	var topo := UI.hbox(10)
	topo.add_child(Componentes.cabecalho_clube(c["clube"], "%s • Semana %d • %d anos" % [c["categoria"], int(c["semana"]), int(j["idade"])]))
	conteudo.add_child(topo)
	var chips := UI.hbox(10)
	chips.add_child(Componentes.chip_moedas())
	chips.add_child(Componentes.chip_dinheiro())
	chips.add_child(UI.chip("grupo", UI.formatar_numero(Jogo.fas()), UI.AZUL, Color(UI.AZUL, 0.14)))
	if int(Jogo.perfil.get("fichas", 0)) > 0:
		chips.add_child(UI.chip("replay", "%d" % int(Jogo.perfil["fichas"]), UI.ROXO))
	chips.add_child(UI.expansor())
	var ovr := UI.chip("estrela", "OVR %d" % Jogo.overall(), UI.OURO, Color(UI.OURO, 0.15))
	chips.add_child(ovr)
	conteudo.add_child(chips)

	var rol := UI.rolagem()
	conteudo.add_child(rol)
	var col := UI.vbox(16)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(col)
	col.add_child(_cartao_jogo())
	col.add_child(_cartao_status())
	col.add_child(_cartao_agenda())
	var obj := _cartao_objetivo()
	if obj:
		col.add_child(obj)
	col.add_child(_cartao_noticias())
	col.add_child(UI.espaco(10))

	_btn_jogar = UI.botao("Jogar a semana", "play", "primario", 96)
	_btn_jogar.pressed.connect(_jogar_semana)
	conteudo.add_child(_btn_jogar)
	_atualizar_botao()
	var nav := Componentes.navegacao("semana")
	add_child(nav)
	nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	nav.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var m: MarginContainer = conteudo.get_parent()
	m.add_theme_constant_override("margin_bottom", 112)
	if not Jogo.perfil.get("tutorial_hub", false):
		_tutorial.call_deferred()
	elif c["temp"].get("objetivo", {}).is_empty():
		_escolher_objetivo.call_deferred()
	elif c["semana_info"].has("evento_forcado") and not c["semana_info"].get("forcado_visto", false):
		pass


# ---------------------------------------------------------------- cartões

func _cartao_jogo() -> PanelContainer:
	var jogo := Jogo.proximo_jogo()
	var adv := Jogo.clube(jogo["adv"])
	var tipo: String = jogo["tipo"]
	var cor_borda := UI.OURO if tipo in ["final", "selecao"] else UI.LINHA
	var card := UI.cartao_borda(UI.CARTAO, cor_borda, 24, 20, 2)
	var col := UI.vbox(12)
	card.add_child(col)
	var comp: String = jogo.get("competicao", Jogo.carreira["temp"]["liga"])
	var rodada := ""
	if tipo == "liga":
		rodada = " • Rodada %d/%d" % [int(jogo["semana"]), int(Jogo.carreira["temp"]["rodadas"])]
	col.add_child(UI.rotulo(("PRÓXIMO JOGO • " + comp + rodada).to_upper(), 19, UI.OURO if tipo != "liga" else UI.TEXTO2, "titulo"))
	var linha := UI.hbox(16)
	linha.add_child(Componentes.Brasao.novo(adv, 70))
	var info := UI.vbox(2)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nome := UI.titulo("vs " + adv["nome"], 36)
	nome.clip_text = true
	info.add_child(nome)
	var pos := Jogo.posicao_tabela()
	var lugar := "Em casa" if jogo.get("casa", true) else "Fora de casa"
	if tipo == "liga":
		lugar += " • Vocês estão em %dº" % pos
	if jogo["adv"] == Jogo.carreira["rival"]["clube"]:
		lugar += " • Time do %s!" % Jogo.carreira["rival"]["nome"]
	info.add_child(UI.rotulo(lugar, 21, UI.TEXTO2, "forte"))
	linha.add_child(info)
	col.add_child(linha)
	var sit := Jogo.situacao_titular()
	var textos := {"titular": ["Você deve começar jogando", "ok", UI.VERDE], "reserva": ["Você deve começar no banco", "info", UI.OURO],
		"fora": ["Fora da lista: melhore a forma e a relação com o técnico", "bloqueio", UI.VERMELHO],
		"lesionado": ["Lesionado: %d semana(s)" % int(Jogo.carreira["status"]["lesao"]), "cura", UI.VERMELHO]}
	if Jogo.carreira.get("contrato", {}).get("pedido_saida", "") == "forcado" and sit == "reserva":
		textos["reserva"] = ["Afastado do time titular (você forçou a saída)", "bloqueio", UI.VERMELHO]
	var t: Array = textos[sit]
	col.add_child(UI.chip(t[1], t[0], t[2], Color(t[2], 0.12)))
	return card


func _cartao_status() -> PanelContainer:
	var sec := Componentes.secao("Como você está", "pessoa")
	var st: Dictionary = Jogo.carreira["status"]
	var en := float(st["energia"])
	sec[1].add_child(UI.linha_status("energia", "Energia", en, UI.VERDE if en >= 40 else UI.VERMELHO))
	sec[1].add_child(UI.linha_status("mente", "Confiança", float(st["moral"]), UI.AZUL))
	var f := Jogo.forma()
	sec[1].add_child(UI.linha_status("grafico", "Forma (média recente)", clampf((f - 3.0) / 7.0 * 100.0, 0, 100), UI.cor_nota(f), "%.1f" % f))
	if en < 25:
		sec[1].add_child(UI.paragrafo("Pouca energia aumenta o risco de lesão e derruba seu rendimento.", 21, UI.VERMELHO))
	var linha := UI.hbox(12)
	var info: Dictionary = Jogo.carreira["semana_info"]
	if int(st["lesao"]) > 0:
		var trat := UI.botao("Tratamento", "anuncio", "anuncio", 72)
		trat.pressed.connect(_tratamento_anuncio)
		trat.disabled = info.get("tratamento", false)
		linha.add_child(trat)
		var trat_m := UI.botao("80", "moeda", "normal", 72)
		trat_m.custom_minimum_size.x = 150
		trat_m.size_flags_horizontal = Control.SIZE_SHRINK_END
		trat_m.pressed.connect(_tratamento_moedas)
		linha.add_child(trat_m)
	elif en < 85:
		var mas := UI.botao("Massagem do fisio (+30)", "anuncio", "anuncio", 72)
		mas.disabled = info.get("massagem", false)
		mas.pressed.connect(_massagem)
		linha.add_child(mas)
	if linha.get_child_count() > 0:
		sec[1].add_child(linha)
	return sec[0]


func _cartao_agenda() -> PanelContainer:
	var sec := Componentes.secao("Agenda da semana • escolha 2", "calendario")
	var grade := GridContainer.new()
	grade.columns = 2
	grade.add_theme_constant_override("h_separation", 12)
	grade.add_theme_constant_override("v_separation", 12)
	for id in Jogo.acoes_disponiveis():
		grade.add_child(_cartao_acao(id))
	if not Jogo.carreira["semana_info"].get("lenda", false) and int(Jogo.carreira["status"]["lesao"]) == 0:
		grade.add_child(_cartao_lenda())
	sec[1].add_child(grade)
	return sec[0]


func _cartao_acao(id: String) -> Button:
	var a: Dictionary = Dados.AGENDA[id]
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0, 112)
	_estilo_acao(b, false)
	var col := UI.vbox(4)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 14
	col.offset_right = -10
	col.offset_top = 10
	col.offset_bottom = -8
	b.add_child(col)
	var topo := UI.hbox(8)
	topo.add_child(UI.icone(a["icone"], 30, UI.OURO))
	var n := UI.rotulo(a["nome"], 22, UI.TEXTO, "forte")
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	topo.add_child(n)
	col.add_child(topo)
	col.add_child(UI.rotulo(_resumo_acao(a), 18, UI.TEXTO2, "texto"))
	b.pressed.connect(func() -> void:
		Audio.tocar("clique")
		if id in selecionadas:
			selecionadas.erase(id)
		elif selecionadas.size() < 2:
			if a.has("custo") and float(Jogo.carreira["dinheiro"]) < float(a["custo"]):
				Tela.aviso("Dinheiro insuficiente (%s)." % UI.formatar_dinheiro(a["custo"]), "dinheiro", UI.VERMELHO)
				return
			selecionadas.append(id)
		else:
			Tela.aviso("Só dá tempo de 2 atividades por semana.", "calendario")
			return
		for k in _cartoes_agenda:
			_estilo_acao(_cartoes_agenda[k], k in selecionadas)
		_atualizar_botao())
	_cartoes_agenda[id] = b
	return b


func _resumo_acao(a: Dictionary) -> String:
	var partes: Array = []
	for x in a.get("xp", {}):
		partes.append("+" + Dados.NOMES_ATRIBUTOS[x].split(" ")[0])
	if a.has("energia"):
		partes.append("%s%d energia" % ["+" if a["energia"] > 0 else "", a["energia"]])
	if a.has("moral") and partes.size() < 3:
		partes.append("+confiança")
	for r in a.get("rel", {}):
		partes.append("+" + {"familia": "família", "amigo": "amizade"}.get(r, r))
	if a.has("dinheiro"):
		partes.append("+" + UI.formatar_dinheiro(a["dinheiro"]))
	if a.has("custo"):
		partes.append("custa " + UI.formatar_dinheiro(a["custo"]))
	return " • ".join(partes.slice(0, 3))


func _estilo_acao(b: Button, sel: bool) -> void:
	var s := UI.caixa(Color("223154") if sel else UI.CARTAO2, 18, 0)
	s.border_color = UI.OURO if sel else UI.LINHA
	s.set_border_width_all(3 if sel else 2)
	for e in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(e, s)


func _cartao_lenda() -> Button:
	var b := UI.botao("", "", "roxo", 112)
	var linha: HBoxContainer = b.get_child(0)
	linha.alignment = BoxContainer.ALIGNMENT_BEGIN
	var col := UI.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var t := UI.hbox(8)
	t.add_child(UI.icone("diamante", 30, UI.ROXO))
	t.add_child(UI.rotulo("Treino com lenda", 22, UI.TEXTO, "forte"))
	col.add_child(t)
	col.add_child(UI.rotulo("Grátis no tempo • 120 moedas", 18, UI.TEXTO2))
	linha.add_child(UI.espaco(4))
	linha.add_child(col)
	b.pressed.connect(_treino_lenda)
	return b


func _cartao_objetivo() -> PanelContainer:
	var o: Dictionary = Jogo.carreira["temp"].get("objetivo", {})
	if o.is_empty():
		return null
	var sec := Componentes.secao("Objetivo da temporada", o.get("icone", "trofeu"))
	var prog := float(o.get("progresso", 0))
	var alvo := float(o["alvo"])
	var txt := "%s  (%s / %s)" % [o["texto"], ("%.1f" % prog) if o["id"] == "media" else str(int(prog)), ("%.1f" % alvo) if o["id"] == "media" else str(int(alvo))]
	sec[1].add_child(UI.paragrafo(txt, 22, UI.TEXTO))
	sec[1].add_child(UI.barra(clampf(prog / maxf(alvo, 0.01), 0, 1), UI.OURO, 12))
	sec[1].add_child(UI.rotulo("Recompensa: %d moedas" % int(o["moedas"]), 19, UI.TEXTO2))
	return sec[0]


func _cartao_noticias() -> PanelContainer:
	var sec := Componentes.secao("Notícias", "jornal", UI.AZUL)
	var n: Array = Jogo.carreira.get("noticias", [])
	if n.is_empty():
		sec[1].add_child(UI.paragrafo("Nada de novo por enquanto.", 21))
	for t in n.slice(0, 3):
		sec[1].add_child(UI.paragrafo("• " + str(t), 21, UI.TEXTO2))
	return sec[0]


func _atualizar_botao() -> void:
	var precisa := mini(2, Jogo.acoes_disponiveis().size())
	_btn_jogar.disabled = selecionadas.size() < precisa
	UI.definir_texto_botao(_btn_jogar, "Jogar a semana" if not _btn_jogar.disabled else "Escolha %d atividade%s" % [precisa - selecionadas.size(), "s" if precisa - selecionadas.size() > 1 else ""])


# ---------------------------------------------------------------- ações extras

func _massagem() -> void:
	if await Anuncios.recompensado("massagem"):
		Jogo.carreira["semana_info"]["massagem"] = true
		Jogo.aplicar_efeitos({"energia": 30})
		Jogo.salvar_carreira()
		Tela.aviso("Massagem feita: +30 de energia.", "energia", UI.VERDE)
		Tela.ir("res://cenas/hub.tscn")


func _tratamento_anuncio() -> void:
	if await Anuncios.recompensado("tratamento"):
		_curar()


func _tratamento_moedas() -> void:
	if Jogo.gastar_moedas(80, "tratamento"):
		_curar()
	else:
		_sem_moedas()


func _curar() -> void:
	Jogo.carreira["semana_info"]["tratamento"] = true
	Jogo.carreira["status"]["lesao"] = maxi(0, int(Jogo.carreira["status"]["lesao"]) - 1)
	Jogo.salvar_carreira()
	Tela.aviso("Tratamento intensivo: -1 semana de lesão.", "cura", UI.VERDE)
	Tela.ir("res://cenas/hub.tscn")


func _sem_moedas() -> void:
	var r := await Tela.dialogo("Moedas insuficientes", "Ganhe moedas no Lance do Dia, no álbum e nos sonhos... ou pegue um pacote na loja.",
		[["Ir para a loja", "loja", "primario"], ["Agora não", "fechar", "fantasma"]], "moeda", UI.OURO)
	if r == 0:
		Tela.ir("res://cenas/loja.tscn")


func _treino_lenda() -> void:
	var nomes: Array = []
	for a in Dados.ATRIBUTOS:
		nomes.append([Dados.NOMES_ATRIBUTOS[a], Dados.ICONES_ATRIBUTOS[a], "normal"])
	nomes.append(["Cancelar", "fechar", "fantasma"])
	var r := await Tela.dialogo("Treino com uma lenda", "Um ídolo aposentado treina você por um dia: +6 de XP no atributo escolhido, sem gastar energia. Custa 120 moedas.", nomes, "diamante", UI.ROXO)
	if r < 0 or r >= Dados.ATRIBUTOS.size():
		return
	if not Jogo.gastar_moedas(120, "treino_lenda"):
		_sem_moedas()
		return
	var a: String = Dados.ATRIBUTOS[r]
	var g := Jogo.dar_xp({a: 6.0})
	Jogo.carreira["semana_info"]["lenda"] = true
	Jogo.salvar_carreira()
	Tela.aviso("%s +%.1f" % [Dados.NOMES_ATRIBUTOS[a], g.get(a, 0.0)], "sobe", UI.VERDE)
	Tela.ir("res://cenas/hub.tscn")


func _tutorial() -> void:
	await Tela.dialogo("Sua semana", "Toda semana você:\n\n1. Escolhe 2 atividades (treinos evoluem atributos, descanso recupera energia).\n2. Vive um acontecimento da vida: suas escolhas mudam relações e carreira.\n3. Joga a partida: nos momentos decisivos, OLHE AO REDOR antes de escolher.\n\nO técnico escala quem está em forma e tem a confiança dele.",
		[["Entendi", "ok", "primario"]], "calendario", UI.OURO)
	Jogo.perfil["tutorial_hub"] = true
	Jogo.salvar_perfil()
	if Jogo.carreira["temp"].get("objetivo", {}).is_empty():
		_escolher_objetivo()


func _escolher_objetivo() -> void:
	var objs := Jogo.objetivos_disponiveis()
	var botoes: Array = []
	for o in objs:
		botoes.append(["%s  (%d moedas)" % [o["texto"], o["moedas"]], o["icone"], "normal"])
	var r := await Tela.dialogo("Temporada %d" % int(Jogo.carreira["temporada"]), "Qual é o seu objetivo nesta temporada? Cumprir rende moedas no fim.", botoes, "trofeu", UI.OURO)
	Jogo.definir_objetivo(objs[maxi(r, 0)])
	Tela.ir("res://cenas/hub.tscn")


# ---------------------------------------------------------------- semana

func _jogar_semana() -> void:
	if _ocupado:
		return
	_ocupado = true
	var efeitos := Jogo.aplicar_agenda(selecionadas)
	if not efeitos.is_empty():
		Tela.aviso("Semana: " + ", ".join(efeitos.slice(0, 4)), "calendario", UI.VERDE)
	var info: Dictionary = Jogo.carreira["semana_info"]
	var evento := {}
	if info.has("evento_forcado"):
		for e in Dados.EVENTOS:
			if e["id"] == info["evento_forcado"]:
				evento = e
		info.erase("evento_forcado")
	elif Jogo.rng.randf() < 0.62:
		evento = Jogo.sortear_evento()
	if not evento.is_empty():
		await _mostrar_evento(evento)
	var sit := Jogo.situacao_titular()
	if sit in ["fora", "lesionado"]:
		var r := Jogo.simular_sem_jogar()
		var adv := Jogo.clube(r["adv"])
		var res := "venceu" if r["venceu"] else ("empatou" if r["empate"] else "perdeu")
		await Tela.dialogo("Você não jogou", "%s. O time %s: %d x %d contra o %s." % ["Lesionado, você assistiu da arquibancada" if sit == "lesionado" else "Fora da lista, você assistiu do banco",
			res, r["gols_nos"], r["gols_adv"], adv["nome"]], [["Continuar", "seta_dir", "primario"]], "info", UI.OURO)
		Tela.ir("res://cenas/temporada.tscn" if Jogo.temporada_acabou() else "res://cenas/hub.tscn")
		return
	Jogo.preparar_partida(Jogo.proximo_jogo())
	Tela.ir("res://cenas/partida.tscn")


func _mostrar_evento(e: Dictionary) -> void:
	Audio.tocar("carta")
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.75)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var m := UI.margem(30, 60 + Tela.margem_topo(), 30, 50)
	fundo.add_child(m)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var centro := CenterContainer.new()
	m.add_child(centro)
	var pers: Array = PERSONAGENS.get(e.get("personagem", "familia"), PERSONAGENS["familia"])
	var card := UI.cartao_borda(UI.CARTAO, pers[1], 30, 30, 3)
	card.custom_minimum_size = Vector2(640, 0)
	centro.add_child(card)
	var col := UI.vbox(18)
	card.add_child(col)
	var cab := UI.hbox(14)
	var circ := UI.cartao(Color(pers[1], 0.18), 40, 14)
	circ.add_child(UI.icone(pers[0], 48, pers[1]))
	cab.add_child(circ)
	var ct := UI.vbox(0)
	ct.add_child(UI.rotulo(pers[2].to_upper(), 19, pers[1], "titulo"))
	var tt := UI.titulo(Jogo.texto(e["titulo"]), 38)
	tt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tt.custom_minimum_size.x = 420
	ct.add_child(tt)
	cab.add_child(ct)
	col.add_child(cab)
	col.add_child(UI.paragrafo(Jogo.texto(e["texto"]), 26, UI.TEXTO))
	var escolha := [-1]
	var sinal := [false]
	for i in e["opcoes"].size():
		var op: Dictionary = e["opcoes"][i]
		var txt := Jogo.texto(op["texto"])
		if op.has("chance"):
			txt += "  (arriscado)"
		var b := UI.botao("", "", "normal", 0)
		b.custom_minimum_size.y = 84
		var linha: HBoxContainer = b.get_child(0)
		linha.alignment = BoxContainer.ALIGNMENT_BEGIN
		linha.add_child(UI.espaco(6))
		var l := UI.paragrafo(txt, 24, UI.TEXTO)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		linha.add_child(l)
		if not Jogo.opcao_evento_disponivel(op):
			b.disabled = true
		b.pressed.connect(func() -> void:
			escolha[0] = i
			sinal[0] = true)
		col.add_child(b)
	card.pivot_offset = Vector2(320, 300)
	card.scale = Vector2(0.92, 0.92)
	card.modulate.a = 0
	var tw := create_tween().set_parallel()
	tw.tween_property(card, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.25)
	while not sinal[0]:
		if not is_inside_tree():
			return
		await get_tree().process_frame
	var r := Jogo.resolver_evento(e, escolha[0])
	fundo.queue_free()
	var linhas: String = r["texto"]
	if not r["efeitos"].is_empty():
		linhas += "\n\n" + "   ".join(r["efeitos"])
	var titulo := "Deu certo!" if r["teve_sorte"] and r["sucesso"] else ("Deu errado..." if r["teve_sorte"] else "Decisão tomada")
	Audio.tocar("sucesso" if r["sucesso"] else "falha")
	await Tela.dialogo(titulo, linhas, [["Continuar", "seta_dir", "primario"]], pers[0], pers[1])
