extends Node
## Autoload "Audio": todos os sons são sintetizados em código na inicialização
## (torcida, apito, chute, coração, moedas, batucada de samba). Nada de assets
## externos: o APK fica leve e sem problemas de licença.

const TAXA := 22050

var _sons := {}
var _jogadores: Array[AudioStreamPlayer] = []
var _torcida: AudioStreamPlayer
var _musica: AudioStreamPlayer
var _intensidade_torcida := 0.0
var _alvo_torcida := 0.0
var _musica_ligada := false
var _pronto := false
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_jogadores.append(p)
	_torcida = AudioStreamPlayer.new()
	_torcida.volume_db = -80.0
	add_child(_torcida)
	_musica = AudioStreamPlayer.new()
	_musica.volume_db = -6.0
	add_child(_musica)
	if DisplayServer.get_name() == "headless":
		return  # testes automáticos: sem áudio
	WorkerThreadPool.add_task(_gerar_tudo)


func _gerar_tudo() -> void:
	_rng.seed = 7
	var s := {}
	s["clique"] = _clique()
	s["chute"] = _chute()
	s["coracao"] = _coracao()
	s["apito"] = _apito(0.55)
	s["apito_final"] = _apito_final()
	s["moeda"] = _moeda()
	s["rede"] = _rede()
	s["sucesso"] = _arpejo([523.25, 659.25, 783.99, 1046.5], 0.09, 0.5)
	s["falha"] = _arpejo([392.0, 311.13], 0.16, 0.45)
	s["revela"] = _arpejo([880.0, 1318.5], 0.07, 0.35)
	s["rebobinar"] = _rebobinar()
	s["carta"] = _carta()
	s["gol"] = _rugido(3.2, 0.25, true)
	s["uhh"] = _rugido(1.4, 0.35, false)
	s["torcida"] = _torcida_loop()
	s["samba"] = _samba()
	call_deferred("_concluir", s)


func _concluir(s: Dictionary) -> void:
	_sons = s
	_pronto = true
	_torcida.stream = _sons["torcida"]
	_torcida.play()
	if _musica_ligada:
		_iniciar_musica()


func _process(delta: float) -> void:
	if not _pronto:
		return
	_intensidade_torcida = move_toward(_intensidade_torcida, _alvo_torcida, delta * 0.8)
	var vol := _volume_efeitos()
	if _intensidade_torcida <= 0.01 or vol <= 0.01:
		_torcida.volume_db = -80.0
	else:
		_torcida.volume_db = linear_to_db(_intensidade_torcida * vol * 0.55)


func _volume_efeitos() -> float:
	return float(Jogo.perfil.get("config", {}).get("som", 1.0))


func _volume_musica() -> float:
	return float(Jogo.perfil.get("config", {}).get("musica", 0.7))


func tocar(nome: String, volume := 1.0, tom := 1.0) -> void:
	if not _pronto or not _sons.has(nome):
		return
	var vol := volume * _volume_efeitos()
	if vol <= 0.01:
		return
	for p in _jogadores:
		if not p.playing:
			p.stream = _sons[nome]
			p.volume_db = linear_to_db(vol)
			p.pitch_scale = tom
			p.play()
			return


## 0 = silêncio, 1 = estádio cheio.
func torcida(intensidade: float) -> void:
	_alvo_torcida = clampf(intensidade, 0.0, 1.0)


func musica(ligada: bool) -> void:
	_musica_ligada = ligada
	if not _pronto:
		return
	if ligada:
		_iniciar_musica()
	else:
		var tw := create_tween()
		tw.tween_property(_musica, "volume_db", -60.0, 0.6)
		tw.tween_callback(_musica.stop)


func atualizar_volumes() -> void:
	if _musica.playing:
		var v := _volume_musica()
		_musica.volume_db = linear_to_db(maxf(v, 0.001) * 0.6)


