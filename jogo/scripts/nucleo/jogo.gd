extends Node
## Autoload "Jogo": estado da carreira e do perfil, regras e simulação.
## Toda a lógica fica aqui (sem UI), para poder ser testada sem tela.
##
## perfil   -> dados permanentes do aparelho (moedas, compras, cosméticos, hall da fama)
## carreira -> a carreira em andamento (jogador, clube, temporada, vida)

signal moedas_mudaram(valor: int)

const ARQ_PERFIL := "user://perfil.json"
const ARQ_CARREIRA := "user://carreira.json"
const VERSAO := 1
const CATEGORIAS := ["Sub-15", "Sub-17", "Sub-20", "Profissional"]
const FATOR_CATEGORIA := {"Sub-15": 0.68, "Sub-17": 0.74, "Sub-20": 0.8, "Profissional": 1.0}

var perfil := {}
var carreira := {}
var rng := RandomNumberGenerator.new()
var partida_atual := {}  # partida preparada para a cena de jogo
var ultimo_relatorio := {}  # relatório da última partida jogada


func _ready() -> void:
	rng.randomize()
	carregar_perfil()
	carregar_carreira()
	perfil["contadores"]["sessoes"] = int(perfil["contadores"].get("sessoes", 0)) + 1
	salvar_perfil()


# ================================================================ persistência

func _perfil_padrao() -> Dictionary:
	return {
		"versao": VERSAO, "moedas": 120, "fichas": 0, "compras": {},
		"cosmeticos": {"chuteiras": ["preta", "branca"], "comemoracoes": ["galera", "aviao", "coracao"], "cores_cabelo": [0, 1, 2, 3, 4]},
		"config": {"som": 1.0, "musica": 0.7, "vibracao": true, "sensibilidade": 1.0},
		"contadores": {"partidas_total": 0, "partidas_desde_intersticial": 0, "recompensados": 0, "sessoes": 0},
		"desafio": {"ultimo": "", "sequencia": 0, "extra_usado": ""},
		"patrocinio": {"dia": "", "vezes": 0},
		"hall": [], "legado_bonus": 0, "oferta_iniciante_ate": 0, "geracao": 1,
	}


func carregar_perfil() -> void:
	perfil = _perfil_padrao()
	var d = _ler_json(ARQ_PERFIL)
	if d is Dictionary:
		for k in d:
			perfil[k] = d[k]
		# garante chaves novas em perfis antigos
		var p := _perfil_padrao()
		for k in p:
			if not perfil.has(k):
				perfil[k] = p[k]
		for k in p["config"]:
			if not perfil["config"].has(k):
				perfil["config"][k] = p["config"][k]


func salvar_perfil() -> void:
	_gravar_json(ARQ_PERFIL, perfil)


func carregar_carreira() -> void:
	carreira = {}
	var d = _ler_json(ARQ_CARREIRA)
	if d is Dictionary and d.get("versao", 0) == VERSAO:
		carreira = d


func salvar_carreira() -> void:
	if carreira.is_empty():
		return
	_gravar_json(ARQ_CARREIRA, carreira)


func tem_carreira() -> bool:
	return not carreira.is_empty() and carreira.get("fase", "") != "aposentado"


func apagar_carreira() -> void:
	carreira = {}
	if FileAccess.file_exists(ARQ_CARREIRA):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARQ_CARREIRA))


func _ler_json(caminho: String):
	for c in [caminho, caminho + ".bak"]:
		if not FileAccess.file_exists(c):
			continue
		var f := FileAccess.open(c, FileAccess.READ)
		if f == null:
			continue
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			return _decodificar(d)
	return null


func _gravar_json(caminho: String, dados: Dictionary) -> void:
	var texto := JSON.stringify(_codificar(dados))
	var tmp := caminho + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		Analytics.erro("Falha ao salvar " + caminho)
		return
	f.store_string(texto)
	f.close()
	var abs := ProjectSettings.globalize_path(caminho)
	if FileAccess.file_exists(caminho):
		DirAccess.copy_absolute(abs, abs + ".bak")
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), abs)


## Converte Color para texto antes de salvar (JSON não tem Color).
func _codificar(v):
	if v is Dictionary:
		var r := {}
		for k in v:
			r[k] = _codificar(v[k])
		return r
	if v is Array:
		var a := []
		for x in v:
			a.append(_codificar(x))
		return a
	if v is Color:
		return "#" + v.to_html(false)
	return v


func _decodificar(v):
	# números inteiros voltam como float do JSON; tratamos nos usos com int().
	return v


# ================================================================ perfil: moedas, compras, cosméticos

func moedas() -> int:
	return int(perfil.get("moedas", 0))


func ganhar_moedas(qtd: int, origem := "") -> void:
	perfil["moedas"] = moedas() + qtd
	salvar_perfil()
	moedas_mudaram.emit(moedas())
	Analytics.evento("moedas_ganhas", {"qtd": qtd, "origem": origem})


func gastar_moedas(qtd: int, motivo := "") -> bool:
	if moedas() < qtd:
		return false
	perfil["moedas"] = moedas() - qtd
	salvar_perfil()
	moedas_mudaram.emit(moedas())
	Analytics.evento("moedas_gastas", {"qtd": qtd, "motivo": motivo})
	return true


func tem_compra(id: String) -> bool:
	return bool(perfil.get("compras", {}).get(id, false))


func vip() -> bool:
	return tem_compra("craque_vip")


func entregar_produto(id: String) -> void:
	var p: Dictionary = Compras.PRODUTOS.get(id, {})
	if p.get("consumivel", false):
		ganhar_moedas(int(p.get("moedas", 0)), "compra_" + id)
		return
	perfil["compras"][id] = true
	match id:
		"craque_vip":
			_desbloquear("chuteiras", "dourada")
			perfil["compras"]["remover_anuncios"] = true
		"pacote_iniciante":
			perfil["moedas"] = moedas() + 1000
			perfil["fichas"] = int(perfil.get("fichas", 0)) + 5
			_desbloquear("chuteiras", "relampago")
			perfil["oferta_iniciante_ate"] = 0
	salvar_perfil()
	moedas_mudaram.emit(moedas())


func _desbloquear(tipo: String, id) -> void:
	var lista: Array = perfil["cosmeticos"][tipo]
	if not (id in lista):
		lista.append(id)


func tem_cosmetico(tipo: String, id) -> bool:
	return id in perfil["cosmeticos"].get(tipo, [])


func comprar_cosmetico(tipo: String, id: String, preco: int) -> bool:
	if tem_cosmetico(tipo, id):
		return true
	if not gastar_moedas(preco, tipo + "_" + id):
		return false
	_desbloquear(tipo, id)
	salvar_perfil()
	return true


func oferta_iniciante_ativa() -> bool:
	return not tem_compra("pacote_iniciante") and int(perfil.get("oferta_iniciante_ate", 0)) > int(Time.get_unix_time_from_system())


# ================================================================ atributos

func atributo(nome: String) -> float:
	return float(carreira["atributos"].get(nome, 50.0))


func overall(c := {}) -> int:
	var car: Dictionary = carreira if c.is_empty() else c
	var pesos: Dictionary = Dados.PESOS_OVERALL[car["jogador"]["posicao"]]
	var soma := 0.0
	for a in pesos:
		soma += float(car["atributos"][a]) * pesos[a]
	return int(round(soma))


func fator_idade(idade: int) -> float:
	if idade <= 18:
		return 1.2
	if idade <= 21:
		return 1.0
	if idade <= 24:
		return 0.75
	if idade <= 27:
		return 0.5
	if idade <= 30:
		return 0.3
	return 0.12


## Aplica XP; retorna ganhos {atributo: delta} (só os relevantes).
func dar_xp(xp: Dictionary) -> Dictionary:
	var ganhos := {}
	var idade := int(carreira["jogador"]["idade"])
	var pot := float(carreira["jogador"]["potencial"])
	for a in xp:
		if not carreira["atributos"].has(a):
			continue
		var atual := float(carreira["atributos"][a])
		var margem := clampf((pot - atual) / 25.0, 0.06, 1.0)
		var ganho := float(xp[a]) * 0.42 * fator_idade(idade) * margem
		carreira["atributos"][a] = minf(atual + ganho, 99.0)
		ganhos[a] = ganho
	return ganhos


func forma() -> float:
	var n: Array = carreira.get("ultimas_notas", [])
	if n.is_empty():
		return 6.5
	var s := 0.0
	for x in n:
		s += float(x)
	return s / n.size()


func _mudar(chave: String, delta: float, minimo := 0.0, maximo := 100.0) -> void:
	var partes := chave.split(".")
	var alvo: Dictionary = carreira[partes[0]]
	alvo[partes[1]] = clampf(float(alvo.get(partes[1], 50.0)) + delta, minimo, maximo)


