class_name Mundo3D
extends Node3D
## Constrói o cenário do jogo. A ambientação evolui com a carreira:
##   "varzea"  - campo de terra do bairro, torcida em pé, lajes e o bar do Zé
##   "base"    - CT de categoria de base: gramado, arquibancada pequena, árvores
##   "estadio" - estádio profissional com 4 arquibancadas, placas de LED e refletores
##   "selecao" - estádio lotado de verde e amarelo
## O gol atacado fica sempre em z = -40 (o jogador ataca na direção -Z).

const LINHA_GOL := -40.0
const LARGURA := 34.0

var cenario := "estadio"
var noite := false
var cor_casa := Color("ffc928")
var cor_fora := Color("c62828")
var torcida: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()


func construir(p_cenario: String, p_noite := false, p_casa := Color("ffc928"), p_fora := Color("c62828"), semente := 1) -> Mundo3D:
	cenario = p_cenario
	noite = p_noite
	cor_casa = p_casa
	cor_fora = p_fora
	_rng.seed = semente
	_ambiente()
	_gramado()
	_linhas()
	_gol(LINHA_GOL, 1)
	_gol(65.0, -1)
	match cenario:
		"varzea":
			_varzea()
		"base":
			_base()
		_:
			_estadio()
	return self


# ---------------------------------------------------------------- ambiente

func _ambiente() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var ceu := ProceduralSkyMaterial.new()
	if noite:
		ceu.sky_top_color = Color("070b1a")
		ceu.sky_horizon_color = Color("1d2a4a")
		ceu.ground_horizon_color = Color("1d2a4a")
		ceu.ground_bottom_color = Color("05070d")
		ceu.sun_angle_max = 1.0
	elif cenario == "varzea":
		ceu.sky_top_color = Color("3d5fa8")
		ceu.sky_horizon_color = Color("ffb27a")
		ceu.ground_horizon_color = Color("e8a06a")
		ceu.ground_bottom_color = Color("4a3a2a")
	else:
		ceu.sky_top_color = Color("2f63c4")
		ceu.sky_horizon_color = Color("bcd6f0")
		ceu.ground_horizon_color = Color("bcd6f0")
		ceu.ground_bottom_color = Color("3a3a3a")
	env.sky = Sky.new()
	env.sky.sky_material = ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55 if noite else 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	if noite:
		env.fog_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sol := DirectionalLight3D.new()
	sol.shadow_enabled = true
	sol.directional_shadow_max_distance = 70.0
	if noite:
		sol.rotation_degrees = Vector3(-62, 20, 0)
		sol.light_color = Color("dfe8ff")
		sol.light_energy = 1.05
	elif cenario == "varzea":
		sol.rotation_degrees = Vector3(-24, -55, 0)
		sol.light_color = Color("ffd2a0")
		sol.light_energy = 1.25
	else:
		sol.rotation_degrees = Vector3(-50, -35, 0)
		sol.light_color = Color("fff3e0")
		sol.light_energy = 1.2
	add_child(sol)


func _gramado() -> void:
	if cenario == "varzea":
		var terra_a := _mat(Color("9a6b45"))
		var terra_b := _mat(Color("8a5d3b"))
		for i in 12:
			var faixa := PlaneMesh.new()
			faixa.size = Vector2(100, 10)
			_malha(faixa, Vector3(0, 0, -46.0 + i * 10.0 + 5.0), terra_a if i % 2 == 0 else terra_b)
		# tufos de grama e manchas, típicos de campo de terra
		var grama := _mat(Color("6f8a3a"))
		for k in 70:
			var p := PlaneMesh.new()
			p.size = Vector2(_rng.randf_range(1.0, 4.0), _rng.randf_range(1.0, 3.0))
			var x := _rng.randf_range(-40, 40)
			if absf(x) < 25.0 and _rng.randf() < 0.7:
				x = signf(x + 0.01) * _rng.randf_range(25.0, 40.0)
			_malha(p, Vector3(x, 0.005, _rng.randf_range(-45, 60)), grama).rotation.y = _rng.randf() * PI
		var poca := _mat(Color("6e4a2e"))
		for k in 10:
			var p := PlaneMesh.new()
			p.size = Vector2(_rng.randf_range(2, 5), _rng.randf_range(1.5, 3.5))
			_malha(p, Vector3(_rng.randf_range(-20, 20), 0.004, _rng.randf_range(-35, 40)), poca).rotation.y = _rng.randf() * PI
	else:
		var a := _mat(Color("2f7d32") if not noite else Color("2a7030"))
		var b := _mat(Color("38903a") if not noite else Color("327f36"))
		for i in 12:
			var faixa := PlaneMesh.new()
			faixa.size = Vector2(100, 10)
			_malha(faixa, Vector3(0, 0, -46.0 + i * 10.0 + 5.0), a if i % 2 == 0 else b)


