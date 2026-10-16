extends Node
## Autoload "Analytics": eventos de produto e Remote Config.
##
## Usa o plugin nativo "MinhaHistoriaFirebase" (código em android_plugins/firebase)
## quando presente: Firebase Analytics + Crashlytics + Remote Config.
## Sem o plugin, registra os eventos no log (e num arquivo local em debug),
## o que permite validar o funil antes de publicar.
##
## Funil principal: abriu_app -> tutorial_inicio -> lance_concluido -> tutorial_fim
## -> clube_escolhido -> partida_fim -> temporada_fim -> aposentadoria.
## Monetização: anuncio_* , compra_*, purchase, loja_aberta, oferta_vista.

signal remote_config_pronto

const PADROES_REMOTE := {
	"intersticial_a_cada_partidas": 2,
	"intersticial_partidas_minimas": 3,
	"oferta_iniciante_horas": 48,
	"moedas_desafio_diario": 40,
	"bonus_patrocinio": 1.0,
}

var backend := "log"
var _firebase: Object = null
var _remote := PADROES_REMOTE.duplicate()
var _sessao_inicio := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sessao_inicio = Time.get_ticks_msec()
	if Engine.has_singleton("MinhaHistoriaFirebase"):
		_firebase = Engine.get_singleton("MinhaHistoriaFirebase")
		backend = "firebase"
		if _firebase.has_signal("remote_config_fetched"):
			_firebase.connect("remote_config_fetched", _remote_recebido)
		_firebase.fetchRemoteConfig(JSON.stringify(PADROES_REMOTE))


func evento(nome: String, params := {}) -> void:
	var limpo := {}
	for k in params:
		var v = params[k]
		limpo[k] = v if (v is int or v is float or v is bool) else str(v).left(100)
	if backend == "firebase":
		_firebase.logEvent(nome, JSON.stringify(limpo))
	elif OS.is_debug_build() and DisplayServer.get_name() != "headless":
		print("[analytics] ", nome, " ", limpo)


func propriedade(nome: String, valor: String) -> void:
	if backend == "firebase":
		_firebase.setUserProperty(nome, valor)


func erro(mensagem: String) -> void:
	if backend == "firebase":
		_firebase.recordError(mensagem)
	else:
		push_warning(mensagem)


func remoto(chave: String):
	return _remote.get(chave, PADROES_REMOTE.get(chave))


func _remote_recebido(json: String) -> void:
	var dados = JSON.parse_string(json)
	if dados is Dictionary:
		for k in dados:
			_remote[k] = dados[k]
	remote_config_pronto.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		evento("sessao_pausa", {"segundos": int((Time.get_ticks_msec() - _sessao_inicio) / 1000.0)})
