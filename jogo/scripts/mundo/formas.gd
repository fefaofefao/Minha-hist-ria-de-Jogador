class_name Formas
extends RefCounted
## Geração de malhas suaves (torno/"lathe", membros afunilados) com cache,
## materiais com brilho de contorno (rim) e texturas de uniforme.

static var _malhas := {}
static var _mats := {}
static var _texturas := {}


## Sólido de revolução. perfil: pares (altura, raio) de baixo para cima.
## escala: achata o corte (x, z) para fazer troncos ovais, chuteiras etc.
static func torno(chave: String, perfil: PackedVector2Array, lados := 14, escala := Vector2.ONE) -> ArrayMesh:
	var k := "%s|%d|%s" % [chave, lados, escala]
	if _malhas.has(k):
		return _malhas[k]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := perfil.size()
	var altura_total := maxf(perfil[n - 1].x - perfil[0].x, 0.001)
	for i in n - 1:
		var a := perfil[i]
		var b := perfil[i + 1]
		for j in lados:
			var t0 := TAU * j / lados
			var t1 := TAU * (j + 1) / lados
			var p00 := Vector3(cos(t0) * a.y * escala.x, a.x, sin(t0) * a.y * escala.y)
			var p01 := Vector3(cos(t1) * a.y * escala.x, a.x, sin(t1) * a.y * escala.y)
			var p10 := Vector3(cos(t0) * b.y * escala.x, b.x, sin(t0) * b.y * escala.y)
			var p11 := Vector3(cos(t1) * b.y * escala.x, b.x, sin(t1) * b.y * escala.y)
			var v0 := (a.x - perfil[0].x) / altura_total
			var v1 := (b.x - perfil[0].x) / altura_total
			var u0 := float(j) / lados
			var u1 := float(j + 1) / lados
			st.set_uv(Vector2(u0, 1.0 - v0)); st.add_vertex(p00)
			st.set_uv(Vector2(u1, 1.0 - v1)); st.add_vertex(p11)
			st.set_uv(Vector2(u0, 1.0 - v1)); st.add_vertex(p10)
			st.set_uv(Vector2(u0, 1.0 - v0)); st.add_vertex(p00)
			st.set_uv(Vector2(u1, 1.0 - v0)); st.add_vertex(p01)
			st.set_uv(Vector2(u1, 1.0 - v1)); st.add_vertex(p11)
	st.generate_normals()
	var m := st.commit()
	_malhas[k] = m
	return m


## Membro afunilado com pontas arredondadas, do pivô (0) para baixo (-comprimento).
static func membro(comprimento: float, r_topo: float, r_base: float, lados := 12, escala := Vector2.ONE, bojo := 0.0) -> ArrayMesh:
	var p := PackedVector2Array()
	var c := comprimento
	p.append(Vector2(-c - r_base * 0.6, 0.0))
	p.append(Vector2(-c - r_base * 0.45, r_base * 0.75))
	p.append(Vector2(-c, r_base))
	for k in range(1, 6):
		var t := k / 6.0
		var r := lerpf(r_base, r_topo, t) + sin(t * PI) * bojo
		p.append(Vector2(-c + c * t, r))
	p.append(Vector2(0.0, r_topo))
	p.append(Vector2(r_topo * 0.45, r_topo * 0.75))
	p.append(Vector2(r_topo * 0.6, 0.0))
	return torno("membro_%.3f_%.3f_%.3f_%.3f" % [c, r_topo, r_base, bojo], p, lados, escala)


static func esfera(r: float, segmentos := 16, aneis := 8, hemisferio := false) -> SphereMesh:
	var k := "esf_%.3f_%d_%d_%s" % [r, segmentos, aneis, hemisferio]
	if _malhas.has(k):
		return _malhas[k]
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * (1.0 if hemisferio else 2.0)
	s.radial_segments = segmentos
	s.rings = aneis
	s.is_hemisphere = hemisferio
	_malhas[k] = s
	return s


static func caixa(t: Vector3) -> BoxMesh:
	var k := "cx_%s" % t
	if _malhas.has(k):
		return _malhas[k]
	var b := BoxMesh.new()
	b.size = t
	_malhas[k] = b
	return b


static func cilindro(r_topo: float, r_base: float, h: float, lados := 10) -> CylinderMesh:
	var k := "cil_%.3f_%.3f_%.3f_%d" % [r_topo, r_base, h, lados]
	if _malhas.has(k):
		return _malhas[k]
	var c := CylinderMesh.new()
	c.top_radius = r_topo
	c.bottom_radius = r_base
	c.height = h
	c.radial_segments = lados
	c.rings = 1
	_malhas[k] = c
	return c


## Material padrão do jogo: leve brilho de contorno para destacar do fundo.
static func mat(cor: Color, rugosidade := 0.85, rim := 0.35) -> StandardMaterial3D:
	var k := "%s_%.2f_%.2f" % [cor.to_html(), rugosidade, rim]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugosidade
	if rim > 0.0:
		m.rim_enabled = true
		m.rim = rim
		m.rim_tint = 0.4
	_mats[k] = m
	return m


static func mat_textura(tex: Texture2D, rugosidade := 0.9) -> StandardMaterial3D:
	var k := "tex_%d" % tex.get_instance_id()
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness = rugosidade
	m.rim_enabled = true
	m.rim = 0.3
	m.rim_tint = 0.4
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_mats[k] = m
	return m


static func mat_emissivo(cor: Color, energia: float) -> StandardMaterial3D:
	var k := "em_%s_%.2f" % [cor.to_html(), energia]
	if _mats.has(k):
		return _mats[k]
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.emission_enabled = true
	m.emission = cor
	m.emission_energy_multiplier = energia
	_mats[k] = m
	return m


## Textura da camisa: "liso", "listras" (verticais), "faixa" (horizontal no peito) ou "metade".
static func textura_camisa(cor: Color, cor2: Color, estilo: String) -> ImageTexture:
	var k := "%s_%s_%s" % [cor.to_html(), cor2.to_html(), estilo]
	if _texturas.has(k):
		return _texturas[k]
	var w := 64
	var h := 64
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var c := cor
			match estilo:
				"listras":
					if int(x / 4.0) % 2 == 1:
						c = cor2
				"faixa":
					if y > 22 and y < 34:
						c = cor2
				"metade":
					if x < w / 2:
						c = cor2
			# leve trama do tecido
			var trama := 0.96 + 0.04 * float((x + y) % 2)
			img.set_pixel(x, y, Color(c.r * trama, c.g * trama, c.b * trama))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_texturas[k] = t
	return t


## Sombra de contato (mancha suave sob jogadores e bola).
static func mat_sombra() -> StandardMaterial3D:
	if _mats.has("_sombra"):
		return _mats["_sombra"]
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var d := Vector2(x - s / 2.0 + 0.5, y - s / 2.0 + 0.5).length() / (s / 2.0)
			img.set_pixel(x, y, Color(0, 0, 0, clampf(1.0 - d, 0.0, 1.0) * 0.55))
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.no_depth_test = false
	m.render_priority = -1
	_mats["_sombra"] = m
	return m


static func shader(caminho: String) -> Shader:
	if _mats.has(caminho):
		return _mats[caminho]
	var s: Shader = load(caminho)
	_mats[caminho] = s
	return s
