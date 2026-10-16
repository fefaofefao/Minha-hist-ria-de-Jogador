class_name Jogador3D
extends Node3D
## Jogador estilizado com corpo suave (sólidos de revolução), articulações de
## joelho e cotovelo, rosto, cabelos, camisa com estampa e animação procedural
## (corrida, chute, comemorações, postura de goleiro).
## A frente do jogador é -Z (convenção do look_at).

const PELES := [Color("4a2f22"), Color("6b4430"), Color("8d5b3e"), Color("b07b55"), Color("d9a77f"), Color("f0c9a6")]
const CORES_CABELO := [Color("141010"), Color("3b2416"), Color("6e4523"), Color("c9a25a"), Color("e8e0d0"), Color("c43b2c"), Color("2d6cdf")]
const ESTILOS_CABELO := ["Raspado", "Curto", "Black power", "Moicano", "Topete", "Tranças"]
const ALTURA_QUADRIL := 0.92

var visual := {}  # pele, cabelo, cor_cabelo, chuteira
var camisa := Color.WHITE
var calcao := Color.BLACK
var meiao := Color.WHITE
var numero := 10
var estilo_camisa := "liso"
var cor2_camisa := Color.WHITE
var goleiro := false

var _quadril: Node3D
var _tronco: Node3D
var _cabeca: Node3D
var _coxa := [null, null]
var _canela := [null, null]
var _pe := [null, null]
var _ombro := [null, null]
var _cotovelo := [null, null]
var _numero_label: Label3D
var _sombra: MeshInstance3D
var _so_terceira_pessoa: Array[Node3D] = []  # escondidos em primeira pessoa

var _ultima_pos := Vector3.ZERO
var _fase := 0.0
var _vel := 0.0
var pose := ""
var _t_pose := 0.0
var mostrar_corpo_superior := true:
	set(v):
		mostrar_corpo_superior = v
		for n in _so_terceira_pessoa:
			if is_instance_valid(n):
				n.visible = v


## Compatibilidade com o resto do jogo: material simples por cor (sem contorno).
static func mat(cor: Color) -> StandardMaterial3D:
	return Formas.mat(cor, 0.9, 0.0)


func configurar(p_camisa: Color, p_calcao: Color, p_visual := {}, p_numero := 10, p_meiao := Color.WHITE,
		p_estilo := "liso", p_cor2 := Color(0, 0, 0, 0)) -> Jogador3D:
	camisa = p_camisa
	calcao = p_calcao
	meiao = p_meiao
	visual = p_visual.duplicate()
	numero = p_numero
	estilo_camisa = p_estilo
	cor2_camisa = p_cor2 if p_cor2.a > 0.0 else p_calcao
	goleiro = p_numero == 1
	_construir()
	return self


