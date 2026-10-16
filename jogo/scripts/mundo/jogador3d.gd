class_name Jogador3D
extends Node3D
## Jogador low-poly com animação procedural (corrida, chute, comemoração,
## queda) e visual customizável (pele, cabelo, chuteira, uniforme, número).

const PELES := [Color("4a2f22"), Color("6b4430"), Color("8d5b3e"), Color("b07b55"), Color("d9a77f"), Color("f0c9a6")]
const CORES_CABELO := [Color("141010"), Color("3b2416"), Color("6e4523"), Color("c9a25a"), Color("e8e0d0"), Color("c43b2c"), Color("2d6cdf")]
const ESTILOS_CABELO := ["Raspado", "Curto", "Black power", "Moicano", "Topete", "Tranças"]

static var _cache_mat := {}

var visual := {}  # pele, cabelo, cor_cabelo, chuteira
var camisa := Color.WHITE
var calcao := Color.BLACK
var meiao := Color.WHITE
var numero := 10

var _quadril: Node3D
var _perna_e: Node3D
var _perna_d: Node3D
var _braco_e: Node3D
var _braco_d: Node3D
var _tronco: Node3D
var _cabeca: Node3D
var _numero_label: Label3D

var _ultima_pos := Vector3.ZERO
var _fase := 0.0
var _vel := 0.0
var pose := ""  # "", "chute", "comemora_*", "caido", "goleiro"
var _t_pose := 0.0
var mostrar_corpo_superior := true:
	set(v):
		mostrar_corpo_superior = v
		if _tronco:
			_tronco.visible = v
			_cabeca.visible = v
			_braco_e.visible = v
			_braco_d.visible = v


static func mat(cor: Color) -> StandardMaterial3D:
	var chave := cor.to_html()
	if _cache_mat.has(chave):
		return _cache_mat[chave]
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.85
	_cache_mat[chave] = m
	return m


func configurar(p_camisa: Color, p_calcao: Color, p_visual := {}, p_numero := 10, p_meiao := Color.WHITE) -> Jogador3D:
	camisa = p_camisa
	calcao = p_calcao
	meiao = p_meiao
	visual = p_visual.duplicate()
	numero = p_numero
	_construir()
	return self


func _construir() -> void:
	for c in get_children():
		c.queue_free()
	var pele: Color = PELES[clampi(int(visual.get("pele", 2)), 0, PELES.size() - 1)]
	var ch = visual.get("chuteira", Color("111111"))
	var chuteira: Color = Color(ch) if ch is String else ch
	var m_pele := mat(pele)

	_quadril = Node3D.new()
	_quadril.position = Vector3(0, 0.86, 0)
	add_child(_quadril)
	_perna_e = _criar_perna(-0.11, m_pele, chuteira)
	_perna_d = _criar_perna(0.11, m_pele, chuteira)
	_malha(_box(Vector3(0.44, 0.3, 0.27)), Vector3(0, 0.03, 0), mat(calcao), _quadril)

	_tronco = Node3D.new()
	_tronco.position = Vector3(0, 0.14, 0)
	_quadril.add_child(_tronco)
	var torso := CapsuleMesh.new()
	torso.radius = 0.235
	torso.height = 0.74
	torso.radial_segments = 8
	torso.rings = 2
	_malha(torso, Vector3(0, 0.3, 0), mat(camisa), _tronco)
	# gola
	_malha(_box(Vector3(0.2, 0.05, 0.2)), Vector3(0, 0.66, 0), mat(camisa.darkened(0.35)), _tronco)

	_braco_e = _criar_braco(-0.31, m_pele)
	_braco_d = _criar_braco(0.31, m_pele)

	_cabeca = Node3D.new()
	_cabeca.position = Vector3(0, 0.77, 0)
	_tronco.add_child(_cabeca)
	var esfera := SphereMesh.new()
	esfera.radius = 0.14
	esfera.height = 0.29
	esfera.radial_segments = 10
	esfera.rings = 5
	_malha(esfera, Vector3(0, 0.0, 0), m_pele, _cabeca)
	_criar_cabelo()

	_numero_label = Label3D.new()
	_numero_label.text = str(numero)
	_numero_label.font = UI.fonte("display")
	_numero_label.font_size = 96
	_numero_label.pixel_size = 0.0028
	_numero_label.outline_size = 0
	_numero_label.modulate = camisa.darkened(0.6) if camisa.get_luminance() > 0.45 else Color(1, 1, 1, 0.95)
	_numero_label.position = Vector3(0, 0.36, 0.238)
	_numero_label.rotation.y = 0.0
	_tronco.add_child(_numero_label)
	mostrar_corpo_superior = mostrar_corpo_superior
	_ultima_pos = global_position if is_inside_tree() else position


func _criar_perna(x: float, m_pele: Material, chuteira: Color) -> Node3D:
	var piv := Node3D.new()
	piv.position = Vector3(x, 0, 0)
	_quadril.add_child(piv)
	_malha(_box(Vector3(0.13, 0.36, 0.13)), Vector3(0, -0.2, 0), m_pele, piv)
	_malha(_box(Vector3(0.14, 0.38, 0.14)), Vector3(0, -0.58, 0), mat(meiao), piv)
	_malha(_box(Vector3(0.15, 0.09, 0.27)), Vector3(0, -0.81, -0.05), mat(chuteira), piv)
	return piv


func _criar_braco(x: float, m_pele: Material) -> Node3D:
	var piv := Node3D.new()
	piv.position = Vector3(x, 0.58, 0)
	_tronco.add_child(piv)
	_malha(_box(Vector3(0.13, 0.2, 0.14)), Vector3(0, -0.08, 0), mat(camisa), piv)
	_malha(_box(Vector3(0.1, 0.42, 0.1)), Vector3(0, -0.33, 0), m_pele, piv)
	return piv


