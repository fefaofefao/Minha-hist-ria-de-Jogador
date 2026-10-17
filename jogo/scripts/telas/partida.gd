extends Control
## Partida: o jogo corre acelerado com narração; nos momentos decisivos entra
## o motor de lances (primeira pessoa). Mata-mata empatado vai para os pênaltis
## (o jogador bate o 3º). No fim: relatório com nota, evolução e memórias.

const LANCE := preload("res://cenas/lance.tscn")

var p: Dictionary
var nos: Dictionary
var adv: Dictionary
var gols_nos := 0
var gols_adv := 0
var minuto := 0
var fim_minuto := 92
var velocidade := 1.0
var pular := false
var lances: Array = []
var _proximo_momento := 0
var _proximo_gol := 0
var _em_campo := true
var _rng := RandomNumberGenerator.new()

var mundo: Mundo3D
var camera: Camera3D
var bonecos: Array = []
var bola3d: MeshInstance3D
var _alvo_bola := Vector3(0, 0.11, 10)
var _ataque := 0.5

var ui: Control
var lbl_placar: Label
var lbl_minuto: Label
var feed: VBoxContainer
var lbl_status: Label
var btn_vel: Button
var btn_pular: Button
var banner: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p = Jogo.partida_atual
	if p.is_empty():
		if Jogo.carreira.get("fase", "") == "prologo":
			p = Jogo.preparar_prologo()
		else:
			Tela.ir("res://cenas/hub.tscn")
			return
	_rng.randomize()
	nos = Jogo.clube(p["nos"])
	adv = Jogo.clube(p["adv"])
	_em_campo = p["titular"] == "titular"
	fim_minuto = 90 + _rng.randi_range(1, 5)
	Audio.musica(false)
	_montar_3d()
	_montar_ui()
	if p["tipo"] == "prologo":
		await _intro_prologo()
	_jogar()


# ---------------------------------------------------------------- 3D de fundo

func _montar_3d() -> void:
	mundo = Mundo3D.new()
	add_child(mundo)
	var cor_fora: Color = adv["cor"]
	mundo.construir(p["cenario"], p.get("noite", false), nos["cor"], cor_fora, hash(p["nos"]) % 1000)
	var forma := [Vector2(0, 20), Vector2(-14, 8), Vector2(-5, 9), Vector2(5, 9), Vector2(14, 8), Vector2(-10, -2),
		Vector2(0, 0), Vector2(10, -2), Vector2(-12, -12), Vector2(0, -14), Vector2(12, -12)]
	for t in 2:
		var casa := t == 0
		for i in forma.size():
			var j := Jogador3D.new()
			add_child(j)
			var visual := {"pele": _rng.randi_range(0, 5), "cabelo": _rng.randi_range(0, 5), "cor_cabelo": _rng.randi_range(0, 3)}
			if i == 0:
				j.configurar(Color("2bb673") if casa else Color("7a3fd1"), Color.BLACK, visual, 1)
			else:
				var uni := Dados.uniforme(p["nos"] if casa else p["adv"])
				j.configurar(nos["cor"] if casa else cor_fora, nos["calcao"] if casa else adv["calcao"], visual, i + 1, Color.WHITE, uni[0], uni[1])
			var base := Vector3(forma[i].x, 0, 12.5 + (forma[i].y + 10) * (1 if casa else -1) * 0.9)
			if not casa:
				base.z = 12.5 - (forma[i].y + 10) * 0.9 - 12
			j.position = base
			bonecos.append({"no": j, "base": base, "casa": casa, "alvo": base})
	var esfera := SphereMesh.new()
	esfera.radius = 0.12
	esfera.height = 0.24
	bola3d = MeshInstance3D.new()
	bola3d.mesh = esfera
	bola3d.material_override = Jogador3D.mat(Color("f5f5f5"))
	bola3d.position = Vector3(0, 0.12, 12.5)
	add_child(bola3d)
	camera = Camera3D.new()
	camera.fov = 50.0
	add_child(camera)
	camera.position = Vector3(46, 26, 12.5)
	camera.look_at(Vector3(0, 0, 12.5), Vector3.UP)
	camera.make_current()


