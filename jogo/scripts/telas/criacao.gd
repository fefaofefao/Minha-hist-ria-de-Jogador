extends Control
## Criação do jogador: nome, apelido, posição e visual, com prévia 3D ao vivo.
## Na "Nova Geração", o filho herda talento do pai (Jogo.perfil["heranca"]).

const NOMES := ["Lucas", "Gabriel", "Rafael", "Matheus", "Pedro", "João", "Gustavo", "Felipe", "Davi", "Arthur",
	"Bruno", "Thiago", "Vinícius", "Caio", "Igor", "Wesley", "Kauã", "Ryan", "Enzo", "Miguel"]
const APELIDOS := ["Pelezinho", "Foguete", "Neymito", "Tico", "Bala", "Raio", "Mágico", "Fenômeno", "Canhota",
	"Furacão", "Maestro", "Zico Jr.", "Diamante", "Cometa", "Faísca"]

var vitrine: Vitrine3D
var dados := {"nome": "", "apelido": "", "posicao": "Atacante", "pele": 2, "cabelo": 1, "cor_cabelo": 0, "chuteira": "preta", "numero": 10}
var heranca := {}
var _campo_nome: LineEdit
var _campo_apelido: LineEdit
var _botoes_posicao := {}
var _lbl_pos: Label
var _lbl_numero: Label
var _grupos := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	heranca = Jogo.perfil.get("heranca", {})
	dados["nome"] = NOMES[randi() % NOMES.size()]
	dados["apelido"] = APELIDOS[randi() % APELIDOS.size()]
	dados["pele"] = randi() % 6
	if not heranca.is_empty():
		dados["apelido"] = "%s Jr." % heranca.get("pai", "Craque")
	vitrine = Vitrine3D.new()
	add_child(vitrine)
	vitrine.construir("varzea", false, _visual(), Dados.VILA["cor"], Dados.VILA["calcao"], dados["numero"])
	vitrine.foco = Vector3(0, 1.0, -28)
	vitrine.raio = 5.6
	vitrine.altura = 1.4
	vitrine.velocidade = 0.35
	vitrine.deslocamento_foco = Vector3(0, -1.25, 0)  # o painel cobre a metade de baixo
	vitrine.embaixadinha = false
	Audio.musica(true)
	_ui()


func _visual() -> Dictionary:
	return {"pele": dados["pele"], "cabelo": dados["cabelo"], "cor_cabelo": dados["cor_cabelo"],
		"chuteira": Color(Dados.CHUTEIRAS[dados["chuteira"]]["cor"])}


func _atualizar_3d() -> void:
	vitrine.trocar_visual(_visual(), Dados.VILA["cor"], Dados.VILA["calcao"], dados["numero"])


