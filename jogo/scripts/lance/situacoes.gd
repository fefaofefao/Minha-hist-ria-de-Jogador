class_name Situacoes
extends RefCounted
## Gera "momentos decisivos" procedurais. Cada situação descreve o posicionamento
## dos jogadores, os pontos de interesse (POIs) que o jogador pode "ler" olhando
## ao redor e as opções (algumas escondidas até serem descobertas).
##
## O gol atacado fica em z = -40; o jogador ataca na direção -Z.

## 35 tipos de lance: 27 de ataque e 8 de defesa.
const TIPOS_ATAQUE := ["chance_area", "mano_a_mano", "contra_ataque", "cruzamento", "falta", "penalti",
	"tabela", "escanteio", "rebote", "chute_longe", "lancamento_recebe",
	"cobranca_escanteio", "linha_de_fundo", "cara_goleiro", "voleio_area", "pivo", "dois_contra_um",
	"falta_lateral", "cruzamento_rasteiro", "arrancada_meio", "peixinho", "pressao_saida", "falta_longe",
	"passe_decisivo", "gol_vazio", "lateral_area", "drible_ponta"]
## Lances defensivos: o atacante volta para ajudar no fim do jogo.
const TIPOS_DEFESA := ["desarme", "afastar", "cobertura_lateral", "escanteio_contra", "chute_bloqueio",
	"rebote_def", "dois_contra_um_def", "linha_impedimento"]
const TIPOS := ["chance_area", "mano_a_mano", "contra_ataque", "cruzamento", "falta", "penalti",
	"tabela", "escanteio", "rebote", "chute_longe", "lancamento_recebe",
	"cobranca_escanteio", "linha_de_fundo", "cara_goleiro", "voleio_area", "pivo", "dois_contra_um",
	"falta_lateral", "cruzamento_rasteiro", "arrancada_meio", "peixinho", "pressao_saida", "falta_longe",
	"passe_decisivo", "gol_vazio", "lateral_area", "drible_ponta",
	"desarme", "afastar", "cobertura_lateral", "escanteio_contra", "chute_bloqueio",
	"rebote_def", "dois_contra_um_def", "linha_impedimento"]
## Ações em que outro jogador finaliza (o protagonista dá a assistência).
const ACOES_PASSE := ["passe", "lancamento", "ajeitar", "calcanhar", "cruzar", "corta_luz"]
## Desfechos que contam como acerto (para nota, segunda chance e manchetes).
const DESFECHOS_BONS := ["gol", "assistencia", "desarme", "bloqueio", "afastou", "impedimento", "falta_tatica"]

## Peso de cada tipo por posição (atacante finaliza mais, meia passa mais, ponta dribla e cruza...).
const PESOS_POSICAO := {
	"Atacante": {"chance_area": 5, "mano_a_mano": 3, "contra_ataque": 1, "cruzamento": 4, "falta": 1, "penalti": 1,
		"tabela": 3, "escanteio": 3, "rebote": 3, "chute_longe": 1, "lancamento_recebe": 4,
		"cobranca_escanteio": 1, "linha_de_fundo": 1, "cara_goleiro": 4, "voleio_area": 3, "pivo": 4, "dois_contra_um": 2,
		"falta_lateral": 1, "cruzamento_rasteiro": 4, "arrancada_meio": 1, "peixinho": 3, "pressao_saida": 3, "falta_longe": 1,
		"passe_decisivo": 1, "gol_vazio": 2, "lateral_area": 3, "drible_ponta": 1},
	"Ponta": {"chance_area": 3, "mano_a_mano": 5, "contra_ataque": 2, "cruzamento": 2, "falta": 1, "penalti": 1,
		"tabela": 3, "escanteio": 1, "rebote": 2, "chute_longe": 2, "lancamento_recebe": 4,
		"cobranca_escanteio": 3, "linha_de_fundo": 5, "cara_goleiro": 3, "voleio_area": 2, "pivo": 1, "dois_contra_um": 3,
		"falta_lateral": 2, "cruzamento_rasteiro": 2, "arrancada_meio": 3, "peixinho": 2, "pressao_saida": 2, "falta_longe": 1,
		"passe_decisivo": 2, "gol_vazio": 2, "lateral_area": 1, "drible_ponta": 5},
	"Meia": {"chance_area": 3, "mano_a_mano": 2, "contra_ataque": 5, "cruzamento": 1, "falta": 3, "penalti": 1,
		"tabela": 4, "escanteio": 1, "rebote": 1, "chute_longe": 4, "lancamento_recebe": 1,
		"cobranca_escanteio": 3, "linha_de_fundo": 1, "cara_goleiro": 2, "voleio_area": 3, "pivo": 1, "dois_contra_um": 4,
		"falta_lateral": 3, "cruzamento_rasteiro": 1, "arrancada_meio": 4, "peixinho": 1, "pressao_saida": 2, "falta_longe": 4,
		"passe_decisivo": 5, "gol_vazio": 2, "lateral_area": 1, "drible_ponta": 2},
}


## Sorteia o tipo do lance pela posição. Tipos em `evitar` (vistos há pouco) ficam bem mais raros.
static func sortear_tipo(posicao: String, rng: RandomNumberGenerator, evitar: Array = []) -> String:
	var pesos: Dictionary = PESOS_POSICAO.get(posicao, PESOS_POSICAO["Atacante"])
	var total := 0.0
	for t in pesos:
		total += float(pesos[t]) * (0.12 if t in evitar else 1.0)
	var r := rng.randf() * total
	for t in pesos:
		r -= float(pesos[t]) * (0.12 if t in evitar else 1.0)
		if r <= 0.0:
			return t
	return "chance_area"


## Sorteia o lance defensivo do fim do jogo, evitando os vistos há pouco.
static func sortear_defesa(rng: RandomNumberGenerator, evitar: Array = []) -> String:
	var livres: Array = []
	for t in TIPOS_DEFESA:
		if not (t in evitar):
			livres.append(t)
	if livres.is_empty():
		livres = TIPOS_DEFESA.duplicate()
	return livres[rng.randi() % livres.size()]


static func bom(desfecho: String) -> bool:
	return desfecho in DESFECHOS_BONS


static func defensivo(tipo: String) -> bool:
	return tipo in TIPOS_DEFESA


## ctx: atributos, moral, pressao (0..1), parceiro, rng, minuto, placar,
##      cenario, noite, cor_casa, calcao_casa, cor_fora, calcao_fora, adversario, visual
static func gerar(tipo: String, ctx: Dictionary) -> Dictionary:
	var rng: RandomNumberGenerator = ctx.get("rng", RandomNumberGenerator.new())
	if tipo == "defesa_tardia":
		tipo = sortear_defesa(rng)
	var s := {
		"tipo": tipo,
		"jogadores": [],
		"pois": [],
		"opcoes": [],
		"ctx": ctx,
	}
	match tipo:
		"chance_area":
			_chance_area(s, ctx, rng)
		"mano_a_mano":
			_mano_a_mano(s, ctx, rng)
		"contra_ataque":
			_contra_ataque(s, ctx, rng)
		"cruzamento":
			_cruzamento(s, ctx, rng)
		"falta":
			_falta(s, ctx, rng)
		"penalti":
			_penalti(s, ctx, rng)
		"tabela":
			_tabela(s, ctx, rng)
		"escanteio":
			_escanteio(s, ctx, rng)
		"rebote":
			_rebote(s, ctx, rng)
		"chute_longe":
			_chute_longe(s, ctx, rng)
		"lancamento_recebe":
			_lancamento_recebe(s, ctx, rng)
		"desarme":
			_desarme(s, ctx, rng)
		"afastar":
			_afastar(s, ctx, rng)
		"cobranca_escanteio":
			_cobranca_escanteio(s, ctx, rng)
		"linha_de_fundo":
			_linha_de_fundo(s, ctx, rng)
		"cara_goleiro":
			_cara_goleiro(s, ctx, rng)
		"voleio_area":
			_voleio_area(s, ctx, rng)
		"pivo":
			_pivo(s, ctx, rng)
		"dois_contra_um":
			_dois_contra_um(s, ctx, rng)
		"falta_lateral":
			_falta_lateral(s, ctx, rng)
		"cruzamento_rasteiro":
			_cruzamento_rasteiro(s, ctx, rng)
		"arrancada_meio":
			_arrancada_meio(s, ctx, rng)
		"peixinho":
			_peixinho(s, ctx, rng)
		"pressao_saida":
			_pressao_saida(s, ctx, rng)
		"falta_longe":
			_falta_longe(s, ctx, rng)
		"passe_decisivo":
			_passe_decisivo(s, ctx, rng)
		"gol_vazio":
			_gol_vazio(s, ctx, rng)
		"lateral_area":
			_lateral_area(s, ctx, rng)
		"drible_ponta":
			_drible_ponta(s, ctx, rng)
		"cobertura_lateral":
			_cobertura_lateral(s, ctx, rng)
		"escanteio_contra":
			_escanteio_contra(s, ctx, rng)
		"chute_bloqueio":
			_chute_bloqueio(s, ctx, rng)
		"rebote_def":
			_rebote_def(s, ctx, rng)
		"dois_contra_um_def":
			_dois_contra_um_def(s, ctx, rng)
		"linha_impedimento":
			_linha_impedimento(s, ctx, rng)
		_:
			s["tipo"] = "chance_area"
			_chance_area(s, ctx, rng)
	s["defensivo"] = defensivo(s["tipo"])
	s["texto"] = _clima(s, ctx) + String(s.get("texto", ""))
	_figurantes(s, rng)
	_calcular_chances(s, ctx)
	s["tempo"] = clampf(_tempo_decisao(ctx) * float(s.get("tempo_mult", 1.0)), 4.5, 10.0)
	return s


## Abre o texto do lance com o clima do jogo (minuto e placar).
static func _clima(s: Dictionary, ctx: Dictionary) -> String:
	var minuto := int(ctx.get("minuto", 45))
	var gc := int(ctx.get("gols_casa", 0))
	var gf := int(ctx.get("gols_fora", 0))
	if minuto < 84 or minuto >= 120:
		return ""
	if s["defensivo"]:
		return "SEGURA! " if gc > gf else ("Tá empatado! " if gc == gf else "")
	if gc < gf:
		return "Precisamos do gol! "
	if gc == gf:
		return "Último lance? "
	return ""


static func _um(rng: RandomNumberGenerator, lista: Array) -> String:
	return lista[rng.randi() % lista.size()]


# ---------------------------------------------------------------- layouts

static func _j(s: Dictionary, papel: String, pos: Vector3, time: String, nome := "") -> void:
	s["jogadores"].append({"papel": papel, "pos": pos, "time": time, "nome": nome})


static func _op(s: Dictionary, id: String, texto: String, acao: String, base: float, atributos: Dictionary, oculta := false, poi := "", requisito := {}, receptor := "") -> void:
	var op := {"id": id, "texto": texto, "acao": acao, "base": base, "atributos": atributos,
		"oculta": oculta, "poi": poi, "requisito": requisito, "chance": base}
	if receptor != "":
		op["receptor"] = receptor
	s["opcoes"].append(op)


static func _poi(s: Dictionary, id: String, papel: String, revela: String, dica: String, aviso: String, bonus := 0.0) -> void:
	s["pois"].append({"id": id, "papel": papel, "revela": revela, "dica": dica, "aviso": aviso, "bonus": bonus})


