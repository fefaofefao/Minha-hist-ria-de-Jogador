extends Node
## Bateria de testes automáticos (headless):
##   godot --headless --path jogo res://testes/testes.tscn            (tudo)
##   godot --headless --path jogo res://testes/testes.tscn -- carreira (só carreira)
##   godot --headless --path jogo res://testes/testes.tscn -- lances   (só lances 3D)
## Sai com código 0 se tudo passou, 1 se houve falha.

var falhas := 0
var verificacoes := 0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 12345
	var args := OS.get_cmdline_user_args()
	var tudo := args.is_empty()
	# isola os saves dos testes
	Jogo.perfil = Jogo._perfil_padrao()
	Jogo.carreira = {}
	if tudo or "compilar" in args:
		_testar_compilacao("res://scripts")
	if tudo or "situacoes" in args:
		_testar_situacoes()
	if tudo or "carreira" in args:
		for i in 6:
			_testar_carreira_completa(i)
		_testar_salvamento()
		_testar_compras()
	if tudo or "lances" in args:
		await _testar_lances()
	if tudo or "telas" in args:
		await _testar_telas()
	print("\n==== %d verificações, %d falhas ====" % [verificacoes, falhas])
	Jogo.apagar_carreira()
	get_tree().quit(1 if falhas > 0 else 0)


func checar(cond: bool, msg: String) -> void:
	verificacoes += 1
	if not cond:
		falhas += 1
		push_error("FALHOU: " + msg)
		print("FALHOU: ", msg)


# ---------------------------------------------------------------- compilação

func _testar_compilacao(pasta: String) -> void:
	var dir := DirAccess.open(pasta)
	for f in dir.get_files():
		if f.ends_with(".gd"):
			var scr: GDScript = load(pasta + "/" + f)
			checar(scr != null and scr.can_instantiate(), "compila: %s/%s" % [pasta, f])
	for d in dir.get_directories():
		_testar_compilacao(pasta + "/" + d)


# ---------------------------------------------------------------- situações

func _testar_situacoes() -> void:
	print("== situações")
	checar(Situacoes.TIPOS.size() == 35, "35 tipos de lance (%d)" % Situacoes.TIPOS.size())
	checar(Situacoes.TIPOS_ATAQUE.size() + Situacoes.TIPOS_DEFESA.size() == 35, "ataque + defesa = 35")
	var unicos := {}
	for t in Situacoes.TIPOS:
		unicos[t] = true
	checar(unicos.size() == 35, "tipos sem repetição")
	for pos in Situacoes.PESOS_POSICAO:
		for t in Situacoes.TIPOS_ATAQUE:
			checar(Situacoes.PESOS_POSICAO[pos].has(t), "peso de %s para %s" % [t, pos])
	var desfechos := {}
	for tipo in Situacoes.TIPOS:
		for k in 60:
			var attrs := {}
			for a in Dados.ATRIBUTOS:
				attrs[a] = rng.randf_range(35, 95)
			var r := RandomNumberGenerator.new()
			r.seed = k * 31 + tipo.length()
			var s := Situacoes.gerar(tipo, {"atributos": attrs, "pressao": rng.randf(), "moral": 60.0, "rng": r})
			checar(s["opcoes"].size() >= 2, "%s tem opções" % tipo)
			checar(float(s["tempo"]) >= 4.5 and float(s["tempo"]) <= 10.0, "%s tempo válido" % tipo)
			var tem_prota := false
			for j in s["jogadores"]:
				if j["papel"] == "prota":
					tem_prota = true
			checar(tem_prota, "%s tem protagonista" % tipo)
			for poi in s["pois"]:
				var achou := false
				for op in s["opcoes"]:
					if op["id"] == poi["revela"]:
						achou = true
				checar(achou, "%s: POI %s revela opção existente" % [tipo, poi["id"]])
			for op in s["opcoes"]:
				checar(op["chance"] >= 0.05 and op["chance"] <= 0.92, "%s chance no intervalo" % tipo)
				var res := Situacoes.resolver(s, op, rng.randf() < 0.2, r)
				checar(res.has("desfecho"), "resolver devolve desfecho")
				desfechos[res["desfecho"]] = int(desfechos.get(res["desfecho"], 0)) + 1
	print("   desfechos: ", desfechos)
	for d in ["gol", "assistencia", "defesa", "fora", "trave", "perdeu", "interceptado", "passou_defesa"]:
		checar(desfechos.has(d), "desfecho %s acontece" % d)


