class_name UI
extends RefCounted
## Kit de interface: paleta, fontes, ícones e construtores de componentes.
## Todas as telas são montadas por código usando estas funções, para manter
## o visual consistente.

const FUNDO := Color("0b111c")
const FUNDO2 := Color("121a29")
const CARTAO := Color("18233a")
const CARTAO2 := Color("21304d")
const LINHA := Color("2c3c5e")
const OURO := Color("ffc928")
const OURO_ESCURO := Color("c99400")
const VERDE := Color("2ed47a")
const VERMELHO := Color("ff5468")
const AZUL := Color("43a8ff")
const ROXO := Color("a77bff")
const LARANJA := Color("ff9a3c")
const TEXTO := Color("f3f6fb")
const TEXTO2 := Color("98a6bf")
const TEXTO3 := Color("5f6e88")

const ICONES := {
	"bola": 0xea2f, "energia": 0xea0b, "coracao": 0xe87d, "estrela": 0xe838, "trofeu": 0xea23,
	"moeda": 0xe263, "loja": 0xea12, "config": 0xe8b8, "play": 0xe037, "casa": 0xe88a,
	"pessoa": 0xe7fd, "album": 0xe3b6, "familia": 0xf1a2, "grupo": 0xf233, "treino": 0xeb43,
	"cama": 0xefdf, "escola": 0xe80c, "celular": 0xe32c, "cura": 0xe3f3, "dinheiro": 0xe227,
	"cadeado": 0xe897, "ok": 0xe86c, "voltar": 0xe5c4, "seta": 0xe5cc, "replay": 0xe042,
	"video": 0xe02c, "tempo": 0xe425, "sobe": 0xe8e5, "desce": 0xe8e3, "aviao": 0xe539,
	"mundo": 0xe80b, "vip": 0xe7af, "brilho": 0xe65f, "mente": 0xea4a, "olho": 0xe8f4,
	"esporte": 0xea30, "aperto": 0xebcb, "jornal": 0xeb81, "feliz": 0xe7f2, "bolo": 0xe7e9,
	"casinha": 0xea44, "carro": 0xe531, "fechar": 0xe5cd, "info": 0xe88e, "som": 0xe050,
	"vibrar": 0xe62d, "calendario": 0xebcc, "medalha": 0xea3f, "fogo": 0xef55, "hoje": 0xe8df,
	"festa": 0xea65, "historico": 0xe889, "reiniciar": 0xf053, "presente": 0xe8f6,
	"grafico": 0xe26b, "ranking": 0xf20c, "troca": 0xe8d4, "escudo": 0xe9e0, "correr": 0xe566,
	"placar": 0xf06e, "zen": 0xea78, "diamante": 0xead5, "foguete": 0xeb9b, "musica": 0xe405,
	"bloqueio": 0xe14b, "desfazer": 0xe166, "seta_esq": 0xe5cb, "seta_dir": 0xe5cc,
	"seta_cima": 0xe5ce, "anuncio": 0xe02c, "coracao_vazio": 0xe87e, "chuteira": 0xea30,
}

static var _fontes := {}


static func fonte(tipo: String) -> Font:
	if _fontes.is_empty():
		_fontes["texto"] = load("res://fontes/Barlow-Medium.ttf")
		_fontes["forte"] = load("res://fontes/Barlow-SemiBold.ttf")
		_fontes["titulo"] = load("res://fontes/BarlowCondensed-Bold.ttf")
		_fontes["display"] = load("res://fontes/BarlowCondensed-ExtraBold.ttf")
		_fontes["icone"] = load("res://fontes/MaterialIcons-Regular.ttf")
	return _fontes[tipo]


static func glifo(nome: String) -> String:
	return char(ICONES.get(nome, 0xe88e))


