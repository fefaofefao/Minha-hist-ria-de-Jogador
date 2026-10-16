extends Control
## Menu principal: estádio 3D ao fundo, embaixadinhas, título e ações.

var vitrine: Vitrine3D
var _lbl_oferta: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var tem := Jogo.tem_carreira()
	var visual: Dictionary = Jogo.visual_jogador() if tem else {"pele": 2, "cabelo": 2, "cor_cabelo": 0, "chuteira": Color("ff6d00")}
	var camisa: Color = Jogo.clube(Jogo.carreira["clube"])["cor"] if tem else Color("ffc928")
	var calcao: Color = Jogo.clube(Jogo.carreira["clube"])["calcao"] if tem else Color("1d3fa8")
	vitrine = Vitrine3D.new()
	add_child(vitrine)
	vitrine.construir("estadio", true, visual, camisa, calcao, int(Jogo.carreira.get("jogador", {}).get("numero", 10)))
	vitrine.foco = Vector3(0, 1.0, -26)
	vitrine.raio = 7.5
	vitrine.altura = 1.7
	vitrine.deslocamento_foco = Vector3(0, 0.35, 0)
	Audio.musica(true)
	Audio.torcida(0.35)
	_ui(tem)
	Analytics.evento("abriu_menu", {"tem_carreira": tem})


func _ui(tem: bool) -> void:
	# degradês para legibilidade
	_degrade(true, 520)
	_degrade(false, 760)

	var m := UI.margem(30, 26 + Tela.margem_topo(), 30, 40)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var col := UI.vbox(14)
	m.add_child(col)

	var topo := UI.hbox(10)
	var cfg := UI.botao("", "config", "fantasma", 68)
	cfg.custom_minimum_size = Vector2(68, 68)
	cfg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	cfg.pressed.connect(func() -> void: Tela.ir("res://cenas/config.tscn"))
	topo.add_child(cfg)
	topo.add_child(UI.expansor())
	topo.add_child(Componentes.chip_moedas())
	col.add_child(topo)

	col.add_child(UI.espaco(30))
	var t1 := UI.titulo("MINHA HISTÓRIA", 86, UI.TEXTO)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_constant_override("outline_size", 14)
	t1.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	col.add_child(t1)
	var t2 := UI.titulo("DE JOGADOR", 72, UI.OURO)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_constant_override("outline_size", 14)
	t2.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	col.add_child(t2)
	var sub := UI.rotulo("Do campinho do bairro ao Mundial", 25, UI.TEXTO2, "forte")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(sub)
	UI.aparecer(t1, 0.1)
	UI.aparecer(t2, 0.25)
	UI.aparecer(sub, 0.4)

	col.add_child(UI.expansor())

	var botoes := UI.vbox(14)
	col.add_child(botoes)
	if tem:
		var j: Dictionary = Jogo.carreira["jogador"]
		var cont := UI.botao("Continuar carreira", "play", "primario", 104)
		var sub_c := UI.rotulo("%s • %d anos • %s" % [j["apelido"], j["idade"], Jogo.nome_clube(Jogo.carreira["clube"])], 20, Color("3a2c00"), "forte")
		var colb: HBoxContainer = cont.get_child(0)
		var v := UI.vbox(0)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		var tt: Label = colb.get_node("Texto")
		colb.remove_child(tt)
		v.add_child(tt)
		v.add_child(sub_c)
		colb.add_child(v)
		cont.pressed.connect(_continuar)
		botoes.add_child(cont)
	var nova := UI.botao("Nova carreira" if tem else "Começar minha história", "bola", "normal" if tem else "primario", 92)
	nova.pressed.connect(_nova)
	botoes.add_child(nova)

	var linha := UI.hbox(14)
	var desafio := UI.botao("Lance do Dia", "hoje", "roxo", 88)
	if not Jogo.desafio_disponivel():
		UI.definir_texto_botao(desafio, "Volte amanhã")
		desafio.disabled = true
	var seq := int(Jogo.perfil["desafio"].get("sequencia", 0))
	if seq > 0:
		var fogo := UI.chip("fogo", str(seq), UI.LARANJA, Color(0, 0, 0, 0.4))
		fogo.position = Vector2(8, -18)
		desafio.add_child(fogo)
	desafio.pressed.connect(func() -> void: Tela.ir("res://cenas/desafio.tscn"))
	linha.add_child(desafio)
	var loja := UI.botao("Loja", "loja", "normal", 88)
	loja.pressed.connect(func() -> void: Tela.ir("res://cenas/loja.tscn"))
	linha.add_child(loja)
	botoes.add_child(linha)

	if Jogo.oferta_iniciante_ativa():
		var oferta := UI.cartao_borda(Color("2a1f05"), UI.OURO, 18, 16)
		var lo := UI.hbox(12)
		oferta.add_child(lo)
		lo.add_child(UI.icone("presente", 40, UI.OURO))
		var tx := UI.vbox(0)
		tx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tx.add_child(UI.rotulo("Pacote do Moleque", 24, UI.OURO, "titulo"))
		_lbl_oferta = UI.rotulo("", 20, UI.TEXTO2, "forte")
		tx.add_child(_lbl_oferta)
		lo.add_child(tx)
		var ver := UI.botao("Ver", "", "primario", 64)
		ver.custom_minimum_size = Vector2(120, 64)
		ver.size_flags_horizontal = Control.SIZE_SHRINK_END
		ver.pressed.connect(func() -> void: Tela.ir("res://cenas/loja.tscn"))
		lo.add_child(ver)
		botoes.add_child(oferta)
		_atualizar_oferta()

	if not Jogo.perfil["hall"].is_empty():
		var hall := UI.botao("Hall da Fama (%d)" % Jogo.perfil["hall"].size(), "trofeu", "fantasma", 70)
		hall.pressed.connect(func() -> void: Tela.ir("res://cenas/legado.tscn"))
		botoes.add_child(hall)
	for i in botoes.get_child_count():
		UI.aparecer(botoes.get_child(i), 0.5 + i * 0.08)


