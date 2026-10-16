extends Node
## Autoload "Anuncios": camada única para anúncios.
##
## - Se o plugin AdMob da Poing Studios estiver instalado (addons/admob) e o app
##   rodar no Android, usa anúncios reais (com consentimento UMP/LGPD).
## - Caso contrário, usa um anúncio SIMULADO (tela de 5 s marcada como teste),
##   para o jogo ficar 100% jogável e testável.
##
## Regras de experiência (config/servicos.cfg):
## - Nenhum intersticial antes da 3ª partida, nunca no meio de um lance,
##   no máximo 1 a cada 2 partidas e com intervalo mínimo de 3 minutos.
## - Quem compra "Remover anúncios" ou "Craque VIP" nunca vê intersticial.
## - Recompensados são sempre opcionais e diegéticos (patrocinador, fisio, "E se...?").

signal recompensa_concluida(ok: bool)

var cfg := ConfigFile.new()
var backend := "simulado"
var _admob := {}  # classes do plugin carregadas dinamicamente
var _recompensado_carregado = null
var _intersticial_carregado = null
var _carregando_recompensado := false
var _carregando_intersticial := false
var _ultimo_intersticial_ms := -1000000
var _camada: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	cfg.load("res://config/servicos.cfg")
	_camada = CanvasLayer.new()
	_camada.layer = 120
	add_child(_camada)
	if OS.get_name() == "Android" and _carregar_classes_admob():
		backend = "admob"
		_iniciar_admob()
	Analytics.evento("anuncios_backend", {"backend": backend})


func _carregar_classes_admob() -> bool:
	var nomes := ["MobileAds", "AdRequest", "RewardedAdLoader", "RewardedAdLoadCallback",
		"InterstitialAdLoader", "InterstitialAdLoadCallback", "OnUserEarnedRewardListener",
		"UserMessagingPlatform", "ConsentRequestParameters"]
	for c in ProjectSettings.get_global_class_list():
		if c["class"] in nomes:
			_admob[c["class"]] = load(c["path"])
	return _admob.size() >= 7


func _iniciar_admob() -> void:
	# Consentimento (LGPD/GDPR) via UMP antes de inicializar o SDK.
	if _admob.has("UserMessagingPlatform") and _admob.has("ConsentRequestParameters"):
		var params = _admob["ConsentRequestParameters"].new()
		_admob["UserMessagingPlatform"].consent_information.update(params, _consentimento_atualizado, _ignorar_erro)
	_admob["MobileAds"].initialize()
	_carregar_recompensado()
	_carregar_intersticial()


func _consentimento_atualizado() -> void:
	_admob["UserMessagingPlatform"].load_consent_form(_formulario_carregado, _ignorar_erro)


func _formulario_carregado(form) -> void:
	const REQUERIDO := 2  # ConsentInformation.ConsentStatus.REQUIRED
	if _admob["UserMessagingPlatform"].consent_information.get_consent_status() == REQUERIDO:
		form.show(_ignorar_erro)


func _ignorar_erro(_erro = null) -> void:
	pass


func _id(chave: String) -> String:
	return str(cfg.get_value("admob", chave + "_android", ""))


func _carregar_recompensado() -> void:
	if backend != "admob" or _carregando_recompensado or _recompensado_carregado != null:
		return
	_carregando_recompensado = true
	var cb = _admob["RewardedAdLoadCallback"].new()
	cb.on_ad_loaded = func(ad) -> void:
		_recompensado_carregado = ad
		_carregando_recompensado = false
	cb.on_ad_failed_to_load = func(erro) -> void:
		_carregando_recompensado = false
		Analytics.evento("anuncio_falhou", {"tipo": "recompensado", "erro": str(erro.message)})
		get_tree().create_timer(30.0).timeout.connect(_carregar_recompensado)
	_admob["RewardedAdLoader"].new().load(_id("recompensado"), _admob["AdRequest"].new(), cb)


func _carregar_intersticial() -> void:
	if backend != "admob" or _carregando_intersticial or _intersticial_carregado != null:
		return
	_carregando_intersticial = true
	var cb = _admob["InterstitialAdLoadCallback"].new()
	cb.on_ad_loaded = func(ad) -> void:
		_intersticial_carregado = ad
		_carregando_intersticial = false
	cb.on_ad_failed_to_load = func(erro) -> void:
		_carregando_intersticial = false
		get_tree().create_timer(45.0).timeout.connect(_carregar_intersticial)
	_admob["InterstitialAdLoader"].new().load(_id("intersticial"), _admob["AdRequest"].new(), cb)


func sem_anuncios() -> bool:
	return Jogo.tem_compra("remover_anuncios") or Jogo.tem_compra("craque_vip")


