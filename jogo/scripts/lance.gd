extends Node3D
## Protótipo do "Momento Decisivo": mecânica Escolha e Veja.
##
## Final da Copa da Vila, 88 minutos, 1 x 1. A bola chega no jogador:
## ele arrasta o dedo para olhar ao redor (olhar revela opções), escolhe
## a jogada e assiste em primeira pessoa. Depois vem o replay na câmera da TV
## e a nota do lance, que no jogo completo vai definir o clube de base.
##
## Tudo é montado por código (sem assets externos) para o protótipo
## ficar leve e fácil de mexer.

enum Estado { INTRO, OLHANDO, EXECUTANDO, REPLAY, RESULTADO }

const POS_PROTA := Vector3(5, 0, -16)
const POS_PARCEIRO := Vector3(-14, 0, -22)
const POS_ZAGUEIRO := Vector3(4, 0, -23)
const POS_GOLEIRO := Vector3(0.5, 0, -38.6)
const LINHA_GOL := -40.0
const ALTURA_OLHOS := 1.65
const TEMPO_DECISAO := 8.0
const ANGULO_REVELA := 0.38  # ~22 graus: quanto precisa olhar na direção do parceiro
const SENSIBILIDADE := 0.004

const COR_VILA := Color(1.0, 0.82, 0.1)
const COR_JARDIM := Color(0.78, 0.12, 0.12)
const PELES := [Color(0.45, 0.3, 0.2), Color(0.85, 0.65, 0.5), Color(0.62, 0.43, 0.3)]
const CORES_TORCIDA := [
	Color(1.0, 0.82, 0.1), Color(1.0, 0.82, 0.1), Color(0.78, 0.12, 0.12),
	Color(0.95, 0.95, 0.95), Color(0.15, 0.3, 0.75), Color(0.1, 0.1, 0.12),
]

const SHADER_VINHETA := """
shader_type canvas_item;
uniform float intensidade = 0.3;
void fragment() {
	float d = length(UV - vec2(0.5)) * 1.45;
	COLOR = vec4(0.0, 0.0, 0.0, smoothstep(0.45, 1.05, d) * intensidade);
}
"""

var estado := Estado.INTRO
var yaw := 0.0
var pitch := -0.12
var olhou_parceiro := false
var tempo_restante := TEMPO_DECISAO
var resultado := {}
var gols_vila := 1

# Câmera em primeira pessoa
var camera_livre := true  # true: o jogador controla; false: segue alvo_olhar
var alvo_olhar := Vector3.ZERO
var base_pov := Basis()
var altura_olhos := ALTURA_OLHOS
var rolagem := 0.0
var balanco := 0.0
var t_balanco := 0.0
var tempo_batida := 0.0
var fase_anterior := 0.0

var bola_no_pe := true
var seguir_bola := false
var seguir_no: Node3D = null  # quando definido, a câmera acompanha este jogador
var pos_zagueiro_decisao := POS_ZAGUEIRO

# Modo de teste automático (godot -- --teste): roda todas as opções e sai.
var modo_teste := false
var fila_teste := ["chute", "drible", "passe", "timeout"]
var indice_teste := 0

var cam_pov: Camera3D
var cam_tv: Camera3D
var bola: MeshInstance3D
var prota: Node3D
var parceiro: Node3D
var zagueiro: Node3D
var goleiro: Node3D
var balao_parceiro: Label3D
var torcida: Array[Node3D] = []

var lbl_placar: Label
var lbl_legenda: Label
var lbl_dica: Label
var lbl_replay: Label
var barra_tempo: ProgressBar
var caixa_opcoes: HBoxContainer
var painel_resultado: PanelContainer
var lbl_resultado: Label
var btn_pular: Button
var mat_vinheta: ShaderMaterial
var flash: ColorRect


func _ready() -> void:
	randomize()
	modo_teste = "--teste" in OS.get_cmdline_user_args()
	_criar_mundo()
	_criar_ui()
	_iniciar()


# ---------------------------------------------------------------- fluxo

