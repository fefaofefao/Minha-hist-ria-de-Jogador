class_name Situacoes
extends RefCounted
## Gera "momentos decisivos" procedurais. Cada situação descreve o posicionamento
## dos jogadores, os pontos de interesse (POIs) que o jogador pode "ler" olhando
## ao redor e as opções (algumas escondidas até serem descobertas).
##
## O gol atacado fica em z = -40; o jogador ataca na direção -Z.

const TIPOS := ["chance_area", "mano_a_mano", "contra_ataque", "cruzamento", "falta", "penalti"]

## Peso de cada tipo por posição (atacante finaliza mais, meia passa mais...).
const PESOS_POSICAO := {
	"Atacante": {"chance_area": 5, "mano_a_mano": 3, "contra_ataque": 1, "cruzamento": 4, "falta": 1, "penalti": 1},
	"Ponta": {"chance_area": 3, "mano_a_mano": 5, "contra_ataque": 2, "cruzamento": 2, "falta": 1, "penalti": 1},
	"Meia": {"chance_area": 3, "mano_a_mano": 2, "contra_ataque": 5, "cruzamento": 1, "falta": 3, "penalti": 1},
}


static func sortear_tipo(posicao: String, rng: RandomNumberGenerator) -> String:
	var pesos: Dictionary = PESOS_POSICAO.get(posicao, PESOS_POSICAO["Atacante"])
	var total := 0
	for t in pesos:
		total += pesos[t]
	var r := rng.randi_range(1, total)
	for t in pesos:
		r -= pesos[t]
		if r <= 0:
			return t
	return "chance_area"


## ctx: atributos, moral, pressao (0..1), parceiro, rng, minuto, placar,
##      cenario, noite, cor_casa, calcao_casa, cor_fora, calcao_fora, adversario, visual
static func gerar(tipo: String, ctx: Dictionary) -> Dictionary:
	var rng: RandomNumberGenerator = ctx.get("rng", RandomNumberGenerator.new())
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
	_figurantes(s, rng)
	_calcular_chances(s, ctx)
	s["tempo"] = _tempo_decisao(ctx)
	return s


# ---------------------------------------------------------------- layouts

static func _j(s: Dictionary, papel: String, pos: Vector3, time: String, nome := "") -> void:
	s["jogadores"].append({"papel": papel, "pos": pos, "time": time, "nome": nome})


static func _op(s: Dictionary, id: String, texto: String, acao: String, base: float, atributos: Dictionary, oculta := false, poi := "", requisito := {}) -> void:
	s["opcoes"].append({"id": id, "texto": texto, "acao": acao, "base": base, "atributos": atributos,
		"oculta": oculta, "poi": poi, "requisito": requisito, "chance": base})


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
	s["texto"] = "A bola sobra pra você na entrada da área!"
	s["bola"] = "pe"
	_op(s, "colocado", "Chute colocado no canto", "chute", 0.30, {"finalizacao": 0.55})
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
	s["texto"] = "Cara a cara com o zagueiro. Ele vem pra cima!"
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
	s["texto"] = "Contra-ataque! Você tem a bola no meio-campo."
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
	s["texto"] = "%s cruza! A bola vem na sua direção..." % ponta
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
	var alvo := Vector3(0, 0, -40)
	var dir := (alvo - prota).normalized()
	var meio := prota + dir * 9.15
	var lateral := Vector3(-dir.z, 0, dir.x)
	for k in 4:
		_j(s, "barreira", meio + lateral * ((k - 1.5) * 0.62) + Vector3(0, 0, 0), "fora")
	var lado := -signf(x) if absf(x) > 0.5 else 1.0
	_j(s, "parceiro", prota + Vector3(lado * 6.0, 0, 2.0), "casa", parceiro)
	_j(s, "goleiro", Vector3(-lado * 1.0, 0, -38.9), "fora")
	_j(s, "zagueiro", Vector3(lado * 7.0, 0, -30.0), "fora")
	s["texto"] = "Falta perigosa! A bola é sua."
	s["bola"] = "parada"
	_op(s, "curva", "Por cima da barreira", "falta_curva", 0.24, {"finalizacao": 0.6})
	_op(s, "forte", "Bomba no canto do goleiro", "falta_forte", 0.18, {"finalizacao": 0.35, "fisico": 0.3})
	_op(s, "rolar", "Rolar pro %s bater" % parceiro, "passe", 0.26, {"passe": 0.25, "visao": 0.3}, true, "parceiro")
	_poi(s, "parceiro", "parceiro", "rolar", "%s pisca pra você..." % parceiro, "%s combinou a jogada ensaiada!" % parceiro)


static func _penalti(s: Dictionary, ctx: Dictionary, rng: RandomNumberGenerator) -> void:
	var visao: float = ctx.get("atributos", {}).get("visao", 50.0)
	_j(s, "prota", Vector3(0, 0, -29.0), "casa")
	_j(s, "goleiro", Vector3(0, 0, -39.6), "fora")
	_j(s, "zagueiro", Vector3(-8.0, 0, -22.0), "fora")
	_j(s, "zagueiro2", Vector3(7.5, 0, -22.5), "fora")
	_j(s, "parceiro", Vector3(4.0, 0, -22.0), "casa", ctx.get("parceiro", "Juninho"))
	s["texto"] = "PÊNALTI! Você vai bater."
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


static func _figurantes(s: Dictionary, rng: RandomNumberGenerator) -> void:
	if s["tipo"] == "penalti":
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
		return _resolver_penalti(s, op, r, rng, chance)
	var sucesso := rng.randf() < chance
	match acao:
		"passe", "lancamento", "ajeitar":
			if sucesso:
				r["desfecho"] = "assistencia"
			else:
				var x := rng.randf()
				r["desfecho"] = "interceptado" if x < 0.45 else ("defesa" if x < 0.8 else "fora")
		"drible", "arrancada", "caneta":
			if sucesso:
				r["desfecho"] = "gol"
			else:
				r["desfecho"] = "perdeu" if rng.randf() < 0.6 else "passou_defesa"
		_:
			if sucesso:
				r["desfecho"] = "gol"
			else:
				var x := rng.randf()
				var p_trave := 0.2 if acao in ["chute_forte", "falta_forte"] else 0.13
				if x < p_trave:
					r["desfecho"] = "trave"
				elif x < p_trave + 0.5:
					r["desfecho"] = "defesa"
				else:
					r["desfecho"] = "fora"
	r["lado"] = -1.0 if rng.randf() < 0.5 else 1.0
	r["alto"] = rng.randf() < 0.5
	return r


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