func _construir() -> void:
	for c in get_children():
		c.queue_free()
	_so_terceira_pessoa.clear()
	var pele: Color = PELES[clampi(int(visual.get("pele", 2)), 0, PELES.size() - 1)]
	var ch = visual.get("chuteira", Color("111111"))
	var chuteira: Color = Color(ch) if ch is String else ch
	var m_pele := Formas.mat(pele, 0.72, 0.12)
	var m_camisa: StandardMaterial3D = Formas.mat_textura(Formas.textura_camisa(camisa, cor2_camisa, estilo_camisa)) if estilo_camisa != "liso" else Formas.mat(camisa, 0.88)
	var m_manga := Formas.mat(camisa, 0.88)
	var m_calcao := Formas.mat(calcao, 0.85)
	var m_meiao := Formas.mat(meiao, 0.9)
	var m_chuteira := Formas.mat(chuteira, 0.35, 0.5)
	var m_sola := Formas.mat(chuteira.darkened(0.55), 0.6, 0.0)

	_quadril = _no(self, Vector3(0, ALTURA_QUADRIL, 0))
	# calção
	var perfil_calcao := PackedVector2Array([Vector2(-0.12, 0.0), Vector2(-0.12, 0.17), Vector2(-0.04, 0.178), Vector2(0.06, 0.172), Vector2(0.12, 0.162), Vector2(0.135, 0.0)])
	_so_terceira_pessoa.append(_malha(Formas.torno("calcao2", perfil_calcao, 16, Vector2(1.15, 0.78)), Vector3.ZERO, m_calcao, _quadril))
	# pernas
	for i in 2:
		var lado := -1.0 if i == 0 else 1.0
		var coxa := _no(_quadril, Vector3(lado * 0.095, -0.04, 0))
		_coxa[i] = coxa
		_so_terceira_pessoa.append(_malha(Formas.membro(0.2, 0.1, 0.1), Vector3(0, 0.02, 0), m_calcao, coxa))
		_so_terceira_pessoa.append(_malha(Formas.membro(0.42, 0.086, 0.06, 12, Vector2.ONE, 0.012), Vector3.ZERO, m_pele, coxa))
		var canela := _no(coxa, Vector3(0, -0.42, 0))
		_canela[i] = canela
		_malha(Formas.membro(0.4, 0.062, 0.046, 12, Vector2(1.0, 1.08), 0.016), Vector3.ZERO, m_meiao, canela)
		var pe := _no(canela, Vector3(0, -0.41, 0))
		_pe[i] = pe
		var bota := _malha(Formas.membro(0.25, 0.052, 0.046, 12, Vector2(0.95, 0.72)), Vector3(0, -0.035, 0.065), m_chuteira, pe)
		bota.rotation.x = PI / 2.0  # bico para a frente (-Z)
		var sola := _malha(Formas.caixa(Vector3(0.095, 0.018, 0.27)), Vector3(0, -0.071, -0.055), m_sola, pe)
		sola.name = "sola"
	# tronco
	_tronco = _no(_quadril, Vector3(0, 0.07, 0))
	var perfil_tronco := PackedVector2Array([Vector2(-0.06, 0.0), Vector2(-0.06, 0.158), Vector2(0.05, 0.162), Vector2(0.2, 0.175),
		Vector2(0.34, 0.205), Vector2(0.46, 0.225), Vector2(0.53, 0.218), Vector2(0.58, 0.17), Vector2(0.61, 0.1), Vector2(0.62, 0.0)])
	_so_terceira_pessoa.append(_malha(Formas.torno("tronco2", perfil_tronco, 20, Vector2(1.27, 0.68)), Vector3.ZERO, m_camisa, _tronco))
	var gola := _malha(Formas.cilindro(0.064, 0.074, 0.03, 14), Vector3(0, 0.6, 0), Formas.mat(cor2_camisa if estilo_camisa != "liso" else camisa.darkened(0.3), 0.8), _tronco)
	_so_terceira_pessoa.append(gola)
	# braços
	for i in 2:
		var lado := -1.0 if i == 0 else 1.0
		var ombro := _no(_tronco, Vector3(lado * 0.255, 0.49, 0))
		_ombro[i] = ombro
		_so_terceira_pessoa.append(ombro)
		var esf := _malha(Formas.esfera(0.085, 12, 6), Vector3(-lado * 0.012, 0.01, 0), m_manga, ombro)
		esf.scale = Vector3(1.0, 0.9, 0.95)
		_malha(Formas.membro(0.18 if not goleiro else 0.28, 0.082, 0.072), Vector3.ZERO, m_manga, ombro)
		_malha(Formas.membro(0.28, 0.064, 0.052, 12, Vector2.ONE, 0.006), Vector3.ZERO, m_pele, ombro)
		var cotovelo := _no(ombro, Vector3(0, -0.28, 0))
		_cotovelo[i] = cotovelo
		_malha(Formas.membro(0.25, 0.052, 0.04, 12, Vector2.ONE, 0.006), Vector3.ZERO, m_manga if goleiro else m_pele, cotovelo)
		var mao := _malha(Formas.esfera(0.065 if goleiro else 0.05, 10, 6), Vector3(0, -0.29, 0), Formas.mat(Color("f2f2f2"), 0.7) if goleiro else m_pele, cotovelo)
		mao.scale = Vector3(0.85, 1.15, 0.65)
	# pescoço e cabeça
	var pescoco := _malha(Formas.membro(0.07, 0.058, 0.066), Vector3(0, 0.68, 0), m_pele, _tronco)
	_so_terceira_pessoa.append(pescoco)
	_cabeca = _no(_tronco, Vector3(0, 0.78, 0))
	_so_terceira_pessoa.append(_cabeca)
	_criar_rosto(pele, m_pele)
	_criar_cabelo(pele)
	# número nas costas
	_numero_label = Label3D.new()
	_numero_label.text = str(numero)
	_numero_label.font = UI.fonte("display")
	_numero_label.font_size = 110
	_numero_label.pixel_size = 0.0022
	_numero_label.outline_size = 0
	var lum := camisa.get_luminance()
	_numero_label.modulate = camisa.darkened(0.7) if lum > 0.5 else Color(1, 1, 1, 0.95)
	_numero_label.position = Vector3(0, 0.34, 0.156)
	_numero_label.double_sided = false
	_tronco.add_child(_numero_label)
	_so_terceira_pessoa.append(_numero_label)
	# sombra de contato
	_sombra = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.95, 0.95)
	_sombra.mesh = q
	_sombra.material_override = Formas.mat_sombra()
	_sombra.top_level = true
	_sombra.rotation.x = -PI / 2.0
	_sombra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_sombra)
	mostrar_corpo_superior = mostrar_corpo_superior
	_ultima_pos = global_position if is_inside_tree() else position