func aplicar_efeitos(ef: Dictionary) -> Array:
	## Retorna lista de textos curtos ("+8 Moral") para mostrar ao jogador.
	var txt: Array = []
	for k in ef:
		var v = ef[k]
		match k:
			"energia":
				_mudar("status.energia", v)
				txt.append(_fmt(v, "Energia"))
			"moral":
				_mudar("status.moral", v)
				txt.append(_fmt(v, "Confiança"))
			"fama":
				_mudar("status.fama", v)
				txt.append(_fmt(v, "Fama"))
			"dinheiro":
				carreira["dinheiro"] = float(carreira["dinheiro"]) + float(v)
				txt.append(("+" if v >= 0 else "") + UI.formatar_dinheiro(v))
			"moedas":
				ganhar_moedas(int(v), "evento")
				txt.append("+%d moedas" % int(v))
			"lesao":
				carreira["status"]["lesao"] = int(carreira["status"].get("lesao", 0)) + int(v)
				txt.append("Lesão: %d semanas" % int(v))
			"flag":
				carreira["flags"][v] = true
			"remove_flag":
				carreira["flags"].erase(v)
			"sonho":
				concluir_sonho(v)
				txt.append("Sonho realizado!")
			_:
				if k.begins_with("rel_"):
					var r: String = k.substr(4)
					_mudar("rel." + r, v)
					txt.append(_fmt(v, {"familia": "Família", "tecnico": "Técnico", "torcida": "Torcida", "amigo": carreira["amigo"]}.get(r, r)))
				elif k.begins_with("xp_"):
					var a: String = k.substr(3)
					dar_xp({a: v})
					txt.append("+%s" % Dados.NOMES_ATRIBUTOS.get(a, a))
	return txt


func _fmt(v: float, nome: String) -> String:
	return "%s%d %s" % ["+" if v >= 0 else "", int(round(v)), nome]


func texto(t: String) -> String:
	if carreira.is_empty():
		return t
	return t.format({
		"apelido": carreira["jogador"]["apelido"], "nome": carreira["jogador"]["nome"],
		"amigo": carreira.get("amigo", "Juninho"), "rival": carreira["rival"]["nome"],
		"clube": nome_clube(carreira.get("clube", "")), "mae": carreira.get("mae", "Dona Cida"),
		"tecnico": carreira.get("tecnico", "Professor Galvão"), "empresario": carreira.get("empresario", "Marcão"),
		"patrocinador": carreira.get("patrocinador", "Tênis Pulso"),
	})


# ================================================================ clubes

func clube(id: String) -> Dictionary:
	if Dados.CLUBES.has(id):
		return Dados.CLUBES[id]
	if id == "vila":
		return {"nome": Dados.VILA["nome"], "sigla": "VIL", "pais": "br", "tier": 1, "forca": 50, "cor": Dados.VILA["cor"], "calcao": Dados.VILA["calcao"]}
	if id == "jardim":
		return {"nome": Dados.JARDIM["nome"], "sigla": "JAR", "pais": "br", "tier": 1, "forca": 50, "cor": Dados.JARDIM["cor"], "calcao": Dados.JARDIM["calcao"]}
	if id == "selecao":
		return {"nome": "Seleção", "sigla": "BRA", "pais": "br", "tier": 5, "forca": 88, "cor": Color("ffd400"), "calcao": Color("1d3fa8")}
	var t: Dictionary = carreira.get("temp", {}).get("times", {})
	if t.has(id):
		var d: Dictionary = t[id]
		return {"nome": d["nome"], "sigla": d["sigla"], "pais": d.get("pais", "br"), "tier": int(d.get("tier", 2)),
			"forca": float(d["forca"]), "cor": Color(d["cor"]), "calcao": Color(d["calcao"])}
	return {"nome": id, "sigla": id.left(3).to_upper(), "pais": "br", "tier": 1, "forca": 55, "cor": Color.GRAY, "calcao": Color.WHITE}


func nome_clube(id: String) -> String:
	return clube(id).get("nome", id) if id != "" else ""


func forca_time(id: String) -> float:
	var c := clube(id)
	var f := float(c["forca"])
	if id.begins_with("gen_") or id == "selecao" or id.begins_with("nac_"):
		return f
	return f * FATOR_CATEGORIA.get(carreira.get("categoria", "Profissional"), 1.0)


# ================================================================ nova carreira e prólogo

func nova_carreira(d: Dictionary) -> void:
	var pos: String = d.get("posicao", "Atacante")
	var attrs := {}
	for a in Dados.ATRIBUTOS:
		attrs[a] = 42.0 + rng.randf_range(-3.0, 4.0)
	for a in Dados.BONUS_POSICAO[pos]:
		attrs[a] += Dados.BONUS_POSICAO[pos][a]
	var herdado: Dictionary = d.get("herdado", {})
	for a in herdado.get("atributos", {}):
		attrs[a] = float(attrs[a]) + float(herdado["atributos"][a])
	var geracao := int(d.get("geracao", 1))
	carreira = {
		"versao": VERSAO, "geracao": geracao,
		"jogador": {"nome": d.get("nome", "Jogador"), "apelido": d.get("apelido", "Craque"), "posicao": pos,
			"pele": int(d.get("pele", 2)), "cabelo": int(d.get("cabelo", 1)), "cor_cabelo": int(d.get("cor_cabelo", 0)),
			"chuteira": d.get("chuteira", "preta"), "numero": int(d.get("numero", 10)), "idade": 15,
			"potencial": clampf(rng.randf_range(80.0, 92.0) + float(herdado.get("potencial", 0.0)), 70.0, 99.0)},
		"atributos": attrs,
		"status": {"energia": 90.0, "moral": 65.0, "fama": float(herdado.get("fama", 0.0)), "lesao": 0},
		"rel": {"familia": 70.0, "tecnico": 50.0, "torcida": 50.0, "amigo": 75.0},
		"dinheiro": float(herdado.get("dinheiro", 0.0)),
		"fase": "prologo", "categoria": "Sub-15", "clube": "vila", "contrato": {},
		"temporada": 0, "ano": 2026, "semana": 0, "temp": {},
		"historico": [], "titulos": [], "memorias": {}, "sonhos": {}, "flags": {}, "eventos_vistos": [],
		"rival": {"nome": Dados.NOMES_RIVAL[rng.randi() % Dados.NOMES_RIVAL.size()], "clube": "jardim", "overall": 52.0, "gols": 0, "titulos": 0},
		"amigo": "Juninho", "mae": "Dona Cida",
		"tecnico": Dados.NOMES_TECNICO[rng.randi() % Dados.NOMES_TECNICO.size()],
		"empresario": "Marcão", "patrocinador": Dados.PATROCINADORES[rng.randi() % Dados.PATROCINADORES.size()],
		"estat": {"jogos": 0, "gols": 0, "assist": 0, "titulos": 0, "selecao_jogos": 0, "selecao_gols": 0, "bolas_cristal": 0, "notas_soma": 0.0},
		"ultimas_notas": [], "sem_gols": 0, "noticias": [], "semana_info": {},
		"pai": herdado.get("pai", ""),
	}
	salvar_carreira()
	Analytics.evento("tutorial_inicio", {"posicao": pos, "geracao": geracao})


func visual_jogador() -> Dictionary:
	var j: Dictionary = carreira["jogador"]
	var ch: String = j.get("chuteira", "preta")
	return {"pele": int(j["pele"]), "cabelo": int(j["cabelo"]), "cor_cabelo": int(j["cor_cabelo"]),
		"chuteira": Color(Dados.CHUTEIRAS.get(ch, Dados.CHUTEIRAS["preta"])["cor"])}


func preparar_prologo() -> Dictionary:
	partida_atual = {
		"tipo": "prologo", "nos": "vila", "adv": "jardim", "casa": true, "cenario": "varzea", "noite": false,
		"titular": "titular", "importancia": 1.0, "competicao": "Final da Copa da Vila",
		"momentos": [
			{"minuto": 31, "tipo": "chance_area", "tutorial": true},
			{"minuto": 63, "tipo": "mano_a_mano"},
			{"minuto": 88, "tipo": "cruzamento"},
		],
		"gols_bg": [{"minuto": 22, "time": "eles", "autor": carreira["rival"]["nome"]}],
		"mata_mata": true,
	}
	return partida_atual


## Depois do prólogo: ofertas dos olheiros conforme a nota.
func ofertas_prologo(nota: float) -> Dictionary:
	var grandes := ["atl_metropolitano", "imperial", "litoral", "porto_sul", "uniao_serrana"]
	var medios := ["leoes_agreste", "operario_leste", "cerrado", "ferroviario"]
	grandes.shuffle()
	medios.shuffle()
	if nota >= 7.6:
		return {"nivel": "grande", "clubes": [grandes[0], grandes[1]]}
	if nota >= 6.3:
		return {"nivel": "medio", "clubes": [medios[0], medios[1]]}
	return {"nivel": "peneira", "clubes": [medios[0]], "plano_b": ["tupa", "estrela_vale", "vila_operaria"][rng.randi() % 3]}