static func criar_tema() -> Theme:
	var t := Theme.new()
	t.default_font = fonte("texto")
	t.default_font_size = 26
	t.set_color("font_color", "Label", TEXTO)

	var normal := caixa(CARTAO2, 16)
	normal.border_color = LINHA
	normal.set_border_width_all(2)
	var hover := caixa(Color("2a3b5f"), 16)
	hover.border_color = OURO
	hover.set_border_width_all(2)
	var press := caixa(Color("33476f"), 16)
	press.border_color = OURO
	press.set_border_width_all(2)
	var desab := caixa(Color("161f33"), 16)
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", press)
	t.set_stylebox("disabled", "Button", desab)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", fonte("forte"))
	t.set_color("font_color", "Button", TEXTO)
	t.set_color("font_hover_color", "Button", TEXTO)
	t.set_color("font_pressed_color", "Button", TEXTO)
	t.set_color("font_disabled_color", "Button", TEXTO3)

	t.set_stylebox("panel", "PanelContainer", caixa(CARTAO, 20))
	t.set_stylebox("panel", "Panel", caixa(CARTAO, 20))

	var campo := caixa(FUNDO2, 14)
	campo.border_color = LINHA
	campo.set_border_width_all(2)
	campo.set_content_margin_all(16)
	var campo_foco: StyleBoxFlat = campo.duplicate()
	campo_foco.border_color = OURO
	t.set_stylebox("normal", "LineEdit", campo)
	t.set_stylebox("focus", "LineEdit", campo_foco)
	t.set_color("font_color", "LineEdit", TEXTO)
	t.set_color("caret_color", "LineEdit", OURO)
	t.set_font_size("font_size", "LineEdit", 30)

	var trilho := caixa(FUNDO2, 8)
	trilho.content_margin_top = 6
	trilho.content_margin_bottom = 6
	t.set_stylebox("slider", "HSlider", trilho)
	var area := caixa(OURO, 8)
	area.content_margin_top = 6
	area.content_margin_bottom = 6
	t.set_stylebox("grabber_area", "HSlider", area)
	t.set_stylebox("grabber_area_highlight", "HSlider", area)
	t.set_icon("grabber", "HSlider", _circulo(30, TEXTO))
	t.set_icon("grabber_highlight", "HSlider", _circulo(34, OURO))

	t.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	var pegador := caixa(Color(1, 1, 1, 0.12), 4)
	pegador.content_margin_left = 3
	pegador.content_margin_right = 3
	t.set_stylebox("grabber", "VScrollBar", pegador)
	t.set_stylebox("grabber_highlight", "VScrollBar", pegador)
	t.set_stylebox("grabber_pressed", "VScrollBar", pegador)
	return t


