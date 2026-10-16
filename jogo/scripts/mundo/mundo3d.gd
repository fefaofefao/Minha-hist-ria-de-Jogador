class_name Mundo3D
extends Node3D
## Constrói o cenário do jogo. A ambientação evolui com a carreira:
##   "varzea"  - campo de terra do bairro: lajes, caixas d'água, fios, pipas, bar do Zé
##   "base"    - CT de categoria de base: arquibancada coberta, prédio, árvores, cones
##   "estadio" - estádio profissional: dois anéis, cobertura com refletores, LED, bancos
##   "selecao" - estádio lotado de verde e amarelo
## Tudo que se repete é desenhado em lote (MultiMesh) para rodar bem no celular.
## O gol atacado fica sempre em z = -40 (o jogador ataca na direção -Z).

const LINHA_GOL := -40.0
const LARGURA := 34.0

var cenario := "estadio"
var noite := false
var cor_casa := Color("ffc928")
var cor_fora := Color("c62828")
var torcida: Array[Node3D] = []
var _mat_torcida: ShaderMaterial
var _empolgacao_base := 0.12
var _redes := {}  # z do gol -> Array[ShaderMaterial]
var _pipas: Array[Node3D] = []
var _bandeiras: Array[MeshInstance3D] = []
var _rng := RandomNumberGenerator.new()
var _t := 0.0

const SHADER_BANDEIRA := """
shader_type spatial;
render_mode cull_disabled;
uniform vec3 cor : source_color = vec3(1.0, 0.8, 0.1);
void vertex() {
	VERTEX.z += sin(TIME * 5.0 + VERTEX.x * 6.0) * 0.06 * (VERTEX.x + 0.25);
}
void fragment() {
	ALBEDO = cor * (0.85 + 0.15 * sin(UV.x * 10.0 + TIME * 5.0));
	ROUGHNESS = 0.9;
}
"""


func construir(p_cenario: String, p_noite := false, p_casa := Color("ffc928"), p_fora := Color("c62828"), semente := 1) -> Mundo3D:
	cenario = p_cenario
	noite = p_noite
	cor_casa = p_casa
	cor_fora = p_fora
	_rng.seed = semente
	_mat_torcida = ShaderMaterial.new()
	_mat_torcida.shader = Formas.shader("res://shaders/torcida.gdshader")
	_mat_torcida.set_shader_parameter("noite", 1.0 if noite else 0.0)
	_mat_torcida.set_shader_parameter("empolgacao", _empolgacao_base)
	_ambiente()
	_gramado()
	_gol(LINHA_GOL, 1)
	_gol(65.0, -1)
	_bandeirinhas()
	match cenario:
		"varzea":
			_varzea()
		"base":
			_base()
		_:
			_estadio()
	return self


func _process(delta: float) -> void:
	_t += delta
	for i in _pipas.size():
		var p := _pipas[i]
		p.position.y += sin(_t * 0.9 + i) * delta * 0.6
		p.rotation.z = sin(_t * 1.7 + i * 2.0) * 0.25


# ================================================================ ambiente

