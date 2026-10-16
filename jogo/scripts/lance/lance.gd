class_name Lance
extends Node3D
## Motor do "Momento Decisivo" (mecânica Escolha e Veja).
##
## Fluxo: plano de TV -> entra nos olhos do jogador -> OLHAR AO REDOR (ler o jogo:
## olhar para pontos de interesse revela opções escondidas) -> ESCOLHER ->
## ver a jogada em primeira pessoa -> (gol: escolher a comemoração) ->
## (erro: "E se...?" segunda chance) -> replay na câmera da TV -> sinal terminou.

signal terminou(resultado: Dictionary)
signal _evento_ui(valor)

enum Fase { MONTANDO, INTRO, OLHANDO, EXECUTANDO, ESCOLHA_EXTRA, REPLAY, FIM }

const ALTURA_OLHOS := 1.62
const SENSIBILIDADE := 0.0045
const ANGULO_POI := 0.30
const TEMPO_LEITURA := 0.45

var s: Dictionary
var ctx: Dictionary
var fase := Fase.MONTANDO
var rng := RandomNumberGenerator.new()
var auto := false  # modo de teste automático

var mundo: Mundo3D
var atores := {}  # papel -> Jogador3D
var barreira: Array[Jogador3D] = []
var figurantes: Array[Jogador3D] = []
var prota: Jogador3D
var bola: MeshInstance3D
var cam_pov: Camera3D
var cam_tv: Camera3D

# câmera em primeira pessoa
var yaw := 0.0
var yaw_base := 0.0
var pitch := -0.06
var camera_livre := true
var alvo_olhar := Vector3.ZERO
var seguir_bola := false
var seguir_no: Node3D = null
var base_pov := Basis()
var altura_olhos := ALTURA_OLHOS
var rolagem := 0.0
var balanco := 0.0
var _t_balanco := 0.0

var bola_no_pe := true
var _bola_com: Node3D = null  # adversário que conduz a bola (lances defensivos)
var _intro_seguir := false
# rastro da bola em chutes fortes
var _rastro_im: ImmediateMesh
var _rastro_pts: Array[Vector3] = []
var _bola_antes := Vector3.ZERO
var _camera_lenta := false
var tempo_total := 7.0
var tempo_restante := 7.0
var leitura := {}  # poi id -> segundos olhando
var descobertos: Array[String] = []
var dicas_mostradas: Array[String] = []
var resultado := {}
var opcao_escolhida := {}
var segunda_chance_usada := false
var comemoracao := ""
var _snapshot := {}
var _bpm := 90.0
var _t_coracao := 0.0
var _pulo_replay := false

# UI
var camada: CanvasLayer
var raiz: Control
var vinheta: ColorRect
var mat_vinheta: ShaderMaterial
var flash: ColorRect
var lbl_placar: Label
var lbl_bpm: Label
var barra_tempo: UI.Barra
var lbl_dica: Label
var icone_dica_esq: Label
var icone_dica_dir: Label
var lbl_legenda: Label
var caixa_opcoes: VBoxContainer
var lbl_replay: Label
var btn_pular: Button
var faixa_intro: PanelContainer

const SHADER_VINHETA := """
shader_type canvas_item;
uniform float intensidade = 0.3;
uniform vec4 cor : source_color = vec4(0.0, 0.0, 0.0, 1.0);
void fragment() {
	vec2 uv = UV - vec2(0.5);
	uv.y *= 0.75;
	float d = length(uv) * 1.6;
	COLOR = vec4(cor.rgb, smoothstep(0.42, 1.05, d) * intensidade);
}
"""


# ================================================================ montagem

func _exit_tree() -> void:
	if _camera_lenta:
		Engine.time_scale = 1.0


func iniciar(situacao: Dictionary) -> void:
	s = situacao
	ctx = s["ctx"]
	auto = ctx.get("auto", false)
	rng.seed = int(ctx.get("semente", randi()))
	_montar_mundo()
	_montar_ui()
	tempo_total = s["tempo"]
	await _intro()
	_comecar_leitura()


func _montar_mundo() -> void:
	mundo = Mundo3D.new()
	add_child(mundo)
	mundo.construir(ctx.get("cenario", "estadio"), ctx.get("noite", false), ctx.get("cor_casa", Color("ffc928")),
		ctx.get("cor_fora", Color("c62828")), int(ctx.get("semente_cenario", 3)))
	var cor_casa: Color = ctx.get("cor_casa", Color("ffc928"))
	var calcao_casa: Color = ctx.get("calcao_casa", Color("1d3fa8"))
	var cor_fora: Color = ctx.get("cor_fora", Color("c62828"))
	var calcao_fora: Color = ctx.get("calcao_fora", Color.WHITE)
	var numeros := [7, 9, 11, 8, 5, 4, 3, 2, 6, 10]
	var n := 0
	for j in s["jogadores"]:
		var a := Jogador3D.new()
		add_child(a)
		var papel: String = j["papel"]
		var visual := {"pele": rng.randi_range(0, 5), "cabelo": rng.randi_range(0, 5), "cor_cabelo": rng.randi_range(0, 3)}
		if papel == "prota":
			a.configurar(cor_casa, calcao_casa, ctx.get("visual", {}), int(ctx.get("numero", 10)), Color.WHITE, ctx.get("estilo_casa", "liso"), ctx.get("cor2_casa", Color.WHITE))
		elif papel == "goleiro":
			var ref := cor_casa if s.get("defensivo", false) else cor_fora
			a.configurar(Color("2bb673") if ref.g < 0.5 else Color("7a3fd1"), Color("111111"), visual, 1, Color("111111"))
		elif j["time"] == "casa":
			a.configurar(cor_casa, calcao_casa, visual, numeros[n % numeros.size()], Color.WHITE, ctx.get("estilo_casa", "liso"), ctx.get("cor2_casa", Color.WHITE))
			n += 1
		else:
			a.configurar(cor_fora, calcao_fora, visual, numeros[(n + 3) % numeros.size()], cor_fora.darkened(0.3), ctx.get("estilo_fora", "liso"), ctx.get("cor2_fora", Color.WHITE))
			n += 1
		a.position = j["pos"]
		a.set_meta("nome", j.get("nome", ""))
		match papel:
			"prota":
				prota = a
				atores["prota"] = a
			"barreira":
				barreira.append(a)
			"figurante":
				figurantes.append(a)
			_:
				atores[papel] = a
	var gol := Vector3(0, 0, -40)
	var foco: Vector3 = s.get("olhar_para", gol)
	_encarar(prota, foco)
	for papel in atores:
		if papel != "prota":
			_encarar(atores[papel], prota.position)
	for papel in ["atacante_adv", "apoio_adv"]:
		if atores.has(papel):
			_encarar(atores[papel], foco)
	for b in barreira:
		_encarar(b, prota.position)
		b.fazer_pose("goleiro")
	for f in figurantes:
		_encarar(f, Vector3(0, 0, -20))
	if atores.has("goleiro"):
		atores["goleiro"].fazer_pose("goleiro")
	if atores.has("parceiro") and s["tipo"] in ["chance_area", "contra_ataque", "rebote", "escanteio"]:
		_encarar(atores["parceiro"], gol)
	for papel in ["atacante", "ponta"]:
		if atores.has(papel) and s["tipo"] in ["tabela", "rebote", "chute_longe"]:
			_encarar(atores[papel], gol)
	var esfera := SphereMesh.new()
	esfera.radius = 0.11
	esfera.height = 0.22
	esfera.radial_segments = 24
	esfera.rings = 12
	bola = MeshInstance3D.new()
	bola.mesh = esfera
	var mb := ShaderMaterial.new()
	mb.shader = Formas.shader("res://shaders/bola.gdshader")
	bola.material_override = mb
	add_child(bola)
	_posicionar_bola_inicial()
	_bola_antes = bola.position
	_rastro_im = ImmediateMesh.new()
	var rastro := MeshInstance3D.new()
	rastro.mesh = _rastro_im
	rastro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mr := StandardMaterial3D.new()
	mr.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mr.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mr.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mr.cull_mode = BaseMaterial3D.CULL_DISABLED
	mr.vertex_color_use_as_albedo = true
	mr.no_depth_test = false
	rastro.material_override = mr
	add_child(rastro)

	cam_pov = Camera3D.new()
	cam_pov.fov = 74.0
	cam_pov.near = 0.04
	cam_pov.far = 300.0
	add_child(cam_pov)
	cam_tv = Camera3D.new()
	cam_tv.fov = 48.0
	cam_tv.far = 300.0
	add_child(cam_tv)

	var d := foco - prota.position
	yaw_base = atan2(-d.x, -d.z)
	yaw = yaw_base
	_snapshot = _capturar()


## Rastro luminoso atrás da bola quando ela viaja rápido (chutes, cruzamentos).
func _atualizar_rastro(delta: float) -> void:
	var p := bola.position
	var vel := p.distance_to(_bola_antes) / maxf(delta, 0.0001)
	_bola_antes = p
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var olho := cam.global_position
	# só em bola rápida e longe da câmera (perto dela o rastro vira um borrão na tela)
	if not bola_no_pe and vel > 12.0 and p.distance_to(olho) > 3.0:
		_rastro_pts.append(p)
		if _rastro_pts.size() > 12:
			_rastro_pts.pop_front()
	elif not _rastro_pts.is_empty():
		_rastro_pts.pop_front()
	_rastro_im.clear_surfaces()
	if _rastro_pts.size() < 2:
		return
	_rastro_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var n := _rastro_pts.size()
	for i in n:
		var a := _rastro_pts[i]
		var b := _rastro_pts[mini(i + 1, n - 1)] if i < n - 1 else a + (a - _rastro_pts[i - 1])
		var tang := (b - a).normalized()
		var lado := tang.cross((olho - a).normalized())
		# bola vindo na direção da câmera: a fita fica de lado e some
		var visivel := clampf(lado.length() * 2.5 - 0.5, 0.0, 1.0)
		lado = lado.normalized() if lado.length() > 0.001 else Vector3.UP
		var t := float(i) / float(n - 1)
		var largura := 0.09 * t
		var cor := Color(1.0, 0.97, 0.9, 0.35 * t * t * visivel)
		_rastro_im.surface_set_color(cor)
		_rastro_im.surface_add_vertex(a + lado * largura)
		_rastro_im.surface_set_color(cor)
		_rastro_im.surface_add_vertex(a - lado * largura)
	_rastro_im.surface_end()


