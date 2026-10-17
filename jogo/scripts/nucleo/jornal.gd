class_name Jornal
extends RefCounted
## "O que os jornais falaram de você": manchetes depois de cada partida, sempre
## ligadas às decisões que o jogador tomou nos momentos decisivos (a escolha
## certa, a melhor opção que ele não viu, o lance que viralizou, o esforço na defesa).

const VEICULOS_BAIRRO := ["Jornal do Bairro", "Rádio Comunitária da Vila", "Grupo da Família", "Página Vila Esperança FC"]
const VEICULOS_BASE := ["Blog da Base", "Canal Joias do Futebol", "Diário do Gol", "Rádio Arquibancada"]
const VEICULOS_PRO := ["Diário do Gol", "Folha da Bola", "Rádio Arquibancada", "Canal Lance a Lance", "@resenha.fc", "Gazeta Esportiva"]
const VEICULOS_FORA := ["Imprensa internacional", "Canal Lance a Lance", "@resenha.fc", "Diário do Gol"]


## Devolve até 3 manchetes: [{veiculo, titulo, bom}].
static func gerar(resumo: Dictionary, p: Dictionary, rng: RandomNumberGenerator) -> Array:
	var c: Dictionary = Jogo.carreira
	var ap: String = c["jogador"]["apelido"]
	var veiculos: Array = _veiculos(p, c).duplicate()
	veiculos.shuffle()
	var lista: Array = []
	if not resumo.get("jogou", false):
		var nos := Jogo.nome_clube(p["nos"])
		if c["status"].get("lesao", 0) > 0 or resumo.has("lesao"):
			lista.append({"titulo": "Lesionado, %s acompanhou do departamento médico o jogo do %s" % [ap, nos], "bom": false})
		else:
			lista.append({"titulo": "No banco, %s só assistiu: o técnico não colocou o garoto em campo" % ap, "bom": false})
	else:
		# 1) os lances, do mais marcante para o menos
		var candidatos: Array = []
		for l in resumo.get("lances", []):
			var t := _manchete_lance(l, resumo, p, ap, rng)
			if t != "":
				candidatos.append({"titulo": t, "peso": _peso(l), "bom": Situacoes.bom(l["desfecho"])})
		candidatos.sort_custom(func(a, b) -> bool: return a["peso"] > b["peso"])
		for k in mini(2, candidatos.size()):
			lista.append(candidatos[k])
		# 2) a partida e os fãs
		var geral := _manchete_geral(resumo, p, ap, rng)
		if geral != "":
			lista.append({"titulo": geral, "bom": resumo.get("venceu", false) or float(resumo.get("nota", 6.0)) >= 7.0})
	for i in lista.size():
		lista[i]["veiculo"] = veiculos[i % veiculos.size()]
		lista[i].erase("peso")
	return lista


static func _veiculos(p: Dictionary, c: Dictionary) -> Array:
	if p.get("tipo", "") == "prologo":
		return VEICULOS_BAIRRO
	if c.get("fase", "") != "pro":
		return VEICULOS_BASE
	if Jogo.clube(c["clube"]).get("pais", "br") != "br":
		return VEICULOS_FORA
	return VEICULOS_PRO


static func _peso(l: Dictionary) -> float:
	var d: String = l["desfecho"]
	var w := {"gol": 10.0, "assistencia": 8.0, "desarme": 9.0, "bloqueio": 9.0, "afastou": 8.5, "gol_sofrido": 7.0,
		"impedimento": 8.5, "falta_tatica": 6.5,
		"falta_dura": 5.0, "salvou_goleiro": 6.0}.get(d, 4.0) as float
	if l["acao"] in Jogo.ACOES_VIRAIS and Situacoes.bom(d):
		w += 3.0
	if int(l.get("minuto", 0)) >= 84:
		w += 1.0
	if l["acao"] in ["penalti_esq", "penalti_dir", "cavadinha"] and d != "gol":
		w += 3.0
	return w


static func _um(rng: RandomNumberGenerator, lista: Array) -> String:
	return lista[rng.randi() % lista.size()]


## "Chute colocado no canto" -> "chute colocado no canto" (para usar no meio da frase).
static func _minusc(t: String) -> String:
	if t.length() < 2 or t.substr(0, 2) == t.substr(0, 2).to_upper():
		return t
	return t.substr(0, 1).to_lower() + t.substr(1)