func _process(delta: float) -> void:
	if bola3d == null or not mundo.visible:
		return
	bola3d.position = bola3d.position.move_toward(_alvo_bola, delta * 9.0)
	if bola3d.position.distance_to(_alvo_bola) < 0.5:
		var z := lerpf(50.0, -30.0, _ataque) + _rng.randf_range(-14, 14)
		_alvo_bola = Vector3(_rng.randf_range(-26, 26), 0.12, z)
	for b in bonecos:
		var no: Node3D = b["no"]
		var base: Vector3 = b["base"]
		var deslocar := (_ataque - 0.5) * -28.0
		var alvo: Vector3 = base + Vector3(0, 0, deslocar) + (bola3d.position - base) * 0.25
		alvo.x = clampf(alvo.x, -32, 32)
		no.position = no.position.move_toward(alvo, delta * 4.5)
		var olhar := Vector3(bola3d.position.x, 0, bola3d.position.z)
		if olhar.distance_to(no.position) > 0.5:
			no.look_at(olhar, Vector3.UP)
	var foco := Vector3(0, 0, bola3d.position.z * 0.6 + 5)
	camera.position = camera.position.lerp(Vector3(44, 24, foco.z + 4), delta * 0.8)
	var atual := camera.global_transform
	var alvo := atual.looking_at(foco, Vector3.UP)
	atual.basis = atual.basis.slerp(alvo.basis, clampf(delta * 1.5, 0.0, 1.0)).orthonormalized()
	camera.global_transform = atual


# ---------------------------------------------------------------- UI

func _montar_ui() -> void:
	ui = Control.new()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.03, 0.07, 0.0))
	g.set_color(1, Color(0.02, 0.03, 0.07, 0.96))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0)
	tex.fill_to = Vector2(0.5, 0.55)
	var fundo := TextureRect.new()
	fundo.texture = tex
	fundo.stretch_mode = TextureRect.STRETCH_SCALE
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	fundo.offset_top = -820

	var topo := UI.margem(22, 20 + Tela.margem_topo(), 22, 0)
	topo.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	ui.add_child(topo)
	var placar := UI.cartao(Color(0.03, 0.05, 0.1, 0.9), 24, 18)
	topo.add_child(placar)
	var pc := UI.vbox(6)
	placar.add_child(pc)
	var comp := UI.rotulo(p.get("competicao", "").to_upper(), 19, UI.OURO, "titulo")
	comp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pc.add_child(comp)
	var linha := UI.hbox(14)
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_child(Componentes.Brasao.novo(nos, 64))
	var sn := UI.titulo(nos["sigla"], 40)
	linha.add_child(sn)
	lbl_placar = UI.titulo("0  x  0", 58, UI.TEXTO)
	lbl_placar.custom_minimum_size.x = 190
	lbl_placar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	linha.add_child(lbl_placar)
	linha.add_child(UI.titulo(adv["sigla"], 40))
	linha.add_child(Componentes.Brasao.novo(adv, 64))
	pc.add_child(linha)
	lbl_minuto = UI.rotulo("0'", 26, UI.TEXTO2, "titulo")
	lbl_minuto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pc.add_child(lbl_minuto)

	var baixo := UI.margem(24, 0, 24, 30)
	baixo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	baixo.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ui.add_child(baixo)
	var col := UI.vbox(14)
	baixo.add_child(col)
	feed = UI.vbox(10)
	feed.custom_minimum_size.y = 420
	feed.alignment = BoxContainer.ALIGNMENT_END
	col.add_child(feed)
	var st := UI.cartao(Color(1, 1, 1, 0.05), 16, 14)
	lbl_status = UI.paragrafo(_texto_status(), 22, UI.TEXTO2)
	st.add_child(lbl_status)
	col.add_child(st)
	var ctrl := UI.hbox(14)
	btn_vel = UI.botao("x1", "tempo", "normal", 80)
	btn_vel.custom_minimum_size.x = 150
	btn_vel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	btn_vel.pressed.connect(func() -> void:
		velocidade = 2.5 if velocidade == 1.0 else 1.0
		UI.definir_texto_botao(btn_vel, "x2" if velocidade > 1.0 else "x1"))
	ctrl.add_child(btn_vel)
	btn_pular = UI.botao("Ir ao próximo lance", "seta_dir", "primario", 80)
	btn_pular.pressed.connect(func() -> void: pular = true)
	ctrl.add_child(btn_pular)
	col.add_child(ctrl)