static func _chance_area(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-11.0, 11.0)
	var z := rng.randf_range(-23.0, -18.5)
	var lado := signf(x) if absf(x) > 0.5 else 1.0
	var prota := Vector3(x, 0, z)
	var adiantado := rng.randf() < 0.45
	var parceiro: String = ctx.get("parceiro", "Juninho")
	_j(s, "prota", prota, "casa")
	_j(s, "parceiro", Vector3(-lado * rng.randf_range(10.0, 15.0), 0, rng.randf_range(-30.0, -25.0)), "casa", parceiro)
	_j(s, "zagueiro", prota + Vector3(-lado * 1.5, 0, -rng.randf_range(4.5, 6.0)), "fora")
	_j(s, "zagueiro2", Vector3(x * 0.3, 0, -33.5), "fora")
	_j(s, "goleiro", Vector3(x * 0.12, 0, -36.2 if adiantado else -38.8), "fora")
	s["texto"] = _um(rng, ["A bola sobra pra você na entrada da área!", "Rebatida da zaga... a bola cai no seu pé!",
		"%s rola pra trás: é sua na meia-lua!" % ctx.get("atacante", "Tico"), "Bola espirrada na área. Você chega primeiro!"])
	s["bola"] = "pe"
	_op(s, "colocado", "Chute colocado no canto", "chute", 0.30, {"finalizacao": 0.55})
	if rng.randf() < 0.4:
		_op(s, "cortar", "Cortar o zagueiro e bater", "drible", 0.3, {"drible": 0.45, "finalizacao": 0.15})
	else:
		_op(s, "forte", "Encher o pé", "chute_forte", 0.24, {"finalizacao": 0.35, "fisico": 0.25})
	_op(s, "passe", "Tocar pro %s" % parceiro, "passe", 0.40, {"passe": 0.45, "visao": 0.15}, true, "parceiro")
	_poi(s, "parceiro", "parceiro", "passe", "%s pede a bola: \"Tô livre!\"" % parceiro, "Você viu o %s livre!" % parceiro)
	if adiantado:
		_op(s, "cobertura", "Encobrir o goleiro", "cobertura", 0.42, {"finalizacao": 0.35, "visao": 0.25}, true, "goleiro", {"visao": 78})
		_poi(s, "goleiro", "goleiro", "cobertura", "O goleiro está fora da linha...", "O goleiro está adiantado: dá pra encobrir!", 0.0)


static func _mano_a_mano(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-7.0, 7.0)
	var z := rng.randf_range(-16.0, -12.0)
	var prota := Vector3(x, 0, z)
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var lado := 1.0 if x < 0 else -1.0
	_j(s, "prota", prota, "casa")
	_j(s, "zagueiro", prota + Vector3(0, 0, -3.6), "fora")
	_j(s, "zagueiro2", Vector3(x * 0.4 - lado * 3.0, 0, -28.0), "fora")
	_j(s, "parceiro", Vector3(lado * rng.randf_range(13.0, 18.0), 0, z - rng.randf_range(4.0, 8.0)), "casa", parceiro)
	_j(s, "marcador", Vector3(lado * rng.randf_range(13.0, 18.0), 0, z - 9.5), "fora")
	_j(s, "goleiro", Vector3(x * 0.1, 0, -38.6), "fora")
	s["texto"] = _um(rng, ["Cara a cara com o zagueiro. Ele vem pra cima!", "Só o último zagueiro entre você e o gol!",
		"Você domina na ponta e encara a marcação.", "O zagueiro deu o bote... e errou o tempo! É você contra ele."])
	s["bola"] = "pe"
	_op(s, "corte", "Corte pra dentro", "drible", 0.36, {"drible": 0.55, "velocidade": 0.15})
	_op(s, "arrancada", "Tocar na frente e arrancar", "arrancada", 0.32, {"velocidade": 0.5, "drible": 0.2})
	_op(s, "caneta", "Dar uma caneta", "caneta", 0.44, {"drible": 0.6}, true, "pernas", {"drible": 72})
	_op(s, "abrir", "Abrir pro %s" % parceiro, "passe", 0.27, {"passe": 0.5}, false)
	_poi(s, "pernas", "zagueiro", "caneta", "Repare nas pernas do zagueiro...", "Ele abriu as pernas: caneta liberada!", 0.0)


static func _contra_ataque(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-5.0, 5.0)
	var prota := Vector3(x, 0, rng.randf_range(-3.0, 3.0))
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var atacante: String = ctx.get("atacante", "Tico")
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	_j(s, "prota", prota, "casa")
	_j(s, "parceiro", Vector3(lado * rng.randf_range(20.0, 26.0), 0, prota.z - rng.randf_range(8.0, 12.0)), "casa", parceiro)
	_j(s, "atacante", Vector3(-lado * rng.randf_range(4.0, 8.0), 0, prota.z - rng.randf_range(13.0, 16.0)), "casa", atacante)
	_j(s, "zagueiro", Vector3(x + rng.randf_range(-2, 2), 0, prota.z - 10.0), "fora")
	_j(s, "zagueiro2", Vector3(-lado * 9.0, 0, prota.z - 15.5), "fora")
	_j(s, "zagueiro3", Vector3(lado * 10.0, 0, prota.z - 17.0), "fora")
	_j(s, "goleiro", Vector3(0, 0, -38.0), "fora")
	s["texto"] = _um(rng, ["Contra-ataque! Você tem a bola no meio-campo.", "Roubada no meio! Você puxa o contra-ataque.",
		"Três contra três! A bola está com você.", "Espaço pra correr! O time inteiro deles está no ataque."])
	s["bola"] = "pe"
	_op(s, "ponta", "Tocar pro %s na ponta" % parceiro, "passe", 0.27, {"passe": 0.45, "visao": 0.15})
	_op(s, "conduzir", "Conduzir e bater de fora", "conduzir", 0.2, {"velocidade": 0.3, "finalizacao": 0.35})
	_op(s, "lancamento", "Lançamento pro %s" % atacante, "lancamento", 0.46, {"passe": 0.4, "visao": 0.35}, true, "atacante", {"visao": 70})
	_poi(s, "atacante", "atacante", "lancamento", "%s faz o movimento lá na frente!" % atacante, "%s está nas costas da zaga: lançamento liberado!" % atacante)