func _ui() -> void:
	var topo := UI.margem(24, 20 + Tela.margem_topo(), 24, 0)
	topo.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	add_child(topo)
	var lt := UI.hbox(12)
	topo.add_child(lt)
	var voltar := UI.botao("", "voltar", "fantasma", 68)
	voltar.custom_minimum_size = Vector2(68, 68)
	voltar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	voltar.pressed.connect(func() -> void: Tela.ir("res://cenas/menu.tscn"))
	lt.add_child(voltar)
	var tcol := UI.vbox(0)
	tcol.add_child(UI.titulo("QUEM É VOCÊ?" if heranca.is_empty() else "NOVA GERAÇÃO", 44))
	tcol.add_child(UI.rotulo("Vila Esperança, 2026" if heranca.is_empty() else "Filho de %s • herdou %s" % [heranca.get("pai", ""), Dados.NOMES_ATRIBUTOS.get(heranca.get("melhor", ""), "talento")], 21, UI.TEXTO2, "forte"))
	lt.add_child(tcol)

	var painel := PanelContainer.new()
	var st := UI.caixa(Color(UI.FUNDO, 0.97), 0, 0)
	st.corner_radius_top_left = 30
	st.corner_radius_top_right = 30
	st.content_margin_left = 26
	st.content_margin_right = 26
	st.content_margin_top = 24
	st.content_margin_bottom = 24
	st.shadow_color = Color(0, 0, 0, 0.5)
	st.shadow_size = 20
	painel.add_theme_stylebox_override("panel", st)
	add_child(painel)
	painel.anchor_left = 0
	painel.anchor_right = 1
	painel.anchor_top = 0.43
	painel.anchor_bottom = 1
	var col_total := UI.vbox(14)
	painel.add_child(col_total)
	var rol := UI.rolagem()
	col_total.add_child(rol)
	var col := UI.vbox(20)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rol.add_child(col)

	# nome e apelido
	var nomes := UI.hbox(14)
	_campo_nome = _campo("Nome", dados["nome"], nomes)
	_campo_apelido = _campo("Apelido (nome na camisa)", dados["apelido"], nomes)
	col.add_child(nomes)

	# posição
	col.add_child(UI.rotulo("POSIÇÃO", 21, UI.TEXTO2, "titulo"))
	var pos := UI.hbox(12)
	for p in Dados.POSICOES:
		var b := UI.botao(p, {"Atacante": "bola", "Ponta": "correr", "Meia": "olho"}[p], "normal", 76)
		b.pressed.connect(_escolher_posicao.bind(p))
		_botoes_posicao[p] = b
		pos.add_child(b)
	col.add_child(pos)
	_lbl_pos = UI.paragrafo("", 22)
	col.add_child(_lbl_pos)
	_escolher_posicao(dados["posicao"])

	# visual
	col.add_child(UI.rotulo("PELE", 21, UI.TEXTO2, "titulo"))
	col.add_child(_amostras("pele", Jogador3D.PELES, func(_i) -> bool: return true))
	col.add_child(UI.rotulo("CABELO", 21, UI.TEXTO2, "titulo"))
	var estilos := HFlowContainer.new()
	estilos.add_theme_constant_override("h_separation", 10)
	estilos.add_theme_constant_override("v_separation", 10)
	_grupos["cabelo"] = []
	for i in Jogador3D.ESTILOS_CABELO.size():
		var b := UI.botao(Jogador3D.ESTILOS_CABELO[i], "", "normal", 62)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.custom_minimum_size.x = 150
		b.pressed.connect(func() -> void:
			dados["cabelo"] = i
			_marcar("cabelo", i)
			_atualizar_3d())
		_grupos["cabelo"].append(b)
		estilos.add_child(b)
	col.add_child(estilos)
	_marcar("cabelo", dados["cabelo"])
	col.add_child(UI.rotulo("COR DO CABELO", 21, UI.TEXTO2, "titulo"))
	col.add_child(_amostras("cor_cabelo", Jogador3D.CORES_CABELO, func(i) -> bool: return Jogo.tem_cosmetico("cores_cabelo", i) or i <= 4))
	col.add_child(UI.rotulo("CHUTEIRA", 21, UI.TEXTO2, "titulo"))
	var ids_ch: Array = []
	var cores_ch: Array = []
	for id in Dados.CHUTEIRAS:
		ids_ch.append(id)
		cores_ch.append(Color(Dados.CHUTEIRAS[id]["cor"]))
	col.add_child(_amostras("chuteira", cores_ch, func(i) -> bool: return Jogo.tem_cosmetico("chuteiras", ids_ch[i]), ids_ch))

	# número
	var num := UI.hbox(12)
	num.add_child(UI.rotulo("NÚMERO DA CAMISA", 21, UI.TEXTO2, "titulo"))
	num.add_child(UI.expansor())
	var menos := UI.botao("", "desce", "normal", 64)
	menos.custom_minimum_size = Vector2(64, 64)
	menos.size_flags_horizontal = Control.SIZE_SHRINK_END
	menos.pressed.connect(_numero.bind(-1))
	num.add_child(menos)
	_lbl_numero = UI.titulo(str(dados["numero"]), 44, UI.OURO)
	_lbl_numero.custom_minimum_size.x = 70
	_lbl_numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.add_child(_lbl_numero)
	var mais := UI.botao("", "sobe", "normal", 64)
	mais.custom_minimum_size = Vector2(64, 64)
	mais.size_flags_horizontal = Control.SIZE_SHRINK_END
	mais.pressed.connect(_numero.bind(1))
	num.add_child(mais)
	col.add_child(num)
	col.add_child(UI.espaco(10))

	var entrar := UI.botao("Entrar em campo", "play", "primario", 96)
	entrar.pressed.connect(_confirmar)
	col_total.add_child(entrar)