func _texto_status() -> String:
	match p["titular"]:
		"titular":
			return "Você é TITULAR hoje. Energia %d%% • Confiança %d%%" % [int(Jogo.carreira["status"]["energia"]), int(Jogo.carreira["status"]["moral"])]
		"reserva":
			return "Você começa no BANCO. Mostre serviço quando entrar."
	return ""


func _narrar(texto: String, nome_icone := "bola", cor := UI.TEXTO2, destaque := false) -> void:
	var c := UI.cartao(Color(0.07, 0.1, 0.17, 0.92) if not destaque else Color(0.2, 0.16, 0.03, 0.95), 16, 14)
	var l := UI.hbox(12)
	c.add_child(l)
	var m := UI.rotulo("%d'" % minuto, 22, UI.TEXTO3, "titulo")
	m.custom_minimum_size.x = 46
	l.add_child(m)
	l.add_child(UI.icone(nome_icone, 28, cor))
	var t := UI.paragrafo(texto, 23, UI.TEXTO if destaque else UI.TEXTO2)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_child(t)
	feed.add_child(c)
	UI.aparecer(c)
	while feed.get_child_count() > 6:
		var velho := feed.get_child(0)
		feed.remove_child(velho)
		velho.queue_free()


func _atualizar_placar() -> void:
	lbl_placar.text = "%d  x  %d" % [gols_nos, gols_adv]
	lbl_placar.pivot_offset = lbl_placar.size / 2.0
	var tw := create_tween()
	tw.tween_property(lbl_placar, "scale", Vector2(1.25, 1.25), 0.12)
	tw.tween_property(lbl_placar, "scale", Vector2.ONE, 0.2)


# ---------------------------------------------------------------- fluxo

func _intro_prologo() -> void:
	var r := await Tela.dialogo("Final da Copa da Vila",
		Jogo.texto("Vila Esperança x Jardim Primavera. O campo de terra está lotado: laje, muro, até em cima do bar do Zé.\n\nDo outro lado está o {rival}, o craque do Jardim. Na arquibancada improvisada, dois olheiros de óculos escuros anotam tudo.\n\n{mae} está na grade, com as mãos juntas.\n\nNos momentos decisivos, a jogada é sua."),
		[["Apito inicial!", "play", "primario"]], "bola", UI.OURO)
	Analytics.evento("prologo_inicio", {"r": r})


