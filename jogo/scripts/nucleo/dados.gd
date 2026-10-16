class_name Dados
extends RefCounted
## Dados estáticos do jogo. Todos os clubes, ligas e marcas são FICTÍCIOS.

const ATRIBUTOS := ["finalizacao", "passe", "drible", "cabeceio", "velocidade", "fisico", "visao", "frieza"]
const NOMES_ATRIBUTOS := {
	"finalizacao": "Finalização", "passe": "Passe", "drible": "Drible", "cabeceio": "Cabeceio",
	"velocidade": "Velocidade", "fisico": "Físico", "visao": "Visão de jogo", "frieza": "Frieza",
}
const ICONES_ATRIBUTOS := {
	"finalizacao": "bola", "passe": "troca", "drible": "correr", "cabeceio": "seta_cima",
	"velocidade": "energia", "fisico": "treino", "visao": "olho", "frieza": "zen",
}
const DESCRICAO_ATRIBUTOS := {
	"visao": "Revela jogadas escondidas e, a partir de 55, dá o \"instinto\" de cada opção.",
	"frieza": "Mais tempo para decidir e menos visão em túnel sob pressão.",
}
const POSICOES := ["Atacante", "Ponta", "Meia"]
const DESCRICAO_POSICOES := {
	"Atacante": "Vive na área: finalizações, cabeçadas e muitos gols.",
	"Ponta": "Dribles, velocidade e mano a mano pelos lados.",
	"Meia": "O cérebro: passes decisivos, lançamentos e faltas.",
}
const PESOS_OVERALL := {
	"Atacante": {"finalizacao": 0.28, "cabeceio": 0.14, "velocidade": 0.14, "drible": 0.12, "fisico": 0.1, "visao": 0.08, "passe": 0.06, "frieza": 0.08},
	"Ponta": {"drible": 0.26, "velocidade": 0.22, "finalizacao": 0.14, "passe": 0.12, "visao": 0.1, "fisico": 0.06, "frieza": 0.06, "cabeceio": 0.04},
	"Meia": {"passe": 0.28, "visao": 0.24, "drible": 0.14, "finalizacao": 0.1, "frieza": 0.1, "velocidade": 0.06, "fisico": 0.05, "cabeceio": 0.03},
}
const BONUS_POSICAO := {
	"Atacante": {"finalizacao": 8, "cabeceio": 5, "fisico": 2},
	"Ponta": {"drible": 8, "velocidade": 7},
	"Meia": {"passe": 8, "visao": 7, "frieza": 2},
}

const VILA := {"nome": "Vila Esperança", "sigla": "VIL", "cor": Color("ffc928"), "calcao": Color("1d3fa8")}
const JARDIM := {"nome": "Jardim Primavera", "sigla": "JAR", "cor": Color("c62828"), "calcao": Color("ffffff")}

