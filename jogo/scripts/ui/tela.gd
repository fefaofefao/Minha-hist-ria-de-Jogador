extends CanvasLayer
## Autoload "Tela": troca de cenas com fade, avisos (toasts), diálogos modais,
## popups de recompensa e área segura (notch) do celular.

signal dialogo_respondido(indice: int)

var _cortina: ColorRect
var _camada_avisos: Control
var _trocando := false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.theme = UI.criar_tema()
	_cortina = ColorRect.new()
	_cortina.color = Color(UI.FUNDO, 0.0)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_cortina)
	_camada_avisos = Control.new()
	_camada_avisos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camada_avisos.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_camada_avisos)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_voltar()


## Botão/gesto "voltar" do Android: nunca fecha o app sem perguntar.
func _voltar() -> void:
	if _trocando or _camada_avisos.get_child_count() > 0:
		return
	var cena := get_tree().current_scene
	if cena == null:
		return
	var caminho := cena.scene_file_path
	match caminho:
		"res://cenas/menu.tscn":
			var r := await dialogo("Sair do jogo?", "Seu progresso está salvo.", [["Sair", "fechar", "perigo"], ["Continuar jogando", "play", "primario"]], "info")
			if r == 0:
				get_tree().quit()
		"res://cenas/partida.tscn", "res://cenas/criacao.tscn", "res://cenas/olheiros.tscn", "res://cenas/temporada.tscn":
			pass  # telas com fluxo próprio: o voltar não interrompe
		"res://cenas/hub.tscn", "res://cenas/config.tscn", "res://cenas/legado.tscn", "res://cenas/desafio.tscn":
			ir("res://cenas/menu.tscn")
		_:
			ir("res://cenas/hub.tscn" if Jogo.tem_carreira() and Jogo.carreira.get("fase", "") in ["base", "pro"] else "res://cenas/menu.tscn")


func ir(cena: String) -> void:
	if _trocando:
		return
	_trocando = true
	_cortina.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_cortina, "color:a", 1.0, 0.22)
	await tw.finished
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(cena)
	await get_tree().process_frame
	await get_tree().process_frame
	var tw2 := create_tween()
	tw2.tween_property(_cortina, "color:a", 0.0, 0.28)
	await tw2.finished
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_trocando = false


## Margem superior extra para câmeras/notch (em pixels da viewport).
func margem_topo() -> int:
	if not OS.has_feature("mobile"):
		return 0
	var seguro := DisplayServer.get_display_safe_area()
	var tela := DisplayServer.screen_get_size()
	if tela.y <= 0:
		return 0
	var escala := get_viewport().get_visible_rect().size.y / float(tela.y)
	return int(seguro.position.y * escala)


func vibrar(ms: int) -> void:
	if OS.has_feature("mobile") and Jogo.perfil.get("config", {}).get("vibracao", true):
		Input.vibrate_handheld(ms)


# ---------------------------------------------------------------- avisos

func aviso(texto: String, nome_icone := "info", cor := UI.OURO) -> void:
	var caixa := UI.cartao_borda(Color(UI.CARTAO2, 0.97), cor, 20, 18)
	caixa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var linha := UI.hbox(12)
	caixa.add_child(linha)
	linha.add_child(UI.icone(nome_icone, 34, cor))
	var l := UI.paragrafo(texto, 24, UI.TEXTO)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	linha.add_child(l)
	_camada_avisos.add_child(caixa)
	caixa.set_anchors_preset(Control.PRESET_TOP_WIDE)
	caixa.offset_left = 28
	caixa.offset_right = -28
	caixa.offset_top = -160
	caixa.offset_bottom = -60
	var y := 30.0 + margem_topo()
	var tw := create_tween()
	tw.tween_property(caixa, "offset_top", y, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(caixa, "offset_bottom", y + 100, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.6)
	tw.tween_property(caixa, "modulate:a", 0.0, 0.3)
	tw.tween_callback(caixa.queue_free)


## Diálogo modal. Retorna o índice do botão escolhido (await Tela.dialogo(...)).
## botoes: Array de [texto, icone, estilo].
func dialogo(titulo: String, texto: String, botoes: Array, nome_icone := "", cor_icone := UI.OURO) -> int:
	var fundo := ColorRect.new()
	fundo.color = Color(0, 0, 0, 0.0)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_camada_avisos.add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(centro)
	var painel := UI.cartao_borda(UI.CARTAO, Color(cor_icone, 0.6), 28, 32)
	painel.custom_minimum_size = Vector2(620, 0)
	centro.add_child(painel)
	var col := UI.vbox(18)
	painel.add_child(col)
	if nome_icone != "":
		col.add_child(UI.icone(nome_icone, 72, cor_icone))
	var t := UI.titulo(titulo, 40)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(t)
	if texto != "":
		var p := UI.paragrafo(texto, 25)
		p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(p)
	col.add_child(UI.espaco(6))
	var escolhido := [-1]
	for i in botoes.size():
		var d: Array = botoes[i]
		var b := UI.botao(d[0], d[1] if d.size() > 1 else "", d[2] if d.size() > 2 else "normal", 80)
		b.pressed.connect(func() -> void:
			escolhido[0] = i
			dialogo_respondido.emit(i))
		col.add_child(b)
	painel.pivot_offset = Vector2(310, 200)
	painel.scale = Vector2(0.9, 0.9)
	painel.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(fundo, "color:a", 0.72, 0.2)
	tw.tween_property(painel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(painel, "modulate:a", 1.0, 0.2)
	while escolhido[0] < 0:
		await dialogo_respondido
	fundo.queue_free()
	return escolhido[0]


## Popup de recompensa com contagem animada.
func recompensa(titulo: String, linhas: Array) -> void:
	Audio.tocar("moeda")
	var textos: Array = []
	for l in linhas:
		textos.append(str(l))
	await dialogo(titulo, "\n".join(textos), [["Show!", "ok", "primario"]], "presente", UI.OURO)