func _ambiente() -> void:
	var ceu := ShaderMaterial.new()
	ceu.shader = Formas.shader("res://shaders/ceu.gdshader")
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ceu
	env.sky.radiance_size = Sky.RADIANCE_SIZE_64
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_strength = 1.0
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 1.3
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.1
	env.adjustment_saturation = 1.18
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_sky_affect = 0.25
	var sol := DirectionalLight3D.new()
	sol.shadow_enabled = true
	sol.shadow_blur = 1.2
	sol.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sol.directional_shadow_max_distance = 75.0
	if noite:
		ceu.set_shader_parameter("topo", Color("050915"))
		ceu.set_shader_parameter("horizonte", Color("1b2846"))
		ceu.set_shader_parameter("chao", Color("070a12"))
		ceu.set_shader_parameter("noite", 1.0)
		ceu.set_shader_parameter("nuvens", 0.35)
		env.ambient_light_energy = 0.55
		env.tonemap_exposure = 1.15
		env.glow_intensity = 0.7
		env.fog_light_color = Color("1b2846")
		env.fog_density = 0.0006
		sol.rotation_degrees = Vector3(-58, 25, 0)
		sol.light_color = Color("e6edff")
		sol.light_energy = 1.25
		# luz de preenchimento dos refletores do lado oposto (sem sombra)
		var preenche := DirectionalLight3D.new()
		preenche.rotation_degrees = Vector3(-45, 200, 0)
		preenche.light_color = Color("f1f4ff")
		preenche.light_energy = 0.55
		add_child(preenche)
	elif cenario == "varzea":
		ceu.set_shader_parameter("topo", Color("3a5fae"))
		ceu.set_shader_parameter("horizonte", Color("ffbb85"))
		ceu.set_shader_parameter("chao", Color("6b4a32"))
		ceu.set_shader_parameter("cor_sol", Color("ffd9a0"))
		ceu.set_shader_parameter("nuvens", 0.6)
		env.ambient_light_energy = 0.6
		env.tonemap_exposure = 1.05
		env.fog_light_color = Color("f2b48a")
		env.fog_density = 0.0014
		env.fog_sun_scatter = 0.25
		sol.rotation_degrees = Vector3(-22, -58, 0)
		sol.light_color = Color("ffd2a2")
		sol.light_energy = 1.35
	else:
		ceu.set_shader_parameter("topo", Color("2a5fc4"))
		ceu.set_shader_parameter("horizonte", Color("bcd8f2"))
		ceu.set_shader_parameter("chao", Color("3a3c40"))
		ceu.set_shader_parameter("nuvens", 0.5 if cenario != "base" else 0.65)
		env.ambient_light_energy = 0.55
		env.tonemap_exposure = 1.0
		env.fog_light_color = Color("c9dcf0")
		env.fog_density = 0.0007
		env.fog_sun_scatter = 0.15
		sol.rotation_degrees = Vector3(-48, -38, 0)
		sol.light_color = Color("fff1dd")
		sol.light_energy = 1.5
	add_child(sol)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _gramado() -> void:
	var plano := PlaneMesh.new()
	plano.size = Vector2(190, 210)
	var m := ShaderMaterial.new()
	m.shader = Formas.shader("res://shaders/gramado.gdshader")
	match cenario:
		"varzea":
			m.set_shader_parameter("modo", 1)
		"base":
			m.set_shader_parameter("desgaste", 0.85)
			m.set_shader_parameter("grama_a", Color("235c1f"))
			m.set_shader_parameter("grama_b", Color("2c6c26"))
		_:
			m.set_shader_parameter("desgaste", 0.35)
	var mi := _malha(plano, Vector3(0, 0, 12.5), m)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _gol(z: float, sentido: int) -> void:
	var cor_trave := Color("f7f7f7") if cenario != "varzea" else Color("e9e2cf")
	var trave := Formas.mat(cor_trave, 0.45, 0.0)
	for x: float in [-3.66, 3.66]:
		_malha(Formas.cilindro(0.06, 0.06, 2.44, 12), Vector3(x, 1.22, z), trave)
	var travessao := _malha(Formas.cilindro(0.06, 0.06, 7.44, 12), Vector3(0, 2.44, z), trave)
	travessao.rotation.z = PI / 2.0
	var fundo := z - 2.0 * sentido
	var ferro := Formas.mat(Color("c8c8c8"), 0.6, 0.0)
	for x: float in [-3.66, 3.66]:
		_malha(Formas.cilindro(0.025, 0.025, 2.44, 6), Vector3(x, 1.22, fundo), ferro)
		var sup := _malha(Formas.cilindro(0.025, 0.025, 2.0, 6), Vector3(x, 2.44, z - 1.0 * sentido), ferro)
		sup.rotation.x = PI / 2.0
	var mats: Array = []
	var buracos := 0.06 if cenario == "varzea" else 0.0
	var cor_rede := Color("f2f2f2") if cenario != "varzea" else Color("e3dcc4")
	# fundo
	var pf := PlaneMesh.new()
	pf.size = Vector2(7.32, 2.44)
	pf.orientation = PlaneMesh.FACE_Z
	pf.subdivide_width = 24
	pf.subdivide_depth = 10
	var nf := _malha(pf, Vector3(0, 1.22, fundo), _mat_rede(Vector2(44, 15), buracos, cor_rede, mats))
	nf.rotation.y = PI if sentido == 1 else 0.0
	# teto
	var pt := PlaneMesh.new()
	pt.size = Vector2(7.32, 2.0)
	pt.subdivide_width = 24
	pt.subdivide_depth = 8
	_malha(pt, Vector3(0, 2.44, z - 1.0 * sentido), _mat_rede(Vector2(44, 12), buracos, cor_rede, mats))
	# laterais
	for x: float in [-3.66, 3.66]:
		var pl := PlaneMesh.new()
		pl.size = Vector2(2.0, 2.44)
		pl.orientation = PlaneMesh.FACE_X
		_malha(pl, Vector3(x, 1.22, z - 1.0 * sentido), _mat_rede(Vector2(12, 15), buracos, cor_rede, mats))
	_redes[z] = mats


func _mat_rede(malhas: Vector2, buracos: float, cor: Color, lista: Array) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = Formas.shader("res://shaders/rede.gdshader")
	m.set_shader_parameter("malhas", malhas)
	m.set_shader_parameter("buracos", buracos)
	m.set_shader_parameter("cor_rede", cor)
	lista.append(m)
	return m