# ---------------------------------------------------------------- carreira

func _lances_simulados(p: Dictionary) -> Array:
	var lances: Array = []
	for m in p["momentos"]:
		var ctx := Jogo.contexto_lance(p, m, 0, 0)
		var s := Situacoes.gerar(m["tipo"], ctx)
		var visiveis: Array = []
		for op in s["opcoes"]:
			if not op["oculta"] or rng.randf() < 0.5:
				visiveis.append(op)
		var op: Dictionary = visiveis[rng.randi() % visiveis.size()]
		var res := Situacoes.resolver(s, op, rng.randf() < 0.1, rng)
		res["minuto"] = m["minuto"]
		res["tipo"] = s["tipo"]
		res["parceiro"] = ctx.get("parceiro", "")
		tipos_vistos[s["tipo"]] = int(tipos_vistos.get(s["tipo"], 0)) + 1
		res["comemoracao"] = "galera" if res["desfecho"] == "gol" else ""
		lances.append(res)
	return lances


func _jogar_partida(p: Dictionary) -> Dictionary:
	var lances := _lances_simulados(p)
	var gn := 0
	var ga := 0
	for g in p["gols_bg"]:
		if g["time"] == "nos":
			gn += 1
		else:
			ga += 1
	for l in lances:
		if l["desfecho"] in ["gol", "assistencia"]:
			gn += 1
	var pen = null
	if p.get("mata_mata", false) and gn == ga:
		pen = {"nos": 5, "adv": 4} if rng.randf() < 0.5 else {"nos": 3, "adv": 4}
	var fas_antes := Jogo.fas()
	var r := Jogo.finalizar_partida({"gols_nos": gn, "gols_adv": ga, "lances": lances, "penaltis": pen})
	var mch: Array = r.get("manchetes", [])
	checar(not mch.is_empty(), "há manchetes depois da partida")
	if r["jogou"] and not lances.is_empty():
		checar(mch.size() >= 2, "manchetes falam dos lances")
	for m in mch:
		var t: String = m.get("titulo", "")
		checar(t.length() > 10 and t.find("%") < 0 and t.find("{") < 0, "manchete bem formada: %s" % t)
		checar(String(m.get("veiculo", "")) != "", "manchete tem veículo")
		amostra_manchetes[t] = true
	checar(Jogo.fas() >= 0, "fãs não negativos")
	checar(int(r.get("fas_total", -1)) == Jogo.fas(), "total de fãs no resumo")
	checar(Jogo.fas() - fas_antes == int(r.get("fas_ganho", 0)) or r.has("marco_fas") or Jogo.fas() >= fas_antes, "ganho de fãs consistente")
	return r