func escolher_clube_base(id: String) -> void:
	carreira["clube"] = id
	carreira["fase"] = "base"
	carreira["categoria"] = "Sub-15"
	carreira["contrato"] = {"salario": 600.0 + clube(id)["tier"] * 250.0, "papel": "Base", "ate": 3}
	# o rival vai para um clube grande diferente
	var opcoes := ["atl_metropolitano", "imperial", "litoral", "porto_sul"]
	opcoes.erase(id)
	carreira["rival"]["clube"] = opcoes[rng.randi() % opcoes.size()]
	carreira["noticias"] = [texto("{rival} assinou com o %s. A rivalidade continua." % nome_clube(carreira["rival"]["clube"]))]
	nova_temporada()
	perfil["oferta_iniciante_ate"] = int(Time.get_unix_time_from_system()) + int(Analytics.remoto("oferta_iniciante_horas")) * 3600
	salvar_perfil()
	Analytics.evento("tutorial_fim", {"clube": id})
	Analytics.evento("clube_escolhido", {"clube": id, "tier": clube(id)["tier"]})


# ================================================================ temporada

func categoria_por_idade(idade: int) -> String:
	if idade <= 15:
		return "Sub-15"
	if idade <= 17:
		return "Sub-17"
	return "Sub-20"


func nova_temporada() -> void:
	carreira["temporada"] = int(carreira["temporada"]) + 1
	carreira["semana"] = 1
	var meu: String = carreira["clube"]
	var pais: String = clube(meu)["pais"]
	var times := {}
	var ids: Array = []
	if pais == "br":
		var candidatos: Array = []
		for id in Dados.CLUBES:
			if Dados.CLUBES[id]["pais"] == "br":
				candidatos.append(id)
		candidatos.erase(meu)
		candidatos.shuffle()
		var n := 7 if carreira["categoria"] != "Profissional" else 9
		# garante o clube do rival na liga, para o clássico pessoal
		var rc: String = carreira["rival"]["clube"]
		if rc in candidatos:
			candidatos.erase(rc)
			candidatos.insert(0, rc)
		ids = candidatos.slice(0, n)
	else:
		for id in Dados.CLUBES:
			if Dados.CLUBES[id]["pais"] == pais and id != meu:
				ids.append(id)
		var nomes: Array = Dados.ENCHIMENTO.get(pais, []).duplicate()
		nomes.shuffle()
		var k := 0
		while ids.size() < 7 and k < nomes.size():
			var gid := "gen_%s_%d" % [pais, k]
			var cor := Color.from_hsv(rng.randf(), rng.randf_range(0.5, 0.9), rng.randf_range(0.5, 0.95))
			times[gid] = {"nome": nomes[k], "sigla": nomes[k].replace(" ", "").left(3).to_upper(), "pais": pais, "tier": 3,
				"forca": rng.randf_range(70.0, 79.0), "cor": "#" + cor.to_html(false), "calcao": "#ffffff"}
			ids.append(gid)
			k += 1
	ids.append(meu)
	var tabela := {}
	for id in ids:
		tabela[id] = {"j": 0, "v": 0, "e": 0, "d": 0, "gp": 0, "gc": 0, "pts": 0}
	# turno único: cada rodada, um adversário diferente
	var adversarios: Array = ids.duplicate()
	adversarios.erase(meu)
	adversarios.shuffle()
	var calendario: Array = []
	for i in adversarios.size():
		calendario.append({"semana": i + 1, "adv": adversarios[i], "casa": i % 2 == 0, "tipo": "liga", "jogado": false})
	var liga: String = "Copa Estadual %s" % carreira["categoria"] if carreira["categoria"] != "Profissional" else Dados.PAISES[pais]["liga"]
	carreira["temp"] = {"liga": liga, "times": times, "tabela": tabela, "calendario": calendario,
		"attrs_inicio": carreira["atributos"].duplicate(),
		"gols": 0, "assist": 0, "jogos": 0, "notas": [], "objetivo": {}, "rodadas": adversarios.size(),
		"campeao": "", "artilheiro": false, "selecao": [], "fim": false}
	carreira["semana_info"] = {}
	salvar_carreira()


func objetivos_disponiveis() -> Array:
	var pos: String = carreira["jogador"]["posicao"]
	var rodadas := int(carreira["temp"]["rodadas"])
	var gols_alvo := int(round(rodadas * (0.7 if pos == "Atacante" else 0.45)))
	var assist_alvo := int(round(rodadas * (0.6 if pos == "Meia" else 0.35)))
	return [
		{"id": "gols", "texto": "Artilheiro: marcar %d gols" % gols_alvo, "alvo": gols_alvo, "moedas": 40, "icone": "bola"},
		{"id": "assist", "texto": "Garçom: dar %d assistências" % assist_alvo, "alvo": assist_alvo, "moedas": 40, "icone": "troca"},
		{"id": "media", "texto": "Constância: média acima de 7,0", "alvo": 7.0, "moedas": 50, "icone": "grafico"},
		{"id": "titulo", "texto": "Ser campeão", "alvo": 1, "moedas": 70, "icone": "trofeu"},
	]


func definir_objetivo(o: Dictionary) -> void:
	carreira["temp"]["objetivo"] = o.duplicate()
	salvar_carreira()


func proximo_jogo() -> Dictionary:
	for j in carreira["temp"]["calendario"]:
		if not j["jogado"]:
			return j
	return {}


func classificacao() -> Array:
	var tab: Dictionary = carreira["temp"]["tabela"]
	var ids := tab.keys()
	ids.sort_custom(func(a, b) -> bool:
		var ta: Dictionary = tab[a]
		var tb: Dictionary = tab[b]
		if int(ta["pts"]) != int(tb["pts"]):
			return int(ta["pts"]) > int(tb["pts"])
		var sa := int(ta["gp"]) - int(ta["gc"])
		var sb := int(tb["gp"]) - int(tb["gc"])
		if sa != sb:
			return sa > sb
		return int(ta["gp"]) > int(tb["gp"]))
	return ids


func posicao_tabela() -> int:
	return classificacao().find(carreira["clube"]) + 1


# ================================================================ semana: agenda e eventos

func acoes_disponiveis() -> Array:
	var r: Array = []
	var fase: String = carreira["fase"]
	var lesionado := int(carreira["status"]["lesao"]) > 0
	for id in Dados.AGENDA:
		var a: Dictionary = Dados.AGENDA[id]
		if a.has("fase") and a["fase"] != fase:
			continue
		if a.get("so_lesionado", false) and not lesionado:
			continue
		if lesionado and id.begins_with("treino"):
			continue
		r.append(id)
	return r


func aplicar_agenda(acoes: Array) -> Array:
	var txt: Array = []
	for id in acoes:
		var a: Dictionary = Dados.AGENDA[id]
		if a.has("custo"):
			if float(carreira["dinheiro"]) < float(a["custo"]):
				continue
			carreira["dinheiro"] = float(carreira["dinheiro"]) - float(a["custo"])
		var ef := {}
		for k in ["energia", "moral", "fama", "dinheiro"]:
			if a.has(k):
				ef[k] = a[k]
		for r in a.get("rel", {}):
			ef["rel_" + r] = a["rel"][r]
		txt.append_array(aplicar_efeitos(ef))
		var ganhos := dar_xp(a.get("xp", {}))
		for g in ganhos:
			if ganhos[g] > 0.05:
				txt.append("+%.1f %s" % [ganhos[g], Dados.NOMES_ATRIBUTOS[g]])
		if a.has("cura"):
			carreira["status"]["lesao"] = maxi(0, int(carreira["status"]["lesao"]) - int(a["cura"]))
		if id == "redes" and rng.randf() < 0.12:
			_mudar("status.moral", -6)
			txt.append("Comentários maldosos: -6 Confiança")
	salvar_carreira()
	return txt


func sortear_evento() -> Dictionary:
	var vistos: Array = carreira["eventos_vistos"]
	var candidatos: Array = []
	var pesos: Array = []
	var total := 0.0
	for e in Dados.EVENTOS:
		if int(e.get("peso", 1)) <= 0:
			continue
		if e.get("unico", false) and e["id"] in vistos:
			continue
		if not _condicao_evento(e):
			continue
		# evita repetir eventos recentes
		var recente: bool = vistos.slice(maxi(0, vistos.size() - 6)).has(e["id"])
		if recente:
			continue
		candidatos.append(e)
		pesos.append(float(e["peso"]))
		total += float(e["peso"])
	if candidatos.is_empty():
		return {}
	var r := rng.randf() * total
	for i in candidatos.size():
		r -= pesos[i]
		if r <= 0.0:
			return candidatos[i]
	return candidatos.back()


func _condicao_evento(e: Dictionary) -> bool:
	var fase: String = e.get("fase", "any")
	var minha: String = carreira["fase"]
	if fase != "any" and fase != minha:
		return false
	var idade := int(carreira["jogador"]["idade"])
	if idade < int(e.get("idade_min", 0)) or idade > int(e.get("idade_max", 99)):
		return false
	if float(carreira["status"]["fama"]) < float(e.get("fama_min", 0)):
		return false
	if e.has("flag") and not carreira["flags"].has(e["flag"]):
		return false
	if e.has("sem_flag") and carreira["flags"].has(e["sem_flag"]):
		return false
	if float(carreira["dinheiro"]) < float(e.get("dinheiro_min", 0)):
		return false
	if e.has("forma_max") and (carreira["ultimas_notas"].size() < 3 or forma() > float(e["forma_max"])):
		return false
	if e.has("sem_gols") and int(carreira.get("sem_gols", 0)) < int(e["sem_gols"]):
		return false
	if e["id"] == "juninho_peneira" and carreira["flags"].has("amigo_no_clube"):
		return false
	return true


