extends Node
## Autoload "Compras": compras no app.
##
## - No Android com o plugin oficial GodotGooglePlayBilling, usa o Google Play
##   Billing de verdade (consulta de preços, compra, consumo e reconhecimento).
## - Sem o plugin, usa um fluxo SIMULADO de confirmação (modo de teste).
##
## Produtos (cadastrar com os mesmos IDs no Play Console):
##   remover_anuncios  (não consumível)  - sem intersticiais
##   craque_vip        (não consumível)  - sem intersticiais + "E se...?" grátis por partida
##                                         + moedas em dobro no desafio diário + chuteira dourada
##   pacote_iniciante  (não consumível, oferta única por 48h após o prólogo)
##   moedas_500 / moedas_1200 / moedas_3000 (consumíveis)

signal compra_concluida(produto: String, ok: bool)
signal precos_atualizados

const PRODUTOS := {
	"remover_anuncios": {"nome": "Remover anúncios", "preco": "R$ 12,90", "consumivel": false,
		"descricao": "Sem anúncios entre as partidas. Para sempre."},
	"craque_vip": {"nome": "Craque VIP", "preco": "R$ 29,90", "consumivel": false,
		"descricao": "Sem anúncios + 1 \"E se...?\" grátis por partida + moedas em dobro no Lance do Dia + Chuteira Dourada."},
	"pacote_iniciante": {"nome": "Pacote do Moleque", "preco": "R$ 6,90", "consumivel": false,
		"descricao": "1.000 moedas + Chuteira Relâmpago + 5 fichas \"E se...?\". Só uma vez."},
	"moedas_500": {"nome": "Saquinho de moedas", "preco": "R$ 4,90", "consumivel": true, "moedas": 500,
		"descricao": "500 moedas"},
	"moedas_1200": {"nome": "Cofrinho de moedas", "preco": "R$ 9,90", "consumivel": true, "moedas": 1200,
		"descricao": "1.200 moedas (+20%)"},
	"moedas_3000": {"nome": "Baú de moedas", "preco": "R$ 19,90", "consumivel": true, "moedas": 3000,
		"descricao": "3.000 moedas (+50%)"},
}

var backend := "simulado"
var _billing: Object = null
var _precos := {}
var _pendente := ""
var _ultimo_ok := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.has_singleton("GodotGooglePlayBilling"):
		_billing = Engine.get_singleton("GodotGooglePlayBilling")
		backend = "google_play"
		_billing.initPlugin()
		_billing.connect("connected", _conectado)
		_billing.connect("disconnected", _desconectado)
		_billing.connect("query_product_details_response", _detalhes)
		_billing.connect("query_purchases_response", _compras_existentes)
		_billing.connect("on_purchase_updated", _compra_atualizada)
		_billing.connect("consume_purchase_response", func(_r: Dictionary) -> void: pass)
		_billing.connect("acknowledge_purchase_response", func(_r: Dictionary) -> void: pass)
		_billing.startConnection()


func preco(id: String) -> String:
	return _precos.get(id, PRODUTOS[id]["preco"])


func disponivel() -> bool:
	return backend == "simulado" or (_billing != null and _billing.isReady())


## Inicia a compra. Retorna true se concluída.
func comprar(id: String) -> bool:
	Analytics.evento("compra_iniciada", {"produto": id})
	if backend == "google_play":
		if not _billing.isReady():
			Tela.aviso("Loja indisponível no momento. Verifique sua conexão.", "info", UI.VERMELHO)
			return false
		_pendente = id
		var r: Dictionary = _billing.purchase(id, "", "", false)
		if int(r.get("response_code", 6)) != 0:
			_pendente = ""
			return false
		# o resultado chega pelo sinal on_purchase_updated -> compra_concluida(produto, ok)
		var args: Array = await compra_concluida
		return bool(args[1])
	return await _simular(id)



func restaurar() -> void:
	if backend == "google_play" and _billing.isReady():
		_billing.queryPurchases("inapp", false)
	else:
		Tela.aviso("Compras restauradas.", "ok", UI.VERDE)


# ---------------------------------------------------------------- Google Play

func _conectado() -> void:
	_billing.queryProductDetails(PackedStringArray(PRODUTOS.keys()), "inapp")
	_billing.queryPurchases("inapp", false)


func _desconectado() -> void:
	get_tree().create_timer(10.0).timeout.connect(func() -> void: _billing.startConnection())


func _detalhes(r: Dictionary) -> void:
	if int(r.get("response_code", 6)) != 0:
		return
	for p in r.get("product_details", []):
		var id: String = p.get("product_id", "")
		var oferta: Dictionary = p.get("one_time_purchase_offer_details", {})
		if id != "" and oferta.has("formatted_price"):
			_precos[id] = oferta["formatted_price"]
	precos_atualizados.emit()


func _compras_existentes(r: Dictionary) -> void:
	if int(r.get("response_code", 6)) != 0:
		return
	for compra in r.get("purchases", []):
		_processar(compra)


func _compra_atualizada(r: Dictionary) -> void:
	var codigo := int(r.get("response_code", 6))
	if codigo == 0:
		for compra in r.get("purchases", []):
			_processar(compra)
	elif codigo == 7 and _pendente != "":  # ITEM_ALREADY_OWNED
		_entregar(_pendente)
		_ultimo_ok = true
		compra_concluida.emit(_pendente, true)
	else:
		_ultimo_ok = false
		compra_concluida.emit(_pendente, false)
		if codigo != 1:  # 1 = cancelado pelo usuário
			Tela.aviso("A compra não foi concluída (código %d)." % codigo, "info", UI.VERMELHO)
	_pendente = ""


func _processar(compra: Dictionary) -> void:
	if int(compra.get("purchase_state", 0)) != 1:  # 1 = PURCHASED (2 = PENDING)
		return
	var token: String = compra.get("purchase_token", "")
	for id in compra.get("product_ids", []):
		if not PRODUTOS.has(id):
			continue
		if PRODUTOS[id]["consumivel"]:
			_billing.consumePurchase(token)
			_entregar(id)
		else:
			if not compra.get("is_acknowledged", false):
				_billing.acknowledgePurchase(token)
			if not Jogo.tem_compra(id):
				_entregar(id)
		_ultimo_ok = true
		compra_concluida.emit(id, true)


# ---------------------------------------------------------------- entrega

func _entregar(id: String) -> void:
	Jogo.entregar_produto(id)
	Analytics.evento("purchase", {"produto": id, "backend": backend})


# ---------------------------------------------------------------- simulação

func _simular(id: String) -> bool:
	var p: Dictionary = PRODUTOS[id]
	var esc := 0
	if DisplayServer.get_name() != "headless":
		esc = await Tela.dialogo("Confirmar compra", "%s\n%s\n\n%s\n\n(Modo de teste: nenhuma cobrança real.)" % [p["nome"], p["descricao"], preco(id)],
			[["Comprar", "ok", "verde"], ["Cancelar", "fechar", "fantasma"]], "loja", UI.VERDE)
	if esc != 0:
		Analytics.evento("compra_cancelada", {"produto": id})
		return false
	_entregar(id)
	compra_concluida.emit(id, true)
	return true