func _iniciar() -> void:
	estado = Estado.INTRO
	Engine.time_scale = 6.0 if modo_teste else 1.0
	gols_vila = 1
	pos_zagueiro_decisao = POS_ZAGUEIRO
	_resetar()
	painel_resultado.visible = false
	caixa_opcoes.visible = false
	barra_tempo.visible = false
	lbl_dica.visible = false
	lbl_replay.visible = false
	btn_pular.visible = false

	cam_tv.global_transform = Transform3D(Basis(), Vector3(18, 14, 2)).looking_at(Vector3(0, 0, -25), Vector3.UP)
	cam_tv.make_current()
	_falar("FINAL DA COPA DA VILA\n88 minutos. Vila 1 x 1 Jardim. Os olheiros estão na arquibancada.")
	await _espera(2.6)

	# Entra nos olhos do jogador.
	var olhos := Transform3D(Basis.from_euler(Vector3(pitch, 0, 0)), POS_PROTA + Vector3(0, ALTURA_OLHOS, 0))
	var tw := create_tween()
	tw.tween_property(cam_tv, "global_transform", olhos, 1.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	yaw = 0.0
	pitch = -0.12
	camera_livre = true
	base_pov = Basis.from_euler(Vector3(pitch, yaw, 0))
	cam_pov.make_current()
	_comecar_decisao()


func _comecar_decisao() -> void:
	estado = Estado.OLHANDO
	tempo_restante = TEMPO_DECISAO
	olhou_parceiro = false
	for filho in caixa_opcoes.get_children():
		filho.queue_free()
	_add_opcao("Chutar de longe", "chute")
	_add_opcao("Driblar o zagueiro", "drible")
	caixa_opcoes.visible = true
	barra_tempo.visible = true
	lbl_dica.visible = true
	_falar("A bola chegou em você! Arraste para olhar ao redor antes de decidir.")
	_grito_do_parceiro()
	if modo_teste:
		_auto_escolher()


func _grito_do_parceiro() -> void:
	await _espera(2.5)
	if estado == Estado.OLHANDO and not olhou_parceiro:
		balao_parceiro.visible = true
		_falar("<<  NEGUINHO, lá da esquerda: \"Tô livre! Tô livre!\"")


func _revelar_passe() -> void:
	olhou_parceiro = true
	balao_parceiro.visible = true
	var botao := _add_opcao("Tocar pro Neguinho  (NOVO)", "passe")
	var tw := create_tween().set_loops(3)
	tw.tween_property(botao, "modulate", Color(1.6, 1.4, 0.5), 0.15)
	tw.tween_property(botao, "modulate", Color.WHITE, 0.15)
	_falar("Você viu o Neguinho livre! Nova opção liberada.")
	_vibrar(40)


func _escolher(acao: String, apressado := false) -> void:
	if estado != Estado.OLHANDO:
		return
	estado = Estado.EXECUTANDO
	caixa_opcoes.visible = false
	barra_tempo.visible = false
	lbl_dica.visible = false
	balao_parceiro.visible = false
	pos_zagueiro_decisao = zagueiro.position
	resultado = _decidir(acao, apressado)
	if apressado:
		_falar("Você demorou demais... chute desesperado!")
		await _espera(0.8)

	# 1) A jogada pelos olhos do jogador.
	camera_livre = false
	await _executar(resultado, true)
	await _espera(0.6)

	# 2) Replay na câmera da TV.
	estado = Estado.REPLAY
	_flash(0.5)
	lbl_replay.visible = true
	btn_pular.visible = not modo_teste
	await _executar(resultado, false)
	Engine.time_scale = 6.0 if modo_teste else 1.0
	lbl_replay.visible = false
	btn_pular.visible = false
	_mostrar_resultado()


func _executar(res: Dictionary, pov: bool) -> void:
	_resetar()
	if pov:
		cam_pov.make_current()
	else:
		cam_tv.global_position = Vector3(22, 7, -20)
		cam_tv.look_at(bola.global_position, Vector3.UP)
		cam_tv.make_current()
		prota.visible = true
	match res["acao"]:
		"chute":
			await _seq_chute(res)
		"drible":
			await _seq_drible(res)
		"passe":
			await _seq_passe(res)


func _mostrar_resultado() -> void:
	estado = Estado.RESULTADO
	var av := _avaliar(resultado)
	var texto: String = "%s\n\nNota do lance: %.1f\n\n" % [av["titulo"], av["nota"]]
	for c in av["consequencias"]:
		texto += "%s\n" % c
	texto += "\n" + _texto_olheiro(av["nota"])
	lbl_resultado.text = texto
	painel_resultado.visible = true
	_falar("")
	if modo_teste:
		print("[teste] %s -> %s | nota %.1f" % [resultado["acao"], resultado["detalhe"], av["nota"]])
		await _espera(3.0)
		indice_teste += 1
		if indice_teste < fila_teste.size():
			_iniciar()
		else:
			print("[teste] fim")
			get_tree().quit()


func _auto_escolher() -> void:
	await _espera(1.0)
	var acao: String = fila_teste[indice_teste]
	if acao == "timeout":
		return  # deixa o tempo acabar
	if acao == "passe":
		yaw = _yaw_para(parceiro.position)
		await _espera(0.3)
	_escolher(acao)


# ---------------------------------------------------------------- regras

func _decidir(acao: String, apressado: bool) -> Dictionary:
	var r := {"acao": acao, "apressado": apressado, "sucesso": true, "detalhe": "gol"}
	match acao:
		"chute":
			var chance := 0.15 if apressado else 0.35
			if randf() >= chance:
				r["sucesso"] = false
				r["detalhe"] = "defesa" if randf() < 0.6 else "fora"
		"drible":
			if randf() >= 0.55:
				r["sucesso"] = false
				r["detalhe"] = "perdeu"
			elif randf() >= 0.7:
				r["detalhe"] = "defesa"
		"passe":
			if randf() >= 0.75:
				r["detalhe"] = "defesa"
	return r


func _avaliar(r: Dictionary) -> Dictionary:
	var nota := 0.0
	var titulo := ""
	var cons: Array[String] = []
	match [r["acao"], r["detalhe"]]:
		["chute", "gol"]:
			nota = 9.5
			titulo = "GOLAÇO DE FORA DA ÁREA!"
			cons.append("+ Fama no bairro")
			if olhou_parceiro:
				cons.append("- Amizade: o Neguinho estava livre e ficou na bronca")
			else:
				cons.append("+ Confiança")
		["chute", "defesa"]:
			nota = 6.0
			titulo = "O goleiro defendeu."
			if olhou_parceiro:
				cons.append("- Amizade: \"Eu tava livre, parceiro!\"")
		["chute", "fora"]:
			nota = 5.0
			titulo = "Isolou!"
			cons.append("- Confiança")
		["drible", "gol"]:
			nota = 9.0
			titulo = "QUE JOGADA INDIVIDUAL!"
			cons.append("+ Drible")
			cons.append("+ Fama no bairro")
		["drible", "defesa"]:
			nota = 7.0
			titulo = "Passou pelo zagueiro, mas parou no goleiro."
			cons.append("+ Drible")
		["drible", "perdeu"]:
			nota = 4.5
			titulo = "Perdeu a bola na hora decisiva."
			cons.append("- Confiança")
			cons.append("O técnico balança a cabeça na beira do campo.")
		["passe", "gol"]:
			nota = 8.5
			titulo = "ASSISTÊNCIA DECISIVA!"
			cons.append("+ Amizade com o Neguinho")
			cons.append("+ Visão de jogo")
		["passe", "defesa"]:
			nota = 7.0
			titulo = "Passe perfeito, mas o goleiro salvou."
			cons.append("+ Visão de jogo")
	if r["apressado"]:
		nota = maxf(nota - 1.0, 2.0)
		cons.append("Você travou na hora H: a pressão da final pesou.")
	return {"nota": nota, "titulo": titulo, "consequencias": cons}


func _texto_olheiro(nota: float) -> String:
	if nota >= 8.0:
		return "Um olheiro do Atlético Metropolitano anotou o seu nome no caderno..."
	if nota >= 6.0:
		return "Um olheiro de um clube médio ficou de olho em você."
	return "Os olheiros foram embora sem anotar nada. Ainda resta a peneira..."


# ---------------------------------------------------------------- sequências

func _seq_chute(res: Dictionary) -> void:
	alvo_olhar = Vector3(0.5, 1.2, LINHA_GOL)
	_falar("Ajeitou pro chute...")
	await _espera(0.6)
	alvo_olhar = bola.position
	await _espera(0.3)
	_soltar_bola()
	match res["detalhe"]:
		"gol":
			_mergulho(Vector3(2.2, 0.5, -38.9), 1.25, 0.45)
			await _chutar_bola(Vector3(2.95, 2.05, LINHA_GOL - 0.2), 1.2, 1.1)
			await _chutar_bola(Vector3(3.0, 0.11, LINHA_GOL - 1.8), 0.1, 0.35)
			await _gol(false)
		"defesa":
			_mergulho(Vector3(1.5, 0.4, -38.8), 1.1, 0.25)
			await _chutar_bola(Vector3(1.6, 1.0, -38.9), 1.0, 1.0)
			_falar("Defendeu o goleiro!")
			await _chutar_bola(Vector3(6.5, 0.11, -35.0), 0.8, 0.7)
		_:
			await _chutar_bola(Vector3(1.8, 4.5, LINHA_GOL - 6.0), 2.0, 1.3)
			_falar("Pra fora! Por cima do gol...")
	seguir_bola = false
	await _espera(1.2)


func _seq_drible(res: Dictionary) -> void:
	_falar("Vai pra cima do zagueiro!")
	seguir_no = zagueiro
	balanco = 1.0
	_mover(zagueiro, Vector3(4.3, 0, -20.6), 0.8)
	await _mover(prota, Vector3(4.2, 0, -18.8), 0.8).finished
	if res["sucesso"]:
		_falar("Ginga pra direita...")
		_mover(zagueiro, Vector3(5.6, 0, -20.8), 0.3)
		await _mover(prota, Vector3(5.4, 0, -19.4), 0.3).finished
		_falar("...e sai pela esquerda!")
		create_tween().tween_property(zagueiro, "rotation:x", -1.4, 0.5)
		seguir_no = null
		alvo_olhar = Vector3(0.5, 1.0, LINHA_GOL)
		await _mover(prota, Vector3(2.0, 0, -25.0), 0.7).finished
		_falar("Deixou o zagueiro no chão! Cara a cara com o goleiro!")
		_mover(goleiro, Vector3(1.2, 0, -35.5), 0.9)
		await _mover(prota, Vector3(1.5, 0, -28.5), 0.8).finished
		balanco = 0.0
		alvo_olhar = bola.position
		await _espera(0.2)
		_soltar_bola()
		if res["detalhe"] == "gol":
			_mergulho(Vector3(-0.3, 0.2, -35.8), 1.2, 0.25)
			await _chutar_bola(Vector3(-2.9, 0.5, LINHA_GOL - 0.2), 0.3, 0.6)
			await _chutar_bola(Vector3(-3.0, 0.11, LINHA_GOL - 1.8), 0.1, 0.3)
			await _gol(false)
		else:
			_mover(goleiro, Vector3(1.4, 0, -34.9), 0.25)
			await _chutar_bola(Vector3(1.4, 0.6, -35.2), 0.2, 0.45)
			_falar("O goleiro fechou o ângulo! Defesaça!")
			await _chutar_bola(Vector3(8.0, 0.11, -31.0), 0.8, 0.7)
	else:
		_falar("O zagueiro chegou firme!")
		_mover(zagueiro, Vector3(5.6, 0, -19.6), 0.25)
		create_tween().tween_property(zagueiro, "rotation:x", -0.9, 0.3)
		await _espera(0.2)
		_soltar_bola(200)
		var queda := create_tween().set_parallel()
		queda.tween_property(self, "rolagem", 0.9, 0.5)
		queda.tween_property(self, "altura_olhos", 0.45, 0.5)
		await _chutar_bola(Vector3(13.0, 0.11, -17.0), 0.4, 0.8)
		_falar("Perdeu a bola...")
	balanco = 0.0
	seguir_bola = false
	await _espera(1.2)


func _seq_passe(res: Dictionary) -> void:
	_falar("Levantou a cabeça... NEGUINHO!")
	seguir_no = parceiro
	await _espera(0.5)
	alvo_olhar = bola.position
	await _espera(0.25)
	_soltar_bola(50)
	_mover(parceiro, Vector3(-13.0, 0, -24.0), 0.9)
	_mover(prota, Vector3(7.0, 0, -19.5), 1.5)
	await _chutar_bola(Vector3(-12.7, 0.11, -24.6), 0.3, 0.9)
	_encarar(parceiro, Vector3(0, 0, LINHA_GOL))
	_falar("O Neguinho domina... e bate!")
	await _espera(0.3)
	if res["detalhe"] == "gol":
		_mergulho(Vector3(-1.8, 0.5, -39.0), 1.25, 0.35)
		await _chutar_bola(Vector3(-3.0, 1.4, LINHA_GOL - 0.2), 0.6, 0.9)
		await _chutar_bola(Vector3(-3.1, 0.11, LINHA_GOL - 1.8), 0.1, 0.3)
		await _gol(true)
	else:
		_mergulho(Vector3(-1.6, 0.4, -38.9), 1.1, 0.2)
		await _chutar_bola(Vector3(-1.7, 1.0, -39.0), 0.5, 0.85)
		_falar("Que defesa do goleiro!")
	seguir_bola = false
	await _espera(1.2)


func _gol(assistencia: bool) -> void:
	gols_vila = 2
	_atualizar_placar()
	_falar("GOOOOOOOL!!!")
	_flash(0.8)
	_vibrar(300)
	seguir_bola = false
	balanco = 1.0
	for t in torcida:
		var tw := create_tween().set_loops(5)
		tw.tween_property(t, "position:y", 0.35, 0.14)
		tw.tween_property(t, "position:y", 0.0, 0.14)
	if assistencia:
		seguir_no = parceiro
		_mover(parceiro, Vector3(-9.0, 0, -29.0), 1.3)
		await _mover(prota, Vector3(-7.5, 0, -27.5), 1.4).finished
		_falar("Abraço no parceiro! VILA 2 x 1!")
	else:
		alvo_olhar = Vector3(14, 6, -46)
		await _mover(prota, Vector3(11, 0, -28), 1.4).finished
		_falar("Corre pra galera! VILA 2 x 1!")
	balanco = 0.0
	seguir_no = null
	await _espera(0.6)


# ---------------------------------------------------------------- helpers de movimento

func _soltar_bola(vibracao := 70) -> void:
	seguir_no = null
	bola_no_pe = false
	seguir_bola = true
	_vibrar(vibracao)


func _chutar_bola(destino: Vector3, altura: float, duracao: float) -> void:
	var de := bola.position
	var trajetoria := func(t: float) -> void:
		bola.position = de.lerp(destino, t) + Vector3(0, altura * 4.0 * t * (1.0 - t), 0)
		bola.rotate_x(-0.35)
	var tw := create_tween()
	tw.tween_method(trajetoria, 0.0, 1.0, duracao)
	await tw.finished


func _mover(n: Node3D, destino: Vector3, duracao: float) -> Tween:
	var tw := create_tween()
	tw.tween_property(n, "position", destino, duracao).set_trans(Tween.TRANS_SINE)
	return tw


func _mergulho(destino: Vector3, inclinacao: float, atraso: float, duracao := 0.45) -> void:
	# O goleiro está virado para +Z (rotation.y = PI): rotation.z positiva tomba para +X do mundo.
	var lado := signf(destino.x - goleiro.position.x)
	var tw := create_tween()
	tw.tween_interval(atraso)
	tw.tween_property(goleiro, "position", destino, duracao).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(goleiro, "rotation:z", lado * inclinacao, duracao)


func _encarar(n: Node3D, alvo: Vector3) -> void:
	var a := Vector3(alvo.x, n.position.y, alvo.z)
	if a.distance_to(n.position) > 0.01:
		n.look_at(a, Vector3.UP)


func _yaw_para(p: Vector3) -> float:
	var d := p - prota.position
	return atan2(-d.x, -d.z)


func _resetar() -> void:
	prota.position = POS_PROTA
	prota.rotation = Vector3.ZERO
	prota.visible = false
	parceiro.position = POS_PARCEIRO
	parceiro.rotation = Vector3.ZERO
	_encarar(parceiro, Vector3(-2, 0, LINHA_GOL))
	zagueiro.position = pos_zagueiro_decisao
	zagueiro.rotation = Vector3.ZERO
	_encarar(zagueiro, POS_PROTA)
	goleiro.position = POS_GOLEIRO
	goleiro.rotation = Vector3(0, PI, 0)
	bola_no_pe = true
	seguir_bola = false
	seguir_no = null
	altura_olhos = ALTURA_OLHOS
	rolagem = 0.0
	balanco = 0.0
	balao_parceiro.visible = false
	_atualizar_placar()


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	if bola_no_pe:
		bola.position = prota.position + Vector3(0, 0.11, -0.7)
	if seguir_bola:
		alvo_olhar = bola.position
	elif seguir_no != null:
		alvo_olhar = seguir_no.position + Vector3(0, 1.3, 0)

	if estado == Estado.OLHANDO:
		tempo_restante -= delta
		barra_tempo.value = tempo_restante / TEMPO_DECISAO * 100.0
		# Câmera lenta: o zagueiro vem chegando devagar.
		zagueiro.position = zagueiro.position.move_toward(prota.position, delta * 0.25)
		if not olhou_parceiro and absf(angle_difference(yaw, _yaw_para(parceiro.position))) < ANGULO_REVELA:
			_revelar_passe()
		if tempo_restante <= 0.0:
			_escolher("chute", true)

	_atualizar_coracao(delta)
	if cam_pov.current:
		_atualizar_camera_pov(delta)
	elif estado == Estado.REPLAY:
		var tf := cam_tv.global_transform
		var desejado := tf.looking_at(bola.global_position, Vector3.UP).basis
		tf.basis = tf.basis.slerp(desejado, clampf(delta * 4.0, 0.0, 1.0))
		cam_tv.global_transform = tf


func _atualizar_camera_pov(delta: float) -> void:
	var olho := prota.position + Vector3(0, altura_olhos, 0)
	if camera_livre:
		base_pov = Basis.from_euler(Vector3(pitch, yaw, 0))
	else:
		var desejado := Transform3D(Basis(), olho).looking_at(alvo_olhar, Vector3.UP).basis
		base_pov = base_pov.slerp(desejado, clampf(delta * 7.0, 0.0, 1.0))
	var bob := Vector3.ZERO
	if balanco > 0.0:
		t_balanco += delta * 11.0
		bob = Vector3(cos(t_balanco * 0.5) * 0.03, sin(t_balanco) * 0.05, 0) * balanco
	cam_pov.global_transform = Transform3D(base_pov * Basis(Vector3(0, 0, 1), rolagem), olho + base_pov * bob)


func _atualizar_coracao(delta: float) -> void:
	# Batimento + visão em túnel: quanto menos tempo, mais fechada a visão.
	tempo_batida += delta
	var tensao := estado == Estado.OLHANDO
	var periodo := 0.42 if tensao else 0.8
	var fase := fmod(tempo_batida, periodo) / periodo
	var pulso := exp(-fase * 8.0)
	var intensidade := 0.3
	if tensao:
		intensidade = 0.6 + 0.3 * (1.0 - tempo_restante / TEMPO_DECISAO) + 0.15 * pulso
		if fase < fase_anterior:
			_vibrar(15)
	fase_anterior = fase
	mat_vinheta.set_shader_parameter("intensidade", intensidade)


func _unhandled_input(evento: InputEvent) -> void:
	# No Android o toque também gera eventos de mouse (emulate_mouse_from_touch),
	# então tratar só o mouse cobre celular e computador sem contar em dobro.
	if estado != Estado.OLHANDO:
		return
	if evento is InputEventMouseMotion and (evento.button_mask & MOUSE_BUTTON_MASK_LEFT):
		yaw = clampf(yaw - evento.relative.x * SENSIBILIDADE, -1.7, 1.7)
		pitch = clampf(pitch - evento.relative.y * SENSIBILIDADE, -0.7, 0.35)


# ---------------------------------------------------------------- UI helpers

func _falar(texto: String) -> void:
	lbl_legenda.text = texto
	lbl_legenda.modulate.a = 0.0
	create_tween().tween_property(lbl_legenda, "modulate:a", 1.0, 0.15)


func _flash(forca: float) -> void:
	flash.color.a = forca
	create_tween().tween_property(flash, "color:a", 0.0, 0.5)


func _vibrar(ms: int) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)