func opcao_evento_disponivel(op: Dictionary) -> bool:
	return float(carreira["dinheiro"]) >= float(op.get("cond_dinheiro", 0))


## Resolve a escolha. Retorna {texto, efeitos_txt}.
func resolver_evento(e: Dictionary, indice: int) -> Dictionary:
	carreira["eventos_vistos"].append(e["id"])
	var op: Dictionary = e["opcoes"][indice]
	var bloco := op
	var sucesso := true
	if op.has("chance"):
		sucesso = rng.randf() < float(op["chance"])
		bloco = op["sucesso"] if sucesso else op["falha"]
	var txt := aplicar_efeitos(bloco.get("efeitos", {}))
	salvar_carreira()
	Analytics.evento("evento_escolha", {"evento": e["id"], "opcao": indice, "sucesso": sucesso})
	return {"texto": texto(bloco.get("resultado", "")), "efeitos": txt, "sucesso": sucesso, "teve_sorte": op.has("chance")}


# ================================================================ partida

func situacao_titular() -> String:
	if int(carreira["status"]["lesao"]) > 0:
		return "lesionado"
	var exigido := forca_time(carreira["clube"]) - 4.0
	var nota := float(overall()) + (forma() - 6.5) * 4.0 + (float(carreira["rel"]["tecnico"]) - 50.0) / 8.0
	nota += (float(carreira["status"]["energia"]) - 50.0) / 25.0
	if nota >= exigido:
		return "titular"
	if nota >= exigido - 9.0:
		return "reserva"
	return "fora"


func preparar_partida(jogo: Dictionary) -> Dictionary:
	var meu: String = carreira["clube"]
	var adv: String = jogo["adv"]
	var titular := situacao_titular()
	var f_nos := forca_time(meu) + (float(overall()) - forca_time(meu)) * 0.15
	var f_adv := forca_time(adv)
	var casa: bool = jogo.get("casa", true)
	var lam_nos := 1.25 * pow(f_nos / f_adv, 2.4) * (1.12 if casa else 0.92)
	var lam_adv := 1.25 * pow(f_adv / f_nos, 2.4) * (0.92 if casa else 1.12)
	var gols_bg: Array = []
	var nomes: Array = Dados.NOMES_COMPANHEIROS.duplicate()
	nomes.shuffle()
	for g in _poisson(lam_nos * 0.72):
		gols_bg.append({"minuto": rng.randi_range(3, 90), "time": "nos", "autor": nomes[gols_bg.size() % nomes.size()]})
	var rival_aqui: bool = adv == carreira["rival"]["clube"]
	for g in _poisson(lam_adv * 0.85):
		var autor: String = carreira["rival"]["nome"] if rival_aqui and rng.randf() < 0.5 else "Camisa %d" % rng.randi_range(7, 11)
		gols_bg.append({"minuto": rng.randi_range(3, 90), "time": "eles", "autor": autor})
	gols_bg.sort_custom(func(a, b) -> bool: return a["minuto"] < b["minuto"])
	var momentos: Array = []
	var n := 0
	var faixa := [8, 88]
	match titular:
		"titular":
			var x := rng.randf()
			n = 2 if x < 0.5 else (3 if x < 0.95 else 4)
		"reserva":
			n = 2 if rng.randf() < 0.3 else 1
			faixa = [64, 89]
	var minutos: Array = []
	for i in n:
		var seg: float = (faixa[1] - faixa[0]) / float(n)
		minutos.append(int(faixa[0] + seg * i + rng.randf_range(2, seg - 2)))
	for m in minutos:
		momentos.append({"minuto": m, "tipo": Situacoes.sortear_tipo(carreira["jogador"]["posicao"], rng)})
	var cenario := "base" if carreira["categoria"] != "Profissional" else "estadio"
	if jogo["tipo"] == "selecao":
		cenario = "selecao"
	partida_atual = {
		"tipo": jogo["tipo"], "nos": meu, "adv": adv, "casa": casa, "cenario": cenario,
		"noite": cenario != "base" and rng.randf() < 0.55, "titular": titular, "momentos": momentos, "gols_bg": gols_bg,
		"mata_mata": jogo["tipo"] in ["final", "selecao"], "competicao": jogo.get("competicao", carreira["temp"]["liga"]),
		"rival": rival_aqui, "importancia": 1.0 if jogo["tipo"] != "liga" else (0.7 if rival_aqui else 0.4),
		"semana": carreira["semana"], "fase_selecao": jogo.get("fase_selecao", ""),
	}
	if jogo["tipo"] == "selecao":
		partida_atual["nos"] = "selecao"
	return partida_atual


func _poisson(lam: float) -> int:
	var l := exp(-lam)
	var k := 0
	var p := 1.0
	while true:
		p *= rng.randf()
		if p <= l:
			break
		k += 1
	return k


## Contexto para o motor de lances.
func contexto_lance(partida: Dictionary, momento: Dictionary, gols_nos: int, gols_adv: int, comemoracoes := true) -> Dictionary:
	var nos := clube(partida["nos"])
	var adv := clube(partida["adv"])
	var minuto := int(momento["minuto"])
	var dif := absi(gols_nos - gols_adv)
	var pressao := float(partida.get("importancia", 0.4)) * 0.5 + (0.3 if minuto >= 80 else 0.0) + (0.2 if dif <= 1 else 0.0)
	var parceiro: String = "Juninho" if (partida["tipo"] == "prologo" or carreira["flags"].has("amigo_no_clube")) else Dados.NOMES_COMPANHEIROS[rng.randi() % 10]
	var lista_com: Array = []
	if comemoracoes:
		var equip: String = carreira["jogador"].get("comemoracao", "galera")
		var ids: Array = perfil["cosmeticos"]["comemoracoes"].duplicate()
		ids.erase(equip)
		ids.insert(0, equip)
		for id in ids:
			if Dados.COMEMORACOES.has(id):
				var c: Dictionary = Dados.COMEMORACOES[id].duplicate()
				c["id"] = id
				lista_com.append(c)
	var modo_sc := ""
	if not partida.get("segunda_chance_usada", false):
		if vip():
			modo_sc = "vip"
		elif int(perfil.get("fichas", 0)) > 0:
			modo_sc = "ficha"
		else:
			modo_sc = "anuncio"
	var ctx := {
		"atributos": carreira["atributos"].duplicate(), "moral": float(carreira["status"]["moral"]),
		"pressao": clampf(pressao, 0.0, 1.0), "minuto": minuto,
		"parceiro": parceiro, "atacante": Dados.NOMES_COMPANHEIROS[rng.randi() % 20], "ponta": Dados.NOMES_COMPANHEIROS[rng.randi() % 20],
		"cenario": partida["cenario"], "noite": partida.get("noite", false),
		"cor_casa": nos["cor"], "calcao_casa": nos["calcao"], "cor_fora": adv["cor"], "calcao_fora": adv["calcao"],
		"sigla_casa": nos["sigla"], "sigla_fora": adv["sigla"], "gols_casa": gols_nos, "gols_fora": gols_adv,
		"visual": visual_jogador(), "numero": int(carreira["jogador"]["numero"]),
		"comemoracoes": lista_com, "segunda_chance": modo_sc, "tutorial": momento.get("tutorial", false),
		"dificuldade": clampf((forca_time(partida["adv"]) - float(overall())) / 100.0, -0.25, 0.3),
		"semente": rng.randi(), "semente_cenario": hash(partida["nos"]) % 1000,
		"rng": RandomNumberGenerator.new(),
	}
	var c1: Color = nos["cor"]
	var c2: Color = adv["cor"]
	if absf(c1.r - c2.r) + absf(c1.g - c2.g) + absf(c1.b - c2.b) < 0.45:
		# uniformes parecidos: o visitante usa o segundo uniforme
		ctx["cor_fora"] = Color("f2f2f2") if c1.get_luminance() < 0.6 else Color("222a3a")
	ctx["rng"].seed = ctx["semente"]
	ctx["titulo_intro"] = "%d' • %s" % [minuto, partida.get("competicao", "")]
	if "--auto" in OS.get_cmdline_user_args():
		ctx["auto"] = true  # modo demonstração/teste: o jogo decide sozinho
	return ctx


## Nota do lance (contribuição para a nota da partida).
func delta_nota(r: Dictionary) -> float:
	var d := {"gol": 1.25, "assistencia": 1.0, "passou_defesa": 0.35, "trave": 0.15, "defesa": 0.05,
		"fora": -0.3, "perdeu": -0.45, "interceptado": -0.4}.get(r["desfecho"], 0.0) as float
	if r["acao"] in ["penalti_esq", "penalti_dir", "cavadinha"] and r["desfecho"] != "gol":
		d = -0.8
	if r["acao"] in ["cobertura", "cavadinha", "falta_curva", "caneta"] and r["desfecho"] == "gol":
		d += 0.3
	if r.get("apressado", false):
		d -= 0.3
	if r.get("opcao_descoberta", false):
		d += 0.15
	return d