static func _circulo(d: int, cor: Color) -> ImageTexture:
	var img := Image.create(d, d, false, Image.FORMAT_RGBA8)
	var r := d / 2.0
	for y in d:
		for x in d:
			var dist := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			img.set_pixel(x, y, Color(cor, clampf(r - dist, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func caixa(cor: Color, raio := 18, margem := 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = cor
	s.set_corner_radius_all(raio)
	s.set_content_margin_all(margem)
	s.anti_aliasing = true
	return s


# ---------------------------------------------------------------- componentes

static func rotulo(texto: String, tamanho := 26, cor := TEXTO, tipo := "texto") -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", fonte(tipo))
	l.add_theme_font_size_override("font_size", tamanho)
	l.add_theme_color_override("font_color", cor)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func paragrafo(texto: String, tamanho := 24, cor := TEXTO2) -> Label:
	var l := rotulo(texto, tamanho, cor)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 10
	return l


static func titulo(texto: String, tamanho := 44, cor := TEXTO) -> Label:
	return rotulo(texto, tamanho, cor, "display")


static func icone(nome: String, tamanho := 30, cor := TEXTO) -> Label:
	var l := rotulo(glifo(nome), tamanho, cor, "icone")
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


static func vbox(sep := 16) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


static func hbox(sep := 12) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", sep)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


static func margem(esq := 24, topo := 24, dir := 24, base := 24) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", esq)
	m.add_theme_constant_override("margin_top", topo)
	m.add_theme_constant_override("margin_right", dir)
	m.add_theme_constant_override("margin_bottom", base)
	m.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return m


static func espaco(altura := 16) -> Control:
	var c := Control.new()
	c.custom_minimum_size.y = altura
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func expansor() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func cartao(cor := CARTAO, raio := 22, margem := 22) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", caixa(cor, raio, margem))
	return p


static func cartao_borda(cor: Color, borda: Color, raio := 22, margem := 22, largura := 2) -> PanelContainer:
	var s := caixa(cor, raio, margem)
	s.border_color = borda
	s.set_border_width_all(largura)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", s)
	return p


## Botão com ícone opcional. estilo: "primario" (ouro), "normal", "perigo", "anuncio", "fantasma", "verde".
static func botao(texto: String, nome_icone := "", estilo := "normal", altura := 84) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(0, altura)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.focus_mode = Control.FOCUS_NONE
	var fundo := CARTAO2
	var borda := LINHA
	var cor_txt := TEXTO
	match estilo:
		"primario":
			fundo = OURO
			borda = Color("ffe07a")
			cor_txt = Color("1a1300")
		"perigo":
			fundo = Color("3a1822")
			borda = VERMELHO
		"anuncio":
			fundo = Color("1b3a2c")
			borda = VERDE
		"verde":
			fundo = VERDE
			borda = Color("8ff0bb")
			cor_txt = Color("002812")
		"fantasma":
			fundo = Color(1, 1, 1, 0.0)
			borda = Color(1, 1, 1, 0.18)
		"roxo":
			fundo = Color("2b1f52")
			borda = ROXO
	var n := caixa(fundo, 18, 14)
	n.border_color = borda
	n.set_border_width_all(2)
	if estilo == "primario" or estilo == "verde":
		n.shadow_color = Color(fundo, 0.35)
		n.shadow_size = 10
		n.shadow_offset = Vector2(0, 4)
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = fundo.lightened(0.08)
	var p: StyleBoxFlat = n.duplicate()
	p.bg_color = fundo.darkened(0.15)
	var d: StyleBoxFlat = n.duplicate()
	d.bg_color = Color(fundo, 0.35)
	d.border_color = Color(borda, 0.3)
	d.shadow_size = 0
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("disabled", d)

	var linha := hbox(12)
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(linha)
	if nome_icone != "":
		var ic := icone(nome_icone, 32, cor_txt)
		ic.name = "Icone"
		linha.add_child(ic)
	if texto != "":
		var l := rotulo(texto, 28, cor_txt, "forte")
		l.name = "Texto"
		linha.add_child(l)
	b.pressed.connect(func() -> void:
		Audio.tocar("clique")
		Tela.vibrar(12))
	return b


static func definir_texto_botao(b: Button, texto: String) -> void:
	var l: Label = b.find_child("Texto", true, false)
	if l:
		l.text = texto


## Chip pequeno (ícone + valor), usado em barras de status.
static func chip(nome_icone: String, texto: String, cor := OURO, fundo := Color(0, 0, 0, 0.35)) -> PanelContainer:
	var p := PanelContainer.new()
	var s := caixa(fundo, 30, 0)
	s.content_margin_left = 14
	s.content_margin_right = 16
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := hbox(6)
	p.add_child(l)
	l.add_child(icone(nome_icone, 26, cor))
	var t := rotulo(texto, 24, TEXTO, "forte")
	t.name = "Valor"
	l.add_child(t)
	return p


static func definir_chip(c: PanelContainer, texto: String) -> void:
	var l: Label = c.find_child("Valor", true, false)
	if l:
		l.text = texto


## Barra de progresso arredondada desenhada à mão.
static func barra(valor: float, cor := OURO, altura := 14) -> Barra:
	var b := Barra.new()
	b.valor = valor
	b.cor = cor
	b.custom_minimum_size = Vector2(60, altura)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


## Linha "ícone  Nome ........ valor" com barra embaixo.
static func linha_status(nome_icone: String, nome: String, valor: float, cor: Color, texto_valor := "") -> VBoxContainer:
	var c := vbox(6)
	var topo := hbox(8)
	topo.add_child(icone(nome_icone, 24, cor))
	var n := rotulo(nome, 22, TEXTO2, "forte")
	n.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(n)
	topo.add_child(rotulo(texto_valor if texto_valor != "" else str(int(valor)), 22, TEXTO, "forte"))
	c.add_child(topo)
	c.add_child(barra(valor / 100.0, cor, 10))
	return c


static func separador() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(1, 1, 1, 0.07)
	r.custom_minimum_size.y = 2
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func rolagem() -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.follow_focus = false
	return s


## 1234 -> "1.234"; 12345 -> "12,3 mil"; 2500000 -> "2,5 mi".
static func formatar_numero(v: float) -> String:
	var n := absf(v)
	var t := ""
	if n >= 1_000_000.0:
		t = ("%.1f mi" % (n / 1_000_000.0)).replace(".", ",")
	elif n >= 10_000.0:
		t = ("%.1f mil" % (n / 1000.0)).replace(".", ",")
	elif n >= 1000.0:
		t = "%d.%03d" % [int(n) / 1000, int(n) % 1000]
	else:
		t = str(int(n))
	return ("-" if v < 0 else "") + t.replace(",0 ", " ")


static func formatar_dinheiro(v: float) -> String:
	var n := absf(v)
	var s := ""
	if n >= 1_000_000.0:
		s = "R$ %.1f mi" % (n / 1_000_000.0)
	elif n >= 10_000.0:
		s = "R$ %d mil" % int(n / 1000.0)
	elif n >= 1000.0:
		s = "R$ %.1f mil" % (n / 1000.0)
	else:
		s = "R$ %d" % int(n)
	s = s.replace(".", ",")
	return ("-" if v < 0 else "") + s


static func cor_nota(nota: float) -> Color:
	if nota >= 8.0:
		return VERDE
	if nota >= 6.5:
		return OURO
	if nota >= 5.0:
		return LARANJA
	return VERMELHO


## Pulso de escala ao aparecer.
static func aparecer(c: Control, atraso := 0.0) -> void:
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_interval(atraso)
	tw.tween_property(c, "modulate:a", 1.0, 0.25)


class Barra extends Control:
	var valor := 0.5:
		set(v):
			valor = clampf(v, 0.0, 1.0)
			queue_redraw()
	var cor := Color.WHITE
	var fundo := Color(1, 1, 1, 0.08)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := size.y / 2.0
		_pilula(Rect2(Vector2.ZERO, size), fundo, r)
		if valor > 0.001:
			_pilula(Rect2(Vector2.ZERO, Vector2(maxf(size.y, size.x * valor), size.y)), cor, r)

	func _pilula(rect: Rect2, c: Color, r: float) -> void:
		var s := StyleBoxFlat.new()
		s.bg_color = c
		s.set_corner_radius_all(int(r))
		s.anti_aliasing = true
		draw_style_box(s, rect)