func _degrade(topo: bool, altura: int) -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.02, 0.03, 0.07, 0.92) if topo else Color(0.02, 0.03, 0.07, 0.0))
	g.set_color(1, Color(0.02, 0.03, 0.07, 0.0) if topo else Color(0.02, 0.03, 0.07, 0.95))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0)
	tex.fill_to = Vector2(0.5, 1)
	var r := TextureRect.new()
	r.texture = tex
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	r.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if topo else Control.PRESET_BOTTOM_WIDE)
	if topo:
		r.offset_bottom = altura
	else:
		r.offset_top = -altura


func _process(_d: float) -> void:
	if _lbl_oferta and Engine.get_process_frames() % 30 == 0:
		_atualizar_oferta()


func _atualizar_oferta() -> void:
	var resta := int(Jogo.perfil.get("oferta_iniciante_ate", 0)) - int(Time.get_unix_time_from_system())
	if resta <= 0:
		_lbl_oferta.text = "Oferta encerrada"
		return
	_lbl_oferta.text = "Só uma vez • termina em %02d:%02d:%02d" % [resta / 3600, (resta % 3600) / 60, resta % 60]


func _continuar() -> void:
	match Jogo.carreira["fase"]:
		"prologo":
			Tela.ir("res://cenas/partida.tscn")
		_:
			if Jogo.temporada_acabou():
				Tela.ir("res://cenas/temporada.tscn")
			else:
				Tela.ir("res://cenas/hub.tscn")


func _nova() -> void:
	if Jogo.tem_carreira():
		var r := await Tela.dialogo("Nova carreira?", "Sua carreira atual (%s) será perdida. Moedas, compras e o Hall da Fama continuam." % Jogo.carreira["jogador"]["apelido"],
			[["Começar do zero", "reiniciar", "perigo"], ["Cancelar", "fechar", "fantasma"]], "info", UI.VERMELHO)
		if r != 0:
			return
		Jogo.apagar_carreira()
	Jogo.perfil.erase("heranca")
	Tela.ir("res://cenas/criacao.tscn")
