extends TelaBase
## Depois da final do bairro: os olheiros fazem propostas conforme a nota.
## Nota alta -> clubes grandes; média -> clubes médios; baixa -> peneira (um lance).

const LANCE := preload("res://cenas/lance.tscn")

var nota := 6.0
var ofertas := {}


func construir() -> void:
	nota = float(Jogo.ultimo_relatorio.get("nota", Jogo.carreira["estat"].get("notas_soma", 6.0)))
	ofertas = Jogo.ofertas_prologo(nota)
	Audio.musica(true)
	conteudo.add_child(UI.espaco(20))
	var t := UI.titulo("OS OLHEIROS VIRAM TUDO", 50, UI.OURO)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conteudo.add_child(t)
	var c := UI.cartao(UI.CARTAO, 24, 22)
	var l := UI.hbox(18)
	l.alignment = BoxContainer.ALIGNMENT_CENTER
	c.add_child(l)
	l.add_child(UI.titulo("%.1f" % nota, 90, UI.cor_nota(nota)))
	var d := UI.vbox(4)
	d.add_child(UI.rotulo("SUA NOTA NA FINAL", 22, UI.TEXTO2, "titulo"))
	d.add_child(Componentes.estrelas(int(round((nota - 3.0) / 7.0 * 5.0)), 5, 30))
	l.add_child(d)
	conteudo.add_child(c)
	var texto := ""
	match ofertas["nivel"]:
		"grande":
			texto = "Que final! Dois clubes GRANDES querem você na base. Escolha seu destino:"
		"medio":
			texto = "Boa partida! Dois clubes de médio porte gostaram do que viram:"
		_:
			texto = "Ninguém fez proposta... mas um olheiro do %s te chamou para uma PENEIRA. Um lance para mudar sua vida." % Jogo.nome_clube(ofertas["clubes"][0])
	var p := UI.paragrafo(texto, 26, UI.TEXTO)
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	conteudo.add_child(p)
	if ofertas["nivel"] == "peneira":
		var b := UI.botao("Fazer a peneira", "olho", "primario", 100)
		b.pressed.connect(_peneira)
		conteudo.add_child(UI.expansor())
		conteudo.add_child(b)
		return
	for id in ofertas["clubes"]:
		conteudo.add_child(_cartao_clube(id))
	conteudo.add_child(UI.expansor())


func _cartao_clube(id: String) -> PanelContainer:
	var c := Jogo.clube(id)
	var card := UI.cartao_borda(UI.CARTAO, Color(c["cor"], 0.7), 24, 22, 3)
	var col := UI.vbox(14)
	card.add_child(col)
	col.add_child(Componentes.cabecalho_clube(id, "Categoria de base • Sub-15"))
	var linha := UI.hbox(10)
	linha.add_child(Componentes.estrelas(int(c["tier"]), 5, 26))
	col.add_child(linha)
	var desc := {5: "Gigante nacional. Disputa forte por posição, vitrine enorme e a pressão de uma torcida exigente.",
		4: "Clube grande, estrutura de ponta. Equilíbrio entre chances de jogar e visibilidade.",
		3: "Clube médio. Mais chances de jogar desde cedo e virar o protagonista.",
		2: "Clube pequeno. Você será a estrela, mas terá que chamar atenção dos grandes."}
	col.add_child(UI.paragrafo(desc.get(int(c["tier"]), ""), 22))
	var b := UI.botao("Assinar com o %s" % c["nome"], "aperto", "primario", 84)
	b.pressed.connect(_assinar.bind(id))
	col.add_child(b)
	return card


func _assinar(id: String) -> void:
	Jogo.escolher_clube_base(id)
	Audio.tocar("sucesso")
	await Tela.dialogo("Contrato assinado!", Jogo.texto("Você é jogador da base do %s. {mae} chorou no telefone.\n\nE o {rival}? Assinou com o %s. A rivalidade só começou." % [Jogo.nome_clube(id), Jogo.nome_clube(Jogo.carreira["rival"]["clube"])]),
		[["Bora!", "seta_dir", "primario"]], "aperto", UI.VERDE)
	await _oferta_inicial()
	Tela.ir("res://cenas/hub.tscn")


func _oferta_inicial() -> void:
	if Jogo.tem_compra("pacote_iniciante") or DisplayServer.get_name() == "headless":
		return
	Analytics.evento("oferta_vista", {"oferta": "pacote_iniciante", "local": "pos_prologo"})
	var r := await Tela.dialogo("Pacote do Moleque", "Para começar a carreira com tudo:\n\n1.000 moedas\nChuteira Relâmpago (exclusiva)\n5 fichas \"E se...?\" para reviver lances\n\nSó %s. Oferta única, por 48 horas." % Compras.preco("pacote_iniciante"),
		[["Quero!", "presente", "primario"], ["Agora não", "fechar", "fantasma"]], "presente", UI.OURO)
	if r == 0:
		var ok := await Compras.comprar("pacote_iniciante")
		if ok:
			await Tela.recompensa("Pacote liberado!", ["+1.000 moedas", "Chuteira Relâmpago", "+5 fichas \"E se...?\""])


func _peneira() -> void:
	var partida := {"nos": "vila", "adv": "jardim", "cenario": "base", "noite": false, "importancia": 1.0, "competicao": "Peneira", "tipo": "peneira"}
	Jogo.partida_atual = partida
	var ctx := Jogo.contexto_lance(partida, {"minuto": 1, "tipo": "chance_area"}, 0, 0)
	ctx["titulo_intro"] = "PENEIRA • %s" % Jogo.nome_clube(ofertas["clubes"][0])
	ctx["sigla_casa"] = "VOC"
	ctx["sigla_fora"] = "PEN"
	var s := Situacoes.gerar("chance_area", ctx)
	visible = false
	var l: Lance = LANCE.instantiate()
	get_parent().add_child(l)
	l.iniciar(s)
	var r: Dictionary = await l.terminou
	l.queue_free()
	visible = true
	Jogo.partida_atual = {}
	if r["desfecho"] in ["gol", "assistencia"]:
		Tela.aviso("Aprovado na peneira!", "ok", UI.VERDE)
		_assinar(ofertas["clubes"][0])
	else:
		var b: String = ofertas["plano_b"]
		await Tela.dialogo("Não foi dessa vez...", "O %s não te aprovou. Mas o treinador do %s viu a peneira e gostou da sua coragem. Ele te oferece uma vaga." % [Jogo.nome_clube(ofertas["clubes"][0]), Jogo.nome_clube(b)],
			[["Aceitar e provar meu valor", "aperto", "primario"]], "info", UI.OURO)
		_assinar(b)