## tier: 1 (pequeno) .. 5 (gigante). forca: nível do time profissional.
const CLUBES := {
	"atl_metropolitano": {"nome": "Atlético Metropolitano", "sigla": "ATM", "pais": "br", "tier": 5, "forca": 82, "cor": Color("c8102e"), "calcao": Color("111111")},
	"imperial": {"nome": "Imperial FC", "sigla": "IMP", "pais": "br", "tier": 5, "forca": 81, "cor": Color("1f4fd1"), "calcao": Color("ffffff")},
	"litoral": {"nome": "EC Litoral", "sigla": "LIT", "pais": "br", "tier": 4, "forca": 77, "cor": Color("f2f2f2"), "calcao": Color("111111")},
	"porto_sul": {"nome": "Porto Sul", "sigla": "PSU", "pais": "br", "tier": 4, "forca": 76, "cor": Color("13306b"), "calcao": Color("5ab0ff")},
	"uniao_serrana": {"nome": "União Serrana", "sigla": "UNS", "pais": "br", "tier": 4, "forca": 75, "cor": Color("6ec6ff"), "calcao": Color("ffffff")},
	"leoes_agreste": {"nome": "Leões do Agreste", "sigla": "LDA", "pais": "br", "tier": 3, "forca": 71, "cor": Color("d6281e"), "calcao": Color("111111")},
	"operario_leste": {"nome": "Operário Leste", "sigla": "OPL", "pais": "br", "tier": 3, "forca": 70, "cor": Color("1b8a3a"), "calcao": Color("ffffff")},
	"cerrado": {"nome": "SE Cerrado", "sigla": "CER", "pais": "br", "tier": 3, "forca": 69, "cor": Color("2e7d32"), "calcao": Color("ffd600")},
	"ferroviario": {"nome": "Ferroviário do Norte", "sigla": "FER", "pais": "br", "tier": 3, "forca": 68, "cor": Color("7b1e3a"), "calcao": Color("ffffff")},
	"tupa": {"nome": "Tupã EC", "sigla": "TUP", "pais": "br", "tier": 2, "forca": 63, "cor": Color("ff7a00"), "calcao": Color("111111")},
	"estrela_vale": {"nome": "Estrela do Vale", "sigla": "EDV", "pais": "br", "tier": 2, "forca": 62, "cor": Color("1565c0"), "calcao": Color("ffd600")},
	"vila_operaria": {"nome": "Vila Operária FC", "sigla": "VOP", "pais": "br", "tier": 2, "forca": 60, "cor": Color("8e244d"), "calcao": Color("ffffff")},
	# exterior
	"sporting_atlantico": {"nome": "Sporting Atlântico", "sigla": "SPA", "pais": "pt", "tier": 4, "forca": 79, "cor": Color("0b8a4b"), "calcao": Color("ffffff")},
	"fc_ribeira": {"nome": "FC Ribeira", "sigla": "RIB", "pais": "pt", "tier": 4, "forca": 78, "cor": Color("1e5bc6"), "calcao": Color("ffffff")},
	"sc_douro": {"nome": "SC Douro", "sigla": "DOU", "pais": "pt", "tier": 3, "forca": 73, "cor": Color("d32f2f"), "calcao": Color("ffffff")},
	"real_castilla": {"nome": "Real Castilla", "sigla": "RCA", "pais": "es", "tier": 5, "forca": 90, "cor": Color("f5f5f5"), "calcao": Color("f5f5f5")},
	"atletico_mediterraneo": {"nome": "Atlético Mediterrâneo", "sigla": "ATD", "pais": "es", "tier": 5, "forca": 86, "cor": Color("d61f2c"), "calcao": Color("1a237e")},
	"cf_valdoria": {"nome": "CF Valdoria", "sigla": "VAL", "pais": "es", "tier": 4, "forca": 80, "cor": Color("ff8f00"), "calcao": Color("111111")},
	"kingsbridge": {"nome": "Kingsbridge United", "sigla": "KBU", "pais": "en", "tier": 5, "forca": 90, "cor": Color("c62828"), "calcao": Color("ffffff")},
	"ravenshire": {"nome": "Ravenshire City", "sigla": "RAV", "pais": "en", "tier": 5, "forca": 89, "cor": Color("7ec8f2"), "calcao": Color("ffffff")},
	"northgate": {"nome": "Northgate Rovers", "sigla": "NGR", "pais": "en", "tier": 4, "forca": 82, "cor": Color("0d47a1"), "calcao": Color("ffffff")},
	"inter_lucenzo": {"nome": "Inter Lucenzo", "sigla": "INL", "pais": "it", "tier": 5, "forca": 87, "cor": Color("0a2a8a"), "calcao": Color("111111")},
	"ac_varenna": {"nome": "AC Varenna", "sigla": "VAR", "pais": "it", "tier": 5, "forca": 86, "cor": Color("b71c1c"), "calcao": Color("111111")},
	"fc_rheinstadt": {"nome": "FC Rheinstadt", "sigla": "RHE", "pais": "de", "tier": 5, "forca": 88, "cor": Color("e53935"), "calcao": Color("ffffff")},
	"sv_nordhafen": {"nome": "SV Nordhafen", "sigla": "NOR", "pais": "de", "tier": 4, "forca": 81, "cor": Color("fdd835"), "calcao": Color("111111")},
	"paris_lumiere": {"nome": "Paris Lumière", "sigla": "PLU", "pais": "fr", "tier": 5, "forca": 89, "cor": Color("102a5c"), "calcao": Color("d32f2f")},
	"olympique_meridional": {"nome": "Olympique Méridional", "sigla": "OME", "pais": "fr", "tier": 4, "forca": 82, "cor": Color("8fd3ff"), "calcao": Color("ffffff")},
	"al_najm": {"nome": "Al-Najm FC", "sigla": "NAJ", "pais": "ar", "tier": 3, "forca": 75, "cor": Color("f5f5f5"), "calcao": Color("0b8a4b")},
	"al_sahel": {"nome": "Al-Sahel", "sigla": "SAH", "pais": "ar", "tier": 3, "forca": 73, "cor": Color("ffd600"), "calcao": Color("0d47a1")},
	"bay_city": {"nome": "Bay City FC", "sigla": "BAY", "pais": "us", "tier": 2, "forca": 70, "cor": Color("ff4fa3"), "calcao": Color("111111")},
	"lone_star": {"nome": "Lone Star SC", "sigla": "LSS", "pais": "us", "tier": 2, "forca": 69, "cor": Color("c62828"), "calcao": Color("0d47a1")},
}

## Padrão da camisa de cada clube: [estilo, cor secundária]. Clubes ausentes usam camisa lisa.
const UNIFORMES := {
	"atl_metropolitano": ["listras", Color("111111")],
	"litoral": ["faixa", Color("111111")],
	"porto_sul": ["listras", Color("5ab0ff")],
	"leoes_agreste": ["metade", Color("f2f2f2")],
	"operario_leste": ["listras", Color("f2f2f2")],
	"cerrado": ["faixa", Color("ffd600")],
	"ferroviario": ["faixa", Color("f2f2f2")],
	"vila_operaria": ["listras", Color("f2f2f2")],
	"sporting_atlantico": ["faixa", Color("f2f2f2")],
	"sc_douro": ["metade", Color("1a1a1a")],
	"atletico_mediterraneo": ["listras", Color("f2f2f2")],
	"inter_lucenzo": ["listras", Color("111111")],
	"ac_varenna": ["listras", Color("111111")],
	"sv_nordhafen": ["listras", Color("111111")],
	"paris_lumiere": ["faixa", Color("d32f2f")],
	"al_sahel": ["faixa", Color("0d47a1")],
	"lone_star": ["metade", Color("f2f2f2")],
	"jardim": ["listras", Color("f2f2f2")],
}


static func uniforme(id: String) -> Array:
	return UNIFORMES.get(id, ["liso", Color.WHITE])

const PAISES := {
	"br": {"nome": "Brasil", "liga": "Campeonato Nacional", "salario": 1.0},
	"pt": {"nome": "Portugal", "liga": "Liga Lusitana", "salario": 1.4},
	"es": {"nome": "Espanha", "liga": "Liga Ibérica", "salario": 2.4},
	"en": {"nome": "Inglaterra", "liga": "Premier Insular", "salario": 2.8},
	"it": {"nome": "Itália", "liga": "Lega Peninsulare", "salario": 2.2},
	"de": {"nome": "Alemanha", "liga": "Liga Germânica", "salario": 2.2},
	"fr": {"nome": "França", "liga": "Liga Francófona", "salario": 2.0},
	"ar": {"nome": "Golfo Arábico", "liga": "Liga do Golfo", "salario": 3.2},
	"us": {"nome": "Estados Unidos", "liga": "Liga América", "salario": 1.8},
}