## A rede ondula a partir do ponto em que a bola entrou.
func impacto_rede(ponto: Vector3) -> void:
	var z := LINHA_GOL if ponto.z < 12.5 else 65.0
	for m in _redes.get(z, []):
		m.set_shader_parameter("impacto", ponto)
		var tw := create_tween()
		tw.tween_method(func(t: float) -> void: m.set_shader_parameter("tempo_impacto", t), 0.0, 2.5, 2.5)


func _bandeirinhas() -> void:
	var sh := Shader.new()
	sh.code = SHADER_BANDEIRA
	var haste := Formas.mat(Color("eeeeee"), 0.5, 0.0)
	for p in [Vector3(-34, 0, -40), Vector3(34, 0, -40), Vector3(-34, 0, 65), Vector3(34, 0, 65)]:
		_malha(Formas.cilindro(0.02, 0.02, 1.5, 6), p + Vector3(0, 0.75, 0), haste)
		var q := QuadMesh.new()
		q.size = Vector2(0.45, 0.32)
		var m := ShaderMaterial.new()
		m.shader = sh
		m.set_shader_parameter("cor", Color("ffd400") if cenario != "varzea" else cor_casa)
		var b := _malha(q, p + Vector3(0.23, 1.33, 0), m)
		_bandeiras.append(b)


# ================================================================ lotes (MultiMesh)

func _lote(mesh: Mesh, itens: Array, pai: Node3D = null, material: Material = null, custom := false) -> MultiMeshInstance3D:
	## itens: Array de [Transform3D, Color] (ou [Transform3D, Color, Color custom]).
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = custom
	mm.mesh = mesh
	mm.instance_count = itens.size()
	for i in itens.size():
		mm.set_instance_transform(i, itens[i][0])
		mm.set_instance_color(i, itens[i][1])
		if custom:
			mm.set_instance_custom_data(i, itens[i][2])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	if material == null:
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.92
		material = m
	mmi.material_override = material
	(pai if pai != null else self).add_child(mmi)
	return mmi


## Caixa em lote: [centro, tamanho, cor, rot_y].
func _caixas(lista: Array, pai: Node3D = null, emissivo := 0.0) -> MultiMeshInstance3D:
	var itens: Array = []
	for c in lista:
		var b := Basis(Vector3.UP, c[3] if c.size() > 3 else 0.0).scaled(c[1])
		itens.append([Transform3D(b, c[0]), c[2]])
	var mat: Material = null
	if emissivo > 0.0:
		var m := ShaderMaterial.new()
		m.shader = _shader_emissivo()
		m.set_shader_parameter("energia", emissivo)
		mat = m
	return _lote(Formas.caixa(Vector3.ONE), itens, pai, mat)


# ================================================================ arquibancadas e torcida

func _cores_torcida() -> Array:
	if cenario == "selecao":
		return [Color("ffd400"), Color("ffd400"), Color("ffd400"), Color("1f9d3a"), Color("1f9d3a"), Color("1d3fa8"), Color.WHITE]
	return [cor_casa, cor_casa, cor_casa, cor_casa.darkened(0.2), cor_fora, Color.WHITE, Color("1d1d22"), Color("2f6fd0"), Color("d6d6d6")]


## Arquibancada em degraus com cadeiras e torcida. O campo fica no +Z local.
func _arquibancada(centro: Vector3, rot_y: float, comprimento: float, filas: int, lotacao: float, base_y := 0.0, cor_concreto := Color("8b8f99")) -> Node3D:
	var pivo := Node3D.new()
	add_child(pivo)
	pivo.position = centro
	pivo.rotation.y = rot_y
	var degrau := 0.62
	var prof := 0.85
	var blocos: Array = []
	var cadeiras: Array = []
	var pessoas: Array = []
	var cores := _cores_torcida()
	var cor_assento_a := cor_casa.darkened(0.15)
	var cor_assento_b := Color("d9d9d9") if cor_casa.get_luminance() < 0.6 else Color("3a3f4a")
	# muro frontal
	blocos.append([Vector3(0, base_y + 0.55, 0.45), Vector3(comprimento, 1.1 + base_y * 2.0, 0.3), cor_concreto.darkened(0.25)])
	for f in filas:
		var h := base_y + (f + 1) * degrau
		var z := -f * prof
		blocos.append([Vector3(0, h / 2.0, z), Vector3(comprimento, h, prof), cor_concreto.darkened(0.04 * (f % 2))])
		var cor_fila := cor_assento_a if (f / 3) % 2 == 0 else cor_assento_b
		cadeiras.append([Vector3(0, h + 0.13, z + 0.12), Vector3(comprimento, 0.26, 0.32), cor_fila])
		var n := int(comprimento / 0.55)
		for k in n:
			# vãos de acesso a cada ~16 m
			var x := -comprimento / 2.0 + 0.3 + k * 0.55
			if fmod(x + comprimento / 2.0, 16.0) < 1.2:
				continue
			if _rng.randf() > lotacao:
				continue
			var bandeira := 1.0 if _rng.randf() < 0.018 else 0.0
			var esc := Vector3(2.4, 1.0, 1.0) if bandeira > 0.5 else Vector3.ONE
			var pos := Vector3(x + _rng.randf_range(-0.08, 0.08), h + 0.62 + bandeira * 0.5, z + 0.05)
			var celular := 1.0 if _rng.randf() < 0.03 else 0.0
			pessoas.append([Transform3D(Basis().scaled(esc), pos), cores[_rng.randi() % cores.size()],
				Color(_rng.randf(), _rng.randf(), bandeira, celular)])
	_caixas(blocos, pivo)
	_caixas(cadeiras, pivo)
	var q := QuadMesh.new()
	q.size = Vector2(0.52, 0.86)
	var mmi := _lote(q, pessoas, pivo, _mat_torcida, true)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	torcida.append(mmi)
	return pivo