## Tufos de grama (ou terra, na várzea) saltando no momento do chute.
func _poeira_chute(ponto: Vector3, forca := 1.0) -> void:
	var p := CPUParticles3D.new()
	var cubo := BoxMesh.new()
	cubo.size = Vector3(0.035, 0.012, 0.035)
	var terra: bool = ctx.get("cenario", "estadio") == "varzea"
	cubo.material = Formas.mat(Color("7a4a2a") if terra else Color("2f6b25"), 0.95, 0.0)
	p.mesh = cubo
	p.amount = int(14 * forca) + 4
	p.one_shot = true
	p.explosiveness = 0.92
	p.lifetime = 0.9
	p.direction = Vector3(0, 1, 0)
	p.spread = 55.0
	p.initial_velocity_min = 1.4 * forca
	p.initial_velocity_max = 3.4 * forca
	p.angular_velocity_min = -720.0
	p.angular_velocity_max = 720.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	p.gravity = Vector3(0, -9.8, 0)
	p.position = Vector3(ponto.x, 0.03, ponto.z)
	add_child(p)
	p.emitting = true
	if terra:
		# nuvem de poeira subindo do chão de terra
		var nuvem := CPUParticles3D.new()
		var q := QuadMesh.new()
		q.size = Vector2(0.5, 0.5)
		var mq := StandardMaterial3D.new()
		mq.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mq.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mq.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mq.vertex_color_use_as_albedo = true
		q.material = mq
		nuvem.mesh = q
		nuvem.amount = 8
		nuvem.one_shot = true
		nuvem.explosiveness = 0.85
		nuvem.lifetime = 1.4
		nuvem.direction = Vector3(0, 1, 0)
		nuvem.spread = 70.0
		nuvem.initial_velocity_min = 0.3
		nuvem.initial_velocity_max = 0.9
		nuvem.gravity = Vector3(0, 0.15, 0)
		nuvem.damping_min = 0.6
		nuvem.damping_max = 1.2
		nuvem.scale_amount_min = 0.6
		nuvem.scale_amount_max = 1.6
		var grad := Gradient.new()
		grad.set_color(0, Color(0.72, 0.5, 0.33, 0.45))
		grad.set_color(1, Color(0.72, 0.5, 0.33, 0.0))
		nuvem.color_ramp = grad
		nuvem.position = p.position + Vector3(0, 0.1, 0)
		add_child(nuvem)
		nuvem.emitting = true
		get_tree().create_timer(2.0).timeout.connect(nuvem.queue_free)
	get_tree().create_timer(1.6).timeout.connect(p.queue_free)


func _posicionar_bola_inicial() -> void:
	match s.get("bola", "pe"):
		"ar":
			bola_no_pe = false
			var origem: Vector3 = s["origem_bola"]
			var cab := prota.position + Vector3(0, 1.9, 0)
			var t := 0.62
			bola.position = origem.lerp(cab, t) + Vector3(0, 6.0 * 4.0 * t * (1.0 - t), 0)
		"adv":
			bola_no_pe = false
			_bola_com = atores.get("atacante_adv")
			bola.position = _pe_do(_bola_com)
		"rebote":
			bola_no_pe = false
			bola.position = _pe_do(atores["atacante"])
		_:
			bola_no_pe = s.get("bola", "pe") == "pe"
			bola.position = _pe_do(prota)


func _pe_do(a: Node3D) -> Vector3:
	return a.position + (-a.global_transform.basis.z).normalized() * 0.75 + Vector3(0, 0.11, 0)


func _capturar() -> Dictionary:
	var snap := {}
	for papel in atores:
		var a: Node3D = atores[papel]
		snap[papel] = [a.position, a.rotation]
	var bs := []
	for b in barreira:
		bs.append([b.position, b.rotation])
	snap["_barreira"] = bs
	snap["_bola"] = bola.position
	snap["_bola_no_pe"] = bola_no_pe
	snap["_bola_com"] = _bola_com
	return snap


func _restaurar(snap: Dictionary) -> void:
	for papel in atores:
		if snap.has(papel):
			atores[papel].position = snap[papel][0]
			atores[papel].rotation = snap[papel][1]
			atores[papel].fazer_pose("goleiro" if papel == "goleiro" else "")
	for i in barreira.size():
		barreira[i].position = snap["_barreira"][i][0]
		barreira[i].rotation = snap["_barreira"][i][1]
	bola.position = snap["_bola"]
	bola_no_pe = snap["_bola_no_pe"]
	_bola_com = snap.get("_bola_com")
	seguir_bola = false
	seguir_no = null
	altura_olhos = ALTURA_OLHOS
	rolagem = 0.0
	balanco = 0.0


# ================================================================ UI

func _montar_ui() -> void:
	camada = CanvasLayer.new()
	add_child(camada)
	raiz = Control.new()
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	camada.add_child(raiz)

	vinheta = ColorRect.new()
	var sh := Shader.new()
	sh.code = SHADER_VINHETA
	mat_vinheta = ShaderMaterial.new()
	mat_vinheta.shader = sh
	vinheta.material = mat_vinheta
	vinheta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(vinheta)
	vinheta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# degradê inferior para legibilidade das opções
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0.02, 0.03, 0.06, 0.82))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	var sombra := TextureRect.new()
	sombra.texture = tex
	sombra.stretch_mode = TextureRect.STRETCH_SCALE
	sombra.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(sombra)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	sombra.offset_top = -620

	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var topo := UI.margem(24, 22 + Tela.margem_topo(), 24, 0)
	topo.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	raiz.add_child(topo)
	var col := UI.vbox(12)
	topo.add_child(col)
	var linha := UI.hbox(10)
	col.add_child(linha)
	var placar := UI.cartao(Color(0.03, 0.05, 0.1, 0.78), 14, 12)
	lbl_placar = UI.rotulo(_texto_placar(), 26, UI.TEXTO, "titulo")
	placar.add_child(lbl_placar)
	linha.add_child(placar)
	linha.add_child(UI.expansor())
	var cardio := UI.cartao(Color(0.03, 0.05, 0.1, 0.78), 14, 12)
	var lc := UI.hbox(6)
	cardio.add_child(lc)
	lc.add_child(UI.icone("coracao", 26, UI.VERMELHO))
	lbl_bpm = UI.rotulo("90", 26, UI.TEXTO, "titulo")
	lc.add_child(lbl_bpm)
	lc.add_child(UI.rotulo("bpm", 18, UI.TEXTO2, "forte"))
	linha.add_child(cardio)
	barra_tempo = UI.barra(1.0, UI.OURO, 10)
	barra_tempo.visible = false
	col.add_child(barra_tempo)
	var linha_dica := UI.hbox(8)
	linha_dica.alignment = BoxContainer.ALIGNMENT_CENTER
	icone_dica_esq = UI.icone("seta_esq", 40, UI.OURO)
	icone_dica_dir = UI.icone("seta_dir", 40, UI.OURO)
	lbl_dica = UI.paragrafo("", 25, UI.OURO)
	lbl_dica.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_dica.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_dica.add_theme_constant_override("outline_size", 8)
	lbl_dica.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	linha_dica.add_child(icone_dica_esq)
	linha_dica.add_child(lbl_dica)
	linha_dica.add_child(icone_dica_dir)
	col.add_child(linha_dica)
	_dica("", 0)

	var baixo := UI.margem(28, 0, 28, 34)
	baixo.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	baixo.grow_vertical = Control.GROW_DIRECTION_BEGIN
	raiz.add_child(baixo)
	var colb := UI.vbox(14)
	baixo.add_child(colb)
	lbl_legenda = UI.paragrafo("", 30, UI.TEXTO)
	lbl_legenda.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_legenda.add_theme_font_override("font", UI.fonte("forte"))
	lbl_legenda.add_theme_constant_override("outline_size", 10)
	lbl_legenda.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	colb.add_child(lbl_legenda)
	caixa_opcoes = UI.vbox(12)
	colb.add_child(caixa_opcoes)

	lbl_replay = UI.rotulo("REPLAY", 30, UI.VERMELHO, "display")
	lbl_replay.visible = false
	raiz.add_child(lbl_replay)
	lbl_replay.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	lbl_replay.offset_left = -200
	lbl_replay.offset_right = -28
	lbl_replay.offset_top = 110 + Tela.margem_topo()
	lbl_replay.offset_bottom = 150 + Tela.margem_topo()
	lbl_replay.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	btn_pular = UI.botao("Pular", "seta_dir", "fantasma", 70)
	btn_pular.visible = false
	btn_pular.size_flags_horizontal = Control.SIZE_SHRINK_END
	btn_pular.custom_minimum_size = Vector2(180, 70)
	btn_pular.pressed.connect(func() -> void:
		_pulo_replay = true
		Engine.time_scale = 6.0)
	colb.add_child(btn_pular)


func _texto_placar() -> String:
	return "%s %d x %d %s   %d'" % [ctx.get("sigla_casa", "VIL"), int(ctx.get("gols_casa", 0)),
		int(ctx.get("gols_fora", 0)), ctx.get("sigla_fora", "JAR"), int(ctx.get("minuto", 88))]


func _falar(texto: String) -> void:
	lbl_legenda.text = texto
	lbl_legenda.modulate.a = 0.0
	create_tween().tween_property(lbl_legenda, "modulate:a", 1.0, 0.15)


func _dica(texto: String, direcao: int) -> void:
	lbl_dica.text = texto
	icone_dica_esq.modulate.a = 1.0 if direcao < 0 else 0.0
	icone_dica_dir.modulate.a = 1.0 if direcao > 0 else 0.0


func _flash(forca: float, cor := Color.WHITE) -> void:
	flash.color = Color(cor, forca)
	create_tween().tween_property(flash, "color:a", 0.0, 0.5)


func _limpar_opcoes() -> void:
	for c in caixa_opcoes.get_children():
		c.queue_free()


func _botao_opcao(op: Dictionary) -> Button:
	var nova: bool = op.get("descoberta", false) or op.get("por_talento", false)
	var b := UI.botao("", "", "primario" if nova else "normal", 92)
	var linha: HBoxContainer = b.get_child(0)
	linha.alignment = BoxContainer.ALIGNMENT_BEGIN
	linha.add_child(UI.espaco(4))
	var ic := "olho" if op.get("descoberta", false) else ("brilho" if op.get("por_talento", false) else _icone_acao(op["acao"]))
	var cor_txt := Color("1a1300") if nova else UI.TEXTO
	linha.add_child(UI.icone(ic, 34, cor_txt))
	var t := UI.rotulo(op["texto"], 28, cor_txt, "forte")
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.clip_text = true
	linha.add_child(t)
	if float(ctx.get("atributos", {}).get("visao", 50.0)) >= 55.0:
		var sens := Situacoes.sensacao(op["chance"])
		var chip := UI.cartao(Color(0, 0, 0, 0.3), 12, 8)
		var l := UI.rotulo(sens[0], 20, sens[1] if not nova else Color("1a1300"), "forte")
		chip.add_child(l)
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		linha.add_child(chip)
	linha.add_child(UI.espaco(4))
	b.pressed.connect(_escolher.bind(op, false))
	return b