## Finaliza a partida. rel: {gols_nos, gols_adv, lances:[resultados], penaltis: {nos, adv}|null}
func finalizar_partida(rel: Dictionary) -> Dictionary:
	var p: Dictionary = partida_atual
	var lances: Array = rel.get("lances", [])
	var gn := int(rel["gols_nos"])
	var ga := int(rel["gols_adv"])
	var venceu := gn > ga
	var empate := gn == ga
	if rel.get("penaltis") != null and empate:
		venceu = int(rel["penaltis"]["nos"]) > int(rel["penaltis"]["adv"])
	var nota := 6.0
	var gols := 0
	var assist := 0
	var xp := {}
	for l in lances:
		nota += delta_nota(l)
		if l["desfecho"] == "gol" and not (l["acao"] in ["passe", "lancamento", "ajeitar"]):
			gols += 1
		if l["desfecho"] == "assistencia":
			assist += 1
		for a in _atributos_da_acao(l["acao"]):
			xp[a] = float(xp.get(a, 0.0)) + (2.5 if l["desfecho"] in ["gol", "assistencia"] else 1.2)
	nota += 0.3 if venceu else (-0.2 if not empate else 0.0)
	nota += rng.randf_range(-0.2, 0.2)
	nota = clampf(nota, 3.0, 10.0)
	var jogou: bool = p["titular"] in ["titular", "reserva"]
	var resumo := {"nota": nota if jogou else 0.0, "gols": gols, "assist": assist, "venceu": venceu, "empate": empate and rel.get("penaltis") == null,
		"gols_nos": gn, "gols_adv": ga, "penaltis": rel.get("penaltis"), "ganhos": {}, "efeitos": [], "memorias": [], "titulo": "",
		"adv": p["adv"], "tipo": p["tipo"], "jogou": jogou, "lances": lances}
	if p["tipo"] == "prologo":
		ultimo_relatorio = resumo
		for l in lances:
			if l["desfecho"] == "gol" and not (l["acao"] in ["passe", "lancamento", "ajeitar"]):
				_memoria("final_bairro", "Final da Copa da Vila", int(l.get("minuto", 0)))
		carreira["estat"]["notas_soma"] = nota
		salvar_carreira()
		return resumo

	if jogou:
		resumo["ganhos"] = dar_xp(xp)
		carreira["ultimas_notas"].append(nota)
		if carreira["ultimas_notas"].size() > 5:
			carreira["ultimas_notas"].pop_front()
		carreira["temp"]["notas"].append(nota)
		carreira["temp"]["jogos"] = int(carreira["temp"]["jogos"]) + 1
		carreira["temp"]["gols"] = int(carreira["temp"]["gols"]) + gols
		carreira["temp"]["assist"] = int(carreira["temp"]["assist"]) + assist
		var e: Dictionary = carreira["estat"]
		e["jogos"] = int(e["jogos"]) + 1
		e["gols"] = int(e["gols"]) + gols
		e["assist"] = int(e["assist"]) + assist
		e["notas_soma"] = float(e["notas_soma"]) + nota
		carreira["sem_gols"] = 0 if gols > 0 else int(carreira.get("sem_gols", 0)) + 1
		var mult := 1.0 if carreira["fase"] == "pro" else 0.5
		if p["tipo"] == "selecao":
			mult = 2.0
			e["selecao_jogos"] = int(e["selecao_jogos"]) + 1
			e["selecao_gols"] = int(e["selecao_gols"]) + gols
		resumo["efeitos"] = aplicar_efeitos({"moral": (nota - 6.5) * 4.0 + (3.0 if venceu else -2.0),
			"fama": (gols * 1.2 + assist * 0.7 + maxf(nota - 7.0, 0.0)) * mult,
			"energia": -20.0 if p["titular"] == "titular" else -10.0})
		_mudar("rel.tecnico", (nota - 6.3) * 2.0)
		_mudar("rel.torcida", (nota - 6.5) * 1.5 + (1.0 if venceu else -1.0))
		# comemorações
		for l in lances:
			var c: String = l.get("comemoracao", "")
			if c != "" and Dados.COMEMORACOES.has(c):
				aplicar_efeitos(Dados.COMEMORACOES[c]["efeitos"])
		# lesão (pouca energia aumenta o risco)
		var risco := 0.02 + (0.1 if float(carreira["status"]["energia"]) < 25.0 else 0.0)
		if rng.randf() < risco:
			var semanas := rng.randi_range(1, 3)
			carreira["status"]["lesao"] = semanas
			resumo["lesao"] = semanas
		_memorias_da_partida(resumo, lances, p)
	else:
		_mudar("status.moral", -3.0)
		_mudar("status.energia", 10.0)

	# tabela / mata-mata
	if p["tipo"] == "liga":
		_registrar_resultado(p["nos"], p["adv"], gn, ga)
		_simular_rodada(p["adv"])
	elif p["tipo"] == "final":
		carreira["temp"]["campeao"] = p["nos"] if venceu else p["adv"]
		if venceu:
			resumo["titulo"] = carreira["temp"]["liga"]
			_conquistar_titulo(carreira["temp"]["liga"])
	elif p["tipo"] == "selecao":
		_avancar_selecao(venceu, resumo)
	# marca o jogo como jogado
	for j in carreira["temp"]["calendario"]:
		if not j["jogado"]:
			j["jogado"] = true
			j["placar"] = [gn, ga]
			j["nota"] = nota if jogou else 0.0
			break
	# salário da semana
	var sal := float(carreira["contrato"].get("salario", 0.0))
	carreira["dinheiro"] = float(carreira["dinheiro"]) + sal
	resumo["salario"] = sal
	_atualizar_objetivo()
	perfil["contadores"]["partidas_total"] = int(perfil["contadores"]["partidas_total"]) + 1
	salvar_perfil()
	_noticias_semana(resumo)
	carreira["semana"] = int(carreira["semana"]) + 1
	carreira["semana_info"] = {}
	_mudar("status.energia", 15.0)  # recuperação natural da semana
	if int(carreira["status"]["lesao"]) > 0 and not resumo.has("lesao"):
		carreira["status"]["lesao"] = int(carreira["status"]["lesao"]) - 1
	_checar_final()
	ultimo_relatorio = resumo
	salvar_carreira()
	Analytics.evento("partida_fim", {"nota": snappedf(nota, 0.1), "gols": gols, "assist": assist, "venceu": venceu,
		"tipo": p["tipo"], "categoria": carreira["categoria"]})
	return resumo


## Semana sem jogar (lesionado/fora da lista): simula a partida do time.
func simular_sem_jogar() -> Dictionary:
	var j := proximo_jogo()
	var p := preparar_partida(j)
	var gn := 0
	var ga := 0
	for g in p["gols_bg"]:
		if g["time"] == "nos":
			gn += 1
		else:
			ga += 1
	var pen = null
	if p["mata_mata"] and gn == ga:
		pen = {"nos": rng.randi_range(3, 5), "adv": rng.randi_range(2, 5)}
		if pen["nos"] == pen["adv"]:
			pen["nos"] += 1
	return finalizar_partida({"gols_nos": gn, "gols_adv": ga, "lances": [], "penaltis": pen})


func _atributos_da_acao(acao: String) -> Array:
	match acao:
		"chute", "chute_forte", "penalti_esq", "penalti_dir":
			return ["finalizacao", "frieza"]
		"cobertura", "cavadinha":
			return ["finalizacao", "visao", "frieza"]
		"falta_curva", "falta_forte":
			return ["finalizacao"]
		"cabeceio", "cabeceio_chao", "ajeitar":
			return ["cabeceio"]
		"drible", "caneta":
			return ["drible"]
		"arrancada", "conduzir":
			return ["velocidade", "drible"]
		"passe":
			return ["passe", "visao"]
		"lancamento":
			return ["passe", "visao"]
	return []


func _registrar_resultado(a: String, b: String, ga: int, gb: int) -> void:
	var tab: Dictionary = carreira["temp"]["tabela"]
	for par in [[a, ga, gb], [b, gb, ga]]:
		var t: Dictionary = tab[par[0]]
		t["j"] = int(t["j"]) + 1
		t["gp"] = int(t["gp"]) + par[1]
		t["gc"] = int(t["gc"]) + par[2]
		if par[1] > par[2]:
			t["v"] = int(t["v"]) + 1
			t["pts"] = int(t["pts"]) + 3
		elif par[1] == par[2]:
			t["e"] = int(t["e"]) + 1
			t["pts"] = int(t["pts"]) + 1
		else:
			t["d"] = int(t["d"]) + 1


## Simula os outros jogos da rodada.
func _simular_rodada(adv_atual: String) -> void:
	var tab: Dictionary = carreira["temp"]["tabela"]
	var outros: Array = tab.keys()
	outros.erase(carreira["clube"])
	outros.erase(adv_atual)
	outros.shuffle()
	var i := 0
	while i + 1 < outros.size():
		var a: String = outros[i]
		var b: String = outros[i + 1]
		var fa := forca_time(a)
		var fb := forca_time(b)
		_registrar_resultado(a, b, _poisson(1.3 * pow(fa / fb, 2.0)), _poisson(1.3 * pow(fb / fa, 2.0)))
		i += 2