func _torcida_em_pe(centro: Vector3, rot_y: float, comprimento: float, filas: int, densidade: float, altura := 0.0) -> void:
	var pivo := Node3D.new()
	add_child(pivo)
	pivo.position = centro
	pivo.rotation.y = rot_y
	var cores := _cores_torcida()
	var pessoas: Array = []
	var n := int(comprimento / 0.5)
	for f in filas:
		for k in n:
			if _rng.randf() > densidade:
				continue
			var pos := Vector3(-comprimento / 2.0 + k * 0.5 + _rng.randf_range(-0.2, 0.2), altura + 0.86 + f * 0.18, -f * 0.6 + _rng.randf_range(-0.15, 0.15))
			pessoas.append([Transform3D(Basis().scaled(Vector3(1.0, 1.9, 1.0)), pos), cores[_rng.randi() % cores.size()],
				Color(_rng.randf(), _rng.randf(), 0.0, 0.0)])
	var q := QuadMesh.new()
	q.size = Vector2(0.55, 0.9)
	var mmi := _lote(q, pessoas, pivo, _mat_torcida, true)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	torcida.append(mmi)


## Faz a torcida pular (gol).
func festa_torcida(vezes := 6) -> void:
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _mat_torcida.set_shader_parameter("empolgacao", v), _empolgacao_base, 1.0, 0.25)
	tw.tween_interval(vezes * 0.3)
	tw.tween_method(func(v: float) -> void: _mat_torcida.set_shader_parameter("empolgacao", v), 1.0, _empolgacao_base, 1.2)


# ================================================================ estádio

