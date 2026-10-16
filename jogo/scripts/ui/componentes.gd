class_name Componentes
extends RefCounted
## Componentes reutilizáveis entre telas.


## Barra de navegação inferior da carreira.
static func navegacao(atual: String) -> PanelContainer:
	var p := UI.cartao(Color("0f1626"), 0, 0)
	var s := UI.caixa(Color("0f1626"), 0, 0)
	s.content_margin_top = 8
	s.content_margin_bottom = 14
	s.border_color = UI.LINHA
	s.border_width_top = 2
	p.add_theme_stylebox_override("panel", s)
	var linha := UI.hbox(0)
	p.add_child(linha)
	var itens := [["semana", "Semana", "calendario", "res://cenas/hub.tscn"], ["carreira", "Carreira", "grafico", "res://cenas/carreira.tscn"],
		["vida", "Vida", "coracao", "res://cenas/vida.tscn"], ["album", "Álbum", "album", "res://cenas/album.tscn"],
		["loja", "Loja", "loja", "res://cenas/loja.tscn"]]
	for it in itens:
		var ativo: bool = it[0] == atual
		var b := Button.new()
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 86)
		var col := UI.vbox(2)
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var cor := UI.OURO if ativo else UI.TEXTO3
		col.add_child(UI.icone(it[2], 36, cor))
		var l := UI.rotulo(it[1], 19, cor, "forte")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(l)
		b.add_child(col)
		if it[0] == "loja" and Jogo.oferta_iniciante_ativa():
			var ponto := UI.rotulo("●", 20, UI.VERMELHO)
			ponto.position = Vector2(80, 6)
			b.add_child(ponto)
		var destino: String = it[3]
		if not ativo:
			b.pressed.connect(func() -> void:
				Audio.tocar("clique")
				Tela.ir(destino))
		linha.add_child(b)
	return p


static func chip_moedas() -> PanelContainer:
	var c := UI.chip("moeda", str(Jogo.moedas()), UI.OURO)
	var atualizar := func(v: int) -> void: UI.definir_chip(c, str(v))
	Jogo.moedas_mudaram.connect(atualizar)
	c.tree_exiting.connect(func() -> void:
		if Jogo.moedas_mudaram.is_connected(atualizar):
			Jogo.moedas_mudaram.disconnect(atualizar))
	return c


static func chip_dinheiro() -> PanelContainer:
	return UI.chip("dinheiro", UI.formatar_dinheiro(float(Jogo.carreira.get("dinheiro", 0))), UI.VERDE)


## Cabeçalho com brasão do clube, nome e subtítulo.
static func cabecalho_clube(id: String, subtitulo: String) -> HBoxContainer:
	var linha := UI.hbox(16)
	var c := Jogo.clube(id)
	linha.add_child(Brasao.novo(c, 74))
	var col := UI.vbox(0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	var t := UI.titulo(c["nome"], 38)
	t.clip_text = true
	col.add_child(t)
	col.add_child(UI.rotulo(subtitulo, 21, UI.TEXTO2, "forte"))
	linha.add_child(col)
	return linha


## Cartão com título de seção.
static func secao(titulo: String, nome_icone := "", cor := UI.OURO) -> Array:
	var cartao := UI.cartao(UI.CARTAO, 22, 22)
	var col := UI.vbox(14)
	cartao.add_child(col)
	var topo := UI.hbox(10)
	if nome_icone != "":
		topo.add_child(UI.icone(nome_icone, 30, cor))
	topo.add_child(UI.rotulo(titulo.to_upper(), 22, UI.TEXTO2, "titulo"))
	col.add_child(topo)
	return [cartao, col]


static func estrelas(n: int, total := 5, tamanho := 22) -> HBoxContainer:
	var h := UI.hbox(0)
	for i in total:
		h.add_child(UI.icone("estrela", tamanho, UI.OURO if i < n else Color(1, 1, 1, 0.15)))
	return h


## Escudo do clube desenhado em código.
class Brasao extends Control:
	var cor := Color.WHITE
	var cor2 := Color.BLACK
	var sigla := "FC"

	static func novo(c: Dictionary, tamanho := 64) -> Brasao:
		var b := Brasao.new()
		b.cor = c.get("cor", Color.WHITE)
		b.cor2 = c.get("calcao", Color.BLACK)
		if b.cor2.is_equal_approx(b.cor):
			b.cor2 = b.cor.darkened(0.5)
		b.sigla = c.get("sigla", "FC")
		b.custom_minimum_size = Vector2(tamanho, tamanho * 1.15)
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return b

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var pts := PackedVector2Array([Vector2(w * 0.08, h * 0.06), Vector2(w * 0.92, h * 0.06), Vector2(w * 0.92, h * 0.5),
			Vector2(w * 0.5, h * 0.96), Vector2(w * 0.08, h * 0.5)])
		var borda := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.52), Vector2(w * 0.5, h), Vector2(0, h * 0.52)])
		draw_colored_polygon(borda, Color(1, 1, 1, 0.9))
		draw_colored_polygon(pts, cor)
		# faixa diagonal com a segunda cor
		var faixa := PackedVector2Array([Vector2(w * 0.08, h * 0.32), Vector2(w * 0.92, h * 0.18), Vector2(w * 0.92, h * 0.34), Vector2(w * 0.08, h * 0.48)])
		draw_colored_polygon(faixa, cor2)
		var f := UI.fonte("display")
		var tam := int(h * 0.3)
		var largura := f.get_string_size(sigla, HORIZONTAL_ALIGNMENT_LEFT, -1, tam).x
		var cor_txt := Color.WHITE if cor.get_luminance() < 0.6 else Color("111111")
		draw_string_outline(f, Vector2((w - largura) / 2.0, h * 0.74), sigla, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, 6, Color(0, 0, 0, 0.35) if cor_txt == Color.WHITE else Color(1, 1, 1, 0.4))
		draw_string(f, Vector2((w - largura) / 2.0, h * 0.74), sigla, HORIZONTAL_ALIGNMENT_LEFT, -1, tam, cor_txt)