func _linhas() -> void:
	var cor := Color("f4f0e0") if cenario != "varzea" else Color("e8dcc0")
	var m := _mat(cor)
	var y := 0.012
	var segs := [
		[Vector3(-LARGURA, y, LINHA_GOL), Vector3(LARGURA, y, LINHA_GOL)],
		[Vector3(-LARGURA, y, 65), Vector3(LARGURA, y, 65)],
		[Vector3(-LARGURA, y, LINHA_GOL), Vector3(-LARGURA, y, 65)],
		[Vector3(LARGURA, y, LINHA_GOL), Vector3(LARGURA, y, 65)],
		[Vector3(-LARGURA, y, 12.5), Vector3(LARGURA, y, 12.5)],
		[Vector3(-20.16, y, -23.5), Vector3(20.16, y, -23.5)],
		[Vector3(-20.16, y, LINHA_GOL), Vector3(-20.16, y, -23.5)],
		[Vector3(20.16, y, LINHA_GOL), Vector3(20.16, y, -23.5)],
		[Vector3(-9.16, y, -34.5), Vector3(9.16, y, -34.5)],
		[Vector3(-9.16, y, LINHA_GOL), Vector3(-9.16, y, -34.5)],
		[Vector3(9.16, y, LINHA_GOL), Vector3(9.16, y, -34.5)],
		[Vector3(-20.16, y, 48.5), Vector3(20.16, y, 48.5)],
		[Vector3(-20.16, y, 65), Vector3(-20.16, y, 48.5)],
		[Vector3(20.16, y, 65), Vector3(20.16, y, 48.5)],
	]
	for s in segs:
		_linha(s[0], s[1], m)
	_arco(Vector3(0, y, 12.5), 9.15, 0.0, TAU, m, 40)
	# meia-lua da grande área
	_arco(Vector3(0, y, -29.0), 9.15, PI * 0.5 - 0.93, PI * 0.5 + 0.93, m, 14)
	_malha(_box(Vector3(0.28, 0.02, 0.28)), Vector3(0, y, -29), m)


func _linha(a: Vector3, b: Vector3, m: Material) -> void:
	var comp := a.distance_to(b) + 0.12
	var tam := Vector3(comp, 0.02, 0.12) if absf(a.x - b.x) > absf(a.z - b.z) else Vector3(0.12, 0.02, comp)
	_malha(_box(tam), (a + b) / 2.0, m)


func _arco(centro: Vector3, raio: float, de: float, ate: float, m: Material, partes: int) -> void:
	for k in partes:
		var a1 := lerpf(de, ate, float(k) / partes)
		var a2 := lerpf(de, ate, float(k + 1) / partes)
		var p1 := centro + Vector3(cos(a1) * raio, 0, -sin(a1) * raio)
		var p2 := centro + Vector3(cos(a2) * raio, 0, -sin(a2) * raio)
		var seg := _malha(_box(Vector3(0.12, 0.02, p1.distance_to(p2) + 0.05)), (p1 + p2) / 2.0, m)
		seg.look_at_from_position(seg.position, p2 + Vector3(0, 0, 0.0001), Vector3.UP)


func _gol(z: float, sentido: int) -> void:
	var branco := _mat(Color("f7f7f7"))
	for x in [-3.66, 3.66]:
		_malha(_box(Vector3(0.12, 2.44, 0.12)), Vector3(x, 1.22, z), branco)
	_malha(_box(Vector3(7.44, 0.12, 0.12)), Vector3(0, 2.44, z), branco)
	var rede := StandardMaterial3D.new()
	rede.albedo_color = Color(1, 1, 1, 0.22)
	rede.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rede.cull_mode = BaseMaterial3D.CULL_DISABLED
	rede.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var fundo := z - 2.0 * sentido
	_malha(_box(Vector3(7.32, 2.44, 0.02)), Vector3(0, 1.22, fundo), rede)
	_malha(_box(Vector3(7.32, 0.02, 2.0)), Vector3(0, 2.44, z - 1.0 * sentido), rede)
	for x in [-3.66, 3.66]:
		_malha(_box(Vector3(0.02, 2.44, 2.0)), Vector3(x, 1.22, z - 1.0 * sentido), rede)
	var cinza := _mat(Color("bbbbbb"))
	for x in [-3.66, 3.66]:
		_malha(_box(Vector3(0.06, 2.44, 0.06)), Vector3(x, 1.22, fundo), cinza)