func _estadio() -> void:
	var lotacao := 0.97 if cenario == "selecao" else 0.88
	var concreto := Color("5a606c") if noite else Color("9298a3")
	var filas_lado := 13
	var filas_fundo := 11
	# anel inferior
	_arquibancada(Vector3(0, 0, -45.5), 0.0, 76.0, filas_fundo, lotacao, 0.0, concreto)
	_arquibancada(Vector3(0, 0, 70.5), PI, 76.0, filas_fundo, lotacao, 0.0, concreto)
	_arquibancada(Vector3(-39.5, 0, 12.5), PI / 2.0, 112.0, filas_lado, lotacao, 0.0, concreto)
	_arquibancada(Vector3(39.5, 0, 12.5), -PI / 2.0, 112.0, filas_lado, lotacao, 0.0, concreto)
	# cantos fechando o anel
	for c in [[Vector3(-37, 0, -43), PI / 4.0], [Vector3(37, 0, -43), -PI / 4.0], [Vector3(-37, 0, 68), PI * 0.75], [Vector3(37, 0, 68), -PI * 0.75]]:
		_arquibancada(c[0], c[1], 14.0, filas_fundo - 2, lotacao, 0.0, concreto)
	# anel superior nas laterais
	var alto := filas_lado * 0.62 + 2.6
	_arquibancada(Vector3(-39.5 - filas_lado * 0.85 - 1.0, 0, 12.5), PI / 2.0, 104.0, 10, lotacao * 0.95, alto, concreto)
	_arquibancada(Vector3(39.5 + filas_lado * 0.85 + 1.0, 0, 12.5), -PI / 2.0, 104.0, 10, lotacao * 0.95, alto, concreto)
	# camarotes (faixa de vidro entre os anéis)
	var vidros: Array = []
	for lado: float in [-1.0, 1.0]:
		vidros.append([Vector3(lado * (39.5 + filas_lado * 0.85 + 0.5), alto - 1.0, 12.5), Vector3(0.3, 1.6, 104.0), Color("2b3d5c") if not noite else Color("ffe9b8")])
	_caixas(vidros, null, 1.6 if noite else 0.0)
	# cobertura com faixa de refletores
	var teto := Formas.mat(Color("2a2f3a"), 0.6, 0.0)
	var y_teto := alto + 10 * 0.62 + 4.0
	# refletores individuais (luminárias com espaço entre si, em vez de uma faixa contínua)
	var lampadas: Array = []
	var cor_lampada := Color("fff6dc") if noite else Color("d9dde3")
	for lado: float in [-1.0, 1.0]:
		var x := lado * 54.0
		var placa := _malha(Formas.caixa(Vector3(22.0, 0.5, 118.0)), Vector3(x, y_teto, 12.5), teto)
		placa.rotation.z = -lado * 0.1
		_malha(Formas.caixa(Vector3(0.6, 0.5, 116.0)), Vector3(lado * 43.3, y_teto - 0.75, 12.5), teto)
		for k in 26:
			lampadas.append([Vector3(lado * 43.0, y_teto - 1.05, -37.0 + k * 3.95), Vector3(0.35, 0.22, 1.6), cor_lampada])
		for k in 9:
			_malha(Formas.cilindro(0.25, 0.3, y_teto, 8), Vector3(lado * 64.0, y_teto / 2.0, -40.0 + k * 13.0), teto)
	for zf: float in [-56.0, 81.0]:
		var placa := _malha(Formas.caixa(Vector3(96.0, 0.5, 14.0)), Vector3(0, 13.5, zf), teto)
		placa.rotation.x = 0.08 * signf(zf)
		_malha(Formas.caixa(Vector3(90.0, 0.5, 0.6)), Vector3(0, 13.1, zf - signf(zf) * 6.8), teto)
		for k in 20:
			lampadas.append([Vector3(-42.75 + k * 4.5, 12.82, zf - signf(zf) * 6.6), Vector3(1.6, 0.22, 0.35), cor_lampada])
	_caixas(lampadas, null, 2.6 if noite else 0.25)
	# placas de LED
	var marcas := ["RAIO ENERGÉTICO", "PULSO", "BANCO ALVORADA", "TELECOM VOX", "GUARANÁ SERRA", "BETEL SEGUROS"]
	var cores_placa := [Color("0b1626"), Color("0d2b52"), Color("3b0d0d"), Color("0d3b22")]
	var placas: Array = []
	for k in 8:
		placas.append([Vector3(-31.5 + k * 9.0, 0.48, -42.4), Vector3(8.7, 0.92, 0.14), cores_placa[k % cores_placa.size()]])
	for k in 11:
		for lado: float in [-1.0, 1.0]:
			placas.append([Vector3(lado * 36.4, 0.48, -35.0 + k * 9.5), Vector3(0.14, 0.92, 9.2), cores_placa[(k + 1) % cores_placa.size()]])
	_caixas(placas, null, 1.8)
	for k in 8:
		var l := Label3D.new()
		l.text = marcas[k % marcas.size()]
		l.font = UI.fonte("display")
		l.font_size = 80
		l.pixel_size = 0.0078
		l.modulate = Color("ffffff") if k % 2 == 0 else Color("ffd84a")
		l.position = Vector3(-31.5 + k * 9.0, 0.48, -42.32)
		l.outline_size = 0
		add_child(l)
	_bancos_e_detalhes()


func _bancos_e_detalhes() -> void:
	var caixas: Array = []
	# bancos de reserva no lado direito
	for z: float in [4.0, 21.0]:
		caixas.append([Vector3(37.0, 0.45, z), Vector3(1.4, 0.9, 7.0), Color("20242c")])
		caixas.append([Vector3(36.6, 1.25, z), Vector3(0.1, 0.7, 7.0), Color("8fb7d6")])
	# fotógrafos atrás do gol
	for k in 10:
		caixas.append([Vector3(-15.0 + k * 3.3 + _rng.randf_range(-0.5, 0.5), 0.45, -43.0), Vector3(0.45, 0.9, 0.45), Color("1f2329")])
		caixas.append([Vector3(-15.0 + k * 3.3, 0.95, -42.8), Vector3(0.18, 0.15, 0.25), Color("111111")])
	# área técnica e túnel
	caixas.append([Vector3(37.8, 1.5, 12.5), Vector3(2.6, 3.0, 5.0), Color("1a1d24")])
	_caixas(caixas)


# ================================================================ CT da base