func _checar_final() -> void:
	var temp: Dictionary = carreira["temp"]
	var cal: Array = temp["calendario"]
	if not proximo_jogo().is_empty():
		return
	var tem_final := false
	for j in cal:
		if j["tipo"] == "final":
			tem_final = true
	if not tem_final and temp["campeao"] == "":
		var ordem := classificacao()
		var pos := ordem.find(carreira["clube"])
		if pos <= 1:
			var adv: String = ordem[1] if pos == 0 else ordem[0]
			cal.append({"semana": cal.size() + 1, "adv": adv, "casa": pos == 0, "tipo": "final", "jogado": false,
				"competicao": "Final • " + temp["liga"]})
			carreira["noticias"].push_front("Vocês estão na FINAL! Adversário: %s." % nome_clube(adv))
		else:
			temp["campeao"] = ordem[0]
			_talvez_selecao()
	elif temp["campeao"] != "" and not temp.get("selecao_checada", false):
		_talvez_selecao()


func _talvez_selecao() -> void:
	var temp: Dictionary = carreira["temp"]
	temp["selecao_checada"] = true
	var idade := int(carreira["jogador"]["idade"])
	var media := media_temporada()
	var minimo := 70.0
	var torneio := ""
	var ano := int(carreira["ano"])
	if carreira["categoria"] == "Profissional":
		minimo = 79.0
		if ano % 4 == 2:
			torneio = "Mundial"
		elif ano % 4 == 0:
			torneio = "Copa Continental"
	elif idade == 17:
		torneio = "Mundial Sub-17"
	elif idade == 19:
		minimo = 74.0
		torneio = "Mundial Sub-20"
	if torneio == "":
		return
	if float(overall()) < minimo or media < 6.6 or float(carreira["status"]["fama"]) < 12.0:
		return
	var nacoes := [["Argentina", "ARG", "75aadb", "111111"], ["França", "FRA", "1d3fa8", "ffffff"], ["Alemanha", "ALE", "f5f5f5", "111111"],
		["Inglaterra", "ING", "f5f5f5", "1d3fa8"], ["Espanha", "ESP", "c8102e", "1d3fa8"], ["Portugal", "POR", "8e1b1b", "0b6b3a"],
		["Holanda", "HOL", "ff7a00", "ffffff"], ["Uruguai", "URU", "6ec6ff", "111111"], ["Itália", "ITA", "1f4fd1", "ffffff"]]
	nacoes.shuffle()
	var fases := ["Quartas de final", "Semifinal", "Final"]
	for i in 3:
		var n: Array = nacoes[i]
		var nid := "nac_%s" % n[1]
		temp["times"][nid] = {"nome": n[0], "sigla": n[1], "pais": "int", "tier": 5, "forca": 80.0 + i * 3 + rng.randf_range(-2, 3),
			"cor": "#" + n[2], "calcao": "#" + n[3]}
		temp["selecao"].append(nid)
	temp["torneio"] = torneio
	temp["calendario"].append({"semana": temp["calendario"].size() + 1, "adv": temp["selecao"][0], "casa": true, "tipo": "selecao",
		"jogado": false, "competicao": "%s • %s" % [torneio, fases[0]], "fase_selecao": fases[0]})
	carreira["noticias"].push_front("CONVOCADO! Você vai disputar o %s pela Seleção." % torneio)
	carreira["semana_info"]["evento_forcado"] = "mundial_convocacao"
	concluir_sonho("selecao")


func _avancar_selecao(venceu: bool, resumo: Dictionary) -> void:
	var temp: Dictionary = carreira["temp"]
	var jogados := 0
	for j in temp["calendario"]:
		if j["tipo"] == "selecao" and j["jogado"]:
			jogados += 1
	var fase_atual := jogados  # índice do jogo que acabou de ser jogado (antes de marcar)
	if not venceu:
		carreira["noticias"].push_front("A Seleção foi eliminada. Fica a experiência.")
		return
	if fase_atual >= 2:
		var t: String = temp["torneio"]
		resumo["titulo"] = t
		_conquistar_titulo(t)
		if t == "Mundial":
			concluir_sonho("mundial")
		return
	var fases := ["Quartas de final", "Semifinal", "Final"]
	temp["calendario"].append({"semana": temp["calendario"].size() + 1, "adv": temp["selecao"][fase_atual + 1], "casa": true,
		"tipo": "selecao", "jogado": false, "competicao": "%s • %s" % [temp["torneio"], fases[fase_atual + 1]],
		"fase_selecao": fases[fase_atual + 1]})


func _conquistar_titulo(nome: String) -> void:
	carreira["titulos"].append({"nome": nome, "ano": carreira["ano"], "clube": nome_clube(partida_atual.get("nos", carreira["clube"]))})
	carreira["estat"]["titulos"] = int(carreira["estat"]["titulos"]) + 1
	aplicar_efeitos({"fama": 8, "moral": 12, "rel_torcida": 8})
	if carreira["fase"] == "pro":
		concluir_sonho("titulo")
	carreira["noticias"].push_front("CAMPEÃO! %s conquistado!" % nome)


func media_temporada() -> float:
	var n: Array = carreira["temp"].get("notas", [])
	if n.is_empty():
		return 0.0
	var s := 0.0
	for x in n:
		s += float(x)
	return s / n.size()


func _atualizar_objetivo() -> void:
	var o: Dictionary = carreira["temp"].get("objetivo", {})
	if o.is_empty():
		return
	match o["id"]:
		"gols":
			o["progresso"] = carreira["temp"]["gols"]
		"assist":
			o["progresso"] = carreira["temp"]["assist"]
		"media":
			o["progresso"] = snappedf(media_temporada(), 0.01)
		"titulo":
			o["progresso"] = 1 if carreira["temp"]["campeao"] == carreira["clube"] else 0


func objetivo_cumprido() -> bool:
	var o: Dictionary = carreira["temp"].get("objetivo", {})
	if o.is_empty():
		return false
	_atualizar_objetivo()
	if o["id"] == "media":
		return float(o.get("progresso", 0)) >= float(o["alvo"]) and int(carreira["temp"]["jogos"]) >= 4
	return float(o.get("progresso", 0)) >= float(o["alvo"])


func temporada_acabou() -> bool:
	return proximo_jogo().is_empty()


# ================================================================ memórias, sonhos e notícias

func _memoria(id: String, adversario: String, minuto: int) -> bool:
	if carreira["memorias"].has(id):
		return false
	carreira["memorias"][id] = {"temporada": carreira["temporada"], "ano": carreira["ano"], "idade": carreira["jogador"]["idade"],
		"clube": nome_clube(carreira["clube"]), "adversario": adversario, "minuto": minuto}
	var total: int = carreira["memorias"].size()
	if total % 4 == 0:
		ganhar_moedas(50, "album")
	return true


func _memorias_da_partida(resumo: Dictionary, lances: Array, p: Dictionary) -> void:
	var adv_nome := nome_clube(p["adv"])
	var novas: Array = []
	var gols := 0
	for l in lances:
		var minuto := int(l.get("minuto", 0))
		var meu_gol: bool = l["desfecho"] == "gol" and not (l["acao"] in ["passe", "lancamento", "ajeitar"])
		if meu_gol:
			gols += 1
			var id := ""
			match l["acao"]:
				"cobertura":
					id = "cobertura"
				"cavadinha":
					id = "cavadinha"
				"falta_curva", "falta_forte":
					id = "falta"
				"cabeceio", "cabeceio_chao":
					id = "cabeca"
				"caneta":
					id = "caneta"
			for m in [id, "primeiro_gol", "segunda_chance" if l.get("segunda_chance", false) else "",
					"rival" if p.get("rival", false) else "", "final" if p["tipo"] == "final" else "",
					"selecao" if p["tipo"] == "selecao" else "", "estreia_pro" if carreira["fase"] == "pro" else "",
					"exterior" if clube(carreira["clube"])["pais"] != "br" and p["tipo"] != "selecao" else "",
					"virada" if minuto >= 80 and resumo["venceu"] else ""]:
				if m != "" and _memoria(m, adv_nome, minuto):
					novas.append(m)
		if l["desfecho"] == "assistencia" and l["acao"] == "lancamento" and _memoria("lancamento", adv_nome, minuto):
			novas.append("lancamento")
	if gols >= 3 and _memoria("hat_trick", adv_nome, 90):
		novas.append("hat_trick")
	if int(carreira["estat"]["gols"]) >= 100:
		concluir_sonho("cem_gols")
	resumo["memorias"] = novas


func concluir_sonho(id: String) -> void:
	if carreira["sonhos"].get(id, false):
		return
	carreira["sonhos"][id] = true
	carreira["flags"]["sonho_" + id] = true
	var s: Dictionary = Dados.SONHOS.get(id, {})
	ganhar_moedas(int(s.get("moedas", 0) / 2), "sonho_" + id)
	carreira["noticias"].push_front("SONHO REALIZADO: %s" % s.get("nome", id))
	Analytics.evento("sonho", {"id": id, "idade": carreira["jogador"]["idade"]})


