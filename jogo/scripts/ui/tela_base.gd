class_name TelaBase
extends Control
## Base para as telas 2D: fundo com gradiente, área segura e cabeçalho padrão.

var conteudo: VBoxContainer  # coluna principal dentro das margens seguras


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_criar_fundo()
	var m := UI.margem(28, 24 + Tela.margem_topo(), 28, 24)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	conteudo = UI.vbox(18)
	m.add_child(conteudo)
	construir()


## Sobrescrever nas telas.
func construir() -> void:
	pass


func _criar_fundo() -> void:
	var g := Gradient.new()
	g.set_color(0, Color("17233b"))
	g.set_color(1, UI.FUNDO)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 0.75)
	var fundo := TextureRect.new()
	fundo.texture = tex
	fundo.stretch_mode = TextureRect.STRETCH_SCALE
	fundo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fundo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fundo)
	var linhas := LinhasCampo.new()
	linhas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(linhas)


func cabecalho(texto: String, voltar_para := "", subtitulo := "") -> HBoxContainer:
	var linha := UI.hbox(14)
	if voltar_para != "":
		var b := UI.botao("", "voltar", "fantasma", 72)
		b.custom_minimum_size = Vector2(72, 72)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.pressed.connect(func() -> void: Tela.ir(voltar_para))
		linha.add_child(b)
	var col := UI.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UI.titulo(texto, 46))
	if subtitulo != "":
		col.add_child(UI.rotulo(subtitulo, 22, UI.TEXTO2, "forte"))
	linha.add_child(col)
	conteudo.add_child(linha)
	return linha


## Desenho sutil de linhas de campo no fundo (identidade visual).
class LinhasCampo extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Color(1, 1, 1, 0.025)
		var w := size.x
		var h := size.y
		draw_arc(Vector2(w / 2.0, h * 0.62), w * 0.32, 0, TAU, 64, c, 3.0, true)
		draw_line(Vector2(0, h * 0.62), Vector2(w, h * 0.62), c, 3.0)
		draw_rect(Rect2(w * 0.18, h - h * 0.12, w * 0.64, h * 0.2), c, false, 3.0)