func _base() -> void:
	var pivo := _arquibancada(Vector3(-39.0, 0, 12.5), PI / 2.0, 60.0, 7, 0.45, 0.0, Color("8b8f99"))
	var cob := _malha(Formas.caixa(Vector3(60.0, 0.25, 8.0)), Vector3(0, 7.2, -2.0), Formas.mat(Color("cfd6df"), 0.5, 0.0), pivo)
	cob.rotation.x = 0.12
	var postes: Array = []
	for k in 6:
		postes.append([Vector3(-27.0 + k * 10.8, 3.6, -5.5), Vector3(0.18, 7.2, 0.18), Color("6b7480")])
	_caixas(postes, pivo)
	_torcida_em_pe(Vector3(0, 0, -45.0), 0.0, 36.0, 2, 0.25)
	# alambrado verde
	var tela := StandardMaterial3D.new()
	tela.albedo_color = Color(0.1, 0.32, 0.16, 0.55)
	tela.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tela.cull_mode = BaseMaterial3D.CULL_DISABLED
	_malha(Formas.caixa(Vector3(90, 2.8, 0.04)), Vector3(0, 1.4, -47.5), tela)
	_malha(Formas.caixa(Vector3(0.04, 2.8, 120)), Vector3(40, 1.4, 12.5), tela)
	# árvores (copas irregulares)
	var troncos: Array = []
	var copas: Array = []
	for k in 40:
		var pos := Vector3(_rng.randf_range(-48, 48), 0, -53 - _rng.randf_range(0, 14))
		if k >= 22:
			pos = Vector3(45 + _rng.randf_range(0, 12), 0, _rng.randf_range(-45, 70))
		var h := _rng.randf_range(2.0, 3.2)
		troncos.append([pos + Vector3(0, h / 2.0, 0), Vector3(0.35, h, 0.35), Color("5b3a22")])
		var verde := Color("1f4d22").lerp(Color("3a6f2c"), _rng.randf())
		for b in 4:
			var r := _rng.randf_range(1.6, 2.6)
			copas.append([pos + Vector3(_rng.randf_range(-1.2, 1.2), h + r * 0.8 + b * 0.7, _rng.randf_range(-1.2, 1.2)), Vector3(r, r * 0.85, r) * 2.0, verde.darkened(0.12 - b * 0.04)])
	_caixas(troncos)
	var itens: Array = []
	for c in copas:
		itens.append([Transform3D(Basis().scaled(c[1] * 0.5), c[0]), c[2]])
	_lote(Formas.esfera(1.0, 10, 6), itens)
	# prédio do CT com janelas
	var predio: Array = [[Vector3(10, 4.0, -64), Vector3(30, 8, 10), Color("e8e9ec")], [Vector3(10, 8.4, -64), Vector3(30.4, 0.8, 10.4), cor_casa]]
	var janelas: Array = []
	for andar in 2:
		for k in 9:
			janelas.append([Vector3(-2.0 + k * 3.0, 2.2 + andar * 3.4, -58.95), Vector3(1.8, 1.4, 0.08), Color("27384f") if not noite else Color("ffe3a3")])
	_caixas(predio)
	_caixas(janelas, null, 1.4 if noite else 0.0)
	var nome := Label3D.new()
	nome.text = "CENTRO DE TREINAMENTO"
	nome.font = UI.fonte("display")
	nome.font_size = 120
	nome.pixel_size = 0.012
	nome.modulate = Color("1a1d24")
	nome.position = Vector3(10, 6.6, -58.9)
	add_child(nome)
	# material de treino: cones, minigols e manequins
	var treino: Array = []
	for k in 10:
		treino.append([Vector3(28.0, 0.15, -10.0 + k * 2.0), Vector3(0.28, 0.3, 0.28), Color("ff6d00")])
	for k in 4:
		var x := -30.0 + k * 3.0
		treino.append([Vector3(x, 1.0, -22.0), Vector3(0.45, 1.8, 0.3), Color("ffd400")])
		treino.append([Vector3(x, 0.1, -22.0), Vector3(0.6, 0.2, 0.6), Color("222222")])
	treino.append([Vector3(28.5, 0.6, 30), Vector3(3.0, 1.2, 0.08), Color("eeeeee")])
	_caixas(treino)


# ================================================================ várzea

