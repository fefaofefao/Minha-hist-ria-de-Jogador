extends TelaBase
## Configurações: som, música, vibração, sensibilidade do olhar, privacidade,
## restauração de compras e apagar carreira.

const URL_PRIVACIDADE := "https://fefaofefao.github.io/Minha-hist-ria-de-Jogador/privacidade.html"


func construir() -> void:
	cabecalho("CONFIGURAÇÕES", "res://cenas/menu.tscn")
	var cfg: Dictionary = Jogo.perfil["config"]
	var rol := UI.rolagem()
	conteudo.add_child(rol)
	var col := UI.vbox(16)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(col)
	var som := Componentes.secao("Som", "som")
	som[1].add_child(_slider("Efeitos e torcida", "som", 0.0, 1.0))
	som[1].add_child(_slider("Batucada do menu", "musica", 0.0, 1.0))
	col.add_child(som[0])
	var jogo := Componentes.secao("Jogo", "esporte")
	jogo[1].add_child(_slider("Sensibilidade do olhar", "sensibilidade", 0.5, 2.0))
	var vib := CheckButton.new()
	vib.text = "Vibração (batimentos e chutes)"
	vib.button_pressed = bool(cfg.get("vibracao", true))
	vib.add_theme_font_override("font", UI.fonte("forte"))
	vib.add_theme_font_size_override("font_size", 24)
	vib.toggled.connect(func(v: bool) -> void:
		cfg["vibracao"] = v
		Jogo.salvar_perfil())
	jogo[1].add_child(vib)
	col.add_child(jogo[0])
	var conta := Componentes.secao("Conta e privacidade", "escudo", UI.AZUL)
	var priv := UI.botao("Política de privacidade", "info", "normal", 72)
	priv.pressed.connect(func() -> void: OS.shell_open(URL_PRIVACIDADE))
	conta[1].add_child(priv)
	var rest := UI.botao("Restaurar compras", "historico", "normal", 72)
	rest.pressed.connect(func() -> void: Compras.restaurar())
	conta[1].add_child(rest)
	if Jogo.tem_carreira():
		var apagar := UI.botao("Apagar carreira atual", "fechar", "perigo", 72)
		apagar.pressed.connect(func() -> void:
			var r := await Tela.dialogo("Apagar carreira?", "Isso não pode ser desfeito. Moedas, compras e Hall da Fama continuam.",
				[["Apagar", "fechar", "perigo"], ["Cancelar", "voltar", "fantasma"]], "info", UI.VERMELHO)
			if r == 0:
				Jogo.apagar_carreira()
				Tela.ir("res://cenas/menu.tscn"))
		conta[1].add_child(apagar)
	col.add_child(conta[0])
	var sobre := Componentes.secao("Sobre", "info", UI.TEXTO2)
	sobre[1].add_child(UI.paragrafo("Minha História de Jogador v%s\nClubes, ligas, marcas e jogadores são fictícios.\nFontes: Barlow (OFL) e Material Icons (Apache 2.0).\nServiços: anúncios %s • loja %s • analytics %s" % [
		ProjectSettings.get_setting("application/config/version", "1.0"), Anuncios.backend, Compras.backend, Analytics.backend], 20, UI.TEXTO3))
	col.add_child(sobre[0])


func _slider(texto: String, chave: String, minimo: float, maximo: float) -> VBoxContainer:
	var cfg: Dictionary = Jogo.perfil["config"]
	var v := UI.vbox(8)
	var topo := UI.hbox(8)
	var l := UI.rotulo(texto, 23, UI.TEXTO, "forte")
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(l)
	var val := UI.rotulo("%d%%" % int(float(cfg.get(chave, 1.0)) * 100), 22, UI.OURO, "titulo")
	topo.add_child(val)
	v.add_child(topo)
	var s := HSlider.new()
	s.min_value = minimo
	s.max_value = maximo
	s.step = 0.05
	s.value = float(cfg.get(chave, 1.0))
	s.custom_minimum_size.y = 44
	s.value_changed.connect(func(x: float) -> void:
		cfg[chave] = x
		val.text = "%d%%" % int(x * 100)
		Audio.atualizar_volumes())
	s.drag_ended.connect(func(_c: bool) -> void:
		Jogo.salvar_perfil()
		if chave == "som":
			Audio.tocar("moeda"))
	v.add_child(s)
	return v