# ---------------------------------------------------------------- cenários

func _varzea() -> void:
	# torcida em pé ao redor do campo
	_gente_em_pe(Vector3(-37, 0, 10), PI / 2.0, 90.0, 3, 0.5)
	_gente_em_pe(Vector3(0, 0, -44.5), 0.0, 60.0, 3, 0.55)
	_gente_em_pe(Vector3(37.5, 0, 0), -PI / 2.0, 70.0, 2, 0.35)
	# alambrado
	var arame := StandardMaterial3D.new()
	arame.albedo_color = Color(0.75, 0.75, 0.75, 0.25)
	arame.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arame.cull_mode = BaseMaterial3D.CULL_DISABLED
	_malha(_box(Vector3(80, 3.2, 0.03)), Vector3(0, 1.6, -43.2), arame)
	var poste := _mat(Color("6d6d6d"))
	for k in 17:
		_malha(_box(Vector3(0.08, 3.4, 0.08)), Vector3(-40 + k * 5, 1.7, -43.2), poste)
	# lajes e casas sem reboco
	var cores := [Color("b5653c"), Color("c47a4a"), Color("d8c7a8"), Color("8fb3c9"), Color("e4d36b"),
		Color("9cc27a"), Color("c96a7a"), Color("a0522d"), Color("eeeeee")]
	for k in 30:
		var h := _rng.randf_range(3.0, 10.0)
		var casa := _malha(_box(Vector3(_rng.randf_range(4, 7), h, _rng.randf_range(4, 6))),
			Vector3(-42 + k * 3.0 + _rng.randf_range(-0.8, 0.8), h / 2.0, -52 - _rng.randf_range(0, 8)), _mat(cores[_rng.randi() % cores.size()]))
		if _rng.randf() < 0.5:
			_malha(_box(Vector3(1.2, 1.2, 0.06)), casa.position + Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, h / 2.0 - 1.0), 2.6), _mat(Color("2b3a4a")))
	for k in 22:
		var h := _rng.randf_range(3.0, 9.0)
		_malha(_box(Vector3(_rng.randf_range(4, 7), h, _rng.randf_range(4, 6))),
			Vector3(-48 - _rng.randf_range(0, 8), h / 2.0, -42 + k * 4.8 + _rng.randf_range(-1, 1)), _mat(cores[_rng.randi() % cores.size()]))
	# caixa d'água azul em cima das lajes
	var azul := _mat(Color("2f6fd0"))
	for k in 8:
		var c := CylinderMesh.new()
		c.top_radius = 0.8
		c.bottom_radius = 0.8
		c.height = 1.1
		c.radial_segments = 10
		_malha(c, Vector3(-38 + k * 10 + _rng.randf_range(-2, 2), _rng.randf_range(7.0, 10.5), -54 - _rng.randf_range(0, 5)), azul)
	# bar do Zé
	var bar := _malha(_box(Vector3(8, 3.4, 5)), Vector3(28, 1.7, -50), _mat(Color("d9534f")))
	var placa := Label3D.new()
	placa.text = "BAR DO ZÉ"
	placa.font = UI.fonte("display")
	placa.font_size = 160
	placa.pixel_size = 0.01
	placa.modulate = Color("fff3c4")
	placa.outline_size = 24
	placa.position = bar.position + Vector3(0, 2.4, 2.6)
	add_child(placa)
	# varal de bandeirinhas
	var cores_b := [cor_casa, Color.WHITE, Color("2f6fd0"), Color("2ecc71"), Color("e74c3c")]
	for k in 40:
		var b := PlaneMesh.new()
		b.size = Vector2(0.5, 0.6)
		b.orientation = PlaneMesh.FACE_Z
		var bm := _mat(cores_b[k % cores_b.size()])
		bm.cull_mode = BaseMaterial3D.CULL_DISABLED
		var x := -30.0 + k * 1.5
		_malha(b, Vector3(x, 5.0 - sin(float(k) / 40.0 * PI) * 0.8, -42.8), bm)