func _criar_rosto(pele: Color, m_pele: Material) -> void:
	var cabeca := _malha(Formas.esfera(0.118, 20, 12), Vector3.ZERO, m_pele, _cabeca)
	cabeca.scale = Vector3(0.92, 1.07, 1.0)
	var queixo := _malha(Formas.esfera(0.088, 16, 8), Vector3(0, -0.042, -0.016), m_pele, _cabeca)
	queixo.scale = Vector3(0.9, 0.68, 0.95)
	for lado: float in [-1.0, 1.0]:
		var orelha := _malha(Formas.esfera(0.026, 8, 5), Vector3(lado * 0.108, -0.005, 0.005), m_pele, _cabeca)
		orelha.scale = Vector3(0.55, 1.0, 0.8)
		var olho := _malha(Formas.esfera(0.021, 10, 6), Vector3(lado * 0.041, 0.016, -0.1), Formas.mat(Color("f4f1ea"), 0.4, 0.0), _cabeca)
		olho.scale = Vector3(1.25, 0.85, 0.55)
		_malha(Formas.esfera(0.0125, 8, 5), Vector3(lado * 0.041, 0.015, -0.11), Formas.mat(Color("2a1a10"), 0.3, 0.0), _cabeca)
		var cor_cab: Color = CORES_CABELO[clampi(int(visual.get("cor_cabelo", 0)), 0, CORES_CABELO.size() - 1)]
		var sobr := _malha(Formas.caixa(Vector3(0.048, 0.013, 0.014)), Vector3(lado * 0.042, 0.047, -0.106), Formas.mat(cor_cab.darkened(0.25), 0.9, 0.0), _cabeca)
		sobr.rotation.z = -lado * 0.14
	var nariz := _malha(Formas.esfera(0.02, 8, 5), Vector3(0, -0.012, -0.116), Formas.mat(pele.darkened(0.06), 0.6, 0.0), _cabeca)
	nariz.scale = Vector3(0.8, 1.15, 1.0)
	_malha(Formas.caixa(Vector3(0.04, 0.006, 0.008)), Vector3(0, -0.058, -0.101), Formas.mat(pele.darkened(0.4).lerp(Color("7a2f2a"), 0.3), 0.7, 0.0), _cabeca)