func _testar_carreira_completa(indice: int) -> void:
	var pos: String = Dados.POSICOES[indice % 3]
	print("== carreira %d (%s)" % [indice, pos])
	tipos_vistos = {}
	Jogo.nova_carreira({"nome": "Teste %d" % indice, "apelido": "T%d" % indice, "posicao": pos})
	checar(Jogo.carreira["fase"] == "prologo", "começa no prólogo")
	var p := Jogo.preparar_prologo()
	var r := _jogar_partida(p)
	checar(r["nota"] >= 3.0 and r["nota"] <= 10.0, "nota do prólogo no intervalo")
	var ofertas := Jogo.ofertas_prologo(r["nota"])
	checar(ofertas["clubes"].size() >= 1, "ofertas após prólogo")
	Jogo.escolher_clube_base(ofertas["clubes"][0])
	checar(Jogo.carreira["fase"] == "base", "entrou na base")
	var temporadas := 0
	var maior_overall := 0
	var paises := {}
	while Jogo.tem_carreira() and temporadas < 30:
		temporadas += 1
		var objs := Jogo.objetivos_disponiveis()
		Jogo.definir_objetivo(objs[rng.randi() % objs.size()])
		var semanas := 0
		while not Jogo.temporada_acabou() and semanas < 30:
			semanas += 1
			var acoes := Jogo.acoes_disponiveis()
			checar(acoes.size() >= 2, "há ações de agenda")
			acoes.shuffle()
			Jogo.aplicar_agenda(acoes.slice(0, 2))
			var e := Jogo.sortear_evento()
			if not e.is_empty() and rng.randf() < 0.7:
				var validas: Array = []
				for i in e["opcoes"].size():
					if Jogo.opcao_evento_disponivel(e["opcoes"][i]):
						validas.append(i)
				if not validas.is_empty():
					var res := Jogo.resolver_evento(e, validas[rng.randi() % validas.size()])
					checar(res["texto"].find("{") < 0, "texto do evento sem placeholder: %s" % e["id"])
			if semanas == 4:
				_testar_contrato()
			var jogo := Jogo.proximo_jogo()
			var titular := Jogo.situacao_titular()
			if titular in ["fora", "lesionado"]:
				Jogo.simular_sem_jogar()
			else:
				var pp := Jogo.preparar_partida(jogo)
				_jogar_partida(pp)
			_checar_invariantes()
		if semanas >= 30:
			var cal: Array = Jogo.carreira["temp"]["calendario"]
			print("   DEBUG temporada travada: clube=%s cat=%s cal=%d" % [Jogo.carreira["clube"], Jogo.carreira["categoria"], cal.size()])
			for j in cal.slice(maxi(0, cal.size() - 6)):
				print("      ", j)
		checar(semanas < 30, "temporada termina")
		var resumo := Jogo.fim_de_temporada()
		checar(resumo.has("media"), "resumo da temporada")
		Jogo.ganhar_moedas(resumo["moedas"], "teste")
		maior_overall = maxi(maior_overall, Jogo.overall())
		if Jogo.deve_aposentar() or (Jogo.pode_aposentar() and rng.randf() < 0.25):
			var l := Jogo.aposentar()
			checar(l["pontos"] >= 0, "legado calculado")
			break
		var saindo: bool = Jogo.carreira["contrato"].get("pedido_saida", "") != ""
		var clube_antes: String = Jogo.carreira["clube"]
		var ofs := Jogo.ofertas_temporada()
		if saindo:
			for o in ofs:
				checar(o["clube"] != clube_antes, "quem pediu para sair não recebe renovação")
		checar(ofs.size() >= 1, "há ofertas na temporada %d (idade %d)" % [temporadas, Jogo.carreira["jogador"]["idade"]])
		var o: Dictionary = ofs[rng.randi() % ofs.size()]
		Jogo.aceitar_oferta(o)
		paises[Jogo.clube(Jogo.carreira["clube"])["pais"]] = true
		if Jogo.carreira["temp"]["calendario"].size() < 7:
			print("   DEBUG calendário curto: clube=%s pais=%s n=%d" % [Jogo.carreira["clube"], Jogo.clube(Jogo.carreira["clube"])["pais"], Jogo.carreira["temp"]["calendario"].size()])
		checar(Jogo.carreira["temp"]["calendario"].size() >= 7, "calendário montado")
	var c := Jogo.carreira
	print("   contrato: ", contagem_contrato)
	print("   tipos de lance: ", tipos_vistos)
	print("   fãs no fim: %d | manchetes diferentes até aqui: %d" % [Jogo.fas(), amostra_manchetes.size()])
	if indice == 0:
		var ks := amostra_manchetes.keys()
		ks.shuffle()
		for k in ks.slice(0, 30):
			print("      > ", k)
	checar(tipos_vistos.size() >= 33, "carreira tem lances variados (%d tipos)" % tipos_vistos.size())
	checar(Jogo.fas() >= 1000, "fãs crescem ao longo da carreira (%d)" % Jogo.fas())
	checar(amostra_manchetes.size() >= 40, "manchetes variadas (%d)" % amostra_manchetes.size())
	print("   idade final %d | overall máx %d | jogos %d | gols %d | títulos %d | sonhos %d | memórias %d | países %s | moedas %d" % [
		c["jogador"]["idade"], maior_overall, c["estat"]["jogos"], c["estat"]["gols"], c["estat"]["titulos"],
		c["sonhos"].size(), c["memorias"].size(), paises.keys(), Jogo.moedas()])
	checar(c["fase"] == "aposentado", "carreira termina em aposentadoria")
	checar(maior_overall >= 70, "jogador evolui (overall máx %d)" % maior_overall)
	checar(int(c["estat"]["jogos"]) > 50, "joga muitas partidas")
	var h := Jogo.heranca()
	checar(h["geracao"] == 2, "herança para a 2ª geração")
	Jogo.nova_carreira({"nome": "Filho", "apelido": "Jr", "posicao": pos, "herdado": h, "geracao": h["geracao"]})
	checar(Jogo.carreira["geracao"] == 2, "nova geração criada")