func _base() -> void:
	_arquibancada(Vector3(-38, 0, -5), PI / 2.0, 70.0, 6, 0.55, Color("8b8f99"))
	_gente_em_pe(Vector3(0, 0, -45), 0.0, 40.0, 2, 0.3)
	# alambrado verde e árvores
	var tela := StandardMaterial3D.new()
	tela.albedo_color = Color(0.1, 0.35, 0.15, 0.55)
	tela.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_malha(_box(Vector3(90, 2.6, 0.04)), Vector3(0, 1.3, -47), tela)
	_malha(_box(Vector3(0.04, 2.6, 110)), Vector3(39, 1.3, 10), tela)
	var copa := _mat(Color("2e6b34"))
	var copa2 := _mat(Color("3d8443"))
	var tronco := _mat(Color("5b3a22"))
	for k in 36:
		var pos := Vector3(_rng.randf_range(-45, 45), 0, -52 - _rng.randf_range(0, 14))
		if k >= 22:
			pos = Vector3(43 + _rng.randf_range(0, 10), 0, _rng.randf_range(-45, 60))
		var h := _rng.randf_range(5, 9)
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = _rng.randf_range(1.6, 2.6)
		c.height = h
		c.radial_segments = 7
		_malha(_box(Vector3(0.3, 1.5, 0.3)), pos + Vector3(0, 0.75, 0), tronco)
		_malha(c, pos + Vector3(0, 1.5 + h / 2.0, 0), copa if k % 2 == 0 else copa2)
	# prédio do CT
	_malha(_box(Vector3(24, 6, 10)), Vector3(10, 3, -62), _mat(Color("e6e6e6")))
	var faixa := _malha(_box(Vector3(24.2, 1.2, 10.2)), Vector3(10, 5.0, -62), _mat(cor_casa))
	faixa.position.y = 5.2


func _estadio() -> void:
	var lotacao := 0.95 if cenario == "selecao" else 0.85
	var concreto := Color("4f5563") if noite else Color("8b8f99")
	_arquibancada(Vector3(0, 0, -47), 0.0, 84.0, 12, lotacao, concreto)
	_arquibancada(Vector3(-41, 0, 12), PI / 2.0, 120.0, 14, lotacao, concreto)
	_arquibancada(Vector3(41, 0, 12), -PI / 2.0, 120.0, 14, lotacao, concreto)
	_arquibancada(Vector3(0, 0, 72), PI, 84.0, 12, lotacao, concreto)
	# cobertura
	var teto := _mat(Color("2a2f3a"))
	_malha(_box(Vector3(90, 0.5, 9)), Vector3(0, 13.5, -55), teto)
	_malha(_box(Vector3(9, 0.5, 126)), Vector3(-49, 15, 12), teto)
	_malha(_box(Vector3(9, 0.5, 126)), Vector3(49, 15, 12), teto)
	# placas de LED com patrocinadores fictícios
	var marcas := ["RAIO ENERGÉTICO", "PULSO", "BANCO ALVORADA", "TELECOM VOX", "GUARANÁ SERRA", "BETEL SEGUROS"]
	var cores_placa := [Color("101820"), Color("0d2b52"), Color("3b0d0d"), Color("0d3b22")]
	for k in 8:
		var x := -31.5 + k * 9.0
		var placa := _malha(_box(Vector3(8.6, 0.9, 0.12)), Vector3(x, 0.45, -42.6), _mat_emissivo(cores_placa[k % cores_placa.size()], 0.6))
		var l := Label3D.new()
		l.text = marcas[k % marcas.size()]
		l.font = UI.fonte("display")
		l.font_size = 72
		l.pixel_size = 0.0085
		l.modulate = Color("ffffff") if k % 2 == 0 else Color("ffd84a")
		l.position = placa.position + Vector3(0, 0, 0.08)
		l.outline_size = 0
		add_child(l)
	for k in 10:
		var z := -36.0 + k * 10.0
		_malha(_box(Vector3(0.12, 0.9, 8.6)), Vector3(-36.6, 0.45, z), _mat_emissivo(cores_placa[k % cores_placa.size()], 0.5))
	# refletores
	var torre := _mat(Color("3a3f4a"))
	for p in [Vector3(-47, 0, -50), Vector3(47, 0, -50), Vector3(-47, 0, 70), Vector3(47, 0, 70)]:
		_malha(_box(Vector3(0.8, 30, 0.8)), p + Vector3(0, 15, 0), torre)
		var painel := _malha(_box(Vector3(6, 3, 0.5)), p + Vector3(0, 30, 0), _mat_emissivo(Color("fffbe6"), 3.5 if noite else 0.4))
		painel.look_at_from_position(painel.position, Vector3(0, 0, 10), Vector3.UP)
	if noite:
		for p in [Vector3(-30, 22, -20), Vector3(30, 22, -20)]:
			var luz := OmniLight3D.new()
			luz.position = p
			luz.omni_range = 60.0
			luz.light_energy = 0.9
			luz.light_color = Color("f4f6ff")
			luz.shadow_enabled = false
			add_child(luz)