func _iniciar_musica() -> void:
	var v := _volume_musica()
	if v <= 0.01:
		return
	if not _musica.playing:
		_musica.stream = _sons["samba"]
		_musica.volume_db = -40.0
		_musica.play()
	var tw := create_tween()
	tw.tween_property(_musica, "volume_db", linear_to_db(v * 0.6), 0.8)


# ---------------------------------------------------------------- síntese

func _wav(amostras: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var dados := PackedByteArray()
	dados.resize(amostras.size() * 2)
	for i in amostras.size():
		dados.encode_s16(i * 2, int(clampf(amostras[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = TAXA
	w.stereo = false
	w.data = dados
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = amostras.size()
	return w


func _buffer(segundos: float) -> PackedFloat32Array:
	var b := PackedFloat32Array()
	b.resize(int(segundos * TAXA))
	return b


func _clique() -> AudioStreamWAV:
	var b := _buffer(0.05)
	for i in b.size():
		var t := float(i) / TAXA
		b[i] = sin(TAU * 1700.0 * t) * exp(-t * 120.0) * 0.5
	return _wav(b)


func _chute() -> AudioStreamWAV:
	var b := _buffer(0.22)
	var fase := 0.0
	for i in b.size():
		var t := float(i) / TAXA
		var f := lerpf(170.0, 55.0, minf(t / 0.08, 1.0))
		fase += TAU * f / TAXA
		var corpo := sin(fase) * exp(-t * 28.0)
		var estalo := _rng.randf_range(-1, 1) * exp(-t * 400.0) * 0.6
		b[i] = (corpo + estalo) * 0.9
	return _wav(b)


func _coracao() -> AudioStreamWAV:
	var b := _buffer(0.5)
	for i in b.size():
		var t := float(i) / TAXA
		var v := 0.0
		for inicio in [0.0, 0.17]:
			var u: float = t - inicio
			if u >= 0.0:
				v += sin(TAU * 52.0 * u) * exp(-u * 22.0) * (1.0 if inicio == 0.0 else 0.7)
		b[i] = v * 0.9
	return _wav(b)


func _apito(duracao: float) -> AudioStreamWAV:
	var b := _buffer(duracao)
	var fase := 0.0
	for i in b.size():
		var t := float(i) / TAXA
		var f := 2950.0 + sin(TAU * 32.0 * t) * 160.0
		fase += TAU * f / TAXA
		var env := minf(t / 0.02, 1.0) * minf((duracao - t) / 0.05, 1.0)
		var trinado := 0.75 + 0.25 * sin(TAU * 32.0 * t)
		b[i] = (sin(fase) * 0.6 + sin(fase * 2.0) * 0.12) * env * trinado * 0.55
	return _wav(b)


func _apito_final() -> AudioStreamWAV:
	var b := _buffer(1.9)
	var trechos := [[0.0, 0.32], [0.45, 0.32], [0.9, 0.95]]
	var fase := 0.0
	for i in b.size():
		var t := float(i) / TAXA
		var v := 0.0
		for tr in trechos:
			var u: float = t - tr[0]
			if u >= 0.0 and u < tr[1]:
				var env := minf(u / 0.02, 1.0) * minf((tr[1] - u) / 0.05, 1.0)
				v = env * (0.75 + 0.25 * sin(TAU * 32.0 * t))
		fase += TAU * (2950.0 + sin(TAU * 32.0 * t) * 160.0) / TAXA
		b[i] = sin(fase) * v * 0.5
	return _wav(b)


func _moeda() -> AudioStreamWAV:
	var b := _buffer(0.5)
	for i in b.size():
		var t := float(i) / TAXA
		var v := sin(TAU * 1567.98 * t) * exp(-t * 14.0) * 0.4
		if t > 0.08:
			var u := t - 0.08
			v += sin(TAU * 2093.0 * u) * exp(-u * 9.0) * 0.45
		b[i] = v
	return _wav(b)


func _arpejo(notas: Array, passo: float, duracao: float) -> AudioStreamWAV:
	var b := _buffer(duracao + passo * notas.size())
	for i in b.size():
		var t := float(i) / TAXA
		var v := 0.0
		for k in notas.size():
			var u: float = t - k * passo
			if u >= 0.0:
				var f: float = notas[k]
				v += (sin(TAU * f * u) + 0.3 * sin(TAU * f * 2.0 * u)) * exp(-u * 7.0) * 0.28
		b[i] = v
	return _wav(b)


func _rede() -> AudioStreamWAV:
	var b := _buffer(0.45)
	var y := 0.0
	var anterior := 0.0
	for i in b.size():
		var t := float(i) / TAXA
		var x := _rng.randf_range(-1, 1)
		var hp := x - anterior  # passa-alta simples: "swish"
		anterior = x
		y = y * 0.5 + hp * 0.5
		b[i] = y * minf(t / 0.03, 1.0) * exp(-t * 7.0) * 0.6
	return _wav(b)


func _rebobinar() -> AudioStreamWAV:
	var b := _buffer(0.9)
	var fase := 0.0
	for i in b.size():
		var t := float(i) / TAXA
		var f := lerpf(1400.0, 180.0, t / 0.9)
		fase += TAU * f / TAXA
		var trem := 0.6 + 0.4 * sin(TAU * 18.0 * t)
		b[i] = (sin(fase) * 0.35 + _rng.randf_range(-1, 1) * 0.08) * trem * minf((0.9 - t) / 0.1, 1.0)
	return _wav(b)


func _carta() -> AudioStreamWAV:
	var b := _buffer(0.25)
	var y := 0.0
	for i in b.size():
		var t := float(i) / TAXA
		y = y * 0.6 + _rng.randf_range(-1, 1) * 0.4
		b[i] = y * sin(PI * t / 0.25) * 0.45
	return _wav(b)


## Ruído de multidão: soma de "vozes" de ruído filtrado com modulação lenta.
func _rugido(duracao: float, ataque: float, comemoracao: bool) -> AudioStreamWAV:
	var b := _buffer(duracao)
	var y1 := 0.0
	var y2 := 0.0
	var brilho := 0.35 if comemoracao else 0.12
	for i in b.size():
		var t := float(i) / TAXA
		var x := _rng.randf_range(-1, 1)
		y1 = y1 * 0.92 + x * 0.08
		y2 = y2 * (1.0 - brilho) + x * brilho
		var env := minf(t / ataque, 1.0) * clampf((duracao - t) / (duracao * 0.6), 0.0, 1.0)
		var mod := 0.8 + 0.2 * sin(TAU * 3.1 * t) * sin(TAU * 1.3 * t)
		b[i] = (y1 * 2.4 + y2 * 0.9) * env * mod * 0.7
	return _wav(b)


func _torcida_loop() -> AudioStreamWAV:
	var dur := 4.0
	var cross := 0.5
	var b := _buffer(dur + cross)
	var y1 := 0.0
	var y2 := 0.0
	for i in b.size():
		var t := float(i) / TAXA
		var x := _rng.randf_range(-1, 1)
		y1 = y1 * 0.95 + x * 0.05
		y2 = y2 * 0.8 + x * 0.2
		var mod := 0.75 + 0.15 * sin(TAU * 0.5 * t) + 0.1 * sin(TAU * 2.3 * t)
		b[i] = (y1 * 2.8 + y2 * 0.35) * mod * 0.6
	# crossfade para o loop não "estalar"
	var n := int(dur * TAXA)
	var nc := int(cross * TAXA)
	var final := PackedFloat32Array()
	final.resize(n)
	for i in n:
		final[i] = b[i]
	for i in nc:
		var a := float(i) / nc
		final[i] = b[i] * a + b[n + i] * (1.0 - a)
	return _wav(final, true)


## Batucada de samba (surdo, caixa, tamborim) + cavaquinho em Karplus-Strong.
func _samba() -> AudioStreamWAV:
	var bpm := 102.0
	var batida := 60.0 / bpm
	var compassos := 4
	var dur := batida * 4.0 * compassos
	var b := _buffer(dur)
	var semi := batida / 4.0
	var total_semis := 16 * compassos
	var tamborim := [1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1, 0, 1, 0]
	var caixa := [1, 0, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 1, 0, 1, 1]
	for s in total_semis:
		var t0 := s * semi
		var pos := s % 16
		# surdo: marcação no 2 e no 4 (forte), resposta no 1 e no 3 (abafado)
		if pos == 4 or pos == 12:
			_somar_surdo(b, t0, 1.0)
		elif pos == 0 or pos == 8:
			_somar_surdo(b, t0, 0.35)
		if caixa[pos] == 1:
			_somar_ruido(b, t0, 0.07, 0.12 if pos % 4 == 0 else 0.07, 0.55)
		if tamborim[pos] == 1:
			_somar_tom(b, t0, 0.05, 1350.0, 0.10)
	# acordes: C6 - A7 - Dm7 - G7 (um por compasso), tocados em síncope
	var acordes := [[261.63, 329.63, 392.0, 440.0], [220.0, 277.18, 329.63, 392.0],
		[293.66, 349.23, 440.0, 523.25], [196.0, 246.94, 293.66, 349.23]]
	var ritmo := [0, 3, 6, 10, 12]
	for c in compassos:
		for r in ritmo:
			var t0: float = (c * 16 + r) * semi
			var notas: Array = acordes[c]
			for k in notas.size():
				_somar_corda(b, t0 + k * 0.012, notas[k], 0.11)
	# normaliza
	var pico := 0.001
	for v in b:
		pico = maxf(pico, absf(v))
	for i in b.size():
		b[i] = b[i] / pico * 0.8
	return _wav(b, true)


func _somar_surdo(b: PackedFloat32Array, t0: float, forca: float) -> void:
	var i0 := int(t0 * TAXA)
	var n := int(0.45 * TAXA)
	var fase := 0.0
	for k in n:
		if i0 + k >= b.size():
			return
		var t := float(k) / TAXA
		fase += TAU * lerpf(95.0, 62.0, minf(t / 0.06, 1.0)) / TAXA
		b[i0 + k] += sin(fase) * exp(-t * (6.0 if forca > 0.5 else 14.0)) * 0.55 * forca


func _somar_ruido(b: PackedFloat32Array, t0: float, dur: float, vol: float, cor: float) -> void:
	var i0 := int(t0 * TAXA)
	var y := 0.0
	var ant := 0.0
	for k in int(dur * TAXA):
		if i0 + k >= b.size():
			return
		var t := float(k) / TAXA
		var x := _rng.randf_range(-1, 1)
		y = (x - ant) * cor + y * (1.0 - cor)
		ant = x
		b[i0 + k] += y * exp(-t * 45.0) * vol


func _somar_tom(b: PackedFloat32Array, t0: float, dur: float, f: float, vol: float) -> void:
	var i0 := int(t0 * TAXA)
	for k in int(dur * TAXA):
		if i0 + k >= b.size():
			return
		var t := float(k) / TAXA
		b[i0 + k] += (sin(TAU * f * t) + _rng.randf_range(-0.3, 0.3)) * exp(-t * 60.0) * vol


func _somar_corda(b: PackedFloat32Array, t0: float, f: float, vol: float) -> void:
	var n := maxi(2, int(TAXA / f))
	var anel := PackedFloat32Array()
	anel.resize(n)
	for k in n:
		anel[k] = _rng.randf_range(-1, 1)
	var i0 := int(t0 * TAXA)
	var dur := int(0.5 * TAXA)
	var idx := 0
	for k in dur:
		if i0 + k >= b.size():
			return
		var prox := (idx + 1) % n
		var v := (anel[idx] + anel[prox]) * 0.497
		anel[idx] = v
		idx = prox
		b[i0 + k] += v * vol