static func _cruzamento(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var prota := Vector3(rng.randf_range(-3.0, 3.0), 0, rng.randf_range(-32.0, -29.0))
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var ponta: String = ctx.get("ponta", "Dudu")
	_j(s, "prota", prota, "casa")
	_j(s, "ponta", Vector3(lado * 26.0, 0, -35.0), "casa", ponta)
	_j(s, "parceiro", Vector3(-lado * rng.randf_range(1.0, 3.0), 0, -26.0), "casa", parceiro)
	_j(s, "zagueiro", prota + Vector3(lado * 0.9, 0, -0.9), "fora")
	_j(s, "zagueiro2", Vector3(-lado * 5.0, 0, -34.0), "fora")
	_j(s, "goleiro", Vector3(lado * 1.2, 0, -38.8), "fora")
	s["texto"] = _um(rng, ["%s cruza! A bola vem na sua direção..." % ponta, "%s vai à linha de fundo e levanta na área!" % ponta,
		"Cruzamento na medida de %s!" % ponta, "%s chuta cruzado... a bola vem pela sua cabeça!" % ponta])
	s["bola"] = "ar"
	s["origem_bola"] = Vector3(lado * 26.0, 0.3, -35.0)
	_op(s, "canto", "Cabeçada no canto", "cabeceio", 0.3, {"cabeceio": 0.6})
	_op(s, "chao", "Testada firme pro chão", "cabeceio_chao", 0.26, {"cabeceio": 0.45, "fisico": 0.15})
	_op(s, "ajeitar", "Ajeitar de cabeça pro %s" % parceiro, "ajeitar", 0.4, {"cabeceio": 0.3, "visao": 0.3}, true, "parceiro")
	_poi(s, "parceiro", "parceiro", "ajeitar", "%s vem chegando de trás!" % parceiro, "%s chega livre na marca do pênalti!" % parceiro)


static func _falta(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-9.0, 9.0)
	var z := rng.randf_range(-21.0, -18.0)
	var prota := Vector3(x, 0, z)
	var parceiro: String = ctx.get("parceiro", "Juninho")
	_j(s, "prota", prota, "casa")
	_barreira(s, prota, 4)
	var lado := -signf(x) if absf(x) > 0.5 else 1.0
	_j(s, "parceiro", prota + Vector3(lado * 6.0, 0, 2.0), "casa", parceiro)
	_j(s, "goleiro", Vector3(-lado * 1.0, 0, -38.9), "fora")
	_j(s, "zagueiro", Vector3(lado * 7.0, 0, -30.0), "fora")
	s["texto"] = _um(rng, ["Falta perigosa! A bola é sua.", "Falta na entrada da área. O capitão te entrega a bola.",
		"Derrubaram você! Falta frontal.", "Falta no bico da área. Barreira armada."])
	s["bola"] = "parada"
	_op(s, "curva", "Por cima da barreira", "falta_curva", 0.24, {"finalizacao": 0.6})
	_op(s, "forte", "Bomba no canto do goleiro", "falta_forte", 0.18, {"finalizacao": 0.35, "fisico": 0.3})
	_op(s, "rolar", "Rolar pro %s bater" % parceiro, "passe", 0.26, {"passe": 0.25, "visao": 0.3}, true, "parceiro")
	_poi(s, "parceiro", "parceiro", "rolar", "%s pisca pra você..." % parceiro, "%s combinou a jogada ensaiada!" % parceiro)


## Barreira a 9,15 m da bola, na linha do gol.
static func _barreira(s: Dictionary, bola: Vector3, n: int) -> void:
	var dir := (Vector3(0, 0, -40) - bola).normalized()
	var meio := bola + dir * 9.15
	var lateral := Vector3(-dir.z, 0, dir.x)
	for k in n:
		_j(s, "barreira", meio + lateral * ((k - (n - 1) / 2.0) * 0.62), "fora")


static func _penalti(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var visao: float = ctx.get("atributos", {}).get("visao", 50.0)
	_j(s, "prota", Vector3(0, 0, -29.0), "casa")
	_j(s, "goleiro", Vector3(0, 0, -39.6), "fora")
	_j(s, "zagueiro", Vector3(-8.0, 0, -22.0), "fora")
	_j(s, "zagueiro2", Vector3(7.5, 0, -22.5), "fora")
	_j(s, "parceiro", Vector3(4.0, 0, -22.0), "casa", ctx.get("parceiro", "Juninho"))
	s["texto"] = _um(rng, ["PÊNALTI! Você vai bater.", "Pênalti marcado! A torcida grita seu nome.",
		"Pênalti! O goleiro tenta te intimidar...", "Pênalti a favor! Você pega a bola e ajeita na marca."])
	s["bola"] = "parada"
	# O goleiro já "decidiu" o lado. A leitura revela, com chance de acerto pela Visão.
	var lado_goleiro := rng.randi_range(0, 9)
	var decisao := "esq" if lado_goleiro < 5 else "dir"
	if lado_goleiro == 9:
		decisao = "fica"
	s["goleiro_decisao"] = decisao
	var acerta_leitura := rng.randf() < clampf(0.55 + visao / 220.0, 0.55, 0.95)
	var leitura := decisao
	if not acerta_leitura:
		leitura = "dir" if decisao == "esq" else "esq"
	s["goleiro_leitura"] = leitura
	var texto_leitura := "O goleiro vai ficar parado no meio!" if leitura == "fica" else (
		"O goleiro está pesando o corpo para a ESQUERDA!" if leitura == "esq" else "O goleiro está pesando o corpo para a DIREITA!")
	_op(s, "esq", "Bater no canto esquerdo", "penalti_esq", 0.72, {"finalizacao": 0.3})
	_op(s, "dir", "Bater no canto direito", "penalti_dir", 0.72, {"finalizacao": 0.3})
	_op(s, "cavadinha", "Cavadinha no meio", "cavadinha", 0.62, {"finalizacao": 0.2, "frieza": 0.3}, true, "goleiro", {"frieza": 75})
	_poi(s, "goleiro", "goleiro", "cavadinha", "Encare o goleiro...", texto_leitura)


static func _tabela(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-8.0, 8.0)
	var z := rng.randf_range(-25.0, -21.5)
	var lado := 1.0 if x < 0 else -1.0
	var prota := Vector3(x, 0, z)
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var atacante: String = ctx.get("atacante", "Tico")
	_j(s, "prota", prota, "casa")
	_j(s, "parceiro", prota + Vector3(lado * rng.randf_range(4.5, 6.5), 0, -rng.randf_range(1.0, 2.5)), "casa", parceiro)
	_j(s, "zagueiro", prota + Vector3(lado * 0.6, 0, -3.2), "fora")
	_j(s, "zagueiro2", Vector3(-lado * 4.0 + x * 0.3, 0, -31.5), "fora")
	_j(s, "atacante", Vector3(x * 0.2 + lado * 1.5, 0, -33.0), "casa", atacante)
	_j(s, "zagueiro3", Vector3(x * 0.2 + lado * 3.0, 0, -34.5), "fora")
	_j(s, "goleiro", Vector3(x * 0.1, 0, -38.7), "fora")
	s["texto"] = _um(rng, ["%s encosta do seu lado pedindo a tabela." % parceiro, "Zagueiro na frente e %s se oferecendo pra tabelar." % parceiro,
		"Você recebe na intermediária... %s chega pra jogar junto." % parceiro])
	s["bola"] = "pe"
	_op(s, "tabela", "Tabelar com %s" % parceiro, "tabela", 0.36, {"passe": 0.3, "visao": 0.15, "finalizacao": 0.25})
	_op(s, "de_fora", "Bater de fora da área", "chute", 0.2, {"finalizacao": 0.55})
	_op(s, "pra_cima", "Partir pra cima do zagueiro", "drible", 0.3, {"drible": 0.5, "velocidade": 0.15})
	_op(s, "calcanhar", "De calcanhar pro %s" % atacante, "calcanhar", 0.45, {"passe": 0.35, "visao": 0.35}, true, "atacante", {"visao": 80}, "atacante")
	_poi(s, "atacante", "atacante", "calcanhar", "%s está entre os zagueiros..." % atacante, "%s ficou livre na área: dá de calcanhar!" % atacante)


static func _escanteio(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var prota := Vector3(lado * rng.randf_range(1.5, 3.5), 0, rng.randf_range(-35.5, -33.5))
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var ponta: String = ctx.get("ponta", "Dudu")
	_j(s, "prota", prota, "casa")
	_j(s, "ponta", Vector3(lado * 33.5, 0, -39.5), "casa", ponta)
	_j(s, "parceiro", Vector3(-lado * rng.randf_range(2.0, 4.0), 0, -34.0), "casa", parceiro)
	_j(s, "zagueiro", prota + Vector3(-lado * 0.7, 0, -0.6), "fora")
	_j(s, "zagueiro2", Vector3(-lado * 3.0, 0, -34.8), "fora")
	_j(s, "zagueiro3", Vector3(0, 0, -31.0), "fora")
	_j(s, "goleiro", Vector3(lado * 0.4, 0, -39.0), "fora")
	s["texto"] = _um(rng, ["Escanteio! %s levanta na área..." % ponta, "Escanteio fechado de %s, a bola vem na sua cabeça!" % ponta,
		"Cobrança de escanteio... você se solta da marcação!"])
	s["bola"] = "ar"
	s["origem_bola"] = Vector3(lado * 33.2, 0.3, -39.6)
	_op(s, "primeiro_pau", "Cabeçada no primeiro pau", "cabeceio", 0.3, {"cabeceio": 0.6})
	_op(s, "desvio", "Desviar pro %s no segundo pau" % parceiro, "ajeitar", 0.32, {"cabeceio": 0.3, "visao": 0.3}, false, "", {}, "parceiro")
	_op(s, "chao", "Testada firme pro chão", "cabeceio_chao", 0.26, {"cabeceio": 0.45, "fisico": 0.15})
	_op(s, "bicicleta", "BICICLETA!", "bicicleta", 0.22, {"fisico": 0.3, "finalizacao": 0.3, "frieza": 0.1}, true, "alta", {"fisico": 82})
	_poi(s, "alta", "ponta", "bicicleta", "Repare na altura da bola...", "A bola vem alta, passando atrás de você: dá pra bicicleta!")


static func _rebote(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-4.0, 4.0)
	var prota := Vector3(x, 0, rng.randf_range(-32.5, -30.5))
	var lado := 1.0 if x < 0 else -1.0
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var atacante: String = ctx.get("atacante", "Tico")
	_j(s, "prota", prota, "casa")
	_j(s, "atacante", Vector3(-lado * rng.randf_range(5.0, 8.0), 0, -24.0), "casa", atacante)
	_j(s, "goleiro", Vector3(x * 0.4, 0, -38.6), "fora")
	_j(s, "zagueiro", prota + Vector3(lado * 1.3, 0, -1.4), "fora")
	_j(s, "zagueiro2", Vector3(lado * 3.5, 0, -36.0), "fora")
	_j(s, "parceiro", Vector3(-lado * 4.5, 0, -34.5), "casa", parceiro)
	s["texto"] = _um(rng, ["%s bate forte... o goleiro solta! A bola sobra pra você!" % atacante, "Chute de %s, o goleiro rebate no seu pé!" % atacante,
		"%s finaliza, a bola espirra no goleiro e cai na pequena área!" % atacante])
	s["bola"] = "rebote"
	s["tempo_mult"] = 0.75  # lance de reflexo: menos tempo para pensar
	_op(s, "empurrar", "Empurrar pro gol", "chute", 0.42, {"finalizacao": 0.35, "frieza": 0.25})
	_op(s, "alto", "Bater de primeira no alto", "chute_forte", 0.34, {"finalizacao": 0.4, "fisico": 0.1})
	_op(s, "rolar", "Rolar pro %s na pequena área" % parceiro, "passe", 0.4, {"passe": 0.35, "visao": 0.2}, true, "parceiro", {}, "parceiro")
	_poi(s, "parceiro", "parceiro", "rolar", "%s grita do outro lado..." % parceiro, "%s está sozinho na pequena área!" % parceiro)
	_op(s, "drible_goleiro", "Driblar o goleiro caído", "drible_goleiro", 0.5, {"drible": 0.35, "frieza": 0.35}, true, "goleiro", {"frieza": 78})
	_poi(s, "goleiro", "goleiro", "drible_goleiro", "Olha o goleiro...", "O goleiro está no chão: dá pra driblar!")


static func _chute_longe(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-9.0, 9.0)
	var z := rng.randf_range(-12.5, -9.5)
	var prota := Vector3(x, 0, z)
	var lado := 1.0 if x >= 0 else -1.0
	var ponta: String = ctx.get("ponta", "Dudu")
	var adiantado := rng.randf() < 0.35
	_j(s, "prota", prota, "casa")
	_j(s, "ponta", Vector3(lado * rng.randf_range(18.0, 23.0), 0, z - rng.randf_range(3.0, 6.0)), "casa", ponta)
	_j(s, "zagueiro", prota + Vector3(0, 0, -6.5), "fora")
	_j(s, "zagueiro2", Vector3(-lado * 5.0, 0, -19.0), "fora")
	_j(s, "zagueiro3", Vector3(lado * 8.0, 0, -20.0), "fora")
	_j(s, "atacante", Vector3(x * 0.3, 0, -27.0), "casa", ctx.get("atacante", "Tico"))
	_j(s, "goleiro", Vector3(x * 0.1, 0, -34.8 if adiantado else -38.6), "fora")
	s["texto"] = _um(rng, ["A bola sobra na intermediária. O gol está longe... ou não?", "Espaço na entrada da área! Ninguém te marcou.",
		"Rebote da defesa, a bola quica na sua frente a 30 metros do gol."])
	s["bola"] = "pe"
	_op(s, "colocado", "Chute colocado de longe", "chute", 0.17, {"finalizacao": 0.55})
	_op(s, "bomba", "Bomba de fora da área", "chute_forte", 0.16, {"finalizacao": 0.35, "fisico": 0.35})
	_op(s, "avancar", "Conduzir e chegar mais perto", "conduzir", 0.22, {"velocidade": 0.3, "drible": 0.2, "finalizacao": 0.2})
	_op(s, "lateral", "Abrir pro %s que passa" % ponta, "passe", 0.38, {"passe": 0.4, "visao": 0.2}, true, "ponta", {}, "ponta")
	_poi(s, "ponta", "ponta", "lateral", "%s vem correndo por fora..." % ponta, "%s passou livre pela ponta!" % ponta)
	if adiantado:
		_op(s, "cobertura", "Encobrir do meio da rua", "cobertura", 0.24, {"finalizacao": 0.4, "visao": 0.3}, true, "goleiro", {"visao": 82})
		_poi(s, "goleiro", "goleiro", "cobertura", "Repare onde está o goleiro...", "O goleiro está adiantado: dá pra encobrir de longe!")


static func _lancamento_recebe(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-7.0, 7.0)
	var prota := Vector3(x, 0, rng.randf_range(-25.0, -22.0))
	var lado := 1.0 if x < 0 else -1.0
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var sai := rng.randf() < 0.6
	_j(s, "prota", prota, "casa")
	_j(s, "zagueiro", prota + Vector3(lado * 1.6, 0, 2.0), "fora")
	_j(s, "zagueiro2", Vector3(-lado * 6.0, 0, -21.0), "fora")
	_j(s, "parceiro", Vector3(lado * 8.0, 0, -20.0), "casa", parceiro)
	_j(s, "goleiro", Vector3(x * 0.15, 0, -35.0 if sai else -38.5), "fora")
	s["texto"] = _um(rng, ["Lançamento longo! Você ganha nas costas da zaga...", "%s lança de 40 metros, a bola vem caindo pra você!" % ctx.get("atacante", "Tico"),
		"Bola esticada! Você dispara entre os zagueiros."])
	s["bola"] = "ar"
	s["origem_bola"] = Vector3(x * 0.4 - lado * 6.0, 0.3, 8.0)
	_op(s, "dominar", "Dominar no peito e bater", "domina_chute", 0.3, {"finalizacao": 0.3, "drible": 0.25})
	_op(s, "voleio", "Bater de primeira, de voleio", "voleio", 0.2, {"finalizacao": 0.5, "frieza": 0.15})
	_op(s, "servir", "Segurar e servir o %s" % parceiro, "passe", 0.3, {"passe": 0.4, "visao": 0.2}, false, "", {}, "parceiro")
	_op(s, "drible_goleiro", "Driblar o goleiro que sai", "drible_goleiro", 0.45, {"drible": 0.4, "velocidade": 0.2}, true, "goleiro", {"drible": 80})
	_poi(s, "goleiro", "goleiro", "drible_goleiro", "O goleiro vem saindo...", "O goleiro saiu mal do gol: dá pra driblar!")


# ---------------------------------------------------------------- defesa (o atacante volta pra ajudar)

static func _desarme(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-8.0, 8.0)
	var z := rng.randf_range(-23.0, -19.0)
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var numero := rng.randi_range(7, 11)
	_j(s, "prota", Vector3(x + lado * 2.4, 0, z + 3.2), "casa")
	_j(s, "atacante_adv", Vector3(x, 0, z), "fora")
	_j(s, "apoio_adv", Vector3(-lado * rng.randf_range(7.0, 10.0), 0, z - rng.randf_range(3.0, 6.0)), "fora")
	_j(s, "zagueiro_nos", Vector3(-lado * 4.0, 0, -31.0), "casa")
	_j(s, "goleiro", Vector3(x * 0.1, 0, -38.6), "casa")
	s["texto"] = _um(rng, ["Contra-ataque deles! Você voltou correndo pra ajudar na marcação.",
		"Perdemos a bola no ataque. Você volta voando atrás do camisa %d!" % numero,
		"Só você alcança o atacante deles. Volta, volta!"])
	s["bola"] = "adv"
	_op(s, "carrinho", "Carrinho na bola", "carrinho", 0.36, {"fisico": 0.3, "velocidade": 0.25, "frieza": 0.1})
	_op(s, "bote", "Bote em pé, na hora certa", "bote", 0.32, {"fisico": 0.25, "frieza": 0.35})
	_op(s, "conter", "Acompanhar e fechar o chute", "conter", 0.42, {"velocidade": 0.35, "visao": 0.15})
	_op(s, "antecipar", "Antecipar o passe pro camisa %d" % (numero + 1), "antecipar", 0.5, {"visao": 0.4, "velocidade": 0.2}, true, "apoio", {"visao": 80})
	_poi(s, "apoio", "apoio_adv", "antecipar", "Olha quem vem do outro lado...", "Ele vai tocar pro companheiro: dá pra antecipar!")


static func _afastar(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var prota := Vector3(lado * rng.randf_range(0.5, 2.5), 0, rng.randf_range(-35.5, -33.5))
	var origem := Vector3(lado * 27.5, 0.3, -33.0)
	_j(s, "prota", prota, "casa")
	_j(s, "atacante_adv", Vector3(-lado * 1.0, 0, prota.z - 0.8), "fora")
	_j(s, "apoio_adv", Vector3(-lado * 4.5, 0, -32.0), "fora")
	_j(s, "ponta_adv", Vector3(lado * 28.0, 0, -33.0), "fora")
	_j(s, "zagueiro_nos", Vector3(-lado * 4.0, 0, -33.0), "casa")
	_j(s, "goleiro", Vector3(lado * 0.5, 0, -39.0), "casa")
	s["texto"] = _um(rng, ["Cruzamento deles na nossa área! Você voltou pra defender.", "Bola alçada na nossa área... é com você!",
		"O treinador pediu: atacante também marca! Lá vem o cruzamento."])
	s["bola"] = "ar"
	s["origem_bola"] = origem
	s["olhar_para"] = origem
	_op(s, "cabeca", "Subir e afastar de cabeça", "afastar_cabeca", 0.46, {"cabeceio": 0.45, "fisico": 0.2})
	_op(s, "chutao", "Esperar cair e dar um chutão", "chutao", 0.36, {"fisico": 0.3, "frieza": 0.2})
	_op(s, "sair", "Dominar e sair jogando", "sair_jogando", 0.24, {"drible": 0.3, "frieza": 0.35, "passe": 0.15})
	_op(s, "deixa", "Gritar \"DEIXA!\" pro goleiro", "deixar_goleiro", 0.55, {"visao": 0.35, "frieza": 0.2}, true, "goleiro")
	_poi(s, "goleiro", "goleiro", "deixa", "E o goleiro?", "O goleiro está saindo do gol: deixa com ele!")


# ---------------------------------------------------------------- ataque (v1.3)

## Você cobra o escanteio.
static func _cobranca_escanteio(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var atacante: String = ctx.get("atacante", "Tico")
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var ponta: String = ctx.get("ponta", "Dudu")
	_j(s, "prota", Vector3(lado * 33.6, 0, -39.4), "casa")
	_j(s, "atacante", Vector3(lado * 2.0, 0, -35.5), "casa", atacante)
	_j(s, "parceiro", Vector3(-lado * 3.0, 0, -33.5), "casa", parceiro)
	_j(s, "ponta", Vector3(lado * 28.0, 0, -36.0), "casa", ponta)
	_j(s, "zagueiro", Vector3(lado * 2.6, 0, -36.2), "fora")
	_j(s, "zagueiro2", Vector3(-lado * 2.4, 0, -34.3), "fora")
	_j(s, "zagueiro3", Vector3(0, 0, -31.5), "fora")
	var adiantado := rng.randf() < 0.4
	_j(s, "goleiro", Vector3(lado * (0.2 if adiantado else 0.8), 0, -37.6 if adiantado else -39.2), "fora")
	s["olhar_para"] = Vector3(0, 0, -34)
	s["texto"] = _um(rng, ["Escanteio pra nós! A bola é sua na bandeirinha.", "Você vai cobrar o escanteio. A área está lotada.",
		"Escanteio! %s pede no primeiro pau, %s no segundo." % [atacante, parceiro]])
	s["bola"] = "parada"
	_op(s, "primeiro", "Cruzar no primeiro pau pro %s" % atacante, "cruzar", 0.3, {"passe": 0.45, "visao": 0.1}, false, "", {}, "atacante")
	_op(s, "segundo", "Cruzar no segundo pau pro %s" % parceiro, "cruzar", 0.27, {"passe": 0.4, "visao": 0.2}, false, "", {}, "parceiro")
	_op(s, "curta", "Cobrança curta com %s" % ponta, "passe", 0.24, {"passe": 0.3, "visao": 0.25}, false, "", {}, "ponta")
	if adiantado:
		_op(s, "olimpico", "Gol olímpico: direto pro gol!", "olimpico", 0.2, {"finalizacao": 0.5, "frieza": 0.15}, true, "goleiro")
		_poi(s, "goleiro", "goleiro", "olimpico", "Olha onde está o goleiro...", "O goleiro saiu do primeiro pau: dá pra bater direto!")


## Na linha de fundo, pela ponta.
static func _linha_de_fundo(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var prota := Vector3(lado * rng.randf_range(27.0, 30.0), 0, -36.5)
	var atacante: String = ctx.get("atacante", "Tico")
	var parceiro: String = ctx.get("parceiro", "Juninho")
	_j(s, "prota", prota, "casa")
	_j(s, "zagueiro", prota + Vector3(-lado * 1.7, 0, -0.2), "fora")
	_j(s, "atacante", Vector3(lado * 1.5, 0, -34.5), "casa", atacante)
	_j(s, "zagueiro2", Vector3(lado * 2.3, 0, -35.3), "fora")
	_j(s, "parceiro", Vector3(-lado * 0.5, 0, -28.5), "casa", parceiro)
	_j(s, "zagueiro3", Vector3(-lado * 3.0, 0, -31.5), "fora")
	_j(s, "goleiro", Vector3(lado * 2.3, 0, -39.0), "fora")
	s["olhar_para"] = Vector3(0, 0, -35)
	s["texto"] = _um(rng, ["Você chegou na linha de fundo! A área está cheia.", "Ganhou do lateral na corrida e está na linha de fundo.",
		"Bola na ponta, você vai até o fundo... e agora?"])
	s["bola"] = "pe"
	_op(s, "alto", "Cruzar alto pro %s" % atacante, "cruzar", 0.3, {"passe": 0.45, "visao": 0.1}, false, "", {}, "atacante")
	_op(s, "atras", "Rolar pra trás pro %s" % parceiro, "passe", 0.32, {"passe": 0.35, "visao": 0.25}, false, "", {}, "parceiro")
	_op(s, "sem_angulo", "Chutar sem ângulo", "chute", 0.12, {"finalizacao": 0.5})
	_op(s, "cruzado", "Chute cruzado no segundo pau", "chute", 0.3, {"finalizacao": 0.45, "visao": 0.2}, true, "goleiro")
	_poi(s, "goleiro", "goleiro", "cruzado", "O goleiro fechou o primeiro pau...", "Ele abriu o segundo pau: chute cruzado!")


## Cara a cara com o goleiro.
static func _cara_goleiro(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-5.0, 5.0)
	var prota := Vector3(x, 0, rng.randf_range(-28.0, -26.0))
	var lado := 1.0 if x < 0 else -1.0
	_j(s, "prota", prota, "casa")
	_j(s, "goleiro", Vector3(x * 0.5, 0, -33.5), "fora")
	_j(s, "zagueiro", prota + Vector3(lado * 1.5, 0, 2.5), "fora")
	_j(s, "parceiro", Vector3(lado * 12.0, 0, -24.0), "casa", ctx.get("parceiro", "Juninho"))
	s["texto"] = _um(rng, ["Você passou de todo mundo. Só o goleiro na sua frente!", "Cara a cara com o goleiro! Ele sai pra fechar o ângulo.",
		"Livre! O goleiro vem desesperado na sua direção."])
	s["bola"] = "pe"
	_op(s, "cruzado", "Bater cruzado", "chute", 0.38, {"finalizacao": 0.5, "frieza": 0.15})
	_op(s, "cobertura", "Tocar por cima dele", "cobertura", 0.34, {"finalizacao": 0.35, "frieza": 0.3})
	_op(s, "driblar", "Driblar o goleiro", "drible_goleiro", 0.4, {"drible": 0.45, "velocidade": 0.15})
	_op(s, "paciencia", "Esperar ele cair e tocar no canto", "paciencia", 0.52, {"frieza": 0.55}, true, "goleiro", {"frieza": 80})
	_poi(s, "goleiro", "goleiro", "paciencia", "Repare no goleiro...", "Ele vai se jogar antes da hora: espera e toca!")


## Bola rebatida pela zaga caindo na entrada da área.
static func _voleio_area(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-6.0, 6.0)
	var prota := Vector3(x, 0, rng.randf_range(-24.0, -22.0))
	var lado := 1.0 if x < 0 else -1.0
	var atacante: String = ctx.get("atacante", "Tico")
	_j(s, "prota", prota, "casa")
	_j(s, "zagueiro", prota + Vector3(0, 0, -2.6), "fora")
	_j(s, "atacante", Vector3(-lado * 4.0, 0, -31.0), "casa", atacante)
	_j(s, "zagueiro2", Vector3(-lado * 3.0, 0, -32.0), "fora")
	_j(s, "goleiro", Vector3(x * 0.1, 0, -38.7), "fora")
	s["texto"] = _um(rng, ["A zaga afasta mal e a bola sobe... ela cai na sua frente!", "Rebatida de cabeça do zagueiro: a bola vem quicando pra você.",
		"Bola espirrada no alto, na entrada da área!"])
	s["bola"] = "ar"
	s["origem_bola"] = Vector3(x * 0.5, 0.3, -34.0)
	_op(s, "voleio", "Voleio de primeira", "voleio", 0.24, {"finalizacao": 0.5, "frieza": 0.15})
	_op(s, "matar", "Matar no peito e bater", "domina_chute", 0.28, {"finalizacao": 0.3, "drible": 0.25})
	_op(s, "escorar", "Escorar de cabeça pro %s" % atacante, "ajeitar", 0.3, {"cabeceio": 0.3, "visao": 0.3}, false, "", {}, "atacante")
	_op(s, "chapeu", "Chapéu no zagueiro e bater", "chapeu", 0.38, {"drible": 0.5, "finalizacao": 0.15}, true, "zagueiro", {"drible": 82})
	_poi(s, "zagueiro", "zagueiro", "chapeu", "O zagueiro vem afobado...", "Ele vem correndo de frente: dá chapéu!")


## Pivô de costas para o gol, zagueiro colado.
static func _pivo(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-4.0, 4.0)
	var prota := Vector3(x, 0, rng.randf_range(-25.0, -23.5))
	var lado := 1.0 if x < 0 else -1.0
	var ponta: String = ctx.get("ponta", "Dudu")
	var parceiro: String = ctx.get("parceiro", "Juninho")
	_j(s, "prota", prota, "casa")
	_j(s, "zagueiro", prota + Vector3(0, 0, -0.9), "fora")
	_j(s, "ponta", Vector3(lado * 16.0, 0, -22.0), "casa", ponta)
	_j(s, "parceiro", Vector3(-lado * 3.0, 0, -15.5), "casa", parceiro)
	_j(s, "zagueiro2", Vector3(-lado * 5.0, 0, -31.0), "fora")
	_j(s, "goleiro", Vector3(x * 0.1, 0, -38.7), "fora")
	s["olhar_para"] = prota + Vector3(0, 0, 10)
	s["sem_corrida"] = true
	s["texto"] = _um(rng, ["Você recebe de costas pro gol, o zagueiro colado em você.", "Pivô! Bola no pé, marcador nas costas.",
		"De costas pra marcação... olhe por cima do ombro."])
	s["bola"] = "pe"
	_op(s, "giro", "Girar em cima do zagueiro e bater", "giro", 0.3, {"drible": 0.3, "fisico": 0.25, "finalizacao": 0.2})
	_op(s, "abrir", "Segurar e abrir pro %s" % ponta, "passe", 0.32, {"passe": 0.35, "fisico": 0.2}, false, "", {}, "ponta")
	_op(s, "ajeitar", "Ajeitar pro %s chutar de fora" % parceiro, "passe", 0.28, {"passe": 0.4}, false, "", {}, "parceiro")
	_op(s, "roleta", "Roleta em cima do zagueiro!", "roleta", 0.36, {"drible": 0.55, "frieza": 0.1}, true, "zagueiro", {"drible": 84})
	_poi(s, "zagueiro", "zagueiro", "roleta", "Ele está colado nas suas costas...", "Ele chegou com tudo: dá pra girar na roleta!")


## Dois contra um.
static func _dois_contra_um(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-6.0, 6.0)
	var prota := Vector3(x, 0, rng.randf_range(-21.0, -18.0))
	var lado := 1.0 if x < 0 else -1.0
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var atacante: String = ctx.get("atacante", "Tico")
	_j(s, "prota", prota, "casa")
	_j(s, "parceiro", prota + Vector3(lado * 7.0, 0, -1.0), "casa", parceiro)
	_j(s, "zagueiro", prota + Vector3(lado * 3.0, 0, -7.0), "fora")
	_j(s, "atacante", Vector3(-lado * 6.0, 0, -26.0), "casa", atacante)
	_j(s, "zagueiro2", prota + Vector3(0, 0, 6.0), "fora")
	_j(s, "goleiro", Vector3(x * 0.1, 0, -38.6), "fora")
	s["texto"] = _um(rng, ["Dois contra um! Você e %s contra o último zagueiro." % parceiro, "Contra-ataque: só um zagueiro pra marcar vocês dois!",
		"Superioridade! O zagueiro não sabe quem marcar."])
	s["bola"] = "pe"
	_op(s, "tocar", "Tocar pro %s na hora certa" % parceiro, "passe", 0.4, {"passe": 0.4, "visao": 0.2}, false, "", {}, "parceiro")
	_op(s, "finta", "Fingir o passe e bater", "finta_chute", 0.3, {"finalizacao": 0.35, "frieza": 0.25})
	_op(s, "carregar", "Carregar até o zagueiro decidir", "conduzir", 0.26, {"velocidade": 0.3, "drible": 0.25})
	_op(s, "diagonal", "Enfiar pro %s na diagonal" % atacante, "passe", 0.46, {"passe": 0.4, "visao": 0.35}, true, "atacante", {}, "atacante")
	_poi(s, "atacante", "atacante", "diagonal", "%s corre do outro lado..." % atacante, "%s entrou na diagonal sozinho!" % atacante)


## Falta pela lateral da área.
static func _falta_lateral(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var prota := Vector3(lado * rng.randf_range(22.0, 26.0), 0, rng.randf_range(-33.0, -29.0))
	var atacante: String = ctx.get("atacante", "Tico")
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var ponta: String = ctx.get("ponta", "Dudu")
	_j(s, "prota", prota, "casa")
	_barreira(s, prota, 2)
	_j(s, "atacante", Vector3(lado * 2.0, 0, -34.5), "casa", atacante)
	_j(s, "zagueiro", Vector3(lado * 2.6, 0, -35.2), "fora")
	_j(s, "parceiro", Vector3(-lado * 3.0, 0, -34.0), "casa", parceiro)
	_j(s, "zagueiro2", Vector3(-lado * 2.4, 0, -34.8), "fora")
	_j(s, "ponta", prota + Vector3(-lado * 4.0, 0, 3.0), "casa", ponta)
	_j(s, "goleiro", Vector3(lado * 0.8, 0, -39.0), "fora")
	s["olhar_para"] = Vector3(0, 0, -35)
	s["texto"] = _um(rng, ["Falta pela lateral da área. Cruzar ou bater?", "Falta no bico da área, pela ponta. Os grandalhões já subiram.",
		"Falta lateral! O goleiro organiza a barreira."])
	s["bola"] = "parada"
	_op(s, "cabeca", "Levantar na cabeça do %s" % atacante, "cruzar", 0.32, {"passe": 0.45, "visao": 0.1}, false, "", {}, "atacante")
	_op(s, "direto", "Bater direto no gol", "falta_curva", 0.14, {"finalizacao": 0.6})
	_op(s, "curta", "Rolar curto pro %s" % ponta, "passe", 0.24, {"passe": 0.3, "visao": 0.2}, false, "", {}, "ponta")
	_op(s, "segundo", "Cruzar fechado no segundo pau pro %s" % parceiro, "cruzar", 0.38, {"passe": 0.4, "visao": 0.3}, true, "parceiro", {}, "parceiro")
	_poi(s, "parceiro", "parceiro", "segundo", "%s está do outro lado..." % parceiro, "%s se soltou da marcação no segundo pau!" % parceiro)


## Cruzamento rasteiro chegando na marca do pênalti.
static func _cruzamento_rasteiro(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var prota := Vector3(rng.randf_range(-3.0, 3.0), 0, rng.randf_range(-29.5, -27.5))
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var ponta: String = ctx.get("ponta", "Dudu")
	_j(s, "prota", prota, "casa")
	_j(s, "ponta", Vector3(lado * 20.0, 0, -37.5), "casa", ponta)
	_j(s, "parceiro", prota + Vector3(-lado * 1.2, 0, 4.0), "casa", parceiro)
	_j(s, "zagueiro", prota + Vector3(lado * 0.8, 0, -1.2), "fora")
	_j(s, "zagueiro2", Vector3(-lado * 3.0, 0, -33.5), "fora")
	_j(s, "goleiro", Vector3(lado * 0.6, 0, -38.7), "fora")
	s["texto"] = _um(rng, ["%s cruza rasteiro! A bola vem rolando pra você." % ponta, "Cruzamento rasteiro de %s na marca do pênalti!" % ponta,
		"%s foi ao fundo e tocou pra trás, rasteiro." % ponta])
	s["bola"] = "rasteira"
	s["origem_bola"] = Vector3(lado * 19.0, 0.11, -37.0)
	_op(s, "primeira", "Bater de primeira", "chute_primeira", 0.34, {"finalizacao": 0.45, "frieza": 0.15})
	_op(s, "dominar", "Dominar e escolher o canto", "domina_chute", 0.3, {"finalizacao": 0.3, "drible": 0.2, "frieza": 0.1})
	_op(s, "chapa", "Bater de chapa no canto", "chute", 0.3, {"finalizacao": 0.5})
	_op(s, "corta_luz", "Corta-luz pro %s que vem atrás" % parceiro, "corta_luz", 0.46, {"visao": 0.45, "frieza": 0.15}, true, "parceiro", {}, "parceiro")
	_poi(s, "parceiro", "parceiro", "corta_luz", "Tem alguém chegando atrás de você...", "%s vem livre atrás: deixa passar!" % parceiro)


## Arrancada desde o meio-campo.
static func _arrancada_meio(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-6.0, 6.0)
	var prota := Vector3(x, 0, rng.randf_range(-3.0, 1.0))
	var lado := 1.0 if x < 0 else -1.0
	var atacante: String = ctx.get("atacante", "Tico")
	var adiantado := rng.randf() < 0.45
	_j(s, "prota", prota, "casa")
	_j(s, "zagueiro", prota + Vector3(lado * 1.0, 0, -4.0), "fora")
	_j(s, "zagueiro2", Vector3(-lado * 6.0, 0, -18.0), "fora")
	_j(s, "zagueiro3", Vector3(lado * 7.0, 0, -20.0), "fora")
	_j(s, "atacante", Vector3(-lado * 8.0, 0, -16.0), "casa", atacante)
	_j(s, "goleiro", Vector3(0, 0, -32.5 if adiantado else -38.4), "fora")
	s["texto"] = _um(rng, ["Você recebe no meio-campo e tem espaço pra correr!", "Bola no círculo central, o campo todo pela frente.",
		"Roubada no meio! Só um volante entre você e a zaga."])
	s["bola"] = "pe"
	_op(s, "arrancar", "Arrancar em velocidade", "conduzir", 0.28, {"velocidade": 0.45, "finalizacao": 0.15})
	_op(s, "lancar", "Lançar o %s" % atacante, "lancamento", 0.36, {"passe": 0.4, "visao": 0.3}, false, "", {}, "atacante")
	_op(s, "volante", "Driblar o volante", "drible", 0.3, {"drible": 0.5, "velocidade": 0.15})
	if adiantado:
		_op(s, "meio_campo", "Chutar do meio de campo!", "chute_meio", 0.16, {"finalizacao": 0.45, "visao": 0.35}, true, "goleiro", {"visao": 85})
		_poi(s, "goleiro", "goleiro", "meio_campo", "Olha o goleiro lá na frente...", "O goleiro está fora do gol: chuta do meio de campo!")


## Cruzamento à meia altura: peixinho ou carrinho.
static func _peixinho(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var prota := Vector3(rng.randf_range(-3.0, 3.0), 0, rng.randf_range(-33.0, -31.5))
	var parceiro: String = ctx.get("parceiro", "Juninho")
	var ponta: String = ctx.get("ponta", "Dudu")
	_j(s, "prota", prota, "casa")
	_j(s, "ponta", Vector3(lado * 22.0, 0, -33.0), "casa", ponta)
	_j(s, "zagueiro", prota + Vector3(lado * 0.8, 0, -0.8), "fora")
	_j(s, "parceiro", Vector3(-lado * 3.5, 0, -31.0), "casa", parceiro)
	_j(s, "zagueiro2", Vector3(-lado * 2.5, 0, -34.5), "fora")
	_j(s, "goleiro", Vector3(lado * 0.5, 0, -38.8), "fora")
	s["texto"] = _um(rng, ["%s cruza à meia altura, a bola vem rápida!" % ponta, "Cruzamento forte de %s na altura da cintura!" % ponta,
		"%s bate cruzado, a bola passa pela pequena área!" % ponta])
	s["bola"] = "ar"
	s["origem_bola"] = Vector3(lado * 21.5, 0.3, -33.0)
	s["arco_bola"] = 1.2
	s["alvo_bola_y"] = 0.8
	_op(s, "peixinho", "Peixinho!", "peixinho", 0.32, {"cabeceio": 0.45, "frieza": 0.1, "fisico": 0.1})
	_op(s, "carrinho", "Se jogar no carrinho pra empurrar", "carrinho_gol", 0.3, {"fisico": 0.3, "finalizacao": 0.3})
	_op(s, "dominar", "Dominar e bater", "domina_chute", 0.2, {"finalizacao": 0.3, "drible": 0.2})
	_op(s, "escorar", "Escorar pro %s" % parceiro, "ajeitar", 0.4, {"cabeceio": 0.3, "visao": 0.3}, true, "parceiro", {}, "parceiro")
	_poi(s, "parceiro", "parceiro", "escorar", "%s entra pelo outro lado..." % parceiro, "%s está livre no segundo pau!" % parceiro)


## Pressão na saída de bola deles.
static func _pressao_saida(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-7.0, 7.0)
	var lado := 1.0 if x < 0 else -1.0
	_j(s, "prota", Vector3(x + lado * 2.0, 0, -26.0), "casa")
	_j(s, "zagueiro_adv", Vector3(x, 0, -33.5), "fora")
	_j(s, "zagueiro2", Vector3(-lado * 9.0, 0, -31.0), "fora")
	_j(s, "goleiro", Vector3(x * 0.3, 0, -38.5), "fora")
	_j(s, "parceiro", Vector3(-lado * 6.0, 0, -22.0), "casa", ctx.get("parceiro", "Juninho"))
	s["texto"] = _um(rng, ["O zagueiro deles quer sair jogando... vai pra cima!", "Saída de bola deles enrolada! Você está perto.",
		"O treinador grita: PRESSIONA! O zagueiro está com a bola na área."])
	s["bola"] = "adv"
	s["com_bola"] = "zagueiro_adv"
	_op(s, "pressionar", "Pressionar o zagueiro", "pressionar", 0.34, {"velocidade": 0.3, "fisico": 0.25})
	_op(s, "fechar", "Fechar a linha de passe", "fechar_passe", 0.3, {"visao": 0.35, "velocidade": 0.2})
	_op(s, "bote", "Dar o bote", "bote_ataque", 0.28, {"fisico": 0.35, "frieza": 0.15})
	_op(s, "recuo", "Cortar o recuo pro goleiro", "antecipar_ataque", 0.46, {"visao": 0.4, "velocidade": 0.25}, true, "goleiro", {"visao": 80})
	_poi(s, "goleiro", "goleiro", "recuo", "O goleiro pede a bola...", "Ele vai recuar pro goleiro: corta no meio!")


## Falta de longe (35 metros).
static func _falta_longe(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-8.0, 8.0)
	var prota := Vector3(x, 0, rng.randf_range(-7.0, -4.5))
	var lado := 1.0 if x < 0 else -1.0
	var atacante: String = ctx.get("atacante", "Tico")
	_j(s, "prota", prota, "casa")
	_barreira(s, prota, 4)
	_j(s, "atacante", Vector3(lado * 2.0, 0, -31.0), "casa", atacante)
	_j(s, "zagueiro", Vector3(lado * 2.5, 0, -31.8), "fora")
	_j(s, "parceiro", prota + Vector3(lado * 5.0, 0, 1.5), "casa", ctx.get("parceiro", "Juninho"))
	_j(s, "zagueiro2", Vector3(-lado * 3.0, 0, -30.0), "fora")
	_j(s, "goleiro", Vector3(0, 0, -38.7), "fora")
	s["texto"] = _um(rng, ["Falta de longe, uns 35 metros. Vale arriscar?", "Falta no meio da rua. O goleiro nem armou barreira direito...",
		"Falta a favor longe do gol. A torcida pede bomba!"])
	s["bola"] = "parada"
	_op(s, "bomba", "Bomba de longe", "falta_forte", 0.12, {"finalizacao": 0.35, "fisico": 0.4})
	_op(s, "levantar", "Levantar na área pro %s" % atacante, "cruzar", 0.28, {"passe": 0.45, "visao": 0.1}, false, "", {}, "atacante")
	_op(s, "colocada", "Colocada por cima da barreira", "falta_curva", 0.1, {"finalizacao": 0.6})
	_op(s, "rapida", "Cobrar rápido antes da barreira!", "falta_rapida", 0.36, {"visao": 0.35, "finalizacao": 0.3}, true, "goleiro")
	_poi(s, "goleiro", "goleiro", "rapida", "Repare no goleiro...", "O goleiro está arrumando a barreira: cobra rápido!")


## Você é o garçom: três companheiros se movimentando.
static func _passe_decisivo(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-4.0, 4.0)
	var prota := Vector3(x, 0, rng.randf_range(-15.0, -12.0))
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var atacante: String = ctx.get("atacante", "Tico")
	var ponta: String = ctx.get("ponta", "Dudu")
	var parceiro: String = ctx.get("parceiro", "Juninho")
	_j(s, "prota", prota, "casa")
	_j(s, "atacante", Vector3(x * 0.3, 0, -29.0), "casa", atacante)
	_j(s, "zagueiro", Vector3(x * 0.3 + 0.6, 0, -29.6), "fora")
	_j(s, "ponta", Vector3(lado * 22.0, 0, -24.0), "casa", ponta)
	_j(s, "parceiro", Vector3(-lado * 7.0, 0, -19.0), "casa", parceiro)
	_j(s, "zagueiro2", Vector3(-lado * 6.0, 0, -22.5), "fora")
	_j(s, "zagueiro3", Vector3(lado * 12.0, 0, -27.0), "fora")
	_j(s, "lateral", Vector3(-lado * 24.0, 0, -22.0), "casa", "o lateral")
	_j(s, "goleiro", Vector3(0, 0, -38.6), "fora")
	s["texto"] = _um(rng, ["Bola no seu pé, três companheiros se mexendo. Quem você escolhe?", "Você é o garçom: a jogada passa por você.",
		"Tempo e espaço na intermediária. Levanta a cabeça!"])
	s["bola"] = "pe"
	_op(s, "enfiar", "Enfiar pro %s" % atacante, "passe", 0.26, {"passe": 0.45, "visao": 0.2}, false, "", {}, "atacante")
	_op(s, "ponta", "Lançar o %s na ponta" % ponta, "lancamento", 0.34, {"passe": 0.4, "visao": 0.25}, false, "", {}, "ponta")
	_op(s, "chega", "Tocar pro %s que chega" % parceiro, "passe", 0.32, {"passe": 0.35, "visao": 0.2}, false, "", {}, "parceiro")
	_op(s, "inverter", "Inverter pro lateral sozinho", "lancamento", 0.46, {"passe": 0.4, "visao": 0.4}, true, "lateral", {}, "lateral")
	_poi(s, "lateral", "lateral", "inverter", "E do outro lado do campo?", "O lateral está sozinho do outro lado!")


## O goleiro deles saiu mal e o gol ficou vazio.
static func _gol_vazio(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-8.0, 8.0)
	var prota := Vector3(x, 0, rng.randf_range(-17.0, -14.0))
	var lado := 1.0 if x < 0 else -1.0
	var parceiro: String = ctx.get("parceiro", "Juninho")
	_j(s, "prota", prota, "casa")
	_j(s, "goleiro", Vector3(lado * 14.0, 0, -24.0), "fora")
	_j(s, "zagueiro2", Vector3(x * 0.2, 0, -34.0), "fora")
	_j(s, "zagueiro", prota + Vector3(-lado * 2.0, 0, -5.0), "fora")
	_j(s, "parceiro", Vector3(-lado * 6.0, 0, -25.0), "casa", parceiro)
	s["texto"] = _um(rng, ["O goleiro deles saiu da área pra cortar e errou! O gol está vazio!", "Gol vazio! O goleiro foi driblado lá na ponta.",
		"O goleiro saiu jogando errado... a bola é sua e o gol está aberto!"])
	s["bola"] = "pe"
	s["sem_goleiro"] = true
	s["texto_defesa"] = "Tiraram em cima da linha!"
	_op(s, "primeira", "Chutar de primeira pro gol vazio", "chute", 0.44, {"finalizacao": 0.4, "frieza": 0.3})
	_op(s, "correr", "Correr com a bola até a área", "conduzir", 0.36, {"velocidade": 0.4, "frieza": 0.2})
	_op(s, "tocar", "Tocar pro %s mais perto" % parceiro, "passe", 0.34, {"passe": 0.35, "visao": 0.2}, false, "", {}, "parceiro")
	_op(s, "encobrir", "Encobrir o zagueiro que voltou pra linha", "cobertura", 0.42, {"finalizacao": 0.4, "visao": 0.3}, true, "linha")
	_poi(s, "linha", "zagueiro2", "encobrir", "Tem alguém voltando...", "O zagueiro correu pra linha: encobre ele!")


## Lateral longo na área.
static func _lateral_area(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var prota := Vector3(lado * rng.randf_range(2.5, 4.5), 0, rng.randf_range(-34.5, -32.5))
	var atacante: String = ctx.get("atacante", "Tico")
	_j(s, "prota", prota, "casa")
	_j(s, "ponta", Vector3(lado * 34.5, 0, -33.0), "casa", ctx.get("ponta", "Dudu"))
	_j(s, "zagueiro", prota + Vector3(0, 0, -0.7), "fora")
	_j(s, "atacante", Vector3(-lado * 2.5, 0, -32.5), "casa", atacante)
	_j(s, "zagueiro2", Vector3(-lado * 2.0, 0, -33.6), "fora")
	_j(s, "goleiro", Vector3(lado * 0.6, 0, -39.0), "fora")
	s["texto"] = _um(rng, ["Lateral longo na área! A bola vem como um escanteio.", "O lateral cobra com as mãos direto na área!",
		"Arremesso lateral na área: a bola vem na sua direção."])
	s["bola"] = "ar"
	s["origem_bola"] = Vector3(lado * 34.0, 2.0, -33.0)
	s["arco_bola"] = 3.0
	_op(s, "desviar", "Desviar de cabeça pro gol", "cabeceio", 0.26, {"cabeceio": 0.6})
	_op(s, "escorar", "Escorar pro %s" % atacante, "ajeitar", 0.34, {"cabeceio": 0.3, "visao": 0.3}, false, "", {}, "atacante")
	_op(s, "girar", "Dominar de costas e girar", "giro", 0.26, {"drible": 0.3, "fisico": 0.3})
	_op(s, "bicicleta", "BICICLETA!", "bicicleta", 0.22, {"fisico": 0.3, "finalizacao": 0.3, "frieza": 0.1}, true, "alta", {"fisico": 84})
	_poi(s, "alta", "ponta", "bicicleta", "Veja a altura da bola...", "A bola vem alta, atrás de você: bicicleta!")


## Ponta encarando o lateral.
static func _drible_ponta(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var prota := Vector3(lado * rng.randf_range(22.0, 26.0), 0, rng.randf_range(-26.0, -22.0))
	var atacante: String = ctx.get("atacante", "Tico")
	_j(s, "prota", prota, "casa")
	_j(s, "zagueiro", prota + Vector3(-lado * 0.3, 0, -3.2), "fora")
	_j(s, "zagueiro2", prota + Vector3(-lado * 3.5, 0, -6.0), "fora")
	_j(s, "atacante", Vector3(lado * 2.0, 0, -33.5), "casa", atacante)
	_j(s, "zagueiro3", Vector3(lado * 2.6, 0, -34.2), "fora")
	_j(s, "goleiro", Vector3(lado * 1.0, 0, -38.7), "fora")
	s["texto"] = _um(rng, ["Mano a mano com o lateral, pela ponta!", "Bola na ponta: o lateral fecha, o volante vem na cobertura.",
		"Você recebe aberto na ponta. Hora do show?"])
	s["bola"] = "pe"
	_op(s, "pedalada", "Pedalada e partir pra cima", "drible", 0.3, {"drible": 0.5, "velocidade": 0.2})
	_op(s, "cortar", "Cortar pro meio e bater colocado", "chute", 0.2, {"finalizacao": 0.45, "drible": 0.15})
	_op(s, "cruzar", "Cruzar de primeira pro %s" % atacante, "cruzar", 0.32, {"passe": 0.45}, false, "", {}, "atacante")
	_op(s, "elastico", "ELÁSTICO!", "elastico", 0.4, {"drible": 0.6}, true, "zagueiro", {"drible": 85})
	_poi(s, "zagueiro", "zagueiro", "elastico", "Olha o pé de apoio do lateral...", "Ele está com o peso no pé errado: elástico!")


# ---------------------------------------------------------------- defesa (v1.3)

## O ponta deles corre pela lateral: você faz a cobertura.
static func _cobertura_lateral(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var at := Vector3(lado * rng.randf_range(23.0, 26.0), 0, rng.randf_range(-20.0, -17.0))
	var numero := rng.randi_range(7, 11)
	_j(s, "prota", at + Vector3(-lado * 2.5, 0, 3.5), "casa")
	_j(s, "atacante_adv", at, "fora")
	_j(s, "apoio_adv", Vector3(lado * 2.0, 0, -31.0), "fora")
	_j(s, "zagueiro_nos", Vector3(-lado * 1.0, 0, -33.0), "casa")
	_j(s, "goleiro", Vector3(lado * 1.0, 0, -38.7), "casa")
	s["texto"] = _um(rng, ["O ponta deles dispara pela lateral! Você faz a cobertura.", "Nosso lateral ficou lá na frente. Só você pra fechar a ponta!",
		"O camisa %d deles vai à linha de fundo... corre!" % numero])
	s["bola"] = "adv"
	s["avanca"] = true
	_op(s, "fechar", "Fechar o cruzamento", "conter", 0.42, {"velocidade": 0.35, "visao": 0.15})
	_op(s, "bote", "Bote na hora certa", "bote", 0.3, {"fisico": 0.25, "frieza": 0.35})
	_op(s, "lateral", "Espirrar a bola pra lateral", "empurrar_lateral", 0.4, {"fisico": 0.3, "velocidade": 0.2})
	_op(s, "antecipar", "Antecipar o cruzamento", "antecipar", 0.48, {"visao": 0.4, "velocidade": 0.2}, true, "apoio", {"visao": 80})
	_poi(s, "apoio", "apoio_adv", "antecipar", "Quem espera na área?", "O centroavante deles espera o cruzamento: antecipa!")


## Escanteio contra nós.
static func _escanteio_contra(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var origem := Vector3(lado * 33.2, 0.3, -39.6)
	_j(s, "prota", Vector3(lado * 3.2, 0, -38.6), "casa")
	_j(s, "ponta_adv", Vector3(lado * 33.5, 0, -39.5), "fora")
	_j(s, "atacante_adv", Vector3(lado * 0.5, 0, -35.5), "fora")
	_j(s, "apoio_adv", Vector3(-lado * 2.5, 0, -34.5), "fora")
	_j(s, "zagueiro_nos", Vector3(lado * 0.0, 0, -35.0), "casa")
	_j(s, "goleiro", Vector3(lado * 0.3, 0, -39.4), "casa")
	s["texto"] = _um(rng, ["Escanteio contra! O treinador te mandou pro primeiro pau.", "Último escanteio deles. Todo mundo na área, você também!",
		"Escanteio pra eles. O grandalhão deles subiu pra área."])
	s["bola"] = "ar"
	s["origem_bola"] = origem
	s["olhar_para"] = origem
	_op(s, "cortar", "Cortar no primeiro pau", "afastar_cabeca", 0.42, {"cabeceio": 0.45, "fisico": 0.2})
	_op(s, "marcar", "Marcar o grandalhão", "marcar", 0.36, {"fisico": 0.4, "cabeceio": 0.2})
	_op(s, "trave", "Ficar na trave", "trave_def", 0.4, {"visao": 0.3, "frieza": 0.3})
	_op(s, "contra", "Sair pro contra-ataque", "puxar_contra", 0.3, {"velocidade": 0.35, "visao": 0.3}, true, "zagueiro", {"visao": 75})
	_poi(s, "zagueiro", "zagueiro_nos", "contra", "E o nosso zagueirão?", "O zagueirão está colado no grandalhão: dá pra sair!")


## Chute de fora da área deles: bloquear.
static func _chute_bloqueio(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-8.0, 8.0)
	var lado := 1.0 if x < 0 else -1.0
	var at := Vector3(x, 0, rng.randf_range(-18.0, -15.5))
	_j(s, "prota", Vector3(x + rng.randf_range(-1.0, 1.0), 0, at.z - 4.0), "casa")
	_j(s, "atacante_adv", at, "fora")
	_j(s, "apoio_adv", Vector3(x + lado * 8.0, 0, at.z - 5.0), "fora")
	_j(s, "zagueiro_nos", Vector3(x - lado * 4.0, 0, -27.0), "casa")
	_j(s, "goleiro", Vector3(x * 0.1, 0, -38.6), "casa")
	s["texto"] = _um(rng, ["O meia deles ajeita pra bater de fora da área!", "Ele vai chutar! Você está na frente da bola.",
		"Bola de frente pro gol pra eles, a 25 metros. Fecha!"])
	s["bola"] = "adv"
	s["olhar_para"] = at
	_op(s, "bloquear", "Se jogar na frente do chute", "bloquear", 0.42, {"fisico": 0.3, "frieza": 0.25})
	_op(s, "conter", "Fechar o ângulo em pé", "conter", 0.34, {"velocidade": 0.25, "visao": 0.25})
	_op(s, "bote", "Dar o bote antes do chute", "bote", 0.28, {"fisico": 0.3, "velocidade": 0.2})
	_op(s, "antecipar", "Antecipar o passe pro lado", "antecipar", 0.46, {"visao": 0.45}, true, "apoio", {"visao": 80})
	_poi(s, "apoio", "apoio_adv", "antecipar", "Tem gente aberta do lado...", "Ele vai tocar pro lado: antecipa!")


## Rebote na nossa área.
static func _rebote_def(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-3.0, 3.0)
	var lado := 1.0 if x < 0 else -1.0
	var prota := Vector3(x, 0, -34.2)
	_j(s, "prota", prota, "casa")
	_j(s, "atacante_adv", Vector3(x - lado * 2.5, 0, -30.5), "fora")
	_j(s, "apoio_adv", Vector3(lado * 5.0, 0, -31.0), "fora")
	_j(s, "zagueiro_nos", Vector3(-lado * 4.0, 0, -33.0), "casa")
	_j(s, "goleiro", Vector3(x * 0.4 + lado * 1.2, 0, -38.6), "casa")
	s["texto"] = _um(rng, ["O goleiro espalmou e a bola ficou viva na nossa área!", "Bate-rebate na nossa pequena área! A bola sobra perto de você.",
		"Chute deles, o goleiro solta... a bola quica na sua frente!"])
	s["bola"] = "solta"
	s["pos_bola"] = prota + Vector3(lado * 0.8, 0.11, -0.8)
	s["goleiro_caido"] = true
	s["olhar_para"] = Vector3(x, 0, -20)
	s["tempo_mult"] = 0.8
	_op(s, "bicao", "Bicão pra frente", "chutao", 0.46, {"fisico": 0.3, "frieza": 0.2})
	_op(s, "sair", "Dominar e sair jogando", "sair_jogando", 0.26, {"drible": 0.3, "frieza": 0.35})
	_op(s, "proteger", "Proteger e deixar sair pela linha de fundo", "proteger", 0.36, {"fisico": 0.4, "frieza": 0.2})
	_op(s, "recuar", "Tocar pro goleiro que levantou", "recuar_goleiro", 0.5, {"visao": 0.35, "frieza": 0.25}, true, "goleiro")
	_poi(s, "goleiro", "goleiro", "recuar", "E o goleiro?", "O goleiro já levantou e pede a bola!")


## Dois atacantes deles contra você.
static func _dois_contra_um_def(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-6.0, 6.0)
	var lado := 1.0 if x < 0 else -1.0
	var at := Vector3(x, 0, rng.randf_range(-20.0, -17.0))
	_j(s, "prota", Vector3(x - lado * 3.0, 0, at.z - 5.0), "casa")
	_j(s, "atacante_adv", at, "fora")
	_j(s, "apoio_adv", at + Vector3(-lado * 6.0, 0, -1.0), "fora")
	_j(s, "zagueiro_nos", Vector3(-lado * 10.0, 0, -30.0), "casa")
	_j(s, "goleiro", Vector3(x * 0.1, 0, -38.6), "casa")
	s["texto"] = _um(rng, ["Dois contra você! Retarda até o time voltar!", "Contra-ataque deles, dois atacantes e você no meio.",
		"Só você e o goleiro contra dois. Calma..."])
	s["bola"] = "adv"
	s["avanca"] = true
	s["olhar_para"] = at + Vector3(-lado * 3.0, 0, 0)
	_op(s, "retardar", "Ficar no meio e retardar", "conter", 0.42, {"visao": 0.3, "velocidade": 0.2, "frieza": 0.15})
	_op(s, "bote", "Bote no que tem a bola", "bote", 0.3, {"fisico": 0.3, "frieza": 0.25})
	_op(s, "marcar_outro", "Marcar o que vai receber", "antecipar", 0.34, {"visao": 0.35, "velocidade": 0.2})
	_op(s, "tatica", "Falta tática (cartão consciente)", "falta_tatica", 0.62, {"frieza": 0.3}, true, "atacante", {"frieza": 70})
	_poi(s, "atacante", "atacante_adv", "tatica", "Ele vai partir em velocidade...", "Sem ninguém na cobertura: a falta tática salva!")


## Linha de impedimento.
static func _linha_impedimento(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var x := rng.randf_range(-6.0, 6.0)
	var lado := 1.0 if rng.randf() < 0.5 else -1.0
	var xa := rng.randf_range(-8.0, 8.0)
	var pas := Vector3(x, 0, rng.randf_range(-12.0, -8.0))
	_j(s, "prota", Vector3(xa + lado * 1.6, 0, -24.8), "casa")
	_j(s, "apoio_adv", pas, "fora")
	_j(s, "atacante_adv", Vector3(xa, 0, -24.3), "fora")
	_j(s, "zagueiro_nos", Vector3(xa - lado * 5.0, 0, -24.8), "casa")
	_j(s, "goleiro", Vector3(0, 0, -38.6), "casa")
	s["texto"] = _um(rng, ["Eles vão lançar nas costas! Você está na linha da defesa.", "O atacante deles está na linha, pronto pra correr.",
		"Bola com o meia deles. O centroavante se prepara pra arrancar."])
	s["bola"] = "adv"
	s["com_bola"] = "apoio_adv"
	s["olhar_para"] = pas
	_op(s, "subir", "Subir a linha (deixar impedido)", "subir_linha", 0.42, {"visao": 0.4, "frieza": 0.2})
	_op(s, "acompanhar", "Correr junto com o atacante", "acompanhar", 0.38, {"velocidade": 0.45})
	_op(s, "recuar", "Recuar e cortar o lançamento", "recuar", 0.34, {"cabeceio": 0.3, "visao": 0.2})
	_op(s, "antecipar", "Antecipar o lançamento", "antecipar", 0.46, {"visao": 0.45, "velocidade": 0.15}, true, "passador", {"visao": 80})
	_poi(s, "passador", "apoio_adv", "antecipar", "Repare no meia deles...", "Ele levantou a cabeça pra lançar: antecipa!")


static func _figurantes(s: Dictionary, rng: RandomNumberGenerator) -> void:
	if s["tipo"] in ["penalti", "escanteio", "cobranca_escanteio", "escanteio_contra", "lateral_area"]:
		return
	for k in 3:
		_j(s, "figurante", Vector3(rng.randf_range(-25, 25), 0, rng.randf_range(-10, 15)), "casa")
	for k in 3:
		_j(s, "figurante", Vector3(rng.randf_range(-25, 25), 0, rng.randf_range(-25, 5)), "fora")


# ---------------------------------------------------------------- chances

static func _calcular_chances(s: Dictionary, ctx: Dictionary) -> void:
	var attrs: Dictionary = ctx.get("atributos", {})
	var pressao: float = ctx.get("pressao", 0.3)
	var frieza: float = attrs.get("frieza", 50.0)
	var moral: float = ctx.get("moral", 60.0)
	var efeito_pressao := pressao * (1.0 - frieza / 130.0) * 0.14
	var dificuldade: float = ctx.get("dificuldade", 0.0)  # (força do adversário - overall) / 100
	for op in s["opcoes"]:
		var c: float = op["base"]
		for a in op["atributos"]:
			c += (float(attrs.get(a, 50.0)) - 50.0) / 100.0 * float(op["atributos"][a]) * 0.85
		c -= efeito_pressao
		c -= dificuldade * 0.6
		c += (moral - 60.0) / 600.0
		op["chance"] = clampf(c, 0.06, 0.9)
		# opção oculta que o jogador já "enxerga" por talento
		if op["oculta"] and not op["requisito"].is_empty():
			var ok := true
			for a in op["requisito"]:
				if float(attrs.get(a, 0.0)) < float(op["requisito"][a]):
					ok = false
			if ok:
				op["oculta"] = false
				op["por_talento"] = true


static func _tempo_decisao(ctx: Dictionary) -> float:
	var frieza: float = ctx.get("atributos", {}).get("frieza", 50.0)
	var pressao: float = ctx.get("pressao", 0.3)
	return clampf(7.5 + (frieza - 50.0) / 25.0 - pressao * 2.0, 4.5, 10.0)


## Instinto: com Visão alta, o jogador "sente" a qualidade de cada opção.
static func sensacao(chance: float) -> Array:
	if chance >= 0.6:
		return ["Ótima", UI.VERDE]
	if chance >= 0.42:
		return ["Boa", Color("9be36b")]
	if chance >= 0.26:
		return ["Possível", UI.OURO]
	return ["Arriscado", UI.VERMELHO]


## Sorteia o desfecho da opção escolhida.
## desfechos: gol, assistencia, defesa, fora, trave, perdeu, interceptado, passou_defesa
static func resolver(s: Dictionary, op: Dictionary, apressado: bool, rng: RandomNumberGenerator, bonus := 0.0) -> Dictionary:
	var chance: float = op["chance"] + bonus
	if apressado:
		chance *= 0.55
	var acao: String = op["acao"]
	var r := {"acao": acao, "opcao": op["id"], "apressado": apressado, "chance": chance}
	if acao in ["penalti_esq", "penalti_dir", "cavadinha"]:
		_avaliar_decisao(s, op, r)
		return _resolver_penalti(s, op, r, rng, chance)
	_avaliar_decisao(s, op, r)
	var sucesso := rng.randf() < chance
	match acao:
		"passe", "lancamento", "ajeitar", "calcanhar", "cruzar", "corta_luz":
			if sucesso:
				r["desfecho"] = "assistencia"
			else:
				var x := rng.randf()
				r["desfecho"] = "interceptado" if x < 0.45 else ("defesa" if x < 0.8 else "fora")
		"drible", "arrancada", "caneta", "elastico":
			if sucesso:
				r["desfecho"] = "gol"
			else:
				r["desfecho"] = "perdeu" if rng.randf() < 0.6 else "passou_defesa"
		"drible_goleiro":
			r["desfecho"] = "gol" if sucesso else ("defesa" if rng.randf() < 0.55 else "perdeu")
		"tabela":
			if sucesso:
				r["desfecho"] = "gol"
			else:
				var x := rng.randf()
				r["desfecho"] = "interceptado" if x < 0.35 else ("defesa" if x < 0.75 else "fora")
		"giro", "roleta", "chapeu":
			if sucesso:
				r["desfecho"] = "gol"
			else:
				var x := rng.randf()
				r["desfecho"] = "perdeu" if x < 0.4 else ("defesa" if x < 0.75 else ("trave" if x < 0.85 else "fora"))
		"pressionar", "fechar_passe", "bote_ataque", "antecipar_ataque":
			r["desfecho"] = "gol" if sucesso else ("perdeu" if rng.randf() < 0.6 else "defesa")
		"subir_linha":
			if sucesso:
				r["desfecho"] = "impedimento"
			else:
				r["driblado"] = true
				r["desfecho"] = "salvou_goleiro" if rng.randf() < 0.4 else "gol_sofrido"
		"carrinho", "bote", "conter", "antecipar", "bloquear", "acompanhar", "empurrar_lateral", "falta_tatica":
			if sucesso:
				r["desfecho"] = {"conter": "bloqueio", "bloquear": "bloqueio", "empurrar_lateral": "afastou",
					"falta_tatica": "falta_tatica"}.get(acao, "desarme")
			else:
				var x := rng.randf()
				var p_falta := {"carrinho": 0.42, "bote": 0.2, "falta_tatica": 0.6}.get(acao, 0.0) as float
				if x < p_falta:
					r["desfecho"] = "falta_dura"
					r["falta_gol"] = rng.randf() < 0.22  # a cobrança da falta pode virar gol deles
				else:
					r["driblado"] = true
					r["desfecho"] = "salvou_goleiro" if rng.randf() < 0.45 else "gol_sofrido"
		"afastar_cabeca", "chutao", "sair_jogando", "deixar_goleiro", "marcar", "trave_def", "puxar_contra", \
				"proteger", "recuar_goleiro", "recuar":
			if sucesso:
				r["desfecho"] = "afastou"
				r["saiu_jogando"] = acao == "sair_jogando"
				r["salvou_linha"] = acao == "trave_def"
				r["puxou_contra"] = acao == "puxar_contra"
			else:
				var p_salva := {"sair_jogando": 0.35, "puxar_contra": 0.3}.get(acao, 0.5) as float
				r["desfecho"] = "salvou_goleiro" if rng.randf() < p_salva else "gol_sofrido"
		_:
			if sucesso:
				r["desfecho"] = "gol"
			else:
				var x := rng.randf()
				var p_trave := 0.2 if acao in ["chute_forte", "falta_forte", "voleio", "bicicleta", "chute_primeira", "olimpico"] else 0.13
				if s["tipo"] == "gol_vazio":
					r["desfecho"] = "trave" if x < 0.25 else ("defesa" if x < 0.45 else "fora")
				elif x < p_trave:
					r["desfecho"] = "trave"
				elif x < p_trave + 0.5:
					r["desfecho"] = "defesa"
				else:
					r["desfecho"] = "fora"
	r["lado"] = -1.0 if rng.randf() < 0.5 else 1.0
	r["alto"] = rng.randf() < 0.5
	return r


## Guarda se a escolha foi a melhor disponível (alimenta as manchetes dos jornais).
static func _avaliar_decisao(s: Dictionary, op: Dictionary, r: Dictionary) -> void:
	var melhor := op
	var ignorada := ""
	for o in s["opcoes"]:
		if o["oculta"] and o != op:
			continue
		if float(o["chance"]) > float(melhor["chance"]):
			melhor = o
		if o != op and (o.get("descoberta", false) or o.get("por_talento", false)):
			ignorada = o["texto"]
	r["opcao_texto"] = op["texto"]
	r["melhor_texto"] = melhor["texto"]
	r["foi_melhor"] = float(op["chance"]) >= float(melhor["chance"]) - 0.03
	r["ignorou"] = ignorada
	r["descoberta"] = op.get("descoberta", false) or op.get("por_talento", false)


static func _resolver_penalti(s: Dictionary, op: Dictionary, r: Dictionary, rng: RandomNumberGenerator, chance: float) -> Dictionary:
	var decisao: String = s.get("goleiro_decisao", "esq")
	var acao: String = op["acao"]
	var escolha := "esq" if acao == "penalti_esq" else ("dir" if acao == "penalti_dir" else "meio")
	r["goleiro"] = decisao
	r["lado"] = -1.0 if escolha == "esq" else (1.0 if escolha == "dir" else 0.0)
	r["alto"] = rng.randf() < 0.4
	var precisao := clampf(chance + 0.12, 0.5, 0.97)  # chance de acertar o alvo
	if rng.randf() > precisao:
		r["desfecho"] = "trave" if rng.randf() < 0.35 else "fora"
		return r
	if escolha == "meio":
		r["desfecho"] = "defesa" if decisao == "fica" else "gol"
	elif escolha == decisao:
		r["desfecho"] = "defesa" if rng.randf() < 0.68 else "gol"
	else:
		r["desfecho"] = "gol"
	return r