func _jogar() -> void:
	Audio.tocar("apito")
	Audio.torcida(0.5)
	_narrar("Começa o jogo!", "play", UI.VERDE)
	var momentos: Array = p["momentos"]
	var gols_bg: Array = p["gols_bg"]
	while minuto < fim_minuto:
		var espera := 0.11 / velocidade
		if pular:
			espera = 0.012
		await get_tree().create_timer(espera).timeout
		minuto += 1
		lbl_minuto.text = "%d'" % mini(minuto, 90) if minuto <= 90 else "90+%d'" % (minuto - 90)
		_ataque = clampf(_ataque + _rng.randf_range(-0.08, 0.08), 0.15, 0.85)
		if minuto == 46:
			_narrar("Intervalo. Respira, bebe água, ouve o técnico.", "tempo")
			Audio.tocar("apito")
			await get_tree().create_timer(0.6 if not pular else 0.1).timeout
		# entrada do reserva
		if not _em_campo and _proximo_momento < momentos.size() and minuto == int(momentos[_proximo_momento]["minuto"]) - 4:
			_em_campo = true
			_narrar("SUBSTITUIÇÃO: você entra em campo!", "troca", UI.OURO, true)
			Audio.torcida(0.7)
		while _proximo_gol < gols_bg.size() and int(gols_bg[_proximo_gol]["minuto"]) == minuto:
			var g: Dictionary = gols_bg[_proximo_gol]
			_proximo_gol += 1
			if g["time"] == "nos":
				gols_nos += 1
				_narrar("GOL do %s! %s marca." % [nos["sigla"], g["autor"]], "bola", UI.VERDE, true)
				Audio.tocar("gol", 0.6)
				mundo.festa_torcida(4)
			else:
				gols_adv += 1
				var rival: bool = g["autor"] == Jogo.carreira["rival"]["nome"]
				_narrar(("Gol do %s. %s comemora provocando." if rival else "Gol do %s. %s balança a rede.") % [adv["sigla"], g["autor"]], "bola", UI.VERMELHO)
				Audio.tocar("uhh", 0.6)
			_atualizar_placar()
			pular = false
		if _proximo_momento < momentos.size() and minuto == int(momentos[_proximo_momento]["minuto"]):
			var m: Dictionary = momentos[_proximo_momento]
			_proximo_momento += 1
			pular = false
			await _momento(m)
		elif _rng.randf() < 0.05 and not pular:
			var frases := ["Escanteio para o %s." % [nos["sigla"], adv["sigla"]][_rng.randi() % 2], "Cartão amarelo por falta dura.",
				"Que defesa do goleiro!", "Chute de longe, por cima do gol.", "A torcida canta alto.", "Impedimento marcado."]
			_narrar(frases[_rng.randi() % frases.size()], "esporte")
	Audio.tocar("apito_final")
	_narrar("Fim de jogo!", "placar", UI.OURO, true)
	await get_tree().create_timer(0.8).timeout
	var penaltis = null
	if p.get("mata_mata", false) and gols_nos == gols_adv:
		penaltis = await _disputa_penaltis()
	var rel := {"gols_nos": gols_nos, "gols_adv": gols_adv, "lances": lances, "penaltis": penaltis}
	var resumo := Jogo.finalizar_partida(rel)
	await _relatorio(resumo)