func comprar_sonho(id: String) -> bool:
	var s: Dictionary = Dados.SONHOS[id]
	var preco := float(s.get("preco", 0))
	if preco <= 0 or float(carreira["dinheiro"]) < preco or carreira["sonhos"].get(id, false):
		return false
	carreira["dinheiro"] = float(carreira["dinheiro"]) - preco
	match id:
		"casa_mae":
			aplicar_efeitos({"rel_familia": 40, "moral": 20})
		"campinho":
			aplicar_efeitos({"rel_torcida": 25, "fama": 10, "moral": 20})
		"carro":
			aplicar_efeitos({"moral": 8, "fama": 2})
	concluir_sonho(id)
	salvar_carreira()
	return true


func _noticias_semana(resumo: Dictionary) -> void:
	var n: Array = carreira["noticias"]
	var r: Dictionary = carreira["rival"]
	if rng.randf() < 0.45:
		var g := rng.randi_range(1, 2)
		r["gols"] = int(r["gols"]) + g
		n.push_front("%s marcou %d gol%s pelo %s." % [r["nome"], g, "s" if g > 1 else "", nome_clube(r["clube"])])
	var lider: String = classificacao()[0] if carreira["temp"]["tabela"].size() > 0 else ""
	if lider != "" and rng.randf() < 0.35:
		n.push_front("%s lidera a %s." % [nome_clube(lider), carreira["temp"]["liga"]])
	while n.size() > 8:
		n.pop_back()


# ================================================================ fim de temporada

func fim_de_temporada() -> Dictionary:
	var temp: Dictionary = carreira["temp"]
	if temp.get("resumo", null) is Dictionary:
		return temp["resumo"]  # já processada (ex.: o app foi fechado nesta tela)
	var media := media_temporada()
	var resumo := {"temporada": carreira["temporada"], "ano": carreira["ano"], "clube": nome_clube(carreira["clube"]),
		"categoria": carreira["categoria"], "jogos": temp["jogos"], "gols": temp["gols"], "assist": temp["assist"],
		"media": media, "posicao": posicao_tabela(), "campeao": nome_clube(temp["campeao"]), "titulos": [], "premios": [],
		"moedas": 0, "evolucao": {}, "objetivo": temp.get("objetivo", {}), "objetivo_ok": objetivo_cumprido()}
	for t in carreira["titulos"]:
		if int(t["ano"]) == int(carreira["ano"]):
			resumo["titulos"].append(t["nome"])
	# prêmios
	if int(temp["gols"]) >= int(temp["rodadas"]) * 0.7 and int(temp["gols"]) >= 5:
		resumo["premios"].append("Artilheiro da " + temp["liga"])
		concluir_sonho("artilheiro")
	if media >= 7.6 and int(temp["jogos"]) >= 5:
		resumo["premios"].append("Craque da temporada")
	if carreira["fase"] == "pro" and media >= 7.8 and int(temp["gols"]) + int(temp["assist"]) >= 10 and overall() >= 86:
		resumo["premios"].append("BOLA DE CRISTAL")
		carreira["estat"]["bolas_cristal"] = int(carreira["estat"]["bolas_cristal"]) + 1
		concluir_sonho("bola_cristal")
		aplicar_efeitos({"fama": 15})
	# moedas da temporada
	var moedas: int = 15 + int(temp["gols"]) * 2 + int(temp["assist"]) * 2 + resumo["titulos"].size() * 25
	if resumo["objetivo_ok"]:
		moedas += int(resumo["objetivo"].get("moedas", 0))
	resumo["moedas"] = moedas
	carreira["historico"].append({"temporada": carreira["temporada"], "ano": carreira["ano"], "idade": carreira["jogador"]["idade"],
		"clube": nome_clube(carreira["clube"]), "categoria": carreira["categoria"], "jogos": temp["jogos"],
		"gols": temp["gols"], "assist": temp["assist"], "media": snappedf(media, 0.01), "titulos": resumo["titulos"]})
	# envelhece e evolui
	var antes: Dictionary = temp.get("attrs_inicio", carreira["atributos"]).duplicate()
	carreira["jogador"]["idade"] = int(carreira["jogador"]["idade"]) + 1
	carreira["ano"] = int(carreira["ano"]) + 1
	_envelhecer()
	for a in carreira["atributos"]:
		var d := float(carreira["atributos"][a]) - float(antes.get(a, carreira["atributos"][a]))
		if absf(d) >= 0.5:
			resumo["evolucao"][a] = d
	# rival evolui
	var r: Dictionary = carreira["rival"]
	r["overall"] = clampf(float(r["overall"]) + rng.randf_range(2.0, 6.0) * fator_idade(int(carreira["jogador"]["idade"])) - (2.0 if int(carreira["jogador"]["idade"]) > 31 else 0.0), 45, 93)
	if rng.randf() < 0.25:
		r["titulos"] = int(r["titulos"]) + 1
	resumo["rival"] = {"nome": r["nome"], "clube": nome_clube(r["clube"]), "overall": int(r["overall"]), "gols": int(r["gols"])}
	temp["resumo"] = resumo
	temp["ofertas"] = []
	salvar_carreira()
	Analytics.evento("temporada_fim", {"temporada": carreira["temporada"], "media": snappedf(media, 0.1), "gols": temp["gols"]})
	return resumo


func _envelhecer() -> void:
	var idade := int(carreira["jogador"]["idade"])
	if idade < 30:
		return
	var queda := 0.6 + (idade - 30) * 0.45
	for a in carreira["atributos"]:
		var f := 1.6 if a in ["velocidade", "fisico"] else (0.4 if a in ["visao", "frieza", "passe"] else 0.9)
		carreira["atributos"][a] = maxf(30.0, float(carreira["atributos"][a]) - queda * f * rng.randf_range(0.6, 1.3))


## Propostas para a próxima temporada (geradas uma vez por temporada).
func ofertas_temporada() -> Array:
	var guardadas: Array = carreira["temp"].get("ofertas", [])
	if not guardadas.is_empty():
		return guardadas
	var novas := _gerar_ofertas()
	carreira["temp"]["ofertas"] = novas
	salvar_carreira()
	return novas


func _gerar_ofertas() -> Array:
	var idade := int(carreira["jogador"]["idade"])
	var ov := float(overall())
	var lista: Array = []
	var atual: String = carreira["clube"]
	var na_base: bool = carreira["fase"] == "base"
	var valor := ov + float(carreira["status"]["fama"]) / 12.0 + (media_temporada() - 6.5) * 2.0
	if carreira["flags"].has("empresario"):
		valor += 2.0
	if na_base:
		var nova_cat := categoria_por_idade(idade)
		var f_pro := float(clube(atual)["forca"])
		if idade >= 20 or (idade >= 17 and ov >= f_pro - 9.0):
			# subir para o profissional
			if ov >= f_pro - 12.0:
				lista.append(_oferta(atual, "Subir para o profissional", true))
			for id in _clubes_por_valor(valor + 8.0, "br", 3):
				if id != atual:
					lista.append(_oferta(id, "Contrato profissional", true))
			if lista.is_empty():
				lista.append(_oferta(["tupa", "estrela_vale", "vila_operaria"][rng.randi() % 3], "Contrato profissional", true))
			if idade < 20:
				lista.append({"clube": atual, "tipo": "base", "titulo": "Seguir na base (%s)" % nova_cat, "salario": float(carreira["contrato"]["salario"]) * 1.25, "papel": "Base"})
		else:
			lista.append({"clube": atual, "tipo": "base", "titulo": "Seguir na base (%s)" % nova_cat, "salario": float(carreira["contrato"]["salario"]) * 1.25, "papel": "Base"})
	else:
		lista.append(_oferta(atual, "Renovar contrato", true))
		var paises := ["br"]
		if valor >= 74.0:
			paises.append_array(["pt", "es", "en", "it", "de", "fr"])
		if carreira["flags"].has("interesse_golfo") or valor >= 72.0:
			paises.append("ar")
		if idade >= 29:
			paises.append("us")
		var vistos := {}
		for pais in paises:
			for id in _clubes_por_valor(valor, pais, 2):
				if id != atual and not vistos.has(id):
					vistos[id] = true
					lista.append(_oferta(id, "Proposta", true))
		lista.shuffle()
		# renovação sempre primeiro
		for i in lista.size():
			if lista[i]["clube"] == atual:
				var o = lista[i]
				lista.remove_at(i)
				lista.insert(0, o)
				break
		while lista.size() > 4:
			lista.pop_back()
	return lista


func _clubes_por_valor(valor: float, pais: String, n: int) -> Array:
	var r: Array = []
	for id in Dados.CLUBES:
		var c: Dictionary = Dados.CLUBES[id]
		if c["pais"] != pais:
			continue
		var f := float(c["forca"])
		if f <= valor + 4.0 and f >= valor - 16.0:
			r.append(id)
	r.shuffle()
	return r.slice(0, n)