func _varzea() -> void:
	# muro pintado em volta do campo, com a torcida em pé e sentada nele
	var muro: Array = []
	var cores_muro := [Color("d9534f"), Color("f0ad4e"), Color("5bc0de"), Color("5cb85c"), Color("ffffff"), Color("9b59b6")]
	for k in 20:
		muro.append([Vector3(-38 + k * 4.0, 0.7, -43.5), Vector3(4.0, 1.4, 0.3), cores_muro[_rng.randi() % cores_muro.size()]])
	for k in 28:
		muro.append([Vector3(-38.5, 0.7, -42 + k * 4.0), Vector3(0.3, 1.4, 4.0), cores_muro[_rng.randi() % cores_muro.size()]])
	_caixas(muro)
	_torcida_em_pe(Vector3(0, 0, -44.6), 0.0, 70.0, 3, 0.55)
	_torcida_em_pe(Vector3(-39.6, 0, 12), PI / 2.0, 100.0, 3, 0.45)
	_torcida_em_pe(Vector3(37.5, 0, 0), -PI / 2.0, 70.0, 2, 0.3)
	# casas e lajes
	var casas: Array = []
	var detalhes: Array = []
	var vergalhoes: Array = []
	var gente_laje: Array = []
	var cores := [Color("b5653c"), Color("c47a4a"), Color("d8c7a8"), Color("8fb3c9"), Color("e4d36b"), Color("9cc27a"),
		Color("c96a7a"), Color("a0522d"), Color("eeeeee"), Color("b8b0a4")]
	# [origem, direção da fileira, quantidade, espaçamento, frente (virada para o campo)]
	var fileiras := [[Vector3(-46, 0, -51), Vector3(1, 0, 0), 30, 3.1, Vector3(0, 0, 1)],
		[Vector3(-47.5, 0, -44), Vector3(0, 0, 1), 26, 4.4, Vector3(1, 0, 0)],
		[Vector3(45.5, 0, -40), Vector3(0, 0, 1), 22, 4.6, Vector3(-1, 0, 0)]]
	for fi in fileiras:
		for k in int(fi[2]):
			var w := _rng.randf_range(4.0, 6.5)
			var d := _rng.randf_range(4.0, 6.0)
			var andares := _rng.randi_range(1, 3)
			var h := andares * 2.9
			var dir: Vector3 = fi[1]
			var frente: Vector3 = fi[4]
			var base_pos: Vector3 = fi[0] + dir * (k * float(fi[3])) - frente * (_rng.randf_range(0, 6) + d / 2.0)
			var rot := 0.0 if absf(frente.z) > 0.5 else PI / 2.0
			var cor: Color = cores[_rng.randi() % cores.size()]
			if _rng.randf() < 0.3:
				cor = Color("b0785a")  # tijolo sem reboco
			casas.append([base_pos + Vector3(0, h / 2.0, 0), Vector3(w, h, d), cor, rot])
			casas.append([base_pos + Vector3(0, h + 0.1, 0), Vector3(w + 0.2, 0.2, d + 0.2), Color("9a9a96"), rot])
			# janelas e porta viradas para o campo
			for a in andares:
				for jn in 2:
					var off := (jn - 0.5) * w * 0.45
					var lat := Vector3(-frente.z, 0, frente.x) * off
					detalhes.append([base_pos + frente * (d / 2.0 + 0.02) + lat + Vector3(0, 1.6 + a * 2.9, 0), Vector3(1.0, 0.9, 1.0), Color("2b3a4a") if not noite else Color("ffd98a"), rot])
			detalhes.append([base_pos + frente * (d / 2.0 + 0.02) + Vector3(0, 1.0, 0), Vector3(0.9, 2.0, 1.0), Color("6d4a2e"), rot])
			# vergalhões da laje
			if _rng.randf() < 0.6:
				for v in 4:
					var off2 := Vector3(_rng.randf_range(-w / 2.2, w / 2.2), 0, _rng.randf_range(-d / 2.2, d / 2.2))
					vergalhoes.append([base_pos + off2 + Vector3(0, h + 0.6, 0), Vector3(0.05, 1.1, 0.05), Color("6a4b3a")])
			# caixa d'água
			if _rng.randf() < 0.45:
				detalhes.append([base_pos + Vector3(_rng.randf_range(-1, 1), h + 0.8, 0), Vector3(1.5, 1.3, 1.5), Color("2f6fd0"), 0.0])
			# gente na laje
			if _rng.randf() < 0.35 and h < 6.5:
				for g in _rng.randi_range(1, 3):
					gente_laje.append(base_pos + Vector3(_rng.randf_range(-w / 3, w / 3), h + 0.2, _rng.randf_range(-d / 3, d / 3)))
	# portas e janelas usam o mesmo lote; janelas ficam finas na direção da parede
	var det_fix: Array = []
	for dd in detalhes:
		var t: Vector3 = dd[1]
		if t.x == 1.5:
			det_fix.append(dd)
		else:
			det_fix.append([dd[0], Vector3(t.x, t.y, 0.08), dd[2], dd[3]])
	_caixas(casas)
	_caixas(det_fix, null, 1.3 if noite else 0.0)
	_caixas(vergalhoes)
	if not gente_laje.is_empty():
		var cores_t := _cores_torcida()
		var itens: Array = []
		for p in gente_laje:
			itens.append([Transform3D(Basis().scaled(Vector3(1.0, 1.9, 1.0)), p + Vector3(0, 0.85, 0)), cores_t[_rng.randi() % cores_t.size()], Color(_rng.randf(), _rng.randf(), 0, 0)])
		var q := QuadMesh.new()
		q.size = Vector2(0.55, 0.9)
		var mmi := _lote(q, itens, null, _mat_torcida, true)
		torcida.append(mmi)
	# postes e fiação
	var fio := Formas.mat(Color("1a1a1a"), 0.8, 0.0)
	var postes := [Vector3(-36, 0, -46.5), Vector3(-12, 0, -46.5), Vector3(12, 0, -46.5), Vector3(36, 0, -46.5)]
	for p in postes:
		_malha(Formas.cilindro(0.12, 0.16, 8.5, 8), p + Vector3(0, 4.25, 0), Formas.mat(Color("7d7d7d"), 0.8, 0.0))
		_malha(Formas.caixa(Vector3(1.6, 0.1, 0.1)), p + Vector3(0, 8.0, 0), fio)
	for i in postes.size() - 1:
		for fios in 3:
			var a: Vector3 = postes[i] + Vector3(-0.6 + fios * 0.6, 8.05, 0)
			var b: Vector3 = postes[i + 1] + Vector3(-0.6 + fios * 0.6, 8.05, 0)
			for s in 8:
				var t0 := s / 8.0
				var t1 := (s + 1) / 8.0
				var p0 := a.lerp(b, t0) - Vector3(0, sin(t0 * PI) * 0.8, 0)
				var p1 := a.lerp(b, t1) - Vector3(0, sin(t1 * PI) * 0.8, 0)
				var seg := _malha(Formas.caixa(Vector3(0.025, 0.025, p0.distance_to(p1) + 0.02)), (p0 + p1) / 2.0, fio)
				seg.look_at_from_position(seg.position, p1, Vector3.UP)
	# varal de bandeirinhas
	var cores_b := [cor_casa, Color.WHITE, Color("2f6fd0"), Color("2ecc71"), Color("e74c3c")]
	var bands: Array = []
	for k in 46:
		var x := -34.0 + k * 1.5
		bands.append([Vector3(x, 5.2 - sin(float(k) / 46.0 * PI) * 0.9, -43.0), Vector3(0.5, 0.6, 0.02), cores_b[k % cores_b.size()]])
	_caixas(bands)
	# pipas no céu
	var cores_p := [Color("e74c3c"), Color("f1c40f"), Color("3498db"), Color("9b59b6"), Color("2ecc71")]
	for k in 5:
		var p := Node3D.new()
		add_child(p)
		p.position = Vector3(_rng.randf_range(-40, 40), _rng.randf_range(22, 34), _rng.randf_range(-80, -55))
		var q := QuadMesh.new()
		q.size = Vector2(1.4, 1.4)
		var m := Formas.mat(cores_p[k % cores_p.size()], 0.9, 0.0).duplicate()
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var pipa := _malha(q, Vector3.ZERO, m, p)
		pipa.rotation.z = PI / 4.0
		_malha(Formas.caixa(Vector3(0.04, 1.6, 0.02)), Vector3(0, -1.4, 0), fio, p)
		_pipas.append(p)
	# bar do Zé
	var bar: Array = [[Vector3(28, 1.7, -50), Vector3(8, 3.4, 5), Color("d9534f")], [Vector3(28, 3.0, -47.0), Vector3(8.6, 0.15, 1.8), Color("f0f0f0")]]
	for k in 4:
		bar.append([Vector3(25.5 + k * 1.7, 0.4, -46.0), Vector3(0.9, 0.08, 0.9), Color("e53935")])
		bar.append([Vector3(25.5 + k * 1.7, 0.2, -46.0), Vector3(0.1, 0.4, 0.1), Color("e53935")])
	_caixas(bar)
	var placa := Label3D.new()
	placa.text = "BAR DO ZÉ"
	placa.font = UI.fonte("display")
	placa.font_size = 160
	placa.pixel_size = 0.01
	placa.modulate = Color("fff3c4")
	placa.outline_size = 24
	placa.position = Vector3(28, 2.6, -47.4)
	add_child(placa)


# ================================================================ helpers

static var _sh_emissivo: Shader


static func _shader_emissivo() -> Shader:
	if _sh_emissivo == null:
		_sh_emissivo = Shader.new()
		_sh_emissivo.code = "shader_type spatial;\nuniform float energia = 1.0;\nvarying vec3 c;\nvoid vertex() { c = COLOR.rgb; }\nvoid fragment() { ALBEDO = c; EMISSION = c * energia; ROUGHNESS = 0.5; }\n"
	return _sh_emissivo

func _malha(mesh: Mesh, pos: Vector3, m: Material, pai: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	(pai if pai != null else self).add_child(mi)
	return mi


func _mat(cor: Color) -> StandardMaterial3D:
	return Formas.mat(cor, 0.9, 0.0)