func _momento(m: Dictionary) -> void:
	if m["tipo"] == "defesa_tardia":
		# o esforço defensivo só vira lance se o resultado estiver em jogo
		if gols_nos < gols_adv:
			m["tipo"] = Situacoes.sortear_tipo(Jogo.carreira["jogador"]["posicao"], _rng)
		elif gols_nos - gols_adv >= 2:
			_narrar("Você volta pra ajudar na marcação. O time administra o placar.", "escudo")
			return
		else:
			m["tipo"] = Situacoes.sortear_defesa(_rng, Jogo.carreira.get("ultimos_tipos", []))
			_narrar("O %s pressiona! Você volta pra ajudar a defender..." % adv["sigla"], "escudo", UI.LARANJA, true)
			Audio.torcida(0.8)
			await get_tree().create_timer(0.6).timeout
	_narrar("MOMENTO DECISIVO!", "olho", UI.OURO, true)
	Audio.tocar("coracao")
	await get_tree().create_timer(0.7).timeout
	var ctx := Jogo.contexto_lance(p, m, gols_nos, gols_adv)
	var r: Dictionary = await _rodar_lance(m["tipo"], ctx)
	r["minuto"] = m["minuto"]
	lances.append(r)
	var d: String = r["desfecho"]
	var delta := Jogo.delta_nota(r)
	var sinal := "+%.1f" % delta if delta >= 0 else "%.1f" % delta
	match d:
		"gol":
			gols_nos += 1
			_narrar("GOOOL SEU! %s  (nota %s)" % [r.get("opcao_texto", ""), sinal], "bola", UI.VERDE, true)
		"assistencia":
			gols_nos += 1
			_narrar("ASSISTÊNCIA SUA! %s  (nota %s)" % [r.get("opcao_texto", ""), sinal], "troca", UI.VERDE, true)
		"falta_tatica":
			_narrar("Falta tática: cartão pra você, mas o contra-ataque morreu  (nota %s)" % sinal, "escudo", UI.OURO)
		"desarme", "bloqueio", "afastou", "impedimento":
			_narrar("QUE VOLTA! Você salvou na defesa: %s  (nota %s)" % [r.get("opcao_texto", ""), sinal], "escudo", UI.VERDE, true)
			mundo.festa_torcida(3)
		"gol_sofrido":
			gols_adv += 1
			_narrar("Gol do %s. Você foi superado na jogada  (nota %s)" % [adv["sigla"], sinal], "bola", UI.VERMELHO)
		"falta_dura":
			_narrar("Cartão amarelo pra você  (nota %s)" % sinal, "info", UI.OURO)
			if r.get("falta_gol", false):
				await get_tree().create_timer(0.8).timeout
				gols_adv += 1
				_narrar("Na cobrança da falta... gol do %s." % adv["sigla"], "bola", UI.VERMELHO)
		"salvou_goleiro":
			_narrar("Você foi driblado, mas o goleiro salvou!  (nota %s)" % sinal, "escudo", UI.TEXTO2)
		_:
			var t: String = {"defesa": "O goleiro defendeu.", "fora": "Pra fora.", "trave": "Na trave!", "perdeu": "Perdeu a bola.",
				"interceptado": "Passe interceptado.", "passou_defesa": "Quase! Grande jogada."}.get(d, "")
			_narrar("%s  (nota %s)" % [t, sinal], "olho", UI.LARANJA if delta < 0 else UI.TEXTO2)
	_atualizar_placar()


func _rodar_lance(tipo: String, ctx: Dictionary) -> Dictionary:
	var s := Situacoes.gerar(tipo, ctx)
	ui.visible = false
	mundo.visible = false
	for b in bonecos:
		b["no"].visible = false
	bola3d.visible = false
	var l: Lance = LANCE.instantiate()
	add_child(l)
	l.iniciar(s)
	var r: Dictionary = await l.terminou
	if r.get("segunda_chance", false):
		p["segunda_chance_usada"] = true
		if r.get("segunda_chance_modo", "") == "ficha":
			Jogo.perfil["fichas"] = maxi(0, int(Jogo.perfil.get("fichas", 0)) - 1)
			Jogo.salvar_perfil()
	# reativa o mundo da partida ANTES de liberar o lance (evita um quadro sem câmera)
	mundo.visible = true
	for b in bonecos:
		b["no"].visible = true
	bola3d.visible = true
	camera.make_current()
	ui.visible = true
	l.queue_free()
	Engine.time_scale = 1.0
	await get_tree().process_frame
	Audio.torcida(0.5)
	return r