func _icone_acao(acao: String) -> String:
	match acao:
		"passe", "lancamento", "ajeitar", "calcanhar", "tabela":
			return "troca"
		"drible", "arrancada", "caneta", "conduzir", "drible_goleiro":
			return "correr"
		"carrinho", "bote", "conter", "antecipar", "afastar_cabeca", "chutao", "sair_jogando", "deixar_goleiro":
			return "escudo"
		_:
			return "bola"


# ================================================================ intro e leitura

## Plano de TV: o SEU jogador aparece inteiro chegando para a jogada. Só no corte
## para os olhos dele o corpo some (a câmera nunca atravessa o modelo).
func _intro() -> void:
	fase = Fase.INTRO
	Audio.torcida(0.55 + float(ctx.get("pressao", 0.3)) * 0.4)
	prota.mostrar_corpo_superior = true
	var frente := (-prota.global_transform.basis.z).normalized()
	var lado_v := frente.cross(Vector3.UP).normalized()
	var destino := prota.position
	var tipo_bola: String = s.get("bola", "pe")
	# chega correndo (com a bola, ou atrás do atacante nos lances de defesa)
	if tipo_bola in ["pe", "adv"] and not (s["tipo"] in ["falta", "penalti"]):
		var recuo := frente * 4.0
		prota.position = destino - recuo
		_mover(prota, destino, 1.3)
		if _bola_com:
			var alvo_adv := _bola_com.position
			_bola_com.position = alvo_adv - recuo
			_mover(_bola_com, alvo_adv, 1.3)
	var plano := rng.randi() % 3
	var cam_pos := destino - frente * 7.5 + Vector3(0, 3.4, 0) + lado_v * 1.5
	match plano:
		1:  # lateral, na altura do jogador
			cam_pos = destino + lado_v * (6.0 if rng.randf() < 0.5 else -6.0) - frente * 1.5 + Vector3(0, 1.7, 0)
		2:  # de frente, ele vindo na direção da câmera
			cam_pos = destino + frente * 6.5 + lado_v * 2.0 + Vector3(0, 1.9, 0)
	cam_tv.global_transform = Transform3D(Basis(), cam_pos).looking_at(prota.position + Vector3(0, 1.1, 0), Vector3.UP)
	cam_tv.make_current()
	_intro_seguir = true
	_falar(s.get("texto", ""))
	if ctx.has("titulo_intro"):
		_dica(ctx["titulo_intro"], 0)
	await _espera(1.6 if not auto else 0.3)
	if tipo_bola == "rebote":
		await _pre_rebote()
	_intro_seguir = false
	# aproxima por trás do ombro, sem entrar no corpo
	var olho := _olho()
	var ombro := olho - frente * 1.5 + lado_v * 0.45 + Vector3(0, 0.25, 0)
	var foco := olho + Basis.from_euler(Vector3(pitch, yaw, 0)) * Vector3(0, 0, -10)
	var tw := create_tween()
	tw.tween_property(cam_tv, "global_transform", Transform3D(Basis(), ombro).looking_at(foco, Vector3.UP), 0.7 if not auto else 0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	# piscada rápida: entra nos olhos do jogador
	var escurece := create_tween()
	escurece.tween_property(flash, "color", Color(0, 0, 0, 0.85), 0.1)
	await escurece.finished
	base_pov = Basis.from_euler(Vector3(pitch, yaw, 0))
	prota.mostrar_corpo_superior = false  # em primeira pessoa: só pernas e chuteiras
	cam_pov.make_current()
	_atualizar_pov(0.0)
	create_tween().tween_property(flash, "color:a", 0.0, 0.18)


## Rebote: o companheiro chuta, o goleiro espalma e a bola sobra para você.
func _pre_rebote() -> void:
	var at: Jogador3D = atores["atacante"]
	var g: Jogador3D = atores["goleiro"]
	_encarar(at, Vector3(0, 0, -40))
	bola.position = _pe_do(at)
	at.fazer_pose("chute")
	await _espera(0.16)
	_tocar_chute(0.9)
	var lado_g := signf(at.position.x - g.position.x)
	if lado_g == 0.0:
		lado_g = 1.0
	_mergulho(g, g.position + Vector3(lado_g * 0.9, 0.3, 0), 0.0, 0.35)
	await _bola_para(g.position + Vector3(lado_g * 0.8, 0.7, 0.5), 0.3, 0.38)
	Audio.tocar("uhh", 0.7)
	await _bola_para(_pe_do(prota), 0.8, 0.45)
	bola_no_pe = true


func _comecar_leitura() -> void:
	fase = Fase.OLHANDO
	camera_livre = true
	tempo_restante = tempo_total
	leitura.clear()
	dicas_mostradas.clear()
	barra_tempo.visible = true
	_dica("", 0)
	_reconstruir_opcoes()
	if ctx.get("tutorial", false) and not segunda_chance_usada:
		_falar("Arraste o dedo para OLHAR AO REDOR. Ler o jogo revela novas jogadas.")
	else:
		_falar("Leia o jogo e decida!")
	_agendar_dicas()
	if auto:
		_auto_jogar()


func _reconstruir_opcoes() -> void:
	_limpar_opcoes()
	for op in s["opcoes"]:
		if not op["oculta"]:
			caixa_opcoes.add_child(_botao_opcao(op))


func _agendar_dicas() -> void:
	var atraso := 1.2
	for poi in s["pois"]:
		if poi["id"] in descobertos:
			continue
		var p: Dictionary = poi
		get_tree().create_timer(atraso, false).timeout.connect(func() -> void:
			if fase == Fase.OLHANDO and not (p["id"] in descobertos):
				dicas_mostradas.append(p["id"])
				_dica(p["dica"], _direcao_poi(p)))
		atraso += 1.4


func _direcao_poi(poi: Dictionary) -> int:
	var alvo: Node3D = atores.get(poi["papel"], null)
	if alvo == null:
		return 0
	var diff := angle_difference(yaw, _yaw_para(alvo.position))
	if absf(diff) < 0.35:
		return 0
	return -1 if diff > 0 else 1


func _yaw_para(p: Vector3) -> float:
	var d := p - prota.position
	return atan2(-d.x, -d.z)


func _revelar(poi: Dictionary) -> void:
	descobertos.append(poi["id"])
	Audio.tocar("revela")
	Tela.vibrar(30)
	_dica(poi["aviso"], 0)
	for op in s["opcoes"]:
		if op["id"] == poi["revela"]:
			op["chance"] = clampf(op["chance"] + float(poi.get("bonus", 0.0)), 0.05, 0.92)
			if op["oculta"]:
				op["oculta"] = false
				op["descoberta"] = true
				var b := _botao_opcao(op)
				caixa_opcoes.add_child(b)
				b.modulate = Color(1.5, 1.4, 0.7)
				var tw := create_tween()
				tw.tween_property(b, "modulate", Color.WHITE, 0.6)


func _escolher(op: Dictionary, apressado: bool) -> void:
	if fase != Fase.OLHANDO:
		return
	fase = Fase.EXECUTANDO
	opcao_escolhida = op
	barra_tempo.visible = false
	_limpar_opcoes()
	_dica("", 0)
	_snapshot = _capturar()
	var bonus := 0.05 if segunda_chance_usada else 0.0
	resultado = Situacoes.resolver(s, op, apressado, rng, bonus)
	if op.has("receptor"):
		resultado["receptor"] = op["receptor"]
	if apressado:
		_falar("Você travou! Decisão no desespero...")
		await _espera(0.7)
	camera_livre = false
	await _executar(true)
	var bom := Situacoes.bom(resultado["desfecho"])
	if resultado["desfecho"] == "gol" and _prota_finalizou():
		await _escolher_comemoracao()
	if not bom and not segunda_chance_usada and ctx.get("segunda_chance", "") != "":
		var quer := await _oferecer_segunda_chance()
		if quer:
			segunda_chance_usada = true
			await _rebobinar()
			_comecar_leitura()
			return
	await _replay()
	_finalizar()


func _prota_finalizou() -> bool:
	return not (resultado["acao"] in Situacoes.ACOES_PASSE)


## Quem recebe o passe do protagonista nesta jogada.
func _receptor() -> Jogador3D:
	var papel: String = resultado.get("receptor", "")
	if papel == "":
		papel = "atacante" if resultado["acao"] in ["lancamento", "calcanhar"] else "parceiro"
	return atores.get(papel, atores.get("parceiro", atores.get("atacante")))


# ================================================================ loop

func _process(delta: float) -> void:
	if fase == Fase.MONTANDO or prota == null:
		return
	if bola_no_pe:
		bola.position = _pe_do(prota)
	elif _bola_com != null:
		bola.position = _pe_do(_bola_com)
	if fase == Fase.INTRO and _intro_seguir and cam_tv.current:
		var alvo_cam := prota.position + Vector3(0, 1.1, 0)
		if cam_tv.global_position.distance_to(alvo_cam) > 0.5:
			cam_tv.look_at(alvo_cam, Vector3.UP)
	_atualizar_rastro(delta)
	if seguir_bola:
		alvo_olhar = bola.position
	elif seguir_no != null:
		alvo_olhar = seguir_no.position + Vector3(0, 1.3, 0)

	if fase == Fase.OLHANDO:
		var real := delta / maxf(Engine.time_scale, 0.001) if not auto else delta
		tempo_restante -= real
		barra_tempo.valor = tempo_restante / tempo_total
		barra_tempo.cor = UI.OURO if tempo_restante > 2.5 else UI.VERMELHO
		_atualizar_leitura(real)
		# câmera lenta: adversários se aproximam devagar
		for papel in ["zagueiro", "zagueiro2"]:
			if atores.has(papel) and s["tipo"] != "penalti" and s["tipo"] != "falta":
				var a: Node3D = atores[papel]
				a.position = a.position.move_toward(prota.position, delta * 0.18)
		if s["tipo"] == "desarme":
			# o atacante deles avança devagar e você acompanha
			var at: Node3D = atores["atacante_adv"]
			at.position = at.position.move_toward(Vector3(at.position.x, 0, -40), delta * 0.3)
			prota.position = prota.position.move_toward(Vector3(prota.position.x, 0, -40), delta * 0.28)
		if tempo_restante <= 0.0:
			var primeira := {}
			for op in s["opcoes"]:
				if not op["oculta"]:
					primeira = op
					break
			_escolher(primeira, true)

	_atualizar_coracao(delta)
	if cam_pov.current:
		_atualizar_pov(delta)
	elif fase == Fase.REPLAY:
		var tf := cam_tv.global_transform
		var alvo := bola.global_position.lerp(Vector3(0, 1, -38), 0.15)
		if tf.origin.distance_to(alvo) > 0.5:
			var desejado := tf.looking_at(alvo, Vector3.UP).basis
			tf.basis = tf.basis.slerp(desejado, clampf(delta * 3.5, 0.0, 1.0)).orthonormalized()
			cam_tv.global_transform = tf


func _atualizar_leitura(dt: float) -> void:
	for poi in s["pois"]:
		if poi["id"] in descobertos:
			continue
		var alvo: Node3D = atores.get(poi["papel"], null)
		if alvo == null:
			continue
		var diff := absf(angle_difference(yaw, _yaw_para(alvo.position)))
		if diff < ANGULO_POI:
			leitura[poi["id"]] = float(leitura.get(poi["id"], 0.0)) + dt
			if leitura[poi["id"]] >= TEMPO_LEITURA:
				_revelar(poi)
		elif poi["id"] in dicas_mostradas and lbl_dica.text == poi["dica"]:
			_dica(poi["dica"], _direcao_poi(poi))


func _olho() -> Vector3:
	return prota.position + Vector3(0, altura_olhos, 0)


func _atualizar_pov(delta: float) -> void:
	var olho := _olho()
	if camera_livre:
		base_pov = Basis.from_euler(Vector3(pitch, yaw, 0))
	elif olho.distance_to(alvo_olhar) > 0.3:
		var desejado := Transform3D(Basis(), olho).looking_at(alvo_olhar, Vector3.UP).basis
		base_pov = base_pov.slerp(desejado, clampf(delta * 7.0, 0.0, 1.0)).orthonormalized()
	var bob := Vector3.ZERO
	if balanco > 0.0:
		_t_balanco += delta * 11.0
		bob = Vector3(cos(_t_balanco * 0.5) * 0.035, sin(_t_balanco) * 0.055, 0) * balanco
	cam_pov.global_transform = Transform3D(base_pov * Basis(Vector3(0, 0, 1), rolagem), olho + base_pov * bob)
	# ninguém "atravessa" a câmera: quem chega muito perto some da visão em primeira pessoa
	var pos_cam := cam_pov.global_position
	for papel in atores:
		if papel != "prota":
			var a: Node3D = atores[papel]
			a.visible = (a.position + Vector3(0, 1.2, 0)).distance_to(pos_cam) > 0.95


func _atualizar_coracao(delta: float) -> void:
	var pressao: float = ctx.get("pressao", 0.3)
	var frieza: float = ctx.get("atributos", {}).get("frieza", 50.0)
	var alvo_bpm := 95.0
	var intens := 0.25
	if fase == Fase.OLHANDO:
		var urgencia := 1.0 - tempo_restante / maxf(tempo_total, 0.1)
		alvo_bpm = 120.0 + pressao * 50.0 + urgencia * 25.0 - (frieza - 50.0) * 0.4
		intens = 0.28 + pressao * (1.0 - frieza / 140.0) * 0.32 + urgencia * 0.22
	elif fase == Fase.EXECUTANDO:
		alvo_bpm = 150.0
		intens = 0.3
	_bpm = lerpf(_bpm, alvo_bpm, clampf(delta * 1.5, 0.0, 1.0))
	lbl_bpm.text = str(int(_bpm))
	var periodo := 60.0 / _bpm
	_t_coracao += delta
	var pulso := 0.0
	if _t_coracao >= periodo:
		_t_coracao = 0.0
		if fase == Fase.OLHANDO:
			Audio.tocar("coracao", 0.55)
			Tela.vibrar(14)
	pulso = exp(-_t_coracao / periodo * 6.0)
	mat_vinheta.set_shader_parameter("intensidade", clampf(intens + pulso * 0.12 * (1.0 if fase == Fase.OLHANDO else 0.3), 0.0, 1.0))


func _unhandled_input(evento: InputEvent) -> void:
	if fase != Fase.OLHANDO:
		return
	# No Android o toque também chega como mouse (emulate_mouse_from_touch).
	if evento is InputEventMouseMotion and (evento.button_mask & MOUSE_BUTTON_MASK_LEFT):
		var sens := SENSIBILIDADE * float(Jogo.perfil.get("config", {}).get("sensibilidade", 1.0))
		yaw = clampf(yaw - evento.relative.x * sens, yaw_base - 1.9, yaw_base + 1.9)
		pitch = clampf(pitch - evento.relative.y * sens, -0.8, 0.45)


# ================================================================ execução

func _executar(pov: bool) -> void:
	if not pov:
		_restaurar(_snapshot)
	var acao: String = resultado["acao"]
	var d: String = resultado["desfecho"]
	match acao:
		"chute", "chute_forte", "cobertura":
			await _seq_chute_prota(acao, d)
		"falta_curva", "falta_forte":
			await _seq_falta(acao, d)
		"penalti_esq", "penalti_dir", "cavadinha":
			await _seq_penalti(acao, d)
		"cabeceio", "cabeceio_chao":
			await _seq_cabeceio(acao, d)
		"drible", "arrancada", "caneta":
			await _seq_drible(acao, d)
		"conduzir":
			await _seq_conduzir(d)
		"passe", "lancamento", "ajeitar", "calcanhar":
			await _seq_passe(acao, d)
		"tabela":
			await _seq_tabela(d)
		"bicicleta":
			await _seq_bicicleta(d)
		"drible_goleiro":
			await _seq_drible_goleiro(d)
		"domina_chute", "voleio":
			await _seq_domina(acao, d)
		"carrinho", "bote", "conter", "antecipar":
			await _seq_desarme(acao, d)
		"afastar_cabeca", "chutao", "sair_jogando", "deixar_goleiro":
			await _seq_afastar(acao, d)
	seguir_bola = false
	_bola_com = null
	seguir_no = null
	balanco = 0.0


func _seq_chute_prota(acao: String, d: String) -> void:
	alvo_olhar = Vector3(0, 1.2, -40)
	_falar("Ajeitou...")
	await _espera(0.45)
	alvo_olhar = bola.position
	await _espera(0.25)
	var tipo := "forte" if acao == "chute_forte" else ("cobertura" if acao == "cobertura" else "colocado")
	await _finalizar_bola(prota, tipo, d, resultado["lado"], resultado["alto"])
	await _pos_finalizacao(d, true)


func _seq_falta(acao: String, d: String) -> void:
	alvo_olhar = Vector3(0, 1.5, -40)
	_falar("Respira... ajeita a bola...")
	var atras := prota.position + prota.global_transform.basis.z.normalized() * 2.2
	var frente := prota.position
	prota.position = atras
	bola_no_pe = false
	await _espera(0.6)
	balanco = 0.7
	await _mover(prota, frente, 0.55).finished
	balanco = 0.0
	alvo_olhar = bola.position
	for b in barreira:
		var tw := create_tween()
		tw.tween_property(b, "position:y", 0.55, 0.18)
		tw.tween_property(b, "position:y", 0.0, 0.25)
	var tipo := "curva" if acao == "falta_curva" else "forte"
	if acao == "falta_forte" and d == "fora":
		# bate na barreira
		prota.fazer_pose("chute")
		await _espera(0.16)
		_tocar_chute()
		seguir_bola = true
		var b0: Node3D = barreira[1]
		await _bola_para(b0.position + Vector3(0, 1.4, 0), 0.2, 0.35)
		Audio.tocar("uhh", 0.8)
		_falar("Na barreira!")
		await _bola_para(b0.position + Vector3(rng.randf_range(-6, 6), 0.11, 9.0), 1.6, 0.8)
		await _espera(0.6)
		return
	await _finalizar_bola(prota, tipo, d, resultado["lado"], true)
	await _pos_finalizacao(d, true)


func _seq_penalti(acao: String, d: String) -> void:
	alvo_olhar = Vector3(0, 1.0, -40)
	_falar("O estádio prende a respiração...")
	bola_no_pe = false
	var frente := prota.position
	prota.position = frente + Vector3(0, 0, 2.4)
	await _espera(0.7)
	balanco = 0.6
	await _mover(prota, frente, 0.6).finished
	balanco = 0.0
	var decisao: String = resultado.get("goleiro", "esq")
	var g: Jogador3D = atores["goleiro"]
	var lado_g := -1.0 if decisao == "esq" else (1.0 if decisao == "dir" else 0.0)
	if lado_g != 0.0:
		var tw := create_tween()
		tw.tween_interval(0.12)
		tw.tween_property(g, "position", Vector3(lado_g * 2.3, 0.45, -39.4), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(g, "rotation:z", lado_g * 1.3, 0.45)
	var tipo := "cavadinha" if acao == "cavadinha" else "penalti"
	await _finalizar_bola(prota, tipo, d, resultado["lado"], resultado["alto"], false)
	await _pos_finalizacao(d, true)


func _seq_cabeceio(acao: String, d: String) -> void:
	seguir_bola = true
	var cab := prota.position + Vector3(0, 2.05, -0.15)
	_falar("Sobe pro cabeceio!")
	var tw := create_tween()
	tw.tween_property(self, "altura_olhos", ALTURA_OLHOS + 0.45, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if atores.has("zagueiro"):
		create_tween().tween_property(atores["zagueiro"], "position:y", 0.35, 0.35)
	await _bola_para(cab, 0.5, 0.45)
	_tocar_chute(0.7)
	var tipo := "cabeca" if acao == "cabeceio" else "cabeca_chao"
	await _finalizar_bola(prota, tipo, d, resultado["lado"], acao == "cabeceio", false)
	var desce := create_tween()
	desce.tween_property(self, "altura_olhos", ALTURA_OLHOS, 0.3)
	if atores.has("zagueiro"):
		create_tween().tween_property(atores["zagueiro"], "position:y", 0.0, 0.3)
	await _pos_finalizacao(d, true)


func _seq_drible(acao: String, d: String) -> void:
	var z: Jogador3D = atores["zagueiro"]
	seguir_no = z
	balanco = 1.0
	var frente := Vector3(0, 0, -1)
	_falar("Vai pra cima!")
	var encontro := prota.position + frente * 1.6
	_mover(z, encontro + frente * 1.3, 0.7)
	await _mover(prota, encontro, 0.7).finished
	var lado := 1.0 if prota.position.x < 0 else -1.0
	if d == "perdeu":
		_falar("O zagueiro chegou firme!")
		_mover(z, prota.position + Vector3(lado * 0.9, 0, -0.5), 0.22)
		create_tween().tween_property(z, "rotation:x", -0.9, 0.25)
		await _espera(0.18)
		bola_no_pe = false
		seguir_no = null
		seguir_bola = true
		Tela.vibrar(160)
		_tocar_chute(0.6)
		var queda := create_tween().set_parallel()
		queda.tween_property(self, "rolagem", 0.85 * lado, 0.45)
		queda.tween_property(self, "altura_olhos", 0.45, 0.45)
		await _bola_para(prota.position + Vector3(-lado * 9.0, 0.11, 4.0), 0.5, 0.8)
		Audio.tocar("uhh", 0.8)
		_falar("Perdeu a bola...")
		await _espera(0.9)
		return
	match acao:
		"caneta":
			_falar("CANETA!")
			bola_no_pe = false
			seguir_bola = true
			var atras_z := z.position + frente * 2.2
			_bola_para(atras_z + Vector3(0, 0.11, 0), 0.0, 0.45)
			await _mover(prota, z.position + Vector3(lado * 1.1, 0, 0), 0.35).finished
			create_tween().tween_property(z, "rotation:y", z.rotation.y + PI, 0.4)
			await _mover(prota, atras_z - frente * 0.6, 0.3).finished
			Audio.tocar("gol", 0.35)
			bola_no_pe = true
			seguir_bola = false
		"arrancada":
			_falar("Toca na frente e arranca!")
			bola_no_pe = false
			seguir_bola = true
			var alvo_bola := prota.position + Vector3(lado * 2.5, 0, -7.0)
			_bola_para(alvo_bola + Vector3(0, 0.11, 0), 0.4, 0.6)
			_mover(z, alvo_bola + Vector3(-lado * 1.4, 0, 1.5), 0.85)
			await _mover(prota, alvo_bola + Vector3(0, 0, 0.6), 0.75).finished
			bola_no_pe = true
			seguir_bola = false
			create_tween().tween_property(z, "rotation:x", -1.2, 0.4)
		_:
			_falar("Ginga... e corta!")
			_mover(z, z.position + Vector3(-lado * 1.4, 0, 0), 0.3)
			await _mover(prota, prota.position + Vector3(-lado * 0.8, 0, -0.3), 0.25).finished
			await _mover(prota, prota.position + Vector3(lado * 2.2, 0, -1.8), 0.35).finished
			create_tween().tween_property(z, "rotation:x", -1.35, 0.45)
	_falar("Passou! Cara a cara com o goleiro!")
	alvo_olhar = Vector3(0, 1.0, -40)
	seguir_no = null
	var g: Jogador3D = atores["goleiro"]
	var ponto := Vector3(clampf(prota.position.x * 0.5, -6, 6), 0, -29.0)
	_mover(g, Vector3(ponto.x * 0.3, 0, -36.0), 0.9)
	await _mover(prota, ponto, 0.9).finished
	balanco = 0.0
	alvo_olhar = bola.position
	await _espera(0.15)
	var desf := "gol" if d == "gol" else "defesa"
	await _finalizar_bola(prota, "rasteiro", desf, resultado["lado"], false)
	await _pos_finalizacao(desf, true)


func _seq_conduzir(d: String) -> void:
	balanco = 1.0
	_falar("Conduz em velocidade...")
	alvo_olhar = Vector3(0, 1.0, -40)
	var destino := prota.position + Vector3(0, 0, -10.0)
	for papel in ["zagueiro", "zagueiro2", "zagueiro3"]:
		if atores.has(papel):
			var a: Node3D = atores[papel]
			_mover(a, a.position + Vector3(0, 0, -4.0), 1.3)
	await _mover(prota, destino, 1.3).finished
	balanco = 0.0
	alvo_olhar = bola.position
	await _espera(0.2)
	await _finalizar_bola(prota, "forte", d, resultado["lado"], resultado["alto"])
	await _pos_finalizacao(d, true)


func _seq_passe(acao: String, d: String) -> void:
	var r: Jogador3D = _receptor()
	seguir_no = r
	if not bola_no_pe and acao != "ajeitar":
		# bola vindo pelo alto: primeiro domina
		seguir_bola = true
		await _bola_para(_pe_do(prota), 0.4, 0.45)
		bola_no_pe = true
		seguir_bola = false
	_falar("De calcanhar!" if acao == "calcanhar" else "Levanta a cabeça...")
	await _espera(0.4 if acao != "calcanhar" else 0.15)
	var destino := r.position
	var altura := 0.25
	var dur := 0.9
	match acao:
		"lancamento":
			destino = Vector3(clampf(r.position.x * 0.6, -10, 10), 0, -27.0)
			altura = 4.5
			dur = 1.3
			_mover(r, destino + Vector3(0, 0, 0.5), 1.3)
			for papel in ["zagueiro2", "zagueiro3"]:
				if atores.has(papel):
					_mover(atores[papel], atores[papel].position + Vector3(0, 0, -3.0), 1.3)
		"ajeitar":
			destino = Vector3(r.position.x * 0.3, 0, -29.5) if s["tipo"] != "escanteio" else r.position + Vector3(0, 0, -0.8)
			_mover(r, destino + Vector3(0, 0, 0.6), 0.75)
		_:
			if resultado.get("receptor", "") == "ponta":
				destino = Vector3(signf(r.position.x) * 11.0, 0, -30.0)
				dur = 1.0
				_mover(r, destino + Vector3(0, 0, 0.6), 1.0)
			elif s["tipo"] == "falta":
				destino = r.position + Vector3(0, 0, -1.0)
				_mover(r, destino + Vector3(0, 0, 0.6), 0.7)
			else:
				destino = r.position + (Vector3(0, 0, -40) - r.position).normalized() * 2.0
				_mover(r, destino + Vector3(0, 0, 0.5), 0.9)
	if acao == "ajeitar":
		var cab := prota.position + Vector3(0, 2.0, -0.1)
		seguir_bola = true
		create_tween().tween_property(self, "altura_olhos", ALTURA_OLHOS + 0.4, 0.35)
		await _bola_para(cab, 0.5, 0.45)
		create_tween().tween_property(self, "altura_olhos", ALTURA_OLHOS, 0.35)
		seguir_bola = false
		seguir_no = r
	else:
		alvo_olhar = bola.position
		await _espera(0.2)
		prota.fazer_pose("chute")
		await _espera(0.16)
	bola_no_pe = false
	_tocar_chute(0.6)
	if d == "interceptado":
		var z: Jogador3D = _adversario_mais_proximo((bola.position + destino) / 2.0)
		seguir_no = null
		seguir_bola = true
		_mover(z, (bola.position + destino) / 2.0 + Vector3(0.4, 0, 0), dur * 0.5)
		await _bola_para((bola.position + destino) / 2.0 + Vector3(0, 0.3, 0), altura * 0.5, dur * 0.5)
		_falar("Interceptado!")
		Audio.tocar("uhh", 0.7)
		await _bola_para(Vector3(rng.randf_range(-20, 20), 0.11, rng.randf_range(0, 15)), 3.0, 1.0)
		await _espera(0.5)
		return
	seguir_bola = true
	await _bola_para(destino + Vector3(0, 0.11, 0), altura, dur)
	seguir_bola = false
	seguir_no = r
	var nome_r: String = r.get_meta("nome", "")
	_falar(("%s domina... e bate!" % nome_r) if nome_r != "" else "Domina... e bate!")
	_encarar(r, Vector3(0, 0, -40))
	bola.position = _pe_do(r)
	await _espera(0.25)
	var desf := "gol" if d == "assistencia" else d
	await _finalizar_bola(r, "colocado", desf, resultado["lado"], resultado["alto"])
	await _pos_finalizacao(desf, false)


## Tabela: toca, passa pelo zagueiro e recebe de volta na frente.
func _seq_tabela(d: String) -> void:
	var r: Jogador3D = atores["parceiro"]
	var z: Jogador3D = atores["zagueiro"]
	seguir_no = r
	_falar("Toca e passa!")
	prota.fazer_pose("toque")
	await _espera(0.12)
	bola_no_pe = false
	_tocar_chute(0.5)
	await _bola_para(r.position + (prota.position - r.position).normalized() * 0.6 + Vector3(0, 0.11, 0), 0.15, 0.45)
	var alvo := Vector3(lerpf(prota.position.x, 0.0, 0.4), 0, prota.position.z - 7.0)
	balanco = 1.0
	_mover(prota, alvo, 0.85)
	_mover(z, z.position + Vector3(0, 0, -1.5), 0.85)
	await _espera(0.35)
	r.fazer_pose("toque")
	_tocar_chute(0.5)
	if d == "interceptado":
		var z2: Jogador3D = atores.get("zagueiro2", z)
		var meio := bola.position.lerp(alvo, 0.6)
		_mover(z2, meio, 0.4)
		seguir_no = null
		seguir_bola = true
		await _bola_para(meio + Vector3(0, 0.11, 0), 0.1, 0.4)
		_falar("Cortaram a tabela!")
		Audio.tocar("uhh", 0.7)
		balanco = 0.0
		await _bola_para(Vector3(rng.randf_range(-20, 20), 0.11, rng.randf_range(-10, 5)), 2.0, 0.8)
		await _espera(0.4)
		return
	seguir_no = null
	seguir_bola = true
	await _bola_para(alvo + Vector3(0, 0.11, -0.75), 0.2, 0.5)
	bola_no_pe = true
	seguir_bola = false
	balanco = 0.0
	_falar("Recebeu de volta, cara a cara!")
	alvo_olhar = Vector3(0, 1.0, -40)
	await _espera(0.15)
	await _finalizar_bola(prota, "colocado", d, resultado["lado"], resultado["alto"])
	await _pos_finalizacao(d, true)


## Bicicleta: a câmera vira de costas para o céu e chicoteia atrás da bola.
func _seq_bicicleta(d: String) -> void:
	seguir_bola = true
	_falar("Se joga de costas...")
	create_tween().tween_property(self, "altura_olhos", ALTURA_OLHOS + 0.35, 0.4)
	await _bola_para(prota.position + Vector3(0, 1.75, 0.25), 0.4, 0.45)
	_falar("BICICLETA!")
	seguir_bola = false
	alvo_olhar = prota.position + Vector3(0, 7.0, 4.0)
	prota.fazer_pose("chute")
	Tela.vibrar(80)
	await _espera(0.28)
	create_tween().tween_property(self, "altura_olhos", 0.45, 0.55).set_delay(0.1)
	await _finalizar_bola(prota, "bicicleta", d, resultado["lado"], resultado["alto"], false)
	create_tween().tween_property(self, "altura_olhos", ALTURA_OLHOS, 0.45)
	await _pos_finalizacao(d, true)


## Drible no goleiro (rebote com o goleiro caído ou goleiro saindo do gol).
func _seq_drible_goleiro(d: String) -> void:
	var g: Jogador3D = atores["goleiro"]
	if not bola_no_pe:
		seguir_bola = true
		await _bola_para(_pe_do(prota), 0.3, 0.4)
		bola_no_pe = true
		seguir_bola = false
	balanco = 1.0
	seguir_no = g
	_falar("Vai pra cima do goleiro...")
	var lado := 1.0 if prota.position.x <= 0 else -1.0
	_mover(g, prota.position.lerp(g.position, 0.5), 0.6)
	await _mover(prota, prota.position + Vector3(0, 0, -2.0), 0.6).finished
	match d:
		"gol":
			_falar("Tira o goleiro da jogada!")
			_mergulho(g, g.position + Vector3(-lado * 1.3, 0.2, 0), 0.0, 0.4)
			await _mover(prota, prota.position + Vector3(lado * 2.2, 0, -1.2), 0.35).finished
			seguir_no = null
			alvo_olhar = Vector3(0, 0.8, -40)
			await _mover(prota, Vector3(prota.position.x * 0.7, 0, prota.position.z - 2.5), 0.4).finished
			balanco = 0.0
			await _finalizar_bola(prota, "rasteiro", "gol", -lado * 0.4, false)
			await _pos_finalizacao("gol", true)
		"defesa":
			_falar("O goleiro se jogou nos seus pés!")
			bola_no_pe = false
			_mergulho(g, prota.position + Vector3(0, 0.2, -0.8), 0.0, 0.3)
			await _bola_para(prota.position + Vector3(lado * 0.4, 0.3, -1.0), 0.1, 0.3)
			Audio.tocar("uhh", 0.9)
			balanco = 0.0
			await _espera(0.7)
		_:
			var z: Jogador3D = atores.get("zagueiro", g)
			_falar("O zagueiro voltou a tempo!")
			_mover(z, prota.position + Vector3(lado * 0.8, 0, -0.4), 0.3)
			await _espera(0.25)
			bola_no_pe = false
			seguir_no = null
			seguir_bola = true
			balanco = 0.0
			Tela.vibrar(120)
			await _bola_para(prota.position + Vector3(-lado * 9.0, 0.11, 3.0), 0.8, 0.8)
			Audio.tocar("uhh", 0.8)
			await _espera(0.5)


## Bola longa: domina no peito ou bate de primeira (voleio).
func _seq_domina(acao: String, d: String) -> void:
	seguir_bola = true
	if acao == "voleio":
		_falar("De primeira!")
		await _bola_para(prota.position + Vector3(0, 0.55, -0.7), 0.3, 0.5)
		prota.fazer_pose("chute")
		await _finalizar_bola(prota, "voleio", d, resultado["lado"], resultado["alto"], false)
	else:
		_falar("Mata no peito...")
		await _bola_para(prota.position + Vector3(0, 1.25, -0.4), 0.35, 0.5)
		Tela.vibrar(30)
		await _bola_para(_pe_do(prota), 0.15, 0.3)
		bola_no_pe = true
		seguir_bola = false
		balanco = 1.0
		alvo_olhar = Vector3(0, 1.0, -40)
		var z: Jogador3D = atores.get("zagueiro")
		if z:
			_mover(z, z.position + Vector3(0, 0, -3.5), 0.6)
		await _mover(prota, prota.position + Vector3(-prota.position.x * 0.15, 0, -3.0), 0.6).finished
		balanco = 0.0
		alvo_olhar = bola.position
		await _espera(0.12)
		await _finalizar_bola(prota, "colocado", d, resultado["lado"], resultado["alto"])
	await _pos_finalizacao(d, true)


# ---------------------------------------------------------------- lances de defesa

## Desarme: você persegue o atacante deles e escolhe como roubar a bola.
func _seq_desarme(acao: String, d: String) -> void:
	var at: Jogador3D = atores["atacante_adv"]
	var ap: Jogador3D = atores.get("apoio_adv", at)
	seguir_no = at
	balanco = 1.0
	_falar("Volta, volta!")
	var frente := Vector3(0, 0, -1)
	var lado := signf(prota.position.x - at.position.x)
	if lado == 0.0:
		lado = 1.0
	var encontro := at.position + frente * 3.0
	_mover(at, encontro, 0.8)
	await _mover(prota, encontro + Vector3(lado * 0.9, 0, 0.9), 0.8).finished
	match acao:
		"antecipar":
			_bola_com = null
			at.fazer_pose("toque")
			_tocar_chute(0.5)
			seguir_no = null
			seguir_bola = true
			var meio := at.position.lerp(ap.position, 0.5)
			if d == "desarme":
				_mover(prota, meio + Vector3(0, 0, 0.6), 0.4)
				await _bola_para(meio + Vector3(0, 0.11, 0), 0.2, 0.42)
				bola_no_pe = true
				await _comemorar_defesa("ANTECIPOU! Que leitura!")
			else:
				_mover(prota, meio + Vector3(0, 0, 1.6), 0.45)
				await _bola_para(ap.position + Vector3(0, 0.11, 0), 0.2, 0.5)
				_falar("Chegou atrasado...")
				await _chute_adversario(ap, d)
		"carrinho":
			_falar("Carrinho!")
			var desliza := create_tween().set_parallel()
			desliza.tween_property(self, "altura_olhos", 0.55, 0.22)
			desliza.tween_property(self, "rolagem", -lado * 0.22, 0.22)
			match d:
				"desarme":
					_mover(prota, at.position + Vector3(lado * 0.3, 0, -0.6), 0.32)
					await _espera(0.24)
					_bola_com = null
					_tocar_chute(0.8)
					seguir_no = null
					seguir_bola = true
					create_tween().tween_property(at, "rotation:x", -1.2, 0.35)
					await _bola_para(at.position + Vector3(lado * 7.0, 0.11, 1.5), 0.6, 0.6)
					await _levantar()
					await _comemorar_defesa("CARRINHO PERFEITO!")
				"falta_dura":
					await _mover(prota, at.position + Vector3(0, 0, -0.3), 0.32).finished
					await _falta_cometida(at)
				_:
					_mover(at, at.position + Vector3(-lado * 1.6, 0, -1.8), 0.35)
					await _mover(prota, prota.position + Vector3(0, 0, -2.2), 0.4).finished
					_falar("Ele cortou! Você ficou no chão...")
					await _chute_adversario(at, d)
		"bote":
			_falar("Agora!")
			await _mover(prota, at.position + Vector3(lado * 0.5, 0, 0.25), 0.3).finished
			match d:
				"desarme":
					_bola_com = null
					bola_no_pe = true
					_tocar_chute(0.5)
					var tw := create_tween()
					tw.tween_property(at, "rotation:x", -0.5, 0.2)
					tw.tween_property(at, "rotation:x", 0.0, 0.3)
					await _comemorar_defesa("ROUBOU A BOLA!")
				"falta_dura":
					await _falta_cometida(at)
				_:
					_mover(at, at.position + Vector3(-lado * 2.0, 0, -3.0), 0.4)
					_falar("Passou por você!")
					await _espera(0.4)
					await _chute_adversario(at, d)
		_:  # conter: acompanha lado a lado e fecha o chute
			_falar("Fecha o ângulo!")
			var adiante := at.position + frente * 2.5
			_mover(at, adiante, 0.6)
			await _mover(prota, adiante + Vector3(lado * 0.7, 0, -0.9), 0.6).finished
			if d == "bloqueio":
				_encarar(at, Vector3(0, 0, -40))
				at.fazer_pose("chute")
				await _espera(0.16)
				_bola_com = null
				_tocar_chute()
				seguir_no = null
				seguir_bola = true
				await _bola_para(_olho() + Vector3(0, -0.7, -0.45), 0.1, 0.18)
				Tela.vibrar(140)
				Audio.tocar("chute", 0.8, 0.8)
				await _bola_para(prota.position + Vector3(lado * 9.0, 0.11, 7.0), 1.6, 0.7)
				await _comemorar_defesa("TRAVOU O CHUTE!")
			else:
				await _chute_adversario(at, d)
	balanco = 0.0


## Cruzamento na nossa área: afastar, chutão, sair jogando ou deixar pro goleiro.
func _seq_afastar(acao: String, d: String) -> void:
	var at: Jogador3D = atores["atacante_adv"]
	var g: Jogador3D = atores["goleiro"]
	var origem: Vector3 = s.get("origem_bola", Vector3(20, 0, -33))
	var fora := Vector3(signf(origem.x) * 0.55, 0, 1.0).normalized()
	seguir_bola = true
	match acao:
		"afastar_cabeca":
			_falar("Sobe!")
			create_tween().tween_property(self, "altura_olhos", ALTURA_OLHOS + 0.45, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			var pulo := create_tween()
			pulo.tween_property(at, "position:y", 0.35, 0.35)
			pulo.tween_property(at, "position:y", 0.0, 0.3)
			if d == "afastou":
				await _bola_para(prota.position + Vector3(0, 2.05, 0) + fora * 0.15, 0.5, 0.45)
				_tocar_chute(0.7)
				create_tween().tween_property(self, "altura_olhos", ALTURA_OLHOS, 0.3)
				await _bola_para(prota.position + fora * 20.0 + Vector3(0, 0.11, 0), 5.0, 1.0)
				await _comemorar_defesa("AFASTOU DE CABEÇA!")
			else:
				await _bola_para(at.position + Vector3(0, 2.1, 0), 0.5, 0.45)
				create_tween().tween_property(self, "altura_olhos", ALTURA_OLHOS, 0.3)
				_falar("Ele subiu mais...")
				await _chute_adversario(at, d, "cabeca")
		"chutao":
			_falar("Deixa cair...")
			await _bola_para(_pe_do(prota) + Vector3(0, 0.3, 0), 0.6, 0.55)
			if d == "afastou":
				prota.fazer_pose("chute")
				await _espera(0.16)
				_tocar_chute(1.0)
				_poeira_chute(bola.position, 1.2)
				await _bola_para(prota.position + fora * 35.0 + Vector3(0, 0.11, 0), 9.0, 1.4)
				await _comemorar_defesa("CHUTÃO! Pro alto e avante!")
			else:
				_mover(at, _pe_do(prota), 0.25)
				await _espera(0.25)
				_falar("Ele chegou antes!")
				await _chute_adversario(at, d, "rasteiro")
		"sair_jogando":
			await _bola_para(_pe_do(prota), 0.5, 0.55)
			bola_no_pe = true
			seguir_bola = false
			if d == "afastou":
				_falar("Domina com classe...")
				balanco = 0.8
				var z: Jogador3D = atores.get("zagueiro_nos", at)
				seguir_no = z
				await _mover(prota, prota.position + fora * 3.5, 0.7).finished
				balanco = 0.0
				prota.fazer_pose("chute")
				await _espera(0.16)
				bola_no_pe = false
				_tocar_chute(0.7)
				seguir_no = null
				seguir_bola = true
				await _bola_para(prota.position + fora * 26.0 + Vector3(0, 0.11, 0), 1.2, 1.0)
				await _comemorar_defesa("Saiu jogando! Que categoria!")
			else:
				_falar("Ele roubou na área!")
				_mover(at, prota.position + fora * 0.3, 0.3)
				await _espera(0.3)
				bola_no_pe = false
				await _chute_adversario(at, d)
		_:  # deixar pro goleiro
			_falar("DEIXAAA!")
			var ponto := prota.position.lerp(g.position, 0.55)
			_mover(g, Vector3(ponto.x, 0, ponto.z), 0.45)
			if d == "afastou":
				var salto := create_tween()
				salto.tween_interval(0.25)
				salto.tween_property(g, "position:y", 0.6, 0.2)
				salto.tween_property(g, "position:y", 0.0, 0.3)
				await _bola_para(Vector3(ponto.x, 2.3, ponto.z), 0.5, 0.48)
				_bola_com = g
				await _comemorar_defesa("O goleiro segurou firme!")
			else:
				await _bola_para(at.position + Vector3(0, 1.9, 0), 0.5, 0.55)
				_falar("Bateu cabeça com o goleiro!")
				await _chute_adversario(at, d, "cabeca")
	balanco = 0.0


func _levantar() -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "altura_olhos", ALTURA_OLHOS, 0.35)
	tw.tween_property(self, "rolagem", 0.0, 0.35)
	await tw.finished


func _comemorar_defesa(texto: String) -> void:
	seguir_bola = false
	seguir_no = null
	_falar(texto)
	Audio.torcida(0.95)
	Tela.vibrar(160)
	mundo.festa_torcida(3)
	_flash(0.25, Color("9be36b"))
	alvo_olhar = prota.position + Vector3(0, 4.0, 10.0)
	await _espera(0.9)


func _falta_cometida(at: Jogador3D) -> void:
	_bola_com = null
	var queda := create_tween().set_parallel()
	queda.tween_property(at, "rotation:x", -1.35, 0.35)
	queda.tween_property(at, "position:y", 0.25, 0.35)
	Audio.tocar("apito", 0.9)
	Tela.vibrar(120)
	await _espera(0.4)
	_flash(0.45, Color("ffd400"))
	_falar("Falta! Cartão amarelo pra você.")
	await _levantar()
	await _espera(0.6)


## O adversário finaliza contra o nosso gol (gol deles ou defesa do nosso goleiro).
func _chute_adversario(a: Jogador3D, d: String, tipo := "colocado") -> void:
	_bola_com = null
	seguir_no = null
	seguir_bola = true
	if tipo != "cabeca":
		_encarar(a, Vector3(0, 0, -40))
		bola.position = _pe_do(a)
		await _espera(0.15)
	var desf := "gol" if d == "gol_sofrido" else "defesa"
	await _finalizar_bola(a, tipo, desf, resultado["lado"], resultado["alto"], tipo != "cabeca")
	if desf == "gol":
		Audio.tocar("uhh", 1.0)
		Audio.torcida(0.3)
		Tela.vibrar(200)
		_falar("Gol deles...")
		ctx["gols_fora"] = int(ctx.get("gols_fora", 0)) + 1
		lbl_placar.text = _texto_placar()
		a.fazer_pose("comemora_bracos")
	else:
		Audio.torcida(0.9)
		_falar("QUE DEFESA! O goleiro salvou você!")
	await _levantar()
	await _espera(0.8)


func _adversario_mais_proximo(p: Vector3) -> Jogador3D:
	var melhor: Jogador3D = null
	var dist := INF
	for papel in atores:
		var a: Jogador3D = atores[papel]
		if papel == "goleiro" or papel == "prota" or papel in ["parceiro", "atacante", "ponta"]:
			continue
		var dd := a.position.distance_to(p)
		if dd < dist:
			dist = dd
			melhor = a
	return melhor if melhor else atores["goleiro"]


## Chute genérico: trajetória e reação do goleiro dependem do desfecho.
func _finalizar_bola(atirador: Jogador3D, tipo: String, d: String, lado: float, alto: bool, anima := true) -> void:
	if anima:
		_encarar(atirador, Vector3(0, 0, -40))
		atirador.fazer_pose("chute")
		await _espera(0.16)
	bola_no_pe = false
	seguir_bola = true
	_tocar_chute(1.0 if tipo != "cavadinha" else 0.5)
	var origem := bola.position
	var dist := origem.distance_to(Vector3(0, 1, -40))
	var vel := 24.0
	var arco := 0.6
	var curva := 0.0
	match tipo:
		"forte":
			vel = 33.0
			arco = 0.3
		"cobertura":
			vel = 15.0
			arco = 3.6
		"curva":
			vel = 21.0
			arco = 2.0
			curva = -lado * 3.0
		"cavadinha":
			vel = 9.0
			arco = 2.2
		"penalti":
			vel = 27.0
			arco = 0.15
		"cabeca", "cabeca_chao":
			vel = 17.0
			arco = 0.05
		"rasteiro":
			vel = 22.0
			arco = 0.05
		"voleio":
			vel = 30.0
			arco = 0.25
		"bicicleta":
			vel = 23.0
			arco = 0.5
	var dur := clampf(dist / vel, 0.35, 2.4)
	_poeira_chute(origem, 1.3 if tipo == "forte" else 1.0)
	# câmera lenta nos últimos metros de um gol (fora do replay)
	if d == "gol" and fase == Fase.EXECUTANDO and not auto:
		get_tree().create_timer(dur * 0.55, true, false, true).timeout.connect(func() -> void:
			if fase == Fase.EXECUTANDO:
				_camera_lenta = true
				Engine.time_scale = 0.4)
	var g: Jogador3D = atores.get("goleiro")
	var alvo := Vector3.ZERO
	var y_alto := 1.95 if alto else 0.35
	if tipo == "cabeca_chao" or tipo == "rasteiro":
		y_alto = 0.25
	if tipo == "cavadinha" or (tipo == "cobertura" and d == "gol"):
		y_alto = 1.7
	var x_gol := lado * 2.85
	if tipo == "cavadinha":
		x_gol = 0.2
	match d:
		"gol":
			alvo = Vector3(x_gol, y_alto, -40.3)
			if g and tipo != "penalti" and tipo != "cavadinha":
				_mergulho(g, Vector3(lado * 1.7, 0.4, g.position.z - 0.3), dur * 0.45, dur * 0.7)
			elif g and tipo == "cavadinha":
				pass  # o goleiro já pulou para um canto no pênalti
		"defesa":
			alvo = Vector3(lado * 1.75 if tipo != "cavadinha" else 0.0, minf(y_alto, 1.5), (g.position.z + 0.2) if g else -39.0)
			if g and tipo != "penalti":
				_mergulho(g, Vector3(alvo.x - lado * 0.3, maxf(alvo.y - 0.9, 0.0), g.position.z), dur * 0.15, dur * 0.85)
			elif g and tipo == "penalti":
				# no pênalti, o goleiro já está indo para o lado certo
				alvo = Vector3(lado * 2.1, 0.7, -39.4)
		"trave":
			alvo = Vector3(lado * 3.62, 1.1, -40.0) if not alto else Vector3(lado * 1.6, 2.44, -40.0)
			if g and tipo != "penalti":
				_mergulho(g, Vector3(lado * 1.6, 0.4, g.position.z), dur * 0.4, dur * 0.7)
		_:
			alvo = Vector3(lado * 5.3, 0.9, -41.0) if not alto else Vector3(lado * 2.2, 3.7, -41.5)
			if g and tipo != "penalti":
				_mergulho(g, Vector3(lado * 1.3, 0.3, g.position.z), dur * 0.5, dur * 0.6)
	await _bola_para(alvo, arco, dur, curva)
	if _camera_lenta:
		_camera_lenta = false
		Engine.time_scale = float(ctx.get("escala_tempo", 1.0))
	match d:
		"gol":
			Audio.tocar("rede", 0.9)
			mundo.impacto_rede(alvo)
			await _bola_para(Vector3(alvo.x * 1.02, 0.15, -41.8), 0.1, 0.32)
		"defesa":
			Tela.vibrar(60)
			if rng.randf() < 0.5:
				await _bola_para(Vector3(lado * 7.0, 0.11, -36.5), 1.3, 0.6)
			else:
				_falar("Encaixou!")
		"trave":
			Audio.tocar("chute", 0.8, 1.6)
			Tela.vibrar(90)
			_falar("NA TRAVE!")
			await _bola_para(Vector3(-lado * 4.0, 0.11, -33.0), 1.0, 0.7)
		_:
			await _bola_para(alvo + Vector3(lado * 1.5, 0.6 if alto else -0.6, -5.0), 0.4, 0.55)


func _pos_finalizacao(d: String, prota_chutou: bool) -> void:
	seguir_bola = false
	match d:
		"gol":
			_flash(0.7)
			Audio.tocar("gol", 1.0)
			Audio.torcida(1.0)
			Tela.vibrar(260)
			mundo.festa_torcida(7)
			ctx["gols_casa"] = int(ctx.get("gols_casa", 0)) + 1
			lbl_placar.text = _texto_placar()
			_falar("GOOOOOOOL!!!" if prota_chutou else "GOOOL! ASSISTÊNCIA SUA!")
			balanco = 1.0
			if prota_chutou:
				alvo_olhar = Vector3(signf(prota.position.x + 0.01) * 22.0, 6.0, -46.0)
				await _mover(prota, prota.position + Vector3(signf(prota.position.x + 0.01) * 5.0, 0, -4.0), 1.3).finished
			else:
				var r: Node3D = _receptor()
				seguir_no = r
				var destino_r := r.position + Vector3(0, 0, 3.0)
				_mover(r, destino_r, 1.2)
				var dir := prota.position - destino_r
				dir.y = 0.0
				dir = dir.normalized() if dir.length() > 0.1 else Vector3(1, 0, 0)
				await _mover(prota, destino_r + dir * 2.2, 1.4).finished
				r.fazer_pose("comemora_bracos")
			balanco = 0.0
		"defesa":
			Audio.tocar("uhh", 1.0)
			_falar("Defendeu o goleiro!")
			await _espera(0.6)
		"trave":
			Audio.tocar("uhh", 1.0)
			await _espera(0.7)
		"fora":
			Audio.tocar("uhh", 0.9)
			_falar("Pra fora!")
			await _espera(0.7)
	await _espera(0.4)


# ================================================================ extras

func _escolher_comemoracao() -> void:
	var opcoes: Array = ctx.get("comemoracoes", [])
	if opcoes.is_empty():
		return
	fase = Fase.ESCOLHA_EXTRA
	_limpar_opcoes()
	_falar("Como você comemora?")
	var escolhido := [""]
	for c in opcoes.slice(0, 4):
		var b := UI.botao(c["nome"], c.get("icone", "festa"), "primario" if c == opcoes[0] else "normal", 84)
		var cid: String = c["id"]
		b.pressed.connect(func() -> void:
			escolhido[0] = cid
			_evento_ui.emit(cid))
		caixa_opcoes.add_child(b)
	var limite := get_tree().create_timer(4.5 if not auto else 0.2, false)
	limite.timeout.connect(func() -> void:
		if escolhido[0] == "":
			escolhido[0] = opcoes[0]["id"]
			_evento_ui.emit(escolhido[0]))
	while escolhido[0] == "":
		await _evento_ui
	comemoracao = escolhido[0]
	_limpar_opcoes()
	var pose := "comemora_bracos"
	for c in opcoes:
		if c["id"] == comemoracao:
			pose = c.get("pose", pose)
	prota.fazer_pose(pose)
	alvo_olhar = prota.position + Vector3(0, 6.0, -12.0)
	await _espera(1.0)


func _oferecer_segunda_chance() -> bool:
	fase = Fase.ESCOLHA_EXTRA
	_limpar_opcoes()
	var modo: String = ctx.get("segunda_chance", "")
	_falar("E se você pudesse voltar no tempo?")
	var escolhido := [-1]
	var texto := "Reviver o lance"
	var icone := "anuncio"
	var estilo := "anuncio"
	if modo == "ficha":
		texto = "Reviver o lance (usar ficha)"
		icone = "replay"
		estilo = "roxo"
	elif modo == "vip":
		texto = "Reviver o lance (VIP)"
		icone = "vip"
		estilo = "primario"
	var b1 := UI.botao(texto, icone, estilo, 92)
	b1.pressed.connect(func() -> void:
		escolhido[0] = 1
		_evento_ui.emit(1))
	var b2 := UI.botao("Seguir o jogo", "seta_dir", "fantasma", 76)
	b2.pressed.connect(func() -> void:
		escolhido[0] = 0
		_evento_ui.emit(0))
	caixa_opcoes.add_child(b1)
	caixa_opcoes.add_child(b2)
	if auto:
		escolhido[0] = 1 if rng.randf() < 0.5 else 0
	while escolhido[0] < 0:
		await _evento_ui
	_limpar_opcoes()
	if escolhido[0] == 0:
		return false
	if modo == "anuncio":
		var ok: bool = await Anuncios.recompensado("segunda_chance")
		if not ok:
			Tela.aviso("O anúncio não carregou. Tente de novo mais tarde.", "info")
			return false
	terminou_meta["segunda_chance_modo"] = modo
	return true


var terminou_meta := {}


func _rebobinar() -> void:
	Audio.tocar("rebobinar")
	_falar("Rebobinando...")
	_flash(0.85, Color("a0c4ff"))
	await _espera(0.35)
	_restaurar(_snapshot)
	prota.mostrar_corpo_superior = false
	camera_livre = true
	yaw = yaw_base
	pitch = -0.06
	cam_pov.make_current()
	_falar("Desta vez você já sabe o que pode acontecer...")
	await _espera(0.6)


func _replay() -> void:
	fase = Fase.REPLAY
	_falar("")
	_dica("", 0)
	lbl_replay.visible = true
	btn_pular.visible = not auto
	_pulo_replay = false
	_flash(0.5)
	prota.mostrar_corpo_superior = true
	if auto:
		Engine.time_scale = maxf(Engine.time_scale, 8.0)
	var placar_antes := int(ctx.get("gols_casa", 0))
	if resultado["desfecho"] in ["gol", "assistencia"]:
		ctx["gols_casa"] = placar_antes - 1
	if resultado["desfecho"] == "gol_sofrido":
		ctx["gols_fora"] = int(ctx.get("gols_fora", 0)) - 1
	_restaurar(_snapshot)
	var lado_cam := 1.0 if prota.position.x <= 0 else -1.0
	if s["tipo"] == "penalti" and rng.randf() < 0.5:
		cam_tv.global_transform = Transform3D(Basis(), Vector3(0, 2.6, -47.5)).looking_at(prota.position + Vector3(0, 1, 0), Vector3.UP)
	else:
		var meio_z := (prota.position.z + -40.0) / 2.0
		cam_tv.global_transform = Transform3D(Basis(), Vector3(lado_cam * 24.0, 8.0, meio_z + 4.0)).looking_at(bola.position, Vector3.UP)
	cam_tv.make_current()
	for papel in atores:
		atores[papel].visible = true
	await _executar(false)
	if comemoracao != "":
		for c in ctx.get("comemoracoes", []):
			if c["id"] == comemoracao:
				prota.fazer_pose(c.get("pose", "comemora_bracos"))
		await _espera(1.2)
	ctx["gols_casa"] = int(ctx.get("gols_casa", 0))
	lbl_replay.visible = false
	btn_pular.visible = false
	Engine.time_scale = float(ctx.get("escala_tempo", 1.0))


func _finalizar() -> void:
	fase = Fase.FIM
	var d: String = resultado["desfecho"]
	var titulo := {"gol": "GOL!", "assistencia": "ASSISTÊNCIA!", "defesa": "DEFENDEU", "fora": "PRA FORA",
		"trave": "NA TRAVE", "perdeu": "PERDEU A BOLA", "interceptado": "INTERCEPTADO", "passou_defesa": "QUASE!",
		"desarme": "DESARME!", "bloqueio": "TRAVOU O CHUTE!", "afastou": "AFASTOU O PERIGO!", "falta_dura": "CARTÃO AMARELO",
		"salvou_goleiro": "O GOLEIRO SALVOU", "gol_sofrido": "GOL DELES..."}
	_falar(titulo.get(d, ""))
	Audio.torcida(0.45)
	await _espera(0.5 if not auto else 0.05)
	var r := resultado.duplicate()
	r["tipo"] = s["tipo"]
	r["comemoracao"] = comemoracao
	r["descobertos"] = descobertos.duplicate()
	r["segunda_chance"] = segunda_chance_usada
	r["segunda_chance_modo"] = terminou_meta.get("segunda_chance_modo", "")
	r["opcao_texto"] = opcao_escolhida.get("texto", "")
	r["opcao_descoberta"] = opcao_escolhida.get("descoberta", false)
	r["minuto"] = ctx.get("minuto", 0)
	r["parceiro"] = ctx.get("parceiro", "")
	if resultado["acao"] in Situacoes.ACOES_PASSE:
		r["receptor_nome"] = _receptor().get_meta("nome", "")
	terminou.emit(r)


# ================================================================ helpers

func _bola_para(destino: Vector3, altura: float, duracao: float, curva := 0.0) -> void:
	var de := bola.position
	var lateral := Vector3.ZERO
	if absf(curva) > 0.0:
		var dir := (destino - de).normalized()
		lateral = Vector3(-dir.z, 0, dir.x) * curva
	var f := func(t: float) -> void:
		bola.position = de.lerp(destino, t) + Vector3(0, altura * 4.0 * t * (1.0 - t), 0) + lateral * (4.0 * t * (1.0 - t))
		bola.rotate_x(-0.4)
	var tw := create_tween()
	tw.tween_method(f, 0.0, 1.0, maxf(duracao, 0.05))
	await tw.finished


func _mover(n: Node3D, destino: Vector3, duracao: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(n, "position", destino, duracao).set_trans(Tween.TRANS_SINE)
	return tw


func _mergulho(g: Jogador3D, destino: Vector3, atraso: float, duracao: float) -> void:
	var lado := signf(destino.x - g.position.x)
	# o goleiro está virado para +Z (rotation.y ~ PI): rotation.z positiva tomba para +X do mundo
	var tw := create_tween()
	tw.tween_interval(atraso)
	tw.tween_property(g, "position", destino, duracao).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(g, "rotation:z", lado * 1.25, duracao)


func _encarar(n: Node3D, alvo: Vector3) -> void:
	var a := Vector3(alvo.x, n.position.y, alvo.z)
	if a.distance_to(n.position) > 0.05:
		n.look_at(a, Vector3.UP)


func _tocar_chute(vol := 1.0) -> void:
	Audio.tocar("chute", vol)
	Tela.vibrar(45)


func _espera(segundos: float) -> void:
	await get_tree().create_timer(segundos, false).timeout


# ================================================================ teste automático

func _auto_jogar() -> void:
	await _espera(0.3)
	# olha para cada POI para revelar
	for poi in s["pois"]:
		var alvo: Node3D = atores.get(poi["papel"], null)
		if alvo and rng.randf() < 0.8:
			yaw = _yaw_para(alvo.position)
			await _espera(TEMPO_LEITURA + 0.15)
	if fase != Fase.OLHANDO:
		return
	if ctx.get("auto_timeout", false):
		return
	var visiveis := []
	for op in s["opcoes"]:
		if not op["oculta"]:
			visiveis.append(op)
	var forcada: String = ctx.get("auto_opcao", "")
	for op in visiveis:
		if op["id"] == forcada:
			_escolher(op, false)
			return
	_escolher(visiveis[rng.randi() % visiveis.size()], false)