func _espera(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout


func _atualizar_placar() -> void:
	lbl_placar.text = "VILA %d x 1 JARDIM    88'" % gols_vila


func _add_opcao(texto: String, acao: String) -> Button:
	var b := Button.new()
	b.text = texto
	b.custom_minimum_size = Vector2(300, 86)
	b.pressed.connect(_escolher.bind(acao, false))
	caixa_opcoes.add_child(b)
	return b


# ---------------------------------------------------------------- construção do mundo

func _criar_mundo() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color(0.28, 0.48, 0.85)
	ceu.sky_horizon_color = Color(0.98, 0.76, 0.55)
	ceu.ground_horizon_color = Color(0.9, 0.72, 0.55)
	ceu.ground_bottom_color = Color(0.3, 0.28, 0.25)
	env.sky = Sky.new()
	env.sky.sky_material = ceu
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var mundo := WorldEnvironment.new()
	mundo.environment = env
	add_child(mundo)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-35, -50, 0)
	sol.light_color = Color(1.0, 0.92, 0.8)
	sol.shadow_enabled = true
	add_child(sol)

	_criar_campo()
	_criar_gol()
	_criar_arquibancada(Vector3(0, 0, -46), 0.0, 70.0)
	_criar_arquibancada(Vector3(-38, 0, -5), PI / 2.0, 90.0)
	_criar_bairro()

	prota = _criar_jogador(COR_VILA, Color(0.1, 0.2, 0.6), POS_PROTA, 0)
	parceiro = _criar_jogador(COR_VILA, Color(0.1, 0.2, 0.6), POS_PARCEIRO, 2)
	zagueiro = _criar_jogador(COR_JARDIM, Color.WHITE, POS_ZAGUEIRO, 1)
	goleiro = _criar_jogador(Color(0.2, 0.75, 0.3), Color.BLACK, POS_GOLEIRO, 1)
	# Figurantes para o campo não parecer vazio.
	var colega := _criar_jogador(COR_VILA, Color(0.1, 0.2, 0.6), Vector3(12, 0, -31), 1)
	var marcador := _criar_jogador(COR_JARDIM, Color.WHITE, Vector3(11, 0, -32.5), 2)
	var volante := _criar_jogador(COR_JARDIM, Color.WHITE, Vector3(-3, 0, -30), 0)
	var lateral := _criar_jogador(COR_JARDIM, Color.WHITE, Vector3(-6, 0, -33), 2)
	for f in [colega, marcador, volante, lateral]:
		_encarar(f, POS_PROTA)

	balao_parceiro = Label3D.new()
	balao_parceiro.text = "Tô livre!"
	balao_parceiro.font_size = 72
	balao_parceiro.outline_size = 18
	balao_parceiro.pixel_size = 0.012
	balao_parceiro.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	balao_parceiro.no_depth_test = true
	balao_parceiro.modulate = COR_VILA
	balao_parceiro.position = Vector3(0, 2.4, 0)
	parceiro.add_child(balao_parceiro)

	var esfera := SphereMesh.new()
	esfera.radius = 0.11
	esfera.height = 0.22
	esfera.radial_segments = 12
	esfera.rings = 6
	bola = _malha(esfera, POS_PROTA, _mat(Color(0.97, 0.97, 0.97)))

	cam_pov = Camera3D.new()
	cam_pov.fov = 75.0
	cam_pov.near = 0.05
	add_child(cam_pov)
	cam_tv = Camera3D.new()
	cam_tv.fov = 50.0
	add_child(cam_tv)