func _arquibancada(centro: Vector3, rot_y: float, comprimento: float, filas: int, lotacao: float, cor_concreto: Color) -> void:
	var pivo := Node3D.new()
	add_child(pivo)
	pivo.position = centro
	pivo.rotation.y = rot_y
	var concreto := _mat(cor_concreto)
	var degrau := 0.75
	for f in filas:
		var h := (f + 1) * degrau
		_malha(_box(Vector3(comprimento, h, 1.0)), Vector3(0, h / 2.0, -f * 1.0), concreto, pivo)
	var cores := _cores_torcida()
	var pessoa := BoxMesh.new()
	pessoa.size = Vector3(0.45, 0.72, 0.35)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	pessoa.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = pessoa
	var por_fila := int(comprimento / 0.75)
	var lugares: Array[Transform3D] = []
	var cores_lugar: Array[Color] = []
	for f in filas:
		for k in por_fila:
			if _rng.randf() > lotacao:
				continue
			var pos := Vector3(-comprimento / 2.0 + 0.4 + k * 0.75 + _rng.randf_range(-0.12, 0.12),
				(f + 1) * degrau + 0.36, -f * 1.0 + _rng.randf_range(-0.1, 0.1))
			lugares.append(Transform3D(Basis(Vector3.UP, _rng.randf_range(-0.3, 0.3)), pos))
			cores_lugar.append(cores[_rng.randi() % cores.size()])
	mm.instance_count = lugares.size()
	for i in lugares.size():
		mm.set_instance_transform(i, lugares[i])
		mm.set_instance_color(i, cores_lugar[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	pivo.add_child(mmi)
	torcida.append(mmi)


func _gente_em_pe(centro: Vector3, rot_y: float, comprimento: float, filas: int, densidade: float) -> void:
	var pivo := Node3D.new()
	add_child(pivo)
	pivo.position = centro
	pivo.rotation.y = rot_y
	var cores := _cores_torcida()
	var pessoa := CapsuleMesh.new()
	pessoa.radius = 0.22
	pessoa.height = 1.65
	pessoa.radial_segments = 6
	pessoa.rings = 1
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	pessoa.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = pessoa
	var lugares: Array[Transform3D] = []
	var cores_lugar: Array[Color] = []
	var n := int(comprimento / 0.7)
	for f in filas:
		for k in n:
			if _rng.randf() > densidade:
				continue
			var pos := Vector3(-comprimento / 2.0 + k * 0.7 + _rng.randf_range(-0.25, 0.25), 0.83 + f * 0.25, -f * 0.8 + _rng.randf_range(-0.2, 0.2))
			lugares.append(Transform3D(Basis(), pos))
			cores_lugar.append(cores[_rng.randi() % cores.size()])
	mm.instance_count = lugares.size()
	for i in lugares.size():
		mm.set_instance_transform(i, lugares[i])
		mm.set_instance_color(i, cores_lugar[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	pivo.add_child(mmi)
	torcida.append(mmi)


func _cores_torcida() -> Array:
	if cenario == "selecao":
		return [Color("ffd400"), Color("ffd400"), Color("ffd400"), Color("1f9d3a"), Color("1f9d3a"), Color("1d3fa8"), Color.WHITE]
	return [cor_casa, cor_casa, cor_casa, cor_fora, Color.WHITE, Color("1d1d22"), Color("2f6fd0"), Color("d6d6d6")]


## Faz a torcida pular (gol).
func festa_torcida(vezes := 6) -> void:
	for t in torcida:
		var base_y := t.position.y
		var tw := create_tween().set_loops(vezes)
		tw.tween_property(t, "position:y", base_y + 0.35, 0.13)
		tw.tween_property(t, "position:y", base_y, 0.13)


# ---------------------------------------------------------------- helpers

func _malha(mesh: Mesh, pos: Vector3, m: Material, pai: Node3D = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	(pai if pai != null else self).add_child(mi)
	return mi


func _box(t: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = t
	return b


func _mat(cor: Color) -> StandardMaterial3D:
	return Jogador3D.mat(cor)


func _mat_emissivo(cor: Color, energia: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.emission_enabled = true
	m.emission = cor
	m.emission_energy_multiplier = energia
	return m