static func _manchete_lance(l: Dictionary, resumo: Dictionary, p: Dictionary, ap: String, rng: RandomNumberGenerator) -> String:
	var d: String = l["desfecho"]
	var a: String = l["acao"]
	var m := int(l.get("minuto", 0))
	var nos := Jogo.nome_clube(p["nos"])
	var adv := Jogo.nome_clube(p["adv"])
	var parceiro: String = l.get("parceiro", "")
	if parceiro == "":
		parceiro = "o companheiro"
	var receptor: String = l.get("receptor_nome", "")
	if receptor == "":
		receptor = "o companheiro"
	var escolha := _minusc(String(l.get("opcao_texto", "")))
	var melhor := String(l.get("melhor_texto", ""))
	var resultado := "a vitória do %s" % nos if resumo.get("venceu", false) else ("o empate" if resumo.get("empate", false) else "a esperança até o fim")
	if d in ["desarme", "bloqueio", "afastou", "impedimento"] and not resumo.get("venceu", false) and not resumo.get("empate", false) \
			and not l.get("saiu_jogando", false):
		return _um(rng, ["Mesmo na derrota, %s voltou até a defesa e salvou um gol aos %d'" % [ap, m],
			"Raça não faltou: %s ajudou na marcação aos %d', mas o %s venceu" % [ap, m, adv]])
	if m >= 120:
		return ("Na disputa de pênaltis, %s bateu com categoria e não tremeu" % ap) if d == "gol" else ("%s perde o pênalti na disputa e chora no gramado" % ap)
	match d:
		"gol":
			match a:
				"chute":
					return _um(rng, ["O chute no canto aos %d' foi a melhor decisão da partida" % m,
						"%s escolheu o canto e o goleiro só olhou aos %d'" % [ap, m], "Frio na hora H: %s bateu colocado e decidiu aos %d'" % [ap, m]])
				"chute_forte":
					return _um(rng, ["Bomba! %s encheu o pé aos %d' e quase rasgou a rede" % [ap, m], "Sem pensar duas vezes: a pancada de %s aos %d' fez o estádio tremer" % [ap, m]])
				"cobertura":
					return _um(rng, ["Viu o goleiro adiantado e encobriu: a leitura de %s decidiu" % ap, "Olhou, viu e encobriu! O gol de %s aos %d' é pura inteligência" % [ap, m]])
				"caneta":
					return "A caneta aos %d minutos está rodando o mundo! Que lance!" % m
				"drible", "arrancada":
					return _um(rng, ["O drible aos %d minutos está rodando o mundo! Que lance!" % m, "Zagueiro do %s procura %s até agora: drible e gol aos %d'" % [adv, ap, m]])
				"cabeceio", "cabeceio_chao":
					return _um(rng, ["Testada certeira: %s subiu mais que todo mundo aos %d'" % [ap, m], "De cabeça! %s escolheu o canto no alto e acertou aos %d'" % [ap, m]])
				"bicicleta":
					return "BICICLETA! O gol de %s aos %d' já é candidato a mais bonito do ano" % [ap, m]
				"voleio":
					return "De primeira! O voleio de %s aos %d' vai passar em todos os programas" % [ap, m]
				"falta_curva":
					return "Por cima da barreira, no ângulo: %s cobrou falta como gente grande" % ap
				"falta_forte":
					return "Pancada de falta! %s escolheu a força e o goleiro nem viu" % ap
				"penalti_esq", "penalti_dir":
					return "Frieza: %s leu o goleiro e bateu no canto certo aos %d'" % [ap, m]
				"cavadinha":
					return "Cavadinha! %s tem gelo nas veias" % ap
				"drible_goleiro":
					return "Deixou o goleiro sentado: %s driblou e entrou com bola e tudo" % ap
				"tabela":
					return "Tabela perfeita com %s: assim nasceu o gol de %s aos %d'" % [parceiro, ap, m]
				"domina_chute":
					return "Matou no peito e guardou: categoria de %s aos %d'" % [ap, m]
				"conduzir":
					return "Arrancada e chute: %s resolveu sozinho aos %d'" % [ap, m]
				"olimpico":
					return "GOL OLÍMPICO! %s bateu o escanteio direto pro fundo da rede aos %d'" % [ap, m]
				"paciencia":
					return "Frieza de veterano: %s esperou o goleiro cair e tocou no canto" % ap
				"chute_meio":
					return "DO MEIO DE CAMPO! %s viu o goleiro adiantado e fez um golaço aos %d'" % [ap, m]
				"falta_rapida":
					return "Esperteza: %s cobrou rápido enquanto o goleiro arrumava a barreira" % ap
				"finta_chute":
					return "Fingiu que ia passar e bateu: %s enganou o estádio inteiro aos %d'" % [ap, m]
				"chute_primeira":
					return "De primeira, sem deixar cair: o chute de %s aos %d' foi a decisão perfeita" % [ap, m]
				"giro":
					return "Giro em cima do zagueiro! %s fez o pivô e marcou aos %d'" % [ap, m]
				"roleta":
					return "ROLETA E GOL! O lance de %s aos %d' está rodando o mundo" % [ap, m]
				"chapeu":
					return "Chapéu no zagueiro e voleio: o gol de %s aos %d' é obra de arte" % [ap, m]
				"elastico":
					return "O elástico aos %d minutos está rodando o mundo! Que lance!" % m
				"peixinho":
					return "PEIXINHO! %s se jogou de cabeça e marcou aos %d'" % [ap, m]
				"carrinho_gol":
					return "Na raça: %s se jogou no carrinho e empurrou pro gol aos %d'" % [ap, m]
				"pressionar", "fechar_passe", "bote_ataque", "antecipar_ataque":
					return "Pressão que vira gol: %s roubou na saída de bola e marcou aos %d'" % [ap, m]
			return "%s decide: %s aos %d' foi a escolha certa" % [ap, escolha, m]
		"assistencia":
			match a:
				"lancamento":
					return "Lançamento de 40 metros! %s achou %s nas costas da zaga" % [ap, receptor]
				"calcanhar":
					return "De calcanhar! A assistência de %s para %s é de outro planeta" % [ap, receptor]
				"ajeitar":
					return "Generoso: %s ajeitou de cabeça para %s marcar aos %d'" % [ap, receptor, m]
				"cruzar":
					return _um(rng, ["Cruzamento na medida: %s colocou a bola na cabeça de %s aos %d'" % [ap, receptor, m],
						"Escolheu o cruzamento certo: %s achou %s na área" % [ap, receptor]])
				"corta_luz":
					return "Corta-luz genial! %s deixou passar e %s marcou aos %d'" % [ap, receptor, m]
			if l.get("opcao_descoberta", false) or l.get("descoberta", false):
				return "%s viu o que ninguém viu: passe para o gol de %s aos %d'" % [ap, receptor, m]
			return _um(rng, ["Garçom! %s serviu %s, que só empurrou pro gol" % [ap, receptor], "Altruísmo: em vez de chutar, %s tocou para %s marcar" % [ap, receptor]])
		"desarme":
			match a:
				"carrinho":
					return "O carrinho salvador aos %d' garantiu %s" % [m, resultado]
				"antecipar":
					return "Leitura de zagueiro: %s antecipou o passe e matou o contra-ataque do %s" % [ap, adv]
				"acompanhar":
					return "Fôlego no fim: %s ganhou a corrida do atacante e salvou aos %d'" % [ap, m]
			return _um(rng, ["Atacante que marca: %s roubou a bola na hora certa aos %d'" % [ap, m],
				"Voltou até a defesa! O desarme de %s aos %d' valeu %s" % [ap, m, resultado]])
		"bloqueio":
			return "Se jogou na frente da bola: o bloqueio de %s aos %d' valeu %s" % [ap, m, resultado]
		"afastou":
			if l.get("saiu_jogando", false):
				return "Classe na defesa: %s dominou dentro da área e saiu jogando aos %d'" % [ap, m]
			match a:
				"chutao":
					return "Na raça! O chutão de %s aos %d' aliviou a pressão e segurou %s" % [ap, m, resultado]
				"deixar_goleiro":
					return "Comunicação: o \"deixa!\" de %s evitou a confusão na área aos %d'" % [ap, m]
				"trave_def":
					return "Em cima da linha! %s ficou na trave e salvou %s aos %d'" % [ap, resultado, m]
				"marcar":
					return "Ganhou do grandalhão no alto: %s marcou como zagueiro aos %d'" % [ap, m]
				"puxar_contra":
					return "Leitura de jogo: %s saiu na hora certa e puxou o contra-ataque" % ap
				"proteger":
					return "Malandragem: %s protegeu a bola com o corpo até sair pela linha de fundo" % ap
				"recuar_goleiro":
					return "Sangue frio na área: %s tocou pro goleiro no meio da confusão" % ap
				"recuar":
					return "Recuou na hora certa: %s cortou o lançamento de cabeça aos %d'" % [ap, m]
				"empurrar_lateral":
					return "Sem frescura: %s espirrou a bola pra lateral e matou a jogada" % ap
			return "Atacante na defesa! %s voltou até a área e afastou de cabeça aos %d'" % [ap, m]
		"impedimento":
			return _um(rng, ["Linha perfeita: %s subiu na hora certa e deixou o atacante impedido aos %d'" % [ap, m],
				"Inteligência: o impedimento armado por %s aos %d' valeu %s" % [ap, m, resultado]])
		"falta_tatica":
			return "Cartão consciente: a falta tática de %s aos %d' matou o contra-ataque do %s" % [ap, m, adv]
		"falta_dura":
			if l.get("falta_gol", false):
				return "Cartão e gol: a falta de %s aos %d' virou gol do %s" % [ap, m, adv]
			return "Cartão amarelo: %s parou o contra-ataque na falta aos %d'" % [ap, m]
		"salvou_goleiro":
			return "%s foi superado aos %d', mas o goleiro do %s salvou" % [ap, m, nos]
		"gol_sofrido":
			if melhor != "" and not l.get("foi_melhor", true):
				return "\"%s\" era o caminho: %s escolheu %s e o %s marcou" % [melhor, ap, escolha, adv]
			return "Voltou pra ajudar, mas foi driblado: o %s marcou aos %d'" % [adv, m]
	# erros no ataque: o jornal analisa a decisão
	if l.get("apressado", false):
		return "Travou! %s demorou demais e perdeu o tempo da jogada aos %d'" % [ap, m]
	if a in ["penalti_esq", "penalti_dir", "cavadinha"]:
		if a == "cavadinha" and d == "defesa":
			return "Cavadinha defendida! O lance de %s vira meme na internet" % ap
		return "%s perde pênalti aos %d' e a torcida não perdoa" % [ap, m]
	if melhor != "" and not l.get("foi_melhor", true):
		return _um(rng, ["\"%s\" era a melhor opção, diz comentarista sobre o lance de %s aos %d'" % [melhor, ap, m],
			"Faltou levantar a cabeça: %s escolheu %s quando o certo era %s" % [ap, escolha, _minusc(melhor)]])
	var ignorou := String(l.get("ignorou", ""))
	if ignorou != "":
		return "Viu e não usou: %s descobriu \"%s\" e preferiu %s" % [ap, ignorou, escolha]
	match d:
		"trave":
			return "Na trave! %s fez a escolha certa aos %d', faltou um palmo" % [ap, m]
		"defesa":
			return "Decisão certa, goleiro inspirado: %s parou no paredão do %s aos %d'" % [ap, adv, m]
		"passou_defesa":
			return "Quase! A jogada de %s aos %d' levantou a torcida" % [ap, m]
	return "Escolheu bem, executou mal: %s desperdiçou a chance aos %d'" % [ap, m]