func _criar_campo() -> void:
	var verde_a := _mat(Color(0.17, 0.4, 0.15))
	var verde_b := _mat(Color(0.2, 0.46, 0.18))
	for i in 12:
		var faixa := PlaneMesh.new()
		faixa.size = Vector2(90, 10)
		_malha(faixa, Vector3(0, 0, -46.0 + i * 10.0 + 5.0), verde_a if i % 2 == 0 else verde_b)
	var y := 0.011
	var linhas := [
		[Vector3(-34, y, LINHA_GOL), Vector3(34, y, LINHA_GOL)],  # linha de fundo
		[Vector3(-34, y, LINHA_GOL), Vector3(-34, y, 65)],  # laterais
		[Vector3(34, y, LINHA_GOL), Vector3(34, y, 65)],
		[Vector3(-34, y, 12.5), Vector3(34, y, 12.5)],  # meio de campo
		[Vector3(-20.16, y, -23.5), Vector3(20.16, y, -23.5)],  # grande área
		[Vector3(-20.16, y, LINHA_GOL), Vector3(-20.16, y, -23.5)],
		[Vector3(20.16, y, LINHA_GOL), Vector3(20.16, y, -23.5)],
		[Vector3(-9.16, y, -34.5), Vector3(9.16, y, -34.5)],  # pequena área
		[Vector3(-9.16, y, LINHA_GOL), Vector3(-9.16, y, -34.5)],
		[Vector3(9.16, y, LINHA_GOL), Vector3(9.16, y, -34.5)],
	]
	var branco := _mat(Color(0.95, 0.95, 0.95))
	for l in linhas:
		var a: Vector3 = l[0]
		var b: Vector3 = l[1]
		var comp := a.distance_to(b) + 0.12
		var tam := Vector3(comp, 0.02, 0.12) if absf(a.x - b.x) > absf(a.z - b.z) else Vector3(0.12, 0.02, comp)
		_malha(_box(tam), (a + b) / 2.0, branco)
	_malha(_box(Vector3(0.25, 0.02, 0.25)), Vector3(0, y, -29), branco)  # marca do pênalti