## Clubes genéricos para completar ligas estrangeiras.
const ENCHIMENTO := {
	"pt": ["Académica do Mondego", "Vitória Atlântica", "Marítimo Insular", "Estoril Praia Sol", "Braga Nova", "Gil Vicente Mar", "Farense Sul"],
	"es": ["CD Montserra", "Real Oviedo Norte", "UD Las Brisas", "SD Navarra", "Racing Cantábrico", "CD Tenerife Alto", "Elche Levante"],
	"en": ["Dockside FC", "Harbour Town", "Elmfield Athletic", "Westmoor", "Oakham Wanderers", "Kingsport", "Ashbury Town"],
	"it": ["SS Tiberina", "Calcio Laguna", "US Monteverde", "AS Sorrentina", "FC Dolomiti", "Torino Alpi", "Genova Porto"],
	"de": ["SC Waldberg", "TSV Altstadt", "VfB Seehafen", "FC Bergland", "Union Ostmark", "Hertha Spree", "Kickers Main"],
	"fr": ["FC Bretagne Mer", "AS Provence", "Stade Lumière", "RC Alsacienne", "US Garonne", "Nantes Atlantique", "Lille Nord"],
	"ar": ["Al-Waha", "Al-Fajr", "Al-Qamar", "Al-Bahr", "Al-Rimal", "Al-Nakheel", "Al-Majd"],
	"us": ["Desert Sun FC", "Lakeshore United", "Golden Bay", "Mountain Peak SC", "River City", "Capital FC", "Northwest Timber"],
}

const NOMES_COMPANHEIROS := ["Dudu", "Tico", "Biel", "Kaique", "Rafinha", "Léo", "Matheuzinho", "Vini", "Caio", "Pedrinho",
	"Gabigol", "Thiaguinho", "Ruan", "Igor", "Wesley", "Lucão", "Davi", "Nathan", "Cauã", "Enzo"]
const NOMES_RIVAL := ["Tavinho", "Kauã Bala", "Renan Fumaça", "Diego Trator", "Breno Flash"]
const NOMES_TECNICO := ["Professor Galvão", "Seu Arlindo", "Mister Sampaio", "Prof. Wagner", "Dona Marta"]

const AGENDA := {
	"treino_finalizacao": {"nome": "Treino de finalização", "icone": "bola", "energia": -18, "xp": {"finalizacao": 3.0, "cabeceio": 1.0}},
	"treino_drible": {"nome": "Treino de drible", "icone": "correr", "energia": -18, "xp": {"drible": 3.0, "velocidade": 1.0}},
	"treino_passe": {"nome": "Treino de passe", "icone": "troca", "energia": -16, "xp": {"passe": 3.0, "visao": 1.0}},
	"treino_fisico": {"nome": "Academia e tiros", "icone": "treino", "energia": -24, "xp": {"fisico": 3.0, "velocidade": 2.0}},
	"treino_tatico": {"nome": "Estudar vídeos de jogo", "icone": "olho", "energia": -10, "xp": {"visao": 3.0, "frieza": 1.0}},
	"cabeceio": {"nome": "Treino de cabeceio", "icone": "seta_cima", "energia": -16, "xp": {"cabeceio": 3.0, "fisico": 1.0}},
	"descansar": {"nome": "Descansar", "icone": "cama", "energia": 35, "moral": 2},
	"familia": {"nome": "Tempo com a família", "icone": "familia", "energia": 12, "moral": 6, "rel": {"familia": 9}},
	"amigos": {"nome": "Rolê com os amigos", "icone": "grupo", "energia": -4, "moral": 9, "rel": {"amigo": 8}},
	"estudar": {"nome": "Ir à escola", "icone": "escola", "energia": -6, "rel": {"familia": 6}, "xp": {"frieza": 1.5}, "fase": "base"},
	"bico": {"nome": "Ajudar em casa (bico)", "icone": "dinheiro", "energia": -14, "dinheiro": 350, "rel": {"familia": 4}, "fase": "base"},
	"redes": {"nome": "Postar nas redes", "icone": "celular", "energia": -2, "fama": 2, "moral": 2},
	"meditar": {"nome": "Respiração e foco", "icone": "zen", "energia": 6, "xp": {"frieza": 2.5}, "moral": 3},
	"psicologo": {"nome": "Psicólogo do esporte", "icone": "mente", "energia": 4, "xp": {"frieza": 3.5, "visao": 1.0}, "moral": 8, "custo": 6000, "fase": "pro"},
	"personal": {"nome": "Personal trainer", "icone": "treino", "energia": -18, "xp": {"fisico": 4.0, "velocidade": 3.0}, "custo": 12000, "fase": "pro"},
	"fisioterapia": {"nome": "Fisioterapia", "icone": "cura", "energia": 20, "cura": 1, "so_lesionado": true},
}

const COMEMORACOES := {
	"galera": {"nome": "Correr pra galera", "pose": "comemora_bracos", "icone": "grupo", "preco": 0, "efeitos": {"rel_torcida": 2}},
	"aviao": {"nome": "Aviãozinho", "pose": "comemora_aviao", "icone": "aviao", "preco": 0, "efeitos": {"fama": 1}},
	"coracao": {"nome": "Coração pra família", "pose": "comemora_coracao", "icone": "coracao", "preco": 0, "efeitos": {"rel_familia": 3, "moral": 2}},
	"joelho": {"nome": "Deslizar de joelhos", "pose": "comemora_joelho", "icone": "festa", "preco": 200, "efeitos": {"rel_torcida": 4}},
	"danca": {"nome": "Dancinha viral", "pose": "comemora_danca", "icone": "musica", "preco": 300, "efeitos": {"fama": 4, "moral": 2}},
	"silencio": {"nome": "Calar o estádio", "pose": "comemora_silencio", "icone": "bloqueio", "preco": 250, "efeitos": {"fama": 5, "moral": 4, "rel_torcida": -1}},
}