func _disputa_penaltis() -> Dictionary:
	_narrar("Empate! A decisão vai para os PÊNALTIS.", "placar", UI.OURO, true)
	await get_tree().create_timer(1.0).timeout
	var pn := 0
	var pa := 0
	var jogou: bool = p["titular"] in ["titular", "reserva"]
	for i in range(1, 11):
		# nós
		var marcou := false
		if i == 3 and jogou:
			_narrar("Sua vez de bater...", "olho", UI.OURO, true)
			await get_tree().create_timer(0.6).timeout
			var ctx := Jogo.contexto_lance(p, {"minuto": 120, "tipo": "penalti"}, gols_nos, gols_adv, false)
			ctx["titulo_intro"] = "DISPUTA DE PÊNALTIS"
			ctx["pressao"] = 1.0
			ctx["segunda_chance"] = ""
			var r: Dictionary = await _rodar_lance("penalti", ctx)
			marcou = r["desfecho"] == "gol"
			r["minuto"] = 120
			r["disputa"] = true
		else:
			marcou = _rng.randf() < 0.76
		if marcou:
			pn += 1
		_narrar("%s: %s  (%d x %d)" % [nos["sigla"], "GOL" if marcou else "PERDEU", pn, pa], "bola", UI.VERDE if marcou else UI.VERMELHO)
		await get_tree().create_timer(0.45).timeout
		if _decidido(i, pn, pa, true):
			break
		var adv_marca := _rng.randf() < 0.72
		if adv_marca:
			pa += 1
		_narrar("%s: %s  (%d x %d)" % [adv["sigla"], "GOL" if adv_marca else "PERDEU", pn, pa], "bola", UI.VERMELHO if adv_marca else UI.VERDE)
		await get_tree().create_timer(0.45).timeout
		if _decidido(i, pn, pa, false):
			break
	if pn == pa:
		pn += 1
	return {"nos": pn, "adv": pa}


func _decidido(rodada: int, pn: int, pa: int, so_nos: bool) -> bool:
	if rodada <= 5:
		var restam_nos := 5 - rodada
		var restam_adv := 5 - rodada + (1 if so_nos else 0)
		return pn > pa + restam_adv or pa > pn + restam_nos
	return not so_nos and pn != pa


# ---------------------------------------------------------------- relatório

## "O que os jornais falaram de você:" (manchetes ligadas às suas decisões).
func _secao_jornais(lista: Array) -> Control:
	var sec := Componentes.secao("O que os jornais falaram de você:", "jornal", UI.OURO)
	for i in lista.size():
		var mch: Dictionary = lista[i]
		var bom: bool = mch.get("bom", true)
		var card := UI.cartao_borda(Color("f4efe2"), UI.OURO if bom else Color("8a8172"), 18, 16)
		var cl := UI.vbox(6)
		card.add_child(cl)
		var topo := UI.hbox(8)
		topo.add_child(UI.icone("jornal" if not String(mch["veiculo"]).begins_with("@") else "celular", 22, Color("5a5040")))
		topo.add_child(UI.rotulo(String(mch["veiculo"]).to_upper(), 18, Color("5a5040"), "titulo"))
		cl.add_child(topo)
		var tit := UI.paragrafo(mch["titulo"], 27 if i == 0 else 24, Color("15120c"))
		tit.add_theme_font_override("font", UI.fonte("titulo"))
		cl.add_child(tit)
		sec[1].add_child(card)
		card.modulate.a = 0.0
		var tw := card.create_tween()
		tw.tween_interval(0.35 + i * 0.35)
		tw.tween_property(card, "modulate:a", 1.0, 0.3)
	return sec[0]


func _cartao_fas(r: Dictionary) -> Control:
	var ganho := int(r.get("fas_ganho", 0))
	var c := UI.cartao(UI.CARTAO, 20, 16)
	var l := UI.hbox(14)
	c.add_child(l)
	l.add_child(UI.icone("grupo", 44, UI.AZUL))
	var col := UI.vbox(2)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.rotulo("FÃS", 20, UI.TEXTO2, "titulo"))
	col.add_child(UI.rotulo("%s no total" % UI.formatar_numero(float(r.get("fas_total", Jogo.fas()))), 24, UI.TEXTO, "forte"))
	if int(r.get("virais", 0)) > 0:
		col.add_child(UI.rotulo("Seu lance viralizou nas redes!", 19, UI.OURO))
	l.add_child(col)
	var txt := ("+%s" % UI.formatar_numero(ganho)) if ganho >= 0 else UI.formatar_numero(ganho)
	l.add_child(UI.titulo(txt, 40, UI.VERDE if ganho >= 0 else UI.VERMELHO))
	return c