func _campo(rotulo: String, valor: String, pai: Control) -> LineEdit:
	var c := UI.vbox(6)
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_child(UI.rotulo(rotulo.to_upper(), 19, UI.TEXTO2, "titulo"))
	var e := LineEdit.new()
	e.text = valor
	e.max_length = 16
	e.add_theme_font_override("font", UI.fonte("forte"))
	e.custom_minimum_size.y = 70
	e.select_all_on_focus = true
	c.add_child(e)
	pai.add_child(c)
	return e


func _amostras(chave: String, cores: Array, liberado: Callable, ids := []) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 12)
	f.add_theme_constant_override("v_separation", 12)
	_grupos[chave] = []
	for i in cores.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(64, 64)
		b.focus_mode = Control.FOCUS_NONE
		var s := UI.caixa(cores[i], 32, 0)
		s.border_color = Color(1, 1, 1, 0.2)
		s.set_border_width_all(3)
		var sel: StyleBoxFlat = s.duplicate()
		sel.border_color = UI.OURO
		sel.set_border_width_all(5)
		b.set_meta("normal", s)
		b.set_meta("sel", sel)
		for estado in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(estado, s)
		var livre: bool = liberado.call(i)
		if not livre:
			var cad := UI.icone("cadeado", 28, Color(1, 1, 1, 0.9))
			cad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			b.add_child(cad)
		b.pressed.connect(func() -> void:
			Audio.tocar("clique")
			if not livre:
				var origem := ""
				if chave == "chuteira":
					origem = Dados.CHUTEIRAS[ids[i]].get("origem", "Loja")
				Tela.aviso("Desbloqueie na Loja%s." % ((" (" + origem + ")") if origem != "" else ""), "cadeado")
				return
			dados[chave] = ids[i] if not ids.is_empty() else i
			_marcar(chave, i)
			_atualizar_3d())
		_grupos[chave].append(b)
		f.add_child(b)
	var atual = dados[chave]
	_marcar(chave, ids.find(atual) if not ids.is_empty() else int(atual))
	return f


func _marcar(chave: String, indice: int) -> void:
	var lista: Array = _grupos.get(chave, [])
	for i in lista.size():
		var b: Button = lista[i]
		if b.has_meta("normal"):
			var s: StyleBox = b.get_meta("sel") if i == indice else b.get_meta("normal")
			for estado in ["normal", "hover", "pressed"]:
				b.add_theme_stylebox_override(estado, s)
		else:
			b.modulate = UI.OURO if i == indice else Color.WHITE


func _escolher_posicao(p: String) -> void:
	dados["posicao"] = p
	for k in _botoes_posicao:
		var b: Button = _botoes_posicao[k]
		b.modulate = UI.OURO.lightened(0.3) if k == p else Color(1, 1, 1, 0.75)
	_lbl_pos.text = Dados.DESCRICAO_POSICOES[p]


func _numero(d: int) -> void:
	dados["numero"] = wrapi(int(dados["numero"]) + d, 1, 100)
	_lbl_numero.text = str(dados["numero"])
	_atualizar_3d()


func _confirmar() -> void:
	dados["nome"] = _campo_nome.text.strip_edges()
	dados["apelido"] = _campo_apelido.text.strip_edges()
	if dados["nome"] == "" or dados["apelido"] == "":
		Tela.aviso("Preencha nome e apelido.", "info", UI.VERMELHO)
		return
	if not heranca.is_empty():
		dados["herdado"] = heranca
		dados["geracao"] = heranca.get("geracao", 2)
	Jogo.nova_carreira(dados)
	Jogo.perfil.erase("heranca")
	Jogo.salvar_perfil()
	Jogo.preparar_prologo()
	Tela.ir("res://cenas/partida.tscn")