const CHUTEIRAS := {
	"preta": {"nome": "Preta clássica", "cor": "111111", "preco": 0},
	"branca": {"nome": "Branca", "cor": "f2f2f2", "preco": 0},
	"laranja": {"nome": "Laranja neon", "cor": "ff6d00", "preco": 150},
	"azul": {"nome": "Azul elétrico", "cor": "2979ff", "preco": 150},
	"rosa": {"nome": "Rosa choque", "cor": "ff2d95", "preco": 200},
	"limao": {"nome": "Verde limão", "cor": "aeea00", "preco": 200},
	"relampago": {"nome": "Relâmpago", "cor": "ffe600", "preco": -1, "origem": "Pacote do Moleque"},
	"dourada": {"nome": "Dourada", "cor": "d4af37", "preco": -1, "origem": "Craque VIP"},
}

const SONHOS := {
	"profissional": {"nome": "Assinar o primeiro contrato profissional", "icone": "aperto", "moedas": 150},
	"carro": {"nome": "Comprar o primeiro carro", "icone": "carro", "moedas": 100, "preco": 80000},
	"casa_mae": {"nome": "Dar uma casa para a mãe", "icone": "casinha", "moedas": 300, "preco": 600000},
	"selecao": {"nome": "Ser convocado para a Seleção", "icone": "mundo", "moedas": 250},
	"exterior": {"nome": "Jogar no exterior", "icone": "aviao", "moedas": 200},
	"titulo": {"nome": "Ganhar um título profissional", "icone": "trofeu", "moedas": 200},
	"artilheiro": {"nome": "Ser artilheiro de uma temporada", "icone": "bola", "moedas": 150},
	"cem_gols": {"nome": "Marcar 100 gols na carreira", "icone": "medalha", "moedas": 300},
	"mundial": {"nome": "Ser campeão do Mundial com a Seleção", "icone": "mundo", "moedas": 500},
	"bola_cristal": {"nome": "Ganhar a Bola de Cristal", "icone": "diamante", "moedas": 800},
	"campinho": {"nome": "Reformar o campinho da Vila Esperança", "icone": "esporte", "moedas": 500, "preco": 3000000},
}

const MEMORIAS := {
	"final_bairro": {"titulo": "A final do bairro", "desc": "Gol na final da Copa da Vila, com os olheiros na arquibancada."},
	"primeiro_gol": {"titulo": "O primeiro de muitos", "desc": "Primeiro gol com a camisa de um clube."},
	"cobertura": {"titulo": "Por cima do goleiro", "desc": "Encobriu o goleiro adiantado."},
	"cavadinha": {"titulo": "Cavadinha", "desc": "Pênalti de cavadinha, com toda a frieza do mundo."},
	"falta": {"titulo": "Na gaveta", "desc": "Gol de falta por cima da barreira."},
	"cabeca": {"titulo": "Testada certeira", "desc": "Gol de cabeça."},
	"caneta": {"titulo": "Caneta e gol", "desc": "Deu uma caneta no zagueiro e marcou."},
	"lancamento": {"titulo": "Visão de jogo", "desc": "Assistência de lançamento nas costas da zaga."},
	"rival": {"titulo": "Recado ao rival", "desc": "Gol contra o time do seu maior rival."},
	"virada": {"titulo": "A virada", "desc": "Gol da virada nos minutos finais."},
	"hat_trick": {"titulo": "Hat-trick", "desc": "Três gols na mesma partida."},
	"segunda_chance": {"titulo": "E se...?", "desc": "Reviveu o lance e fez o gol."},
	"final": {"titulo": "Gol de título", "desc": "Gol numa final."},
	"estreia_pro": {"titulo": "Estreia de gala", "desc": "Gol como profissional."},
	"exterior": {"titulo": "Do bairro para o mundo", "desc": "Primeiro gol no exterior."},
	"selecao": {"titulo": "Com a amarelinha", "desc": "Gol pela Seleção."},
	"bicicleta": {"titulo": "De bicicleta", "desc": "Gol de bicicleta num escanteio."},
	"voleio": {"titulo": "De primeira", "desc": "Gol de voleio depois de um lançamento."},
	"salvou_defesa": {"titulo": "Atacante que marca", "desc": "Voltou para defender no fim do jogo e segurou o resultado."},
}

const PATROCINADORES := ["Raio Energético", "Tênis Pulso", "Guaraná Serra", "Banco Alvorada", "Telecom Vox", "Relógios Kairós"]