## Mostra um anúncio recompensado. Retorna true se o jogador ganhou a recompensa.
func recompensado(local: String) -> bool:
	Analytics.evento("anuncio_recompensado_pedido", {"local": local})
	var ok := false
	if backend == "admob" and _recompensado_carregado != null:
		ok = await _mostrar_recompensado_admob()
	else:
		ok = await _simular(true, local)
	if ok:
		Jogo.perfil["contadores"]["recompensados"] = int(Jogo.perfil["contadores"].get("recompensados", 0)) + 1
		Jogo.salvar_perfil()
		Analytics.evento("anuncio_recompensado_ganho", {"local": local})
	return ok


func _mostrar_recompensado_admob() -> bool:
	var ad = _recompensado_carregado
	_recompensado_carregado = null
	var ganhou := [false]
	var fechou := [false]
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
		fechou[0] = true
		recompensa_concluida.emit(ganhou[0])
	ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_e) -> void:
		fechou[0] = true
		recompensa_concluida.emit(false)
	var ouvinte = _admob["OnUserEarnedRewardListener"].new()
	ouvinte.on_user_earned_reward = func(_item) -> void:
		ganhou[0] = true
	Audio.musica(false)
	ad.show(ouvinte)
	while not fechou[0]:
		await recompensa_concluida
	_carregar_recompensado()
	return ganhou[0]


## Intersticial com as regras de frequência. Chamar só em pausas naturais (pós-jogo).
func talvez_intersticial(local: String) -> void:
	var c: Dictionary = Jogo.perfil["contadores"]
	c["partidas_desde_intersticial"] = int(c.get("partidas_desde_intersticial", 0)) + 1
	if sem_anuncios():
		return
	var minimas := int(cfg.get_value("regras_anuncios", "intersticial_partidas_minimas", 3))
	var a_cada := int(cfg.get_value("regras_anuncios", "intersticial_a_cada_partidas", 2))
	var intervalo := int(cfg.get_value("regras_anuncios", "intersticial_intervalo_segundos", 180)) * 1000
	if int(c.get("partidas_total", 0)) < minimas:
		return
	if int(c["partidas_desde_intersticial"]) < a_cada:
		return
	if Time.get_ticks_msec() - _ultimo_intersticial_ms < intervalo:
		return
	c["partidas_desde_intersticial"] = 0
	_ultimo_intersticial_ms = Time.get_ticks_msec()
	Analytics.evento("anuncio_intersticial", {"local": local})
	if backend == "admob":
		if _intersticial_carregado != null:
			var ad = _intersticial_carregado
			_intersticial_carregado = null
			var fechou := [false]
			ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func() -> void:
				fechou[0] = true
				recompensa_concluida.emit(true)
			ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(_e) -> void:
				fechou[0] = true
				recompensa_concluida.emit(false)
			ad.show()
			while not fechou[0]:
				await recompensa_concluida
			_carregar_intersticial()
	else:
		await _simular(false, local)


# ---------------------------------------------------------------- simulação

func _simular(recompensado: bool, local: String) -> bool:
	if DisplayServer.get_name() == "headless" or "--auto" in OS.get_cmdline_user_args():
		return true  # testes automáticos / modo demonstração
	var fundo := ColorRect.new()
	fundo.color = Color(0.02, 0.02, 0.04, 0.97)
	fundo.mouse_filter = Control.MOUSE_FILTER_STOP
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_camada.add_child(fundo)
	var centro := CenterContainer.new()
	centro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fundo.add_child(centro)
	var col := UI.vbox(22)
	col.custom_minimum_size = Vector2(560, 0)
	centro.add_child(col)
	var tag := UI.rotulo("ANÚNCIO SIMULADO  •  MODO DE TESTE", 22, UI.TEXTO3, "forte")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(tag)
	var marca := UI.cartao_borda(Color("101a2e"), UI.AZUL, 26, 36)
	var mc := UI.vbox(10)
	marca.add_child(mc)
	var ic := UI.icone("energia", 96, UI.OURO)
	mc.add_child(ic)
	var t := UI.titulo("RAIO ENERGÉTICO", 54, UI.OURO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mc.add_child(t)
	var p := UI.paragrafo("Aqui aparecerá o anúncio do AdMob quando o plugin estiver instalado.", 24)
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mc.add_child(p)
	col.add_child(marca)
	var contador := UI.titulo("5", 64)
	contador.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(contador)
	var fechar := UI.botao("Fechar", "fechar", "fantasma", 76)
	fechar.disabled = true
	col.add_child(fechar)
	var concluido := [false]
	var ganhou := [false]
	fechar.pressed.connect(func() -> void:
		concluido[0] = true
		recompensa_concluida.emit(ganhou[0]))
	for k in range(5, 0, -1):
		contador.text = str(k)
		await get_tree().create_timer(1.0, true, false, true).timeout
	contador.text = "Recompensa garantida!" if recompensado else ""
	ganhou[0] = true
	fechar.disabled = false
	while not concluido[0]:
		await recompensa_concluida
	fundo.queue_free()
	return ganhou[0] if recompensado else true