func _criar_cabelo(pele: Color) -> void:
	var estilo := int(visual.get("cabelo", 1))
	var cor: Color = CORES_CABELO[clampi(int(visual.get("cor_cabelo", 0)), 0, CORES_CABELO.size() - 1)]
	var m := Formas.mat(cor, 0.75, 0.3)
	var m_curto := Formas.mat(cor.lerp(pele, 0.45), 0.9, 0.1)
	match estilo:
		0:
			var c := _malha(Formas.esfera(0.121, 18, 9, true), Vector3(0, 0.006, 0.004), m_curto, _cabeca)
			c.scale = Vector3(0.95, 0.85, 1.03)
		1:
			var c := _malha(Formas.esfera(0.126, 18, 9, true), Vector3(0, 0.01, 0.006), m, _cabeca)
			c.scale = Vector3(0.96, 0.92, 1.04)
			var franja := _malha(Formas.esfera(0.06, 10, 6), Vector3(0, 0.082, -0.082), m, _cabeca)
			franja.scale = Vector3(1.55, 0.45, 0.75)
		2:
			var base := _malha(Formas.esfera(0.165, 16, 10), Vector3(0, 0.06, 0.02), m, _cabeca)
			base.scale = Vector3(1.0, 0.92, 1.0)
			for k in 12:
				var a := TAU * k / 12.0
				var alt := 0.02 + (k % 3) * 0.045
				_malha(Formas.esfera(0.06, 8, 5), Vector3(cos(a) * 0.14, 0.05 + alt, 0.02 + sin(a) * 0.14), m, _cabeca)
		3:
			var c := _malha(Formas.esfera(0.121, 18, 9, true), Vector3(0, 0.006, 0.004), m_curto, _cabeca)
			c.scale = Vector3(0.95, 0.85, 1.03)
			for k in 6:
				var z := -0.085 + k * 0.034
				var cone := _malha(Formas.cilindro(0.0, 0.03, 0.1, 8), Vector3(0, 0.125 - absf(z) * 0.25, z), m, _cabeca)
				cone.rotation.x = 0.35
		4:
			var c := _malha(Formas.esfera(0.125, 18, 9, true), Vector3(0, 0.008, 0.006), m, _cabeca)
			c.scale = Vector3(0.96, 0.88, 1.03)
			var topete := _malha(Formas.esfera(0.075, 12, 8), Vector3(0, 0.115, -0.05), m, _cabeca)
			topete.scale = Vector3(1.15, 0.85, 1.55)
			topete.rotation.x = -0.35
		5:
			var c := _malha(Formas.esfera(0.126, 18, 9, true), Vector3(0, 0.01, 0.006), m, _cabeca)
			c.scale = Vector3(0.96, 0.92, 1.04)
			for k in 7:
				var a := lerpf(-1.1, 1.1, k / 6.0)
				var tr := _no(_cabeca, Vector3(sin(a) * 0.1, 0.02, 0.04 + cos(a) * 0.07))
				_malha(Formas.membro(0.2, 0.017, 0.013, 6), Vector3.ZERO, m, tr)
				tr.rotation = Vector3(0.35, 0, -sin(a) * 0.25)