## Eventos narrativos (cartas). Placeholders: {apelido} {amigo} {rival} {clube} {mae} {tecnico} {empresario} {patrocinador}
## cond: fase (base/pro), idade_min/max, fama_min, flag, sem_flag, lesionado, dinheiro_min, clube_tier_min
## efeitos: energia moral fama dinheiro rel_* xp_* flag/remove_flag lesao(semanas) moedas
const EVENTOS := [
	{"id": "mae_onibus", "fase": "base", "unico": true, "peso": 6, "personagem": "familia",
		"titulo": "A passagem do ônibus", "texto": "{mae} juntou as moedas da semana para pagar sua passagem até o CT. \"Vai lá e mostra quem você é, meu filho.\"",
		"opcoes": [
			{"texto": "Prometer que um dia retribui tudo", "efeitos": {"moral": 10, "rel_familia": 10, "flag": "promessa_mae"}, "resultado": "Você guarda essa promessa no peito. Um dia, uma casa pra ela."},
			{"texto": "Dizer que vai a pé para ela economizar", "efeitos": {"energia": -15, "rel_familia": 6, "xp_fisico": 2}, "resultado": "Uma hora e meia de caminhada. As pernas doem, mas o coração está leve."}]},
	{"id": "juninho_peneira", "fase": "base", "unico": true, "peso": 6, "personagem": "amigo", "idade_max": 16,
		"titulo": "O {amigo} não passou", "texto": "{amigo} foi reprovado na peneira do {clube}. Ele está arrasado. Você pode pedir ao {tecnico} uma nova chance para ele.",
		"opcoes": [
			{"texto": "Pedir ao técnico (arriscado)", "chance": 0.55,
				"sucesso": {"efeitos": {"rel_amigo": 20, "rel_tecnico": -2, "flag": "amigo_no_clube"}, "resultado": "O técnico deu mais uma chance... e o {amigo} arrebentou! Vocês vão jogar juntos."},
				"falha": {"efeitos": {"rel_tecnico": -8, "rel_amigo": 8}, "resultado": "\"Aqui quem escolhe sou eu, moleque.\" O técnico não gostou nada."}},
			{"texto": "Consolar o amigo e seguir em frente", "efeitos": {"rel_amigo": 5, "moral": -3}, "resultado": "Ele entende. Mas a amizade sente o baque."}]},
	{"id": "festa_vespera", "fase": "any", "peso": 5, "personagem": "amigo",
		"titulo": "Festa na véspera", "texto": "O pessoal vai fazer um churrasco com pagode até tarde, justo na véspera do jogo. \"Bora, só um pouquinho!\"",
		"opcoes": [
			{"texto": "Ir e voltar cedo", "chance": 0.6,
				"sucesso": {"efeitos": {"moral": 8, "rel_amigo": 8, "energia": -5}, "resultado": "Voltou cedo de verdade. Cabeça leve para o jogo."},
				"falha": {"efeitos": {"moral": 4, "energia": -30, "rel_tecnico": -6}, "resultado": "\"Só mais uma música\"... Chegou às 3h. O técnico percebeu as olheiras."}},
			{"texto": "Ficar em casa e dormir cedo", "efeitos": {"energia": 15, "rel_amigo": -4, "xp_frieza": 1}, "resultado": "Foco total. Os amigos zoaram, mas você dormiu como um anjo."}]},
	{"id": "empresario_marcao", "fase": "any", "unico": true, "peso": 6, "personagem": "empresario", "idade_min": 16, "fama_min": 8,
		"titulo": "O empresário {empresario}", "texto": "Um homem de óculos escuros e corrente de ouro te procura: \"Sou o {empresario}. Coloco você na Europa em dois anos. É só assinar com 20% pra mim.\"",
		"opcoes": [
			{"texto": "Assinar com ele", "efeitos": {"flag": "empresario", "dinheiro": 2000, "moral": 5}, "resultado": "Ele te deu um tênis novo e um contrato de 12 páginas. Agora você tem empresário: as propostas tendem a ser melhores."},
			{"texto": "Pedir para a família ler o contrato antes", "efeitos": {"rel_familia": 8, "xp_frieza": 1}, "resultado": "{mae} achou tudo muito estranho. Melhor esperar."}]},
	{"id": "jornalista_rival", "fase": "any", "peso": 4, "personagem": "imprensa", "fama_min": 10,
		"titulo": "Pergunta sobre o rival", "texto": "Um repórter enfia o microfone na sua cara: \"O {rival} disse que você só joga no bairro. O que responde?\"",
		"opcoes": [
			{"texto": "\"Responde em campo.\"", "efeitos": {"fama": 3, "xp_frieza": 1.5}, "resultado": "Resposta curta e certeira. Viralizou nas redes."},
			{"texto": "Provocar de volta", "efeitos": {"fama": 6, "moral": 4, "rel_tecnico": -4, "flag": "rixa_rival"}, "resultado": "A frase virou manchete. O clássico contra ele agora vale o dobro."},
			{"texto": "Elogiar o rival", "efeitos": {"fama": 1, "rel_torcida": 3}, "resultado": "Atitude de craque. A torcida gostou."}]},
	{"id": "lesao_leve", "fase": "any", "peso": 3, "personagem": "medico",
		"titulo": "Dor na coxa", "texto": "No fim do treino, aquela fisgada na coxa. O médico pede exame, mas tem jogo importante no fim de semana.",
		"opcoes": [
			{"texto": "Jogar no sacrifício", "chance": 0.5,
				"sucesso": {"efeitos": {"rel_tecnico": 6, "moral": 3}, "resultado": "Aguentou firme. O técnico elogiou sua entrega."},
				"falha": {"efeitos": {"lesao": 3, "moral": -8}, "resultado": "A fisgada virou estiramento. Três semanas fora."}},
			{"texto": "Fazer o exame e se poupar", "efeitos": {"energia": 20, "rel_tecnico": -2}, "resultado": "Nada grave. Melhor prevenir."}]},
	{"id": "treino_extra_tecnico", "fase": "any", "peso": 5, "personagem": "tecnico",
		"titulo": "Proposta do técnico", "texto": "{tecnico}: \"Fica depois do treino. Quero te ensinar uma coisa que ninguém aprende na escolinha.\"",
		"opcoes": [
			{"texto": "Ficar (treino de visão de jogo)", "efeitos": {"energia": -15, "xp_visao": 4, "rel_tecnico": 8}, "resultado": "Ele te mostrou como ler a defesa antes da bola chegar. Os olhos agora veem mais."},
			{"texto": "Ficar (treino de frieza)", "efeitos": {"energia": -12, "xp_frieza": 4, "rel_tecnico": 8}, "resultado": "Pênaltis com a torcida xingando no alto-falante. Agora a pressão pesa menos."},
			{"texto": "Agradecer, mas descansar", "efeitos": {"energia": 10, "rel_tecnico": -3}, "resultado": "Ele deu de ombros. Oportunidades não batem duas vezes."}]},
	{"id": "patrocinio_tenis", "fase": "any", "peso": 4, "personagem": "patrocinador", "fama_min": 18, "unico": true,
		"titulo": "Proposta de patrocínio", "texto": "A {patrocinador} quer você como garoto-propaganda. Pagam bem, mas o contrato exige muitas gravações.",
		"opcoes": [
			{"texto": "Aceitar", "efeitos": {"flag": "patrocinador", "dinheiro": 15000, "fama": 6, "energia": -10}, "resultado": "Contrato assinado! Agora você pode gravar comerciais toda semana (na aba Vida)."},
			{"texto": "Recusar e focar no futebol", "efeitos": {"moral": 3, "xp_frieza": 1}, "resultado": "Primeiro a bola. O dinheiro vem depois."}]},
	{"id": "mae_doente", "fase": "any", "peso": 3, "personagem": "familia", "unico": true, "idade_min": 17,
		"titulo": "Notícia de casa", "texto": "{mae} foi internada com uma infecção. Ela diz no telefone que está bem e que você não precisa vir.",
		"opcoes": [
			{"texto": "Ir para casa (perde a semana)", "efeitos": {"rel_familia": 20, "energia": -10, "rel_tecnico": -3, "moral": 5}, "resultado": "Você segurou a mão dela no hospital. Ela já está sorrindo de novo."},
			{"texto": "Pagar o melhor hospital", "cond_dinheiro": 20000, "efeitos": {"dinheiro": -20000, "rel_familia": 12, "moral": 4}, "resultado": "Ela foi transferida para um quarto particular. Alívio."},
			{"texto": "Ficar e jogar por ela", "efeitos": {"moral": -4, "rel_familia": -6, "xp_frieza": 2}, "resultado": "Você joga com o nome dela escrito na munhequeira."}]},
	{"id": "redes_polemica", "fase": "any", "peso": 3, "personagem": "imprensa", "fama_min": 15,
		"titulo": "Vídeo antigo vazou", "texto": "Um vídeo seu zoando o próprio clube, de anos atrás, está circulando. A torcida está irritada.",
		"opcoes": [
			{"texto": "Pedir desculpas publicamente", "efeitos": {"rel_torcida": 4, "fama": -1, "moral": -2}, "resultado": "A maioria aceitou. Ainda tem gente pegando no pé."},
			{"texto": "Ignorar", "efeitos": {"rel_torcida": -8, "moral": -3}, "resultado": "A cada jogo, a vaia vem mais alta."}]},
	{"id": "crianca_fa", "fase": "any", "peso": 4, "personagem": "torcida", "fama_min": 12,
		"titulo": "O pequeno fã", "texto": "Um menino de 9 anos, com sua camisa feita a caneta, espera na grade do CT só para te ver.",
		"opcoes": [
			{"texto": "Dar sua chuteira para ele", "efeitos": {"rel_torcida": 6, "fama": 3, "moral": 8}, "resultado": "Os olhos dele brilharam. Você lembrou de quando era você na grade."},
			{"texto": "Tirar uma foto rápida", "efeitos": {"rel_torcida": 2, "fama": 1}, "resultado": "Ele vai guardar essa foto para sempre."}]},
	{"id": "rival_mensagem", "fase": "any", "peso": 3, "personagem": "rival", "flag": "rixa_rival",
		"titulo": "Mensagem do {rival}", "texto": "O {rival} manda mensagem: \"Domingo eu vou te deixar no chão de novo, que nem na Copa da Vila.\"",
		"opcoes": [
			{"texto": "Responder com um emoji de palhaço", "efeitos": {"moral": 6, "fama": 2}, "resultado": "Print, story, repost. A internet adorou."},
			{"texto": "Mostrar ao técnico e treinar mais", "efeitos": {"xp_drible": 3, "rel_tecnico": 4, "energia": -10}, "resultado": "Raiva convertida em treino."}]},
	{"id": "bolsa_estudos", "fase": "base", "peso": 3, "personagem": "familia", "unico": true,
		"titulo": "Prova de recuperação", "texto": "A escola avisa: se você não passar na recuperação, perde a bolsa. A prova cai no dia do treino.",
		"opcoes": [
			{"texto": "Fazer a prova", "efeitos": {"rel_familia": 12, "rel_tecnico": -4, "flag": "estudou"}, "resultado": "Nota 7,5! {mae} colou a prova na geladeira."},
			{"texto": "Ir para o treino", "efeitos": {"rel_familia": -10, "rel_tecnico": 5, "xp_finalizacao": 2}, "resultado": "O futebol é sua prioridade. A família ficou preocupada."}]},
	{"id": "dieta", "fase": "any", "peso": 4, "personagem": "medico",
		"titulo": "A nutricionista", "texto": "A nutricionista do clube monta uma dieta rígida: sem refrigerante, sem pastel, sem açaí com leite condensado.",
		"opcoes": [
			{"texto": "Seguir à risca", "efeitos": {"xp_fisico": 3, "moral": -3, "energia": 8}, "resultado": "Duas semanas depois, o corpo agradece."},
			{"texto": "Seguir... mais ou menos", "efeitos": {"xp_fisico": 1, "moral": 3}, "resultado": "Um pastel de vez em quando ninguém é de ferro."}]},
	{"id": "convite_capitao", "fase": "any", "peso": 3, "personagem": "tecnico", "idade_min": 18, "unico": true,
		"titulo": "A braçadeira", "texto": "{tecnico} te chama: \"O capitão se machucou. Quero você com a braçadeira no próximo jogo.\"",
		"opcoes": [
			{"texto": "Aceitar com orgulho", "efeitos": {"moral": 10, "rel_tecnico": 6, "fama": 3, "xp_frieza": 2}, "resultado": "A braçadeira pesa, mas te faz crescer."},
			{"texto": "Sugerir um jogador mais experiente", "efeitos": {"rel_tecnico": 2, "rel_torcida": 2}, "resultado": "Humildade reconhecida pelo grupo."}]},
	{"id": "aposta", "fase": "pro", "peso": 2, "personagem": "empresario", "unico": true,
		"titulo": "Proposta suspeita", "texto": "Um desconhecido oferece R$ 50 mil para você levar um cartão amarelo no próximo jogo.",
		"opcoes": [
			{"texto": "Recusar e denunciar", "efeitos": {"fama": 8, "rel_torcida": 8, "moral": 5}, "resultado": "A denúncia derrubou um esquema de apostas. Você virou exemplo."},
			{"texto": "Recusar em silêncio", "efeitos": {"moral": -2}, "resultado": "Você bloqueia o número. O estômago fica embrulhado por dias."}]},
	{"id": "fa_clube_bairro", "fase": "any", "peso": 3, "personagem": "torcida", "fama_min": 25,
		"titulo": "A Vila assiste", "texto": "Mandaram um vídeo: o bar do Zé lotado, todo mundo da Vila Esperança assistindo ao seu jogo no telão.",
		"opcoes": [
			{"texto": "Mandar um áudio para a galera", "efeitos": {"moral": 10, "rel_torcida": 3}, "resultado": "O áudio tocou no alto-falante da laje. Gritaria geral."},
			{"texto": "Prometer um gol para eles", "efeitos": {"moral": 6, "flag": "promessa_gol"}, "resultado": "Promessa feita. Agora é cumprir."}]},
	{"id": "proposta_relampago", "fase": "pro", "peso": 2, "personagem": "empresario", "fama_min": 40,
		"titulo": "Proposta milionária", "texto": "{empresario} liga eufórico: \"Tem clube do Golfo pagando o triplo. Mas é longe de tudo... e a liga é fraca.\"",
		"opcoes": [
			{"texto": "Ouvir no fim da temporada", "efeitos": {"flag": "interesse_golfo"}, "resultado": "A proposta vai aparecer na janela de transferências."},
			{"texto": "Nem pensar, meu sonho é a Europa", "efeitos": {"moral": 3}, "resultado": "Ambição é combustível."}]},
	{"id": "garoto_base", "fase": "pro", "peso": 3, "personagem": "torcida", "idade_min": 27,
		"titulo": "O garoto da base", "texto": "Um moleque de 15 anos da base te pede dicas. Ele lembra muito você naquela final do bairro.",
		"opcoes": [
			{"texto": "Treinar com ele depois do expediente", "efeitos": {"energia": -10, "rel_tecnico": 4, "xp_visao": 2, "moral": 8}, "resultado": "Ensinar também é aprender."},
			{"texto": "Dar um conselho e um abraço", "efeitos": {"moral": 4}, "resultado": "\"Olha pra cima antes de receber a bola.\" Ele nunca vai esquecer."}]},
	{"id": "veterano_corpo", "fase": "pro", "peso": 3, "personagem": "medico", "idade_min": 31,
		"titulo": "O corpo cobra", "texto": "O joelho estala na escada. O preparador sugere reduzir a carga e cuidar do corpo.",
		"opcoes": [
			{"texto": "Fazer o tratamento completo", "efeitos": {"energia": 15, "dinheiro": -15000, "moral": 2}, "resultado": "Fisioterapia, gelo, pilates. Ainda tem lenha pra queimar."},
			{"texto": "Treinar normalmente", "chance": 0.6,
				"sucesso": {"efeitos": {"xp_fisico": 2}, "resultado": "Aguentou bem. Por enquanto."},
				"falha": {"efeitos": {"lesao": 4, "moral": -6}, "resultado": "O joelho não aguentou. Quatro semanas fora."}}]},
	{"id": "mae_casa", "fase": "pro", "peso": 4, "personagem": "familia", "flag": "promessa_mae", "sem_flag": "sonho_casa_mae", "dinheiro_min": 600000, "unico": true,
		"titulo": "A promessa", "texto": "Você passa em frente a uma casa à venda com quintal e pé de manga. É a casa que {mae} sempre sonhou.",
		"opcoes": [
			{"texto": "Comprar a casa (R$ 600 mil)", "efeitos": {"dinheiro": -600000, "rel_familia": 40, "moral": 20, "sonho": "casa_mae"}, "resultado": "{mae} chorou na porta. \"Eu sempre soube, meu filho.\" Promessa cumprida."},
			{"texto": "Ainda não", "efeitos": {}, "resultado": "Um dia. Em breve."}]},
	{"id": "documentario", "fase": "pro", "peso": 2, "personagem": "imprensa", "fama_min": 55, "unico": true,
		"titulo": "Documentário", "texto": "Uma plataforma de streaming quer gravar um documentário sobre sua vida, da Vila Esperança até aqui.",
		"opcoes": [
			{"texto": "Aceitar e abrir sua vida", "efeitos": {"fama": 12, "dinheiro": 300000, "energia": -15}, "resultado": "\"Da Vila para o Mundo\" virou o mais assistido da semana."},
			{"texto": "Preferir a privacidade", "efeitos": {"moral": 4, "rel_familia": 5}, "resultado": "Algumas histórias são só suas."}]},
	{"id": "vaias", "fase": "any", "peso": 3, "personagem": "torcida", "forma_max": 5.8,
		"titulo": "Vaias", "texto": "Depois das últimas atuações, parte da torcida te vaiou no aquecimento.",
		"opcoes": [
			{"texto": "Treinar dobrado para reagir", "efeitos": {"energia": -20, "xp_finalizacao": 2, "xp_drible": 2, "moral": -2}, "resultado": "Quem tem caráter, reage."},
			{"texto": "Conversar com o psicólogo do clube", "efeitos": {"moral": 8, "xp_frieza": 2}, "resultado": "Você entendeu que a vaia é sobre o resultado, não sobre você."}]},
	{"id": "irmao_chuteira", "fase": "any", "peso": 3, "personagem": "familia", "unico": true,
		"titulo": "O irmão caçula", "texto": "Seu irmão de 8 anos quer uma chuteira de verdade para jogar na escolinha da Vila.",
		"opcoes": [
			{"texto": "Comprar a melhor chuteira (R$ 900)", "cond_dinheiro": 900, "efeitos": {"dinheiro": -900, "rel_familia": 10, "moral": 6}, "resultado": "Ele dormiu de chuteira. Literalmente."},
			{"texto": "Dar a sua chuteira velha", "efeitos": {"rel_familia": 5, "moral": 3}, "resultado": "\"É a chuteira da final!\" Ele não poderia estar mais feliz."}]},
	{"id": "seca_gols", "fase": "any", "peso": 3, "personagem": "tecnico", "sem_gols": 3,
		"titulo": "Seca de gols", "texto": "Três jogos sem marcar. {tecnico}: \"Para de pensar e chuta.\"",
		"opcoes": [
			{"texto": "Treinar finalização até cansar", "efeitos": {"xp_finalizacao": 4, "energia": -18}, "resultado": "Quinhentos chutes. A rede vai sentir."},
			{"texto": "Rever seus gols antigos", "efeitos": {"moral": 10}, "resultado": "Você lembrou quem é. A confiança voltou."}]},
	{"id": "mundial_convocacao", "fase": "any", "peso": 0, "personagem": "imprensa",
		"titulo": "Convocado!", "texto": "Seu nome foi chamado para a Seleção. O celular não para de tocar.",
		"opcoes": [{"texto": "Ligar para {mae}", "efeitos": {"moral": 15, "rel_familia": 10}, "resultado": "Ela gritou tanto que a vizinhança inteira descobriu."}]},
	{"id": "contusao_rival", "fase": "pro", "peso": 2, "personagem": "rival", "unico": true,
		"titulo": "O rival se machucou", "texto": "O {rival} rompeu o ligamento e vai ficar meses parado. A imprensa pede uma palavra sua.",
		"opcoes": [
			{"texto": "Mandar força publicamente", "efeitos": {"fama": 4, "rel_torcida": 5, "moral": 3, "remove_flag": "rixa_rival"}, "resultado": "Rivais em campo, irmãos de origem. Ele te agradeceu em particular."},
			{"texto": "Não comentar", "efeitos": {}, "resultado": "Silêncio às vezes é respeito."}]},
	{"id": "noite_sem_sono", "fase": "any", "peso": 3, "personagem": "familia",
		"titulo": "Insônia", "texto": "A cabeça não para: contrato, família, jogo. São 3h da manhã e você está olhando o teto.",
		"opcoes": [
			{"texto": "Ligar para o {amigo}", "efeitos": {"rel_amigo": 6, "moral": 6, "energia": -5}, "resultado": "Ele contou piada até você dormir no telefone."},
			{"texto": "Fazer exercício de respiração", "efeitos": {"xp_frieza": 2.5, "energia": 5}, "resultado": "4 segundos inspira, 7 segura, 8 solta. Dormiu."}]},
	{"id": "carro_ostentacao", "fase": "pro", "peso": 2, "personagem": "amigo", "dinheiro_min": 200000,
		"titulo": "O carro importado", "texto": "O {amigo} te manda foto de um esportivo amarelo: \"Agora você pode, irmão!\"",
		"opcoes": [
			{"texto": "Comprar (R$ 180 mil)", "efeitos": {"dinheiro": -180000, "fama": 4, "moral": 6, "rel_familia": -4}, "resultado": "Lindo. {mae} achou um exagero."},
			{"texto": "Investir o dinheiro", "efeitos": {"dinheiro": 25000, "rel_familia": 4}, "resultado": "Um consultor aplicou bem. Seu eu de 35 anos agradece."}]},
	{"id": "campinho_abandonado", "fase": "pro", "peso": 3, "personagem": "torcida", "sem_flag": "sonho_campinho", "unico": true, "idade_min": 22,
		"titulo": "O campinho", "texto": "Fotos do campinho da Vila Esperança: trave enferrujada, mato alto. A molecada não tem onde jogar.",
		"opcoes": [
			{"texto": "Prometer reformar (sonho)", "efeitos": {"flag": "promessa_campinho", "moral": 5}, "resultado": "O sonho entrou na sua lista. Custa R$ 3 milhões (aba Vida)."},
			{"texto": "Doar uniformes por enquanto", "efeitos": {"dinheiro": -5000, "rel_torcida": 4, "fama": 2}, "resultado": "Os moleques mandaram vídeo agradecendo."}]},
	{"id": "renovacao_antecipada", "fase": "pro", "peso": 3, "personagem": "diretoria", "forma_min": 7.2, "sem_flag": "renovou_antes",
		"titulo": "A diretoria quer renovar", "texto": "O presidente do {clube} te chama na sala dele: \"Você é o futuro deste clube. Vamos renovar agora, com aumento de 20%?\"",
		"opcoes": [
			{"texto": "Assinar a renovação", "efeitos": {"salario_pct": 0.2, "contrato_mais": 2, "rel_diretoria": 12, "rel_torcida": 5, "flag": "renovou_antes"}, "resultado": "Caneta na mão, foto oficial. A torcida comemorou nas redes."},
			{"texto": "Pedir para esperar o fim da temporada", "efeitos": {"rel_diretoria": -3, "flag": "renovou_antes"}, "resultado": "\"Você que sabe. A porta está aberta... por enquanto.\""}]},
	{"id": "sondagem", "fase": "pro", "peso": 3, "personagem": "empresario", "fama_min": 25, "forma_min": 6.9,
		"titulo": "Sondagem de um gigante", "texto": "{empresario} cochicha: \"Um clube enorme perguntou de você. Se você der um sinal, a proposta chega na janela.\"",
		"opcoes": [
			{"texto": "Dar o sinal", "efeitos": {"flag": "sondado", "rel_diretoria": -4, "moral": 5}, "resultado": "A proposta deve aparecer no fim da temporada. A diretoria já desconfia."},
			{"texto": "Focar no clube atual", "efeitos": {"rel_diretoria": 6, "rel_torcida": 3}, "resultado": "Lealdade também constrói carreira."}]},
	{"id": "presidente_cobra", "fase": "any", "peso": 3, "personagem": "diretoria", "forma_max": 5.9,
		"titulo": "Cobrança da diretoria", "texto": "O diretor de futebol aparece no treino: \"O investimento em você precisa dar retorno. Quero ver reação.\"",
		"opcoes": [
			{"texto": "Prometer reação", "efeitos": {"moral": -2, "xp_frieza": 1.5, "rel_diretoria": 2}, "resultado": "Pressão é combustível. Agora é cumprir."},
			{"texto": "Responder que o problema é o esquema tático", "efeitos": {"rel_diretoria": -6, "rel_tecnico": -8, "fama": 2}, "resultado": "O técnico ficou sabendo. O clima esquentou."}]},
]