var contagem_contrato := {}
var tipos_vistos := {}
var amostra_manchetes := {}


func _testar_contrato() -> void:
	var antes := float(Jogo.carreira["contrato"].get("salario", 0.0))
	var x := rng.randf()
	if x < 0.45 and Jogo.motivo_sem_negociacao() == "":
		var pct: float = [0.1, 0.25, 0.5][rng.randi() % 3]
		var ch := Jogo.chance_renegociar(pct)
		checar(ch >= 0.05 and ch <= 0.92, "chance de renegociar no intervalo")
		var r := Jogo.renegociar(pct)
		contagem_contrato[r["resultado"]] = int(contagem_contrato.get(r["resultado"], 0)) + 1
		if r["resultado"] == "contraproposta":
			Jogo.responder_contraproposta(rng.randf() < 0.6, r["contraproposta"])
		checar(float(Jogo.carreira["contrato"]["salario"]) >= antes, "salário não diminui ao negociar")
		checar(Jogo.motivo_sem_negociacao() != "", "só uma negociação por temporada")
	elif x < 0.6 and Jogo.carreira["contrato"].get("pedido_saida", "") == "":
		var motivos := Jogo.MOTIVOS_SAIDA.keys()
		var r := Jogo.pedir_saida(motivos[rng.randi() % motivos.size()])
		contagem_contrato["saida_aceita" if r["aceito"] else "saida_recusada"] = int(contagem_contrato.get("saida_aceita" if r["aceito"] else "saida_recusada", 0)) + 1
		if not r["aceito"] and rng.randf() < 0.4:
			Jogo.forcar_saida()
			contagem_contrato["forcada"] = int(contagem_contrato.get("forcada", 0)) + 1
			checar(Jogo.situacao_titular() in ["reserva", "lesionado"], "afastado após forçar saída")
		elif r["aceito"] and rng.randf() < 0.2:
			Jogo.cancelar_saida()
			checar(Jogo.carreira["contrato"]["pedido_saida"] == "", "cancelar saída")
	checar(Jogo.valor_mercado() > 0, "valor de mercado positivo")


func _checar_invariantes() -> void:
	var c := Jogo.carreira
	for a in c["atributos"]:
		var v := float(c["atributos"][a])
		checar(v >= 25.0 and v <= 99.0, "atributo %s no intervalo (%f)" % [a, v])
	for k in ["energia", "moral", "fama"]:
		var v := float(c["status"][k])
		checar(v >= 0.0 and v <= 100.0, "status %s no intervalo" % k)
	for k in c["rel"]:
		checar(float(c["rel"][k]) >= 0.0 and float(c["rel"][k]) <= 100.0, "relação %s no intervalo" % k)


func _testar_salvamento() -> void:
	print("== salvamento")
	Jogo.nova_carreira({"nome": "Save", "apelido": "Salvo", "posicao": "Meia"})
	Jogo.preparar_prologo()
	Jogo.finalizar_partida({"gols_nos": 1, "gols_adv": 1, "lances": [], "penaltis": {"nos": 5, "adv": 4}})
	Jogo.escolher_clube_base("cerrado")
	var p := Jogo.preparar_partida(Jogo.proximo_jogo())
	_jogar_partida(p)
	Jogo.salvar_carreira()
	var antes := JSON.stringify(Jogo._codificar(Jogo.carreira))
	Jogo.carreira = {}
	Jogo.carregar_carreira()
	checar(not Jogo.carreira.is_empty(), "carreira recarregada")
	checar(Jogo.carreira["clube"] == "cerrado", "clube preservado")
	checar(int(Jogo.carreira["semana"]) == 2, "semana preservada")
	# continua jogando depois de recarregar (tipos vindos do JSON)
	var p2 := Jogo.preparar_partida(Jogo.proximo_jogo())
	var r := _jogar_partida(p2)
	checar(r.has("nota"), "joga após recarregar")
	checar(antes.length() > 100, "save tem conteúdo")
	Jogo.salvar_perfil()
	Jogo.perfil = {}
	Jogo.carregar_perfil()
	checar(Jogo.perfil.has("moedas"), "perfil recarregado")