func _criar_gol() -> void:
	var branco := _mat(Color(0.97, 0.97, 0.97))
	for x in [-3.66, 3.66]:
		_malha(_box(Vector3(0.12, 2.44, 0.12)), Vector3(x, 1.22, LINHA_GOL), branco)
	_malha(_box(Vector3(7.44, 0.12, 0.12)), Vector3(0, 2.44, LINHA_GOL), branco)
	var rede := StandardMaterial3D.new()
	rede.albedo_color = Color(1, 1, 1, 0.28)
	rede.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rede.cull_mode = BaseMaterial3D.CULL_DISABLED
	_malha(_box(Vector3(7.32, 2.44, 0.02)), Vector3(0, 1.22, LINHA_GOL - 2.0), rede)
	_malha(_box(Vector3(7.32, 0.02, 2.0)), Vector3(0, 2.44, LINHA_GOL - 1.0), rede)
	for x in [-3.66, 3.66]:
		_malha(_box(Vector3(0.02, 2.44, 2.0)), Vector3(x, 1.22, LINHA_GOL - 1.0), rede)


func _criar_arquibancada(centro: Vector3, rot_y: float, comprimento: float) -> void:
	var pivo := Node3D.new()
	add_child(pivo)
	pivo.position = centro
	pivo.rotation.y = rot_y
	var concreto := _mat(Color(0.55, 0.55, 0.58))
	var filas := 7
	for f in filas:
		var h := (f + 1) * 0.8
		_malha(_box(Vector3(comprimento, h, 1.0)), Vector3(0, h / 2.0, -f * 1.0), concreto, pivo)

	var pessoa := BoxMesh.new()
	pessoa.size = Vector3(0.45, 0.75, 0.35)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	pessoa.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = pessoa
	var por_fila := int(comprimento / 0.8)
	mm.instance_count = por_fila * filas
	var i := 0
	for f in filas:
		for k in por_fila:
			var pos := Vector3(-comprimento / 2.0 + 0.4 + k * 0.8 + randf_range(-0.15, 0.15),
				(f + 1) * 0.8 + 0.37, -f * 1.0 + randf_range(-0.1, 0.1))
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, randf_range(-0.3, 0.3)), pos))
			mm.set_instance_color(i, CORES_TORCIDA.pick_random())
			i += 1
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	pivo.add_child(mmi)
	torcida.append(mmi)