func _oferta(id: String, titulo: String, pro: bool) -> Dictionary:
	var c := clube(id)
	var ov := float(overall())
	var tier_mult: float = [0.5, 0.5, 0.8, 1.0, 1.6, 2.5][clampi(int(c["tier"]), 0, 5)]
	var pais_mult: float = Dados.PAISES.get(c["pais"], {"salario": 1.0})["salario"]
	var sal: float = 2000.0 * pow(1.16, ov - 60.0) * tier_mult * pais_mult
	sal *= rng.randf_range(0.9, 1.15)
	if carreira["flags"].has("empresario"):
		sal *= 1.12
	var f := float(c["forca"])
	var papel := "Titular" if ov >= f - 2.0 else ("Rodízio" if ov >= f - 8.0 else "Reserva")
	return {"clube": id, "tipo": "pro", "titulo": titulo, "salario": snappedf(maxf(sal, 1500.0), 100.0), "papel": papel,
		"pais": Dados.PAISES.get(c["pais"], {}).get("nome", ""), "pro": pro}


func aceitar_oferta(o: Dictionary) -> void:
	var antigo: String = carreira["clube"]
	carreira["clube"] = o["clube"]
	carreira["contrato"] = {"salario": float(o["salario"]), "papel": o["papel"], "ate": int(carreira["temporada"]) + 2}
	if o["tipo"] == "pro":
		if carreira["fase"] == "base":
			concluir_sonho("profissional")
		carreira["fase"] = "pro"
		carreira["categoria"] = "Profissional"
	else:
		carreira["categoria"] = categoria_por_idade(int(carreira["jogador"]["idade"]))
	if clube(o["clube"])["pais"] != "br":
		concluir_sonho("exterior")
	if antigo != o["clube"]:
		_mudar("rel.tecnico", -100.0)
		_mudar("rel.tecnico", 50.0)
		carreira["tecnico"] = Dados.NOMES_TECNICO[rng.randi() % Dados.NOMES_TECNICO.size()]
		carreira["flags"].erase("amigo_no_clube")
		carreira["noticias"].push_front("Novo desafio: você assinou com o %s." % nome_clube(o["clube"]))
		Analytics.evento("transferencia", {"de": antigo, "para": o["clube"]})
	# o rival também muda de patamar
	var r: Dictionary = carreira["rival"]
	if float(r["overall"]) >= 80.0 and Dados.CLUBES.get(r["clube"], {}).get("pais", "br") == "br" and rng.randf() < 0.5:
		r["clube"] = ["kingsbridge", "real_castilla", "inter_lucenzo", "fc_rheinstadt", "paris_lumiere"][rng.randi() % 5]
		carreira["noticias"].push_front("%s foi vendido para o %s." % [r["nome"], nome_clube(r["clube"])])
	nova_temporada()


func pode_aposentar() -> bool:
	return int(carreira["jogador"]["idade"]) >= 33


func deve_aposentar() -> bool:
	var idade := int(carreira["jogador"]["idade"])
	return idade >= 39 or (idade >= 34 and overall() < 58)


# ================================================================ legado e nova geração

func legado() -> Dictionary:
	var e: Dictionary = carreira["estat"]
	var pontos: int = int(e["gols"]) * 2 + int(e["assist"]) + int(e["titulos"]) * 40 + int(e["selecao_gols"]) * 5 \
		+ int(e["bolas_cristal"]) * 200 + carreira["sonhos"].size() * 25 + carreira["memorias"].size() * 10
	var titulo := "Herói do bairro"
	if pontos >= 1600:
		titulo = "Lenda do futebol mundial"
	elif pontos >= 900:
		titulo = "Ídolo nacional"
	elif pontos >= 450:
		titulo = "Craque respeitado"
	elif pontos >= 200:
		titulo = "Jogador profissional"
	var jogos := maxi(1, int(e["jogos"]))
	return {"pontos": pontos, "titulo": titulo, "gols": e["gols"], "assist": e["assist"], "titulos": e["titulos"],
		"jogos": e["jogos"], "media": float(e["notas_soma"]) / jogos, "bolas": e["bolas_cristal"],
		"nome": carreira["jogador"]["nome"], "apelido": carreira["jogador"]["apelido"], "geracao": carreira.get("geracao", 1),
		"rival": carreira["rival"]}


func aposentar() -> Dictionary:
	var l := legado()
	carreira["fase"] = "aposentado"
	perfil["hall"].append({"apelido": l["apelido"], "nome": l["nome"], "pontos": l["pontos"], "titulo": l["titulo"],
		"gols": l["gols"], "titulos": l["titulos"], "geracao": l["geracao"]})
	ganhar_moedas(mini(int(l["pontos"] / 20), 150), "aposentadoria")
	salvar_perfil()
	salvar_carreira()
	Analytics.evento("aposentadoria", {"pontos": l["pontos"], "idade": carreira["jogador"]["idade"]})
	return l


## Herança para a próxima geração (filho do jogador).
func heranca() -> Dictionary:
	var l := legado()
	var melhor := ""
	var melhor_v := 0.0
	for a in carreira["atributos"]:
		if float(carreira["atributos"][a]) > melhor_v:
			melhor_v = float(carreira["atributos"][a])
			melhor = a
	var bonus_pot := clampf(float(l["pontos"]) / 400.0, 0.0, 5.0)
	if carreira["sonhos"].get("campinho", false):
		bonus_pot += 1.5
	return {"atributos": {melhor: 5.0}, "potencial": bonus_pot, "fama": clampf(float(l["pontos"]) / 80.0, 0.0, 15.0),
		"dinheiro": float(carreira["dinheiro"]) * 0.1, "pai": l["apelido"], "geracao": int(carreira.get("geracao", 1)) + 1,
		"melhor": melhor}


# ================================================================ desafio diário (Lance do Dia)

func hoje() -> String:
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d["year"], d["month"], d["day"]]


func desafio_disponivel() -> bool:
	return perfil["desafio"].get("ultimo", "") != hoje()


func contexto_desafio() -> Dictionary:
	var d := Time.get_date_dict_from_system()
	var semente: int = d["year"] * 1000 + d["month"] * 40 + d["day"]
	var r := RandomNumberGenerator.new()
	r.seed = semente
	var tipo: String = Situacoes.TIPOS[r.randi() % Situacoes.TIPOS.size()]
	var attrs := {}
	if tem_carreira():
		attrs = carreira["atributos"].duplicate()
	else:
		for a in Dados.ATRIBUTOS:
			attrs[a] = 60.0
	var lista_com: Array = []
	for id in perfil["cosmeticos"]["comemoracoes"]:
		var c: Dictionary = Dados.COMEMORACOES[id].duplicate()
		c["id"] = id
		lista_com.append(c)
	var ctx := {"atributos": attrs, "moral": 65.0, "pressao": 0.6, "minuto": 90, "parceiro": "Juninho",
		"cenario": ["estadio", "base", "varzea", "selecao"][r.randi() % 4], "noite": r.randf() < 0.5,
		"cor_casa": Color("ffc928"), "calcao_casa": Color("1d3fa8"), "cor_fora": Color("c62828"), "calcao_fora": Color.WHITE,
		"sigla_casa": "VOC", "sigla_fora": "DES", "gols_casa": 0, "gols_fora": 0,
		"visual": visual_jogador() if tem_carreira() else {"pele": 2, "cabelo": 1, "cor_cabelo": 0, "chuteira": Color("111111")},
		"numero": 10, "comemoracoes": lista_com, "segunda_chance": "", "semente": semente, "semente_cenario": semente % 97,
		"titulo_intro": "LANCE DO DIA • %02d/%02d" % [d["day"], d["month"]], "rng": r}
	return {"tipo": tipo, "ctx": ctx}


func registrar_desafio(bom: bool) -> int:
	var dsf: Dictionary = perfil["desafio"]
	var ontem := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)
	if dsf.get("ultimo", "") == ontem:
		dsf["sequencia"] = int(dsf.get("sequencia", 0)) + 1
	elif dsf.get("ultimo", "") != hoje():
		dsf["sequencia"] = 1
	dsf["ultimo"] = hoje()
	var base := int(Analytics.remoto("moedas_desafio_diario")) if bom else 10
	var bonus := mini(int(dsf["sequencia"]), 7) * 10
	var total := (base + bonus) * (2 if vip() else 1)
	ganhar_moedas(total, "desafio_diario")
	salvar_perfil()
	Analytics.evento("desafio_diario", {"bom": bom, "sequencia": dsf["sequencia"]})
	return total


# ================================================================ patrocínio (anúncio recompensado diegético)

func patrocinio_disponivel() -> int:
	var p: Dictionary = perfil["patrocinio"]
	if p.get("dia", "") != hoje():
		p["dia"] = hoje()
		p["vezes"] = 0
	var limite := int(Anuncios.cfg.get_value("regras_anuncios", "recompensado_patrocinio_por_dia", 3))
	return maxi(0, limite - int(p["vezes"]))


func valor_patrocinio() -> float:
	var sal := float(carreira.get("contrato", {}).get("salario", 800.0))
	return snappedf(maxf(1500.0, sal * 0.6 + float(carreira["status"]["fama"]) * 400.0) * float(Analytics.remoto("bonus_patrocinio")), 100.0)


func receber_patrocinio() -> float:
	var v := valor_patrocinio()
	carreira["dinheiro"] = float(carreira["dinheiro"]) + v
	_mudar("status.fama", 0.5)
	perfil["patrocinio"]["vezes"] = int(perfil["patrocinio"]["vezes"]) + 1
	salvar_perfil()
	salvar_carreira()
	return v
