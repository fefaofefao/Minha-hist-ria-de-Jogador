class_name Vitrine3D
extends Node3D
## Cenário 3D de fundo para menus: estádio, um jogador com a bola e a câmera
## girando devagar ao redor.

var mundo: Mundo3D
var jogador: Jogador3D
var bola: MeshInstance3D
var camera: Camera3D
var raio := 6.5
var altura := 2.0
var velocidade := 0.12
var foco := Vector3(0, 1.1, -25)
var deslocamento_foco := Vector3.ZERO
var _angulo := 0.6
var _t := 0.0
var embaixadinha := true


func construir(cenario: String, noite: bool, visual: Dictionary, camisa: Color, calcao: Color, numero := 10,
		estilo := "liso", cor2 := Color(0, 0, 0, 0)) -> Vitrine3D:
	mundo = Mundo3D.new()
	add_child(mundo)
	mundo.construir(cenario, noite, camisa, Color("c62828"), 11)
	jogador = Jogador3D.new()
	add_child(jogador)
	jogador.configurar(camisa, calcao, visual, numero, Color.WHITE, estilo, cor2)
	jogador.position = Vector3(foco.x, 0, foco.z)
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
	camera = Camera3D.new()
	camera.fov = 52.0
	add_child(camera)
	camera.make_current()
	return self


func trocar_visual(visual: Dictionary, camisa: Color, calcao: Color, numero := 10) -> void:
	jogador.configurar(camisa, calcao, visual, numero)


func _process(delta: float) -> void:
	if camera == null:
		return
	_t += delta
	_angulo += delta * velocidade
	jogador.position = Vector3(foco.x, 0, foco.z)
	var centro := foco + deslocamento_foco
	camera.position = Vector3(centro.x + sin(_angulo) * raio, altura, centro.z + cos(_angulo) * raio)
	camera.look_at(centro, Vector3.UP)
	# de frente para a câmera, num leve 3/4
	jogador.rotation.y = lerp_angle(jogador.rotation.y, _angulo + PI + 0.45, delta * 2.0)
	if embaixadinha:
		var ciclo := fmod(_t, 0.62) / 0.62
		var frente := Vector3(sin(jogador.rotation.y), 0, cos(jogador.rotation.y)) * -0.35
		bola.position = jogador.position + frente + Vector3(0, 0.2 + sin(ciclo * PI) * 0.75, 0)
		bola.rotate_x(delta * 6.0)
		if ciclo < 0.08 and jogador.pose == "":
			jogador.fazer_pose("toque")
	else:
		bola.position = jogador.position + Vector3(0.3, 0.11, -0.4)