func _criar_cabelo() -> void:
	var estilo := int(visual.get("cabelo", 1))
	var cor: Color = CORES_CABELO[clampi(int(visual.get("cor_cabelo", 0)), 0, CORES_CABELO.size() - 1)]
	var m := mat(cor)
	match estilo:
		0:
			pass
		1:
			var s := SphereMesh.new()
			s.radius = 0.148
			s.height = 0.17
			s.radial_segments = 10
			s.rings = 3
			s.is_hemisphere = true
			_malha(s, Vector3(0, 0.03, 0.005), m, _cabeca)
		2:
			var s := SphereMesh.new()
			s.radius = 0.21
			s.height = 0.36
			s.radial_segments = 10
			s.rings = 5
			_malha(s, Vector3(0, 0.1, 0.03), m, _cabeca)
		3:
			_malha(_box(Vector3(0.06, 0.1, 0.3)), Vector3(0, 0.15, 0.02), m, _cabeca)
		4:
			var s := SphereMesh.new()
			s.radius = 0.15
			s.height = 0.16
			s.is_hemisphere = true
			s.radial_segments = 10
			s.rings = 3
			_malha(s, Vector3(0, 0.03, 0.0), m, _cabeca)
			_malha(_box(Vector3(0.2, 0.09, 0.16)), Vector3(0, 0.15, -0.06), m, _cabeca)
		5:
			var s := SphereMesh.new()
			s.radius = 0.15
			s.height = 0.17
			s.is_hemisphere = true
			s.radial_segments = 10
			s.rings = 3
			_malha(s, Vector3(0, 0.03, 0.0), m, _cabeca)
			for k in 5:
				var ang := -0.6 + k * 0.3
				_malha(_box(Vector3(0.035, 0.22, 0.035)), Vector3(sin(ang) * 0.14, -0.06, cos(ang) * 0.12), m, _cabeca)


func _malha(mesh: Mesh, pos: Vector3, m: Material, pai: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	pai.add_child(mi)
	return mi


func _box(t: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = t
	return b


# ---------------------------------------------------------------- animação

func fazer_pose(nome: String) -> void:
	pose = nome
	_t_pose = 0.0


func _process(delta: float) -> void:
	if _quadril == null or delta <= 0.0:
		return
	var p := global_position
	var desloc := Vector2(p.x - _ultima_pos.x, p.z - _ultima_pos.z).length()
	_ultima_pos = p
	_vel = lerpf(_vel, desloc / delta, clampf(delta * 10.0, 0.0, 1.0))
	_t_pose += delta
	var corrida := clampf(_vel / 6.0, 0.0, 1.0)
	_fase += delta * (4.0 + _vel * 1.6)
	var balanco := sin(_fase) * 0.85 * corrida
	var respira := sin(_t_pose * 2.2) * 0.03

	var pe := 0.0
	var pd := 0.0
	var be := -balanco * 0.8
	var bd := balanco * 0.8
	var be_z := 0.12
	var bd_z := -0.12
	var inclina := -0.12 * corrida
	var altura := 0.86 + absf(sin(_fase)) * 0.05 * corrida
	pe = balanco
	pd = -balanco
	match pose:
		"chute":
			# perna direita: recua e chuta
			var t := _t_pose
			pd = (-0.9 * clampf(t / 0.18, 0.0, 1.0)) if t < 0.18 else lerpf(-0.9, 1.25, clampf((t - 0.18) / 0.12, 0.0, 1.0))
			be_z = 0.6
			bd_z = -0.5
			inclina = 0.08
			if t > 0.7:
				pose = ""
		"comemora_bracos":
			be_z = 2.6 + sin(_t_pose * 9.0) * 0.15
			bd_z = -2.6 - sin(_t_pose * 9.0) * 0.15
			be = 0.0
			bd = 0.0
			altura += absf(sin(_t_pose * 6.0)) * 0.12
		"comemora_aviao":
			be_z = 1.5
			bd_z = -1.5
			be = 0.0
			bd = 0.0
			inclina = -0.25
		"comemora_joelho":
			pe = -1.5
			pd = -1.5
			altura = 0.5
			be_z = 2.4
			bd_z = -2.4
			inclina = -0.35
		"comemora_coracao":
			be = 1.6
			bd = 1.6
			be_z = -0.5
			bd_z = 0.5
		"comemora_danca":
			var s := sin(_t_pose * 10.0)
			pe = s * 0.5
			pd = -s * 0.5
			be_z = 1.2 + s * 0.6
			bd_z = -1.2 + s * 0.6
			_tronco.rotation.y = s * 0.3
		"comemora_silencio":
			bd = 2.0
			bd_z = 0.35
			be = 0.2
		"lamenta":
			be = 2.4
			bd = 2.4
			be_z = 0.4
			bd_z = -0.4
			inclina = 0.15
		"goleiro":
			be_z = 0.9
			bd_z = -0.9
			pe = -0.25
			pd = -0.25
			altura = 0.78
			inclina = 0.2
	if pose != "comemora_danca":
		_tronco.rotation.y = 0.0
	_perna_e.rotation.x = pe
	_perna_d.rotation.x = pd
	_braco_e.rotation.x = be
	_braco_d.rotation.x = bd
	# be_z/bd_z: valores positivos (esq.) e negativos (dir.) abrem os braços para fora.
	_braco_e.rotation.z = -(be_z + respira)
	_braco_d.rotation.z = -(bd_z - respira)
	_tronco.rotation.x = inclina
	_quadril.position.y = altura