static func _manchete_geral(resumo: Dictionary, p: Dictionary, ap: String, rng: RandomNumberGenerator) -> String:
	var nos := Jogo.nome_clube(p["nos"])
	var adv := Jogo.nome_clube(p["adv"])
	var nota := float(resumo.get("nota", 6.0))
	var placar := "%d x %d" % [int(resumo.get("gols_nos", 0)), int(resumo.get("gols_adv", 0))]
	if resumo.has("marco_fas"):
		return "%s passa de %s fãs nas redes sociais" % [ap, UI.formatar_numero(float(resumo["marco_fas"]))]
	if String(resumo.get("titulo", "")) != "":
		return "CAMPEÃO! %s ergue a taça da %s com o %s" % [ap, resumo["titulo"], nos]
	if resumo.get("heroi_defesa", false) and resumo.get("venceu", false):
		return "Do ataque à defesa: o esforço de %s no fim garantiu o %s %s %s" % [ap, nos, placar, adv]
	var ganho := int(resumo.get("fas_ganho", 0))
	if ganho > 0 and ganho >= int(resumo.get("fas_total", 1)) * 0.12:
		return "+%s fãs: as redes de %s explodiram depois do jogo" % [UI.formatar_numero(ganho), ap]
	if nota >= 8.5:
		return _um(rng, ["Noite de craque: nota %s para %s no %s %s %s" % [_nota(nota), ap, nos, placar, adv], "%s é o nome do jogo: nota %s" % [ap, _nota(nota)]])
	if nota <= 5.0:
		return _um(rng, ["Jogo para esquecer: %s não achou espaço contra o %s" % [ap, adv], "Noite apagada: nota %s para %s" % [_nota(nota), ap]])
	if p.get("rival", false):
		return "No clássico contra o rival, %s fica com nota %s" % [ap, _nota(nota)]
	if ganho < 0:
		return "Torcida cobra %s nas redes: %s seguidores a menos" % [ap, UI.formatar_numero(-ganho)]
	return "%s %s %s: %s termina com nota %s" % [nos, placar, adv, ap, _nota(nota)]


static func _nota(n: float) -> String:
	return ("%.1f" % n).replace(".", ",")