func _no(pai: Node3D, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	pai.add_child(n)
	return n


func _malha(mesh: Mesh, pos: Vector3, m: Material, pai: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	pai.add_child(mi)
	return mi


# ---------------------------------------------------------------- animação

func fazer_pose(nome: String) -> void:
	pose = nome
	_t_pose = 0.0


func _process(delta: float) -> void:
	if _quadril == null or delta <= 0.0:
		return
	var p := global_position
	_sombra.global_position = Vector3(p.x, 0.012, p.z)
	var desloc := Vector2(p.x - _ultima_pos.x, p.z - _ultima_pos.z).length()
	_ultima_pos = p
	_vel = lerpf(_vel, desloc / delta, clampf(delta * 10.0, 0.0, 1.0))
	_t_pose += delta
	var k := clampf(_vel / 6.0, 0.0, 1.0)
	_fase += delta * (3.0 + _vel * 1.55)
	var s := sin(_fase)
	var respira := sin(_t_pose * 2.0) * 0.025

	# corrida / parado (base)
	var coxa := [s * 0.78 * k, -s * 0.78 * k]
	var joelho := [-(0.08 + (0.5 + 0.5 * sin(_fase + 1.7)) * 1.15 * k), -(0.08 + (0.5 + 0.5 * sin(_fase + 1.7 + PI)) * 1.15 * k)]
	var tornozelo := [0.0, 0.0]
	var braco_x := [-s * 0.7 * k, s * 0.7 * k]
	var abertura := [0.1 + respira, 0.1 + respira]
	var cotovelo := [0.25 + 0.95 * k, 0.25 + 0.95 * k]
	var inclina := -0.14 * k + respira * 0.4
	var giro := s * 0.14 * k
	var altura := ALTURA_QUADRIL + absf(s) * 0.05 * k - 0.02 * k
	var cabeca_x := 0.0
	var t := _t_pose
	match pose:
		"chute":
			var antes := clampf(t / 0.17, 0.0, 1.0)
			var contato := clampf((t - 0.17) / 0.12, 0.0, 1.0)
			coxa[1] = lerpf(-0.75 * antes, 1.25, contato) if t > 0.17 else -0.75 * antes
			joelho[1] = lerpf(-1.3 * antes, -0.15, contato) if t > 0.17 else -1.3 * antes
			coxa[0] = 0.1
			joelho[0] = -0.2
			abertura = [0.9, 0.7]
			braco_x = [0.3, -0.4]
			cotovelo = [0.6, 0.6]
			inclina = 0.12
			giro = -0.25 * antes + 0.35 * contato
			if t > 0.75:
				pose = ""
		"toque":
			var u := sin(clampf(t / 0.28, 0.0, 1.0) * PI)
			coxa[1] = u * 0.55
			joelho[1] = -u * 0.65
			tornozelo[1] = u * 0.3
			if t > 0.3:
				pose = ""
		"comemora_bracos":
			abertura = [2.6 + sin(t * 9.0) * 0.12, 2.6 - sin(t * 9.0) * 0.12]
			braco_x = [0.0, 0.0]
			cotovelo = [0.2, 0.2]
			altura += absf(sin(t * 6.0)) * 0.14
			cabeca_x = -0.3
		"comemora_aviao":
			abertura = [1.5, 1.5]
			braco_x = [0.0, 0.0]
			cotovelo = [0.05, 0.05]
			inclina = -0.3
			giro = sin(t * 2.0) * 0.25
		"comemora_joelho":
			coxa = [-0.15, -0.15]
			joelho = [-1.55, -1.55]
			altura = 0.52
			abertura = [2.5, 2.5]
			braco_x = [0.0, 0.0]
			cotovelo = [0.15, 0.15]
			inclina = 0.3
			cabeca_x = -0.45
		"comemora_coracao":
			braco_x = [1.35, 1.35]
			cotovelo = [1.3, 1.3]
			abertura = [-0.35, -0.35]
		"comemora_danca":
			var d := sin(t * 10.0)
			coxa = [d * 0.4, -d * 0.4]
			joelho = [-0.4 - d * 0.3, -0.4 + d * 0.3]
			abertura = [1.2 + d * 0.5, 1.2 - d * 0.5]
			cotovelo = [1.2, 1.2]
			giro = d * 0.35
			altura -= 0.06
		"comemora_silencio":
			braco_x = [0.1, 1.9]
			cotovelo = [0.2, 2.1]
			abertura = [0.15, -0.2]
			cabeca_x = -0.15
		"lamenta":
			braco_x = [2.4, 2.4]
			cotovelo = [2.0, 2.0]
			abertura = [0.5, 0.5]
			inclina = 0.12
			cabeca_x = 0.3
		"goleiro":
			coxa = [0.38, 0.38]
			joelho = [-0.75, -0.75]
			tornozelo = [0.35, 0.35]
			altura = 0.8
			inclina = -0.22
			braco_x = [0.55, 0.55]
			abertura = [0.75, 0.75]
			cotovelo = [0.7, 0.7]
	for i in 2:
		_coxa[i].rotation.x = coxa[i]
		_canela[i].rotation.x = joelho[i]
		_pe[i].rotation.x = tornozelo[i] - joelho[i] * 0.25
		_ombro[i].rotation.x = braco_x[i]
		# abertura positiva afasta o braço do corpo (esquerdo vai para -X, direito para +X)
		_ombro[i].rotation.z = -abertura[i] if i == 0 else abertura[i]
		_cotovelo[i].rotation.x = cotovelo[i]
	_tronco.rotation.x = inclina
	_tronco.rotation.y = giro
	_cabeca.rotation.x = cabeca_x - inclina * 0.5
	_quadril.position.y = altura