func _criar_bairro() -> void:
	# Casinhas coloridas atrás das arquibancadas: é um campo de bairro.
	var cores := [Color(0.9, 0.5, 0.3), Color(0.95, 0.85, 0.5), Color(0.5, 0.7, 0.85),
		Color(0.85, 0.85, 0.8), Color(0.6, 0.8, 0.5), Color(0.8, 0.45, 0.5)]
	for k in 26:
		var h := randf_range(3.0, 9.0)
		_malha(_box(Vector3(randf_range(4, 7), h, randf_range(4, 7))),
			Vector3(-30 + k * 3.2 + randf_range(-1, 1), h / 2.0, -58 - randf_range(0, 6)), _mat(cores.pick_random()))
	for k in 24:
		var h := randf_range(3.0, 9.0)
		_malha(_box(Vector3(randf_range(4, 7), h, randf_range(4, 7))),
			Vector3(-50 - randf_range(0, 6), h / 2.0, -45 + k * 4.5 + randf_range(-1, 1)), _mat(cores.pick_random()))


func _criar_jogador(camisa: Color, calcao: Color, pos: Vector3, pele: int) -> Node3D:
	var j := Node3D.new()
	add_child(j)
	j.position = pos
	var mat_pele := _mat(PELES[pele])
	var meiao := _mat(Color(0.95, 0.95, 0.95))
	for lado in [-0.11, 0.11]:
		_malha(_box(Vector3(0.15, 0.8, 0.15)), Vector3(lado, 0.4, 0), meiao, j)
		_malha(_box(Vector3(0.12, 0.6, 0.12)), Vector3(lado * 2.9, 1.25, 0), mat_pele, j)
	_malha(_box(Vector3(0.44, 0.28, 0.26)), Vector3(0, 0.88, 0), _mat(calcao), j)
	var tronco := CapsuleMesh.new()
	tronco.radius = 0.23
	tronco.height = 0.75
	tronco.radial_segments = 8
	tronco.rings = 2
	_malha(tronco, Vector3(0, 1.3, 0), _mat(camisa), j)
	var cabeca := SphereMesh.new()
	cabeca.radius = 0.14
	cabeca.height = 0.28
	cabeca.radial_segments = 8
	cabeca.rings = 4
	_malha(cabeca, Vector3(0, 1.72, 0), mat_pele, j)
	return j