func _testar_compras() -> void:
	print("== compras")
	Jogo.perfil = Jogo._perfil_padrao()
	var m0 := Jogo.moedas()
	Jogo.entregar_produto("moedas_500")
	checar(Jogo.moedas() == m0 + 500, "moedas entregues")
	Jogo.entregar_produto("craque_vip")
	checar(Jogo.vip() and Jogo.tem_compra("remover_anuncios"), "VIP remove anúncios")
	checar(Jogo.tem_cosmetico("chuteiras", "dourada"), "VIP dá chuteira dourada")
	Jogo.entregar_produto("pacote_iniciante")
	checar(int(Jogo.perfil["fichas"]) == 5, "pacote dá fichas")
	checar(Anuncios.sem_anuncios(), "sem anúncios após compra")
	checar(not Jogo.comprar_cosmetico("comemoracoes", "danca", 999999), "não compra sem moedas")
	checar(Jogo.comprar_cosmetico("comemoracoes", "danca", 300), "compra cosmético")


# ---------------------------------------------------------------- lances 3D (headless)

func _testar_lances() -> void:
	print("== lances 3D")
	Jogo.nova_carreira({"nome": "Lance", "apelido": "L", "posicao": "Atacante"})
	var p := Jogo.preparar_prologo()
	Engine.time_scale = 10.0
	var cena: PackedScene = load("res://cenas/lance.tscn")
	var contagem := {}
	for tipo in Situacoes.TIPOS:
		for k in 5:
			var ctx := Jogo.contexto_lance(p, {"minuto": 80, "tipo": tipo}, 1, 1)
			ctx["auto"] = true
			ctx["escala_tempo"] = 10.0
			ctx["segunda_chance"] = "ficha" if k % 2 == 0 else ""
			if k == 4:
				ctx["auto_timeout"] = true
			var s := Situacoes.gerar(tipo, ctx)
			var l: Lance = cena.instantiate()
			add_child(l)
			var inicio := Time.get_ticks_msec()
			l.iniciar(s)
			var res = await _esperar_lance(l, 40000)
			checar(res is Dictionary, "lance %s terminou" % tipo)
			if res is Dictionary:
				contagem[tipo + ":" + res["desfecho"]] = int(contagem.get(tipo + ":" + res["desfecho"], 0)) + 1
			l.queue_free()
			await get_tree().process_frame
			checar(Time.get_ticks_msec() - inicio < 40000, "lance %s em tempo razoável" % tipo)
	Engine.time_scale = 1.0
	print("   ", contagem)


func _esperar_lance(l: Lance, limite_ms: int):
	var res := [null]
	l.terminou.connect(func(r: Dictionary) -> void: res[0] = r)
	var t0 := Time.get_ticks_msec()
	while res[0] == null and Time.get_ticks_msec() - t0 < limite_ms:
		await get_tree().process_frame
	return res[0]


# ---------------------------------------------------------------- telas

func _testar_telas() -> void:
	print("== telas")
	var telas := ["res://cenas/menu.tscn", "res://cenas/criacao.tscn", "res://cenas/hub.tscn", "res://cenas/loja.tscn",
		"res://cenas/config.tscn", "res://cenas/album.tscn", "res://cenas/carreira.tscn", "res://cenas/vida.tscn",
		"res://cenas/desafio.tscn", "res://cenas/legado.tscn", "res://cenas/olheiros.tscn"]
	Jogo.nova_carreira({"nome": "Tela", "apelido": "Telinha", "posicao": "Ponta"})
	Jogo.preparar_prologo()
	Jogo.finalizar_partida({"gols_nos": 2, "gols_adv": 1, "lances": [], "penaltis": null})
	Jogo.escolher_clube_base("imperial")
	for t in telas:
		if not ResourceLoader.exists(t):
			checar(false, "tela existe: " + t)
			continue
		var cena: PackedScene = load(t)
		var n := cena.instantiate()
		add_child(n)
		for i in 5:
			await get_tree().process_frame
		checar(is_instance_valid(n), "tela abre: " + t)
		n.queue_free()
		await get_tree().process_frame