func _relatorio(r: Dictionary) -> void:
	ui.visible = false
	var fundo := ColorRect.new()
	fundo.color = Color(UI.FUNDO, 0.0)
	add_child(fundo)
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	create_tween().tween_property(fundo, "color:a", 0.93, 0.3)
	var m := UI.margem(28, 40 + Tela.margem_topo(), 28, 30)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var col := UI.vbox(16)
	m.add_child(col)
	var venceu: bool = r["venceu"]
	var empate: bool = r["empate"]
	var titulo := "VITÓRIA" if venceu else ("EMPATE" if empate else "DERROTA")
	var cor := UI.VERDE if venceu else (UI.OURO if empate else UI.VERMELHO)
	var t := UI.titulo(titulo, 72, cor)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(t)
	var placar_txt := "%s %d x %d %s" % [nos["sigla"], r["gols_nos"], r["gols_adv"], adv["sigla"]]
	if r.get("penaltis") != null:
		placar_txt += "  (pên. %d x %d)" % [r["penaltis"]["nos"], r["penaltis"]["adv"]]
	var pl := UI.rotulo(placar_txt, 30, UI.TEXTO, "titulo")
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(pl)
	if r.get("titulo", "") != "":
		var tc := UI.cartao_borda(Color("2a1f05"), UI.OURO, 22, 20)
		var tl := UI.hbox(14)
		tl.alignment = BoxContainer.ALIGNMENT_CENTER
		tc.add_child(tl)
		tl.add_child(UI.icone("trofeu", 56, UI.OURO))
		tl.add_child(UI.titulo("CAMPEÃO!\n" + r["titulo"], 34, UI.OURO))
		col.add_child(tc)
		Audio.tocar("gol")
		mundo.festa_torcida(10)
	var rol := UI.rolagem()
	col.add_child(rol)
	var conteudo := UI.vbox(16)
	conteudo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(conteudo)
	if r["jogou"]:
		var nota_c := UI.cartao(UI.CARTAO, 24, 22)
		var nl := UI.hbox(18)
		nota_c.add_child(nl)
		var nota := float(r["nota"])
		var nn := UI.titulo("%.1f" % nota, 96, UI.cor_nota(nota))
		nl.add_child(nn)
		var nd := UI.vbox(6)
		nd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nd.add_child(UI.rotulo("SUA NOTA", 22, UI.TEXTO2, "titulo"))
		nd.add_child(Componentes.estrelas(int(round((nota - 3.0) / 7.0 * 5.0)), 5, 30))
		nd.add_child(UI.rotulo("%d gol%s • %d assistência%s" % [r["gols"], "s" if r["gols"] != 1 else "", r["assist"], "s" if r["assist"] != 1 else ""], 24, UI.TEXTO, "forte"))
		nl.add_child(nd)
		conteudo.add_child(nota_c)
		nn.pivot_offset = Vector2(60, 50)
		nn.scale = Vector2(0.4, 0.4)
		create_tween().tween_property(nn, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		conteudo.add_child(UI.paragrafo("Você não entrou em campo nesta partida.", 24))
	if not r.get("manchetes", []).is_empty():
		conteudo.add_child(_secao_jornais(r["manchetes"]))
	if int(r.get("fas_ganho", 0)) != 0 or r.has("fas_total"):
		conteudo.add_child(_cartao_fas(r))
	if not r.get("lances", []).is_empty():
		var sec_l := Componentes.secao("Seus lances", "olho")
		for l in r["lances"]:
			var d: String = l["desfecho"]
			var delta := Jogo.delta_nota(l)
			var bom := Situacoes.bom(d)
			var linha := UI.hbox(10)
			var mn := UI.rotulo("%d'" % int(l.get("minuto", 0)), 22, UI.TEXTO3, "titulo")
			mn.custom_minimum_size.x = 50
			linha.add_child(mn)
			linha.add_child(UI.icone("olho" if l.get("opcao_descoberta", false) else ("bola" if bom else "fechar"), 26, UI.VERDE if bom else UI.TEXTO2))
			var nome_d := {"gol": "Gol", "assistencia": "Assistência", "defesa": "Defesa do goleiro", "fora": "Pra fora", "trave": "Trave",
				"perdeu": "Perdeu a bola", "interceptado": "Interceptado", "passou_defesa": "Quase",
				"desarme": "Desarme", "bloqueio": "Chute travado", "afastou": "Afastou o perigo", "falta_dura": "Cartão amarelo",
				"salvou_goleiro": "Driblado (o goleiro salvou)", "gol_sofrido": "Gol sofrido",
				"impedimento": "Deixou impedido", "falta_tatica": "Falta tática"}.get(d, d) as String
			var tx := UI.paragrafo("%s • %s" % [l.get("opcao_texto", ""), nome_d], 21, UI.TEXTO if bom else UI.TEXTO2)
			tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			linha.add_child(tx)
			linha.add_child(UI.rotulo(("+%.1f" % delta) if delta >= 0 else ("%.1f" % delta), 22, UI.VERDE if delta >= 0 else UI.VERMELHO, "titulo"))
			sec_l[1].add_child(linha)
		if r["lances"].any(func(x) -> bool: return x.get("opcao_descoberta", false)):
			sec_l[1].add_child(UI.paragrafo("Jogadas com o olho foram descobertas lendo o jogo (+0,15 na nota).", 19, UI.TEXTO3))
		conteudo.add_child(sec_l[0])
	if not r.get("memorias", []).is_empty():
		var sec := Componentes.secao("Nova memória no álbum", "album")
		for mid in r["memorias"]:
			var md: Dictionary = Dados.MEMORIAS.get(mid, {})
			var card := UI.cartao_borda(Color("2a1f05"), UI.OURO, 16, 14)
			var cl := UI.vbox(2)
			card.add_child(cl)
			cl.add_child(UI.rotulo(md.get("titulo", mid), 26, UI.OURO, "titulo"))
			cl.add_child(UI.paragrafo(md.get("desc", ""), 21))
			sec[1].add_child(card)
		conteudo.add_child(sec[0])
		Audio.tocar("sucesso")
	if not r.get("ganhos", {}).is_empty():
		var sec := Componentes.secao("Evolução", "sobe", UI.VERDE)
		for a in r["ganhos"]:
			if float(r["ganhos"][a]) >= 0.05:
				sec[1].add_child(UI.linha_status(Dados.ICONES_ATRIBUTOS[a], Dados.NOMES_ATRIBUTOS[a] + "  +%.1f" % r["ganhos"][a],
					Jogo.atributo(a), UI.VERDE, str(int(Jogo.atributo(a)))))
		conteudo.add_child(sec[0])
	var extras: Array = r.get("efeitos", []).duplicate()
	if float(r.get("salario", 0)) > 0:
		extras.append("+%s de salário" % UI.formatar_dinheiro(r["salario"]))
	if r.has("lesao"):
		extras.append("LESÃO: %d semana%s fora" % [r["lesao"], "s" if r["lesao"] > 1 else ""])
	if not extras.is_empty():
		var sec := Componentes.secao("Consequências", "info", UI.AZUL)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 10)
		flow.add_theme_constant_override("v_separation", 10)
		for e in extras:
			var negativo: bool = str(e).begins_with("-") or str(e).begins_with("LESÃO")
			flow.add_child(UI.chip("desce" if negativo else "sobe", str(e), UI.VERMELHO if negativo else UI.VERDE, Color(1, 1, 1, 0.06)))
		sec[1].add_child(flow)
		conteudo.add_child(sec[0])
	var cont := UI.botao("Continuar", "seta_dir", "primario", 96)
	col.add_child(cont)
	await cont.pressed
	if p["tipo"] == "prologo":
		Tela.ir("res://cenas/olheiros.tscn")
		return
	await Anuncios.talvez_intersticial("pos_partida")
	Jogo.partida_atual = {}
	Tela.ir("res://cenas/temporada.tscn" if Jogo.temporada_acabou() else "res://cenas/hub.tscn")