func _malha(mesh: Mesh, pos: Vector3, mat: Material, pai: Node3D = null) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.mesh = mesh
	m.material_override = mat
	m.position = pos
	(pai if pai != null else self).add_child(m)
	return m


func _box(tamanho: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = tamanho
	return b


func _mat(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.9
	return m


# ---------------------------------------------------------------- construção da UI

func _criar_ui() -> void:
	var camada := CanvasLayer.new()
	add_child(camada)
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.theme = _criar_tema()
	camada.add_child(raiz)

	var vinheta := ColorRect.new()
	var shader := Shader.new()
	shader.code = SHADER_VINHETA
	mat_vinheta = ShaderMaterial.new()
	mat_vinheta.shader = shader
	vinheta.material = mat_vinheta
	_cheio(vinheta, raiz)

	flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0)
	_cheio(flash, raiz)

	lbl_placar = Label.new()
	var fundo := StyleBoxFlat.new()
	fundo.bg_color = Color(0.05, 0.06, 0.1, 0.85)
	fundo.set_corner_radius_all(8)
	fundo.set_content_margin_all(12)
	lbl_placar.add_theme_stylebox_override("normal", fundo)
	lbl_placar.add_theme_font_size_override("font_size", 24)
	lbl_placar.position = Vector2(20, 20)
	raiz.add_child(lbl_placar)

	barra_tempo = ProgressBar.new()
	barra_tempo.show_percentage = false
	var cheio := StyleBoxFlat.new()
	cheio.bg_color = COR_VILA
	cheio.set_corner_radius_all(6)
	var vazio := StyleBoxFlat.new()
	vazio.bg_color = Color(0, 0, 0, 0.5)
	vazio.set_corner_radius_all(6)
	barra_tempo.add_theme_stylebox_override("fill", cheio)
	barra_tempo.add_theme_stylebox_override("background", vazio)
	barra_tempo.set_anchors_preset(Control.PRESET_CENTER_TOP)
	barra_tempo.offset_left = -220
	barra_tempo.offset_right = 220
	barra_tempo.offset_top = 28
	barra_tempo.offset_bottom = 44
	raiz.add_child(barra_tempo)

	lbl_dica = _rotulo(raiz, "<<   arraste para olhar ao redor   >>", 22)
	lbl_dica.set_anchors_preset(Control.PRESET_TOP_WIDE)
	lbl_dica.offset_left = 0
	lbl_dica.offset_right = 0
	lbl_dica.offset_top = 52
	lbl_dica.offset_bottom = 90
	lbl_dica.modulate = Color(1, 1, 1, 0.8)

	lbl_legenda = _rotulo(raiz, "", 30)
	lbl_legenda.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	lbl_legenda.offset_top = -250
	lbl_legenda.offset_bottom = -150
	lbl_legenda.offset_left = 40
	lbl_legenda.offset_right = -40
	lbl_legenda.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM

	lbl_replay = _rotulo(raiz, "REPLAY", 30)
	lbl_replay.modulate = Color(1, 0.3, 0.3)
	lbl_replay.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	lbl_replay.offset_left = -220
	lbl_replay.offset_right = -24
	lbl_replay.offset_top = 20
	lbl_replay.offset_bottom = 60
	lbl_replay.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	caixa_opcoes = HBoxContainer.new()
	caixa_opcoes.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caixa_opcoes.alignment = BoxContainer.ALIGNMENT_CENTER
	caixa_opcoes.add_theme_constant_override("separation", 20)
	caixa_opcoes.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	caixa_opcoes.offset_left = 0
	caixa_opcoes.offset_right = 0
	caixa_opcoes.offset_top = -130
	caixa_opcoes.offset_bottom = -32
	raiz.add_child(caixa_opcoes)

	btn_pular = Button.new()
	btn_pular.text = "Pular >>"
	btn_pular.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn_pular.offset_left = -200
	btn_pular.offset_right = -24
	btn_pular.offset_top = -100
	btn_pular.offset_bottom = -24
	btn_pular.pressed.connect(func() -> void: Engine.time_scale = 5.0)
	raiz.add_child(btn_pular)

	var centro := CenterContainer.new()
	centro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.add_child(centro)
	painel_resultado = PanelContainer.new()
	painel_resultado.custom_minimum_size = Vector2(760, 0)
	centro.add_child(painel_resultado)
	var coluna := VBoxContainer.new()
	coluna.add_theme_constant_override("separation", 18)
	painel_resultado.add_child(coluna)
	lbl_resultado = Label.new()
	lbl_resultado.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_resultado.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(lbl_resultado)
	var de_novo := Button.new()
	de_novo.text = "Jogar o lance de novo"
	de_novo.custom_minimum_size = Vector2(0, 80)
	de_novo.pressed.connect(_iniciar)
	coluna.add_child(de_novo)


func _cheio(c: Control, pai: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pai.add_child(c)
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _rotulo(pai: Control, texto: String, tamanho: int) -> Label:
	var l := Label.new()
	l.text = texto
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", tamanho)
	pai.add_child(l)
	return l


func _criar_tema() -> Theme:
	var t := Theme.new()
	t.default_font_size = 28
	t.set_constant("outline_size", "Label", 10)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.9))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.1, 0.14, 0.88)
	normal.border_color = COR_VILA
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(14)
	normal.set_content_margin_all(18)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.18, 0.22, 0.3, 0.95)
	var pressionado: StyleBoxFlat = normal.duplicate()
	pressionado.bg_color = COR_VILA
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressionado)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_pressed_color", "Button", Color.BLACK)

	var painel := StyleBoxFlat.new()
	painel.bg_color = Color(0.06, 0.08, 0.12, 0.94)
	painel.border_color = COR_VILA
	painel.set_border_width_all(3)
	painel.set_corner_radius_all(18)
	painel.set_content_margin_all(32)
	t.set_stylebox("panel", "PanelContainer", painel)
	return t
