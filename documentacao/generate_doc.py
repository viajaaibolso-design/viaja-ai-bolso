#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gerador da documentação técnica e funcional do projeto Viajaí Bolso (viaja_ai_app).
Reconstrói o PDF cumulativo a partir do estado atual descrito abaixo + changelog_data.json.

Uso:
    python3 generate_doc.py
Gera: documentacao_projeto.pdf

Observação: este script usa a biblioteca "reportlab" (Python). Se seu ambiente local
não tiver Python/reportlab instalado, peça para o Claude regenerar o PDF na próxima
conversa — ele roda este mesmo script no ambiente de nuvem e devolve o PDF atualizado
aqui na pasta documentacao/.
"""

import json
import os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle,
    ListFlowable, ListItem, HRFlowable, KeepTogether
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY

HERE = os.path.dirname(os.path.abspath(__file__))
OUTPUT_PATH = os.path.join(HERE, "documentacao_projeto.pdf")
CHANGELOG_PATH = os.path.join(HERE, "changelog_data.json")

# Paleta baseada em lib/constants.dart do próprio app
PRIMARY = colors.HexColor("#007B6E")
PRIMARY_LIGHT = colors.HexColor("#00A896")
TEXT_DARK = colors.HexColor("#1A1A2E")
TEXT_GREY = colors.HexColor("#6B6B6B")
BG_LIGHT = colors.HexColor("#F5F5F5")
WARN = colors.HexColor("#B45309")

styles = getSampleStyleSheet()

styles.add(ParagraphStyle(
    name="CoverTitle", fontName="Helvetica-Bold", fontSize=28,
    textColor=PRIMARY, alignment=TA_CENTER, leading=34, spaceAfter=6,
))
styles.add(ParagraphStyle(
    name="CoverSubtitle", fontName="Helvetica", fontSize=14,
    textColor=TEXT_GREY, alignment=TA_CENTER, leading=20, spaceAfter=4,
))
styles.add(ParagraphStyle(
    name="CoverMeta", fontName="Helvetica", fontSize=11,
    textColor=TEXT_DARK, alignment=TA_CENTER, leading=16,
))
styles.add(ParagraphStyle(
    name="H1", fontName="Helvetica-Bold", fontSize=17,
    textColor=PRIMARY, spaceBefore=18, spaceAfter=10,
))
styles.add(ParagraphStyle(
    name="H2", fontName="Helvetica-Bold", fontSize=13,
    textColor=TEXT_DARK, spaceBefore=12, spaceAfter=6,
))
styles.add(ParagraphStyle(
    name="H3", fontName="Helvetica-Bold", fontSize=11,
    textColor=PRIMARY_LIGHT, spaceBefore=8, spaceAfter=4,
))
styles.add(ParagraphStyle(
    name="BodyText2", fontName="Helvetica", fontSize=9.7,
    textColor=TEXT_DARK, leading=14, alignment=TA_JUSTIFY, spaceAfter=6,
))
styles.add(ParagraphStyle(
    name="BulletText", fontName="Helvetica", fontSize=9.7,
    textColor=TEXT_DARK, leading=13.5, alignment=TA_LEFT,
))
styles.add(ParagraphStyle(
    name="Small", fontName="Helvetica", fontSize=8.3,
    textColor=TEXT_GREY, leading=11,
))
styles.add(ParagraphStyle(
    name="CellHead", fontName="Helvetica-Bold", fontSize=8.7,
    textColor=colors.white, leading=11,
))
styles.add(ParagraphStyle(
    name="Cell", fontName="Helvetica", fontSize=8.7,
    textColor=TEXT_DARK, leading=11.5,
))
styles.add(ParagraphStyle(
    name="ChangelogTitle", fontName="Helvetica-Bold", fontSize=12,
    textColor=PRIMARY, spaceBefore=10, spaceAfter=2,
))

story = []


def h1(text):
    story.append(Paragraph(text, styles["H1"]))
    story.append(HRFlowable(width="100%", thickness=1, color=PRIMARY_LIGHT, spaceAfter=8))


def h2(text):
    story.append(Paragraph(text, styles["H2"]))


def h3(text):
    story.append(Paragraph(text, styles["H3"]))


def body(text):
    story.append(Paragraph(text, styles["BodyText2"]))


def bullets(items):
    story.append(ListFlowable(
        [ListItem(Paragraph(i, styles["BulletText"]), leftIndent=6, bulletColor=PRIMARY) for i in items],
        bulletType="bullet", start="•", leftIndent=14, spaceBefore=2, spaceAfter=8,
    ))


def make_table(header, rows, col_widths):
    data = [[Paragraph(h, styles["CellHead"]) for h in header]]
    for r in rows:
        data.append([Paragraph(str(c), styles["Cell"]) for c in r])
    t = Table(data, colWidths=col_widths, repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), PRIMARY),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, BG_LIGHT]),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#D9D9D9")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
    ]))
    story.append(t)
    story.append(Spacer(1, 10))


# =========================================================================
# CAPA
# =========================================================================
story.append(Spacer(1, 6 * cm))
story.append(Paragraph("Viajaí Bolso", styles["CoverTitle"]))
story.append(Paragraph("Documentação Técnica e Funcional do Projeto", styles["CoverSubtitle"]))
story.append(Spacer(1, 1.2 * cm))
story.append(Paragraph("App de controle de gastos em viagens — Flutter", styles["CoverMeta"]))
story.append(Spacer(1, 2 * cm))
story.append(Paragraph(
    "Projeto desenvolvido como trabalho de conclusão do 3º período do curso de "
    "Análise e Desenvolvimento de Sistemas, em fase de evolução para se tornar "
    "um aplicativo funcional completo.", styles["CoverMeta"]
))
story.append(Spacer(1, 3 * cm))
story.append(Paragraph("Documento gerado e atualizado automaticamente a cada alteração relevante no código.",
                        styles["Small"]))
story.append(PageBreak())

# =========================================================================
# 1. VISÃO GERAL
# =========================================================================
h1("1. Visão Geral do Projeto")
body(
    "O <b>Viajaí Bolso</b> é um aplicativo mobile (Flutter) para controle financeiro de viagens: "
    "o usuário cadastra viagens — cada uma com destino, período e orçamento — e registra despesas "
    "associadas a cada viagem, categorizadas (alimentação, transporte, etc.), acompanhando o quanto "
    "já foi gasto em relação ao orçamento definido."
)
body(
    "O projeto nasceu como protótipo de conclusão do 3º período do curso de Análise e Desenvolvimento "
    "de Sistemas e agora está em evolução para se tornar um aplicativo funcional completo, a ser "
    "apresentado como projeto final do curso. Este documento acompanha essa evolução: a cada mudança "
    "relevante no código, uma nova seção é adicionada ao <b>Histórico de Alterações</b> (seção 7), "
    "mantendo sempre a descrição das seções anteriores atualizada com o estado mais recente do app."
)

h2("1.1 Principais dependências (pubspec.yaml)")
make_table(
    ["Pacote", "Finalidade"],
    [
        ["http", "Comunicação com o backend via requisições REST (GET/POST/PUT/DELETE)"],
        ["shared_preferences", "Persistência local simples — usada para manter a sessão do usuário logado"],
        ["image_picker / image_picker_for_web", "Seleção de fotos (foto de perfil e foto da viagem), convertidas para base64"],
        ["intl", "Suporte a internacionalização/formatação (incluído, uso pontual)"],
    ],
    [4.5 * cm, 11 * cm],
)

h2("1.2 Arquitetura em camadas")
body(
    "O código em <font face='Courier'>lib/</font> está organizado em três camadas, sem uso de "
    "gerenciador de estado externo (Provider, Riverpod, Bloc) — o controle de estado é feito "
    "manualmente com <font face='Courier'>setState</font>:"
)
bullets([
    "<b>constants.dart</b> — configurações globais: endereço do backend e paleta de cores do app.",
    "<b>models/</b> — classes de dados puras (Despesa, Categoria, Usuario, Viagem), cada uma com "
    "método <font face='Courier'>fromJson</font> para converter a resposta da API.",
    "<b>services/</b> — camada de acesso ao backend via HTTP (AuthService, ViagemService, "
    "DespesaService, DashboardService).",
    "<b>screens/</b> — telas do app, que chamam os services diretamente (não há camada intermediária "
    "de controller/repository).",
])
body(
    "<b>Ponto de atenção técnico:</b> o endereço do backend (<font face='Courier'>baseUrl</font>) está "
    "fixo no código como um IP de rede local (<font face='Courier'>http://192.168.0.9:5000</font>), "
    "sem variável de ambiente para produção. Isso será um dos primeiros pontos a resolver na evolução "
    "do protótipo para app funcional."
)

story.append(PageBreak())

# =========================================================================
# 2. MODELOS DE DADOS
# =========================================================================
h1("2. Modelos de Dados (lib/models)")

h2("2.1 Despesa e Categoria — despesa.dart")
body("Representa uma despesa individual vinculada a uma viagem e a uma categoria.")
make_table(
    ["Campo (Despesa)", "Tipo", "Descrição"],
    [
        ["idDespesa", "int?", "Identificador único (gerado pelo backend)"],
        ["descricao", "String", "Descrição da despesa"],
        ["valor", "double", "Valor gasto"],
        ["data / hora", "String / String?", "Data e hora do gasto"],
        ["formaPagamento", "String", "Ex.: Cartão de crédito, Débito, Dinheiro, Pix, Outros"],
        ["idViagem / idCategoria", "int", "Referências à viagem e categoria associadas"],
        ["categoria / icone", "String? / String?", "Nome e ícone da categoria (retornados pelo backend)"],
    ],
    [4.5 * cm, 3 * cm, 8 * cm],
)
body("A classe <b>Categoria</b> representa uma categoria de despesa (id, nome, ícone), obtida via API.")

h2("2.2 Usuario — usuario.dart")
make_table(
    ["Campo", "Tipo", "Descrição"],
    [
        ["idUsuario", "int", "Identificador do usuário"],
        ["nome / email", "String", "Dados básicos de cadastro"],
        ["foto", "String?", "Foto de perfil (base64)"],
        ["moedaPadrao", "String", "Moeda padrão do usuário (default: 'BRL')"],
        ["token", "String?", "Token de sessão/autenticação"],
    ],
    [4.5 * cm, 3 * cm, 8 * cm],
)

h2("2.3 Viagem — viagem.dart")
make_table(
    ["Campo", "Tipo", "Descrição"],
    [
        ["idViagem", "int?", "Identificador da viagem"],
        ["nome / destino", "String", "Nome e destino da viagem"],
        ["foto", "String?", "Foto da viagem (base64)"],
        ["dataInicio / dataFim", "String", "Período da viagem (AAAA-MM-DD)"],
        ["orcamento", "double", "Orçamento definido para a viagem"],
        ["totalGasto / percentualGasto", "double", "Valores agregados calculados pelo backend"],
        ["idUsuario", "int?", "Dono da viagem"],
    ],
    [4.5 * cm, 3 * cm, 8 * cm],
)

story.append(PageBreak())

# =========================================================================
# 3. SERVIÇOS (COMUNICAÇÃO COM O BACKEND)
# =========================================================================
h1("3. Serviços — Comunicação com o Backend (lib/services)")
body(
    "Todos os serviços usam o pacote <font face='Courier'>http</font> para se comunicar com uma API "
    "REST externa (o código do backend não faz parte deste repositório Flutter). Não há banco de dados "
    "local para viagens/despesas — o app depende do backend estar acessível a cada tela."
)

h2("3.1 AuthService — autenticação e perfil")
make_table(
    ["Método", "Endpoint", "Função"],
    [
        ["cadastrar(nome, email, senha)", "POST /cadastro", "Cria uma nova conta"],
        ["login(email, senha)", "POST /login", "Autentica o usuário"],
        ["logoff(idUsuario)", "POST /logoff", "Encerra a sessão no backend"],
        ["recuperarSenha(email)", "POST /recuperar-senha", "Envia código de recuperação por e-mail"],
        ["redefinirSenha(...)", "POST /redefinir-senha", "Redefine a senha usando o código recebido"],
        ["getPerfil(idUsuario)", "GET /perfil/{id}", "Busca os dados do perfil"],
        ["atualizarPerfil(...)", "PUT /atualizarperfil", "Atualiza nome, e-mail, moeda e/ou foto"],
        ["alterarSenha(...)", "PUT /alterarsenha", "Troca a senha do usuário"],
    ],
    [5 * cm, 3.7 * cm, 6.8 * cm],
)

h2("3.2 ViagemService, DespesaService e DashboardService")
make_table(
    ["Classe / Método", "Endpoint", "Função"],
    [
        ["ViagemService.listar(idUsuario)", "GET /viagens/{id}", "Lista as viagens do usuário"],
        ["ViagemService.cadastrar / atualizar / remover", "POST/PUT/DELETE", "CRUD de viagens"],
        ["DespesaService.listar(idViagem)", "GET /despesas/{id}", "Lista despesas de uma viagem"],
        ["DespesaService.listarCategorias()", "GET /categorias", "Lista categorias disponíveis"],
        ["DespesaService.cadastrar / atualizar / remover", "POST/PUT/DELETE", "CRUD de despesas"],
        ["DashboardService.getDashboard(idUsuario)", "GET /dashboard/{id}", "Dados agregados: viagem ativa, gastos de hoje, maior gasto, últimas despesas"],
    ],
    [5.8 * cm, 3.7 * cm, 6 * cm],
)
body(
    "<b>Observação técnica:</b> nenhum serviço verifica o <font face='Courier'>statusCode</font> da "
    "resposta HTTP; o tratamento de erro é feito de forma genérica nas telas (mensagem fixa "
    "\"Erro de conexão com o servidor\"). Esse ponto é candidato a melhoria na próxima fase."
)

story.append(PageBreak())

# =========================================================================
# 4. TELAS E FUNCIONALIDADES
# =========================================================================
h1("4. Telas e Funcionalidades (lib/screens)")

screens = [
    ("SplashScreen", "Tela inicial. Exibe a logo por 2 segundos e verifica se há uma sessão salva "
     "(SharedPreferences). Se houver, leva direto ao MainScreen; senão, à tela de Login."),
    ("LoginScreen", "Login com e-mail e senha, opção de mostrar/ocultar senha, links para "
     "\"Esqueci minha senha\" e \"Cadastre-se\". Em caso de sucesso, salva a sessão localmente e "
     "abre o MainScreen."),
    ("CadastroScreen", "Cadastro de novo usuário (nome, e-mail, senha, confirmação de senha) com "
     "aceite obrigatório dos Termos de Uso (texto exibido na própria tela)."),
    ("RecuperarSenhaScreen", "Fluxo de recuperação de senha em duas etapas: solicitar código por "
     "e-mail e, em seguida, informar o código recebido junto com a nova senha."),
    ("MainScreen", "Shell de navegação principal, com barra inferior de 4 abas: Início (Dashboard), "
     "Viagens, Despesas e Perfil."),
    ("DashboardScreen", "Tela inicial pós-login: saudação personalizada, resumo da viagem ativa "
     "(gasto vs. orçamento, com indicador circular de progresso), gastos do dia, maior gasto e "
     "lista das despesas mais recentes. Suporta atualizar puxando a tela (pull-to-refresh)."),
    ("ViagensScreen", "Lista todas as viagens cadastradas em cards (foto, nome, destino, datas, "
     "progresso do orçamento), com opções de editar e excluir cada viagem, e botão para cadastrar "
     "uma nova."),
    ("NovaViagemScreen", "Formulário de criação/edição de viagem: foto (câmera/galeria), nome, "
     "destino, datas de início e fim, e orçamento."),
    ("DespesasScreen", "Seleciona uma viagem e lista suas despesas, com filtro por categoria. "
     "Permite cadastrar, editar e excluir despesas por um formulário em painel deslizante, incluindo "
     "categoria, descrição, valor, data e forma de pagamento. Mostra o total das despesas filtradas."),
    ("PerfilScreen", "Exibe e permite editar os dados do usuário (foto, nome, e-mail), alterar a "
     "senha e encerrar a sessão (logoff), limpando os dados salvos localmente."),
]

for name, desc in screens:
    story.append(KeepTogether([Paragraph(name, styles["H3"]), Paragraph(desc, styles["BodyText2"])]))

story.append(PageBreak())

# =========================================================================
# 5. FLUXO DE NAVEGAÇÃO
# =========================================================================
h1("5. Fluxo de Navegação")
body("Resumo do fluxo entre as telas do aplicativo, a partir da inicialização:")
bullets([
    "<b>Splash</b> → verifica sessão salva → <b>Login</b> (se não houver sessão) ou <b>MainScreen</b> "
    "(se já houver uma sessão salva).",
    "<b>Login</b> → sucesso leva ao <b>MainScreen</b>; \"Cadastre-se\" leva ao <b>Cadastro</b>; "
    "\"Esqueci minha senha\" leva à <b>Recuperação de Senha</b>.",
    "<b>MainScreen</b> organiza 4 abas fixas: <b>Dashboard</b> | <b>Viagens</b> (→ Nova/Editar Viagem) "
    "| <b>Despesas</b> (formulário em painel deslizante) | <b>Perfil</b>.",
    "<b>Perfil → Sair da conta</b> encerra a sessão e retorna à tela de <b>Login</b>, limpando todo o "
    "histórico de navegação.",
])

story.append(PageBreak())

# =========================================================================
# 6. ESTADO ATUAL E PONTOS DE EVOLUÇÃO
# =========================================================================
h1("6. Estado Atual e Pontos de Evolução")
body(
    "Como protótipo acadêmico, o app já demonstra o fluxo completo de cadastro, login, gestão de "
    "viagens e despesas. Os pontos abaixo estão mapeados como próximos passos para transformá-lo em "
    "um app funcional completo — úteis tanto para o planejamento das próximas entregas quanto para a "
    "banca de apresentação:"
)
bullets([
    "Endereço do backend fixo no código (IP de rede local); precisa de configuração por ambiente "
    "(desenvolvimento/produção) e uso de HTTPS.",
    "Tratamento de erros de rede é genérico (sem checagem de status HTTP nem mensagens específicas "
    "por tipo de erro).",
    "Algumas opções da interface ainda são placeholders sem função: botão \"Ver todas\" no Dashboard, "
    "filtro de despesas, e os itens \"Moeda padrão\", \"Configurações\", \"Sobre o app\" e \"Suporte\" "
    "na tela de Perfil.",
    "Termos de Uso exibidos no Cadastro são apenas um texto estático, sem uma tela própria de conteúdo "
    "legal.",
    "Não há persistência local (offline) dos dados de viagens/despesas — o app depende do backend "
    "estar sempre acessível.",
    "Os modelos de dados (Despesa, Usuario, Viagem) não possuem método toJson(); o envio de dados ao "
    "backend é remontado manualmente em cada tela.",
    "Não há rotas nomeadas nem testes automatizados no projeto até o momento.",
])

story.append(PageBreak())

# =========================================================================
# 7. HISTÓRICO DE ALTERAÇÕES
# =========================================================================
h1("7. Histórico de Alterações")
body(
    "Esta seção registra, em ordem cronológica, as mudanças feitas no projeto a partir desta "
    "documentação — servindo como registro de evolução para a apresentação final."
)

with open(CHANGELOG_PATH, encoding="utf-8") as f:
    changelog = json.load(f)

for entry in changelog:
    block = [
        Paragraph(f"Versão {entry['versao']} — {entry['titulo']}", styles["ChangelogTitle"]),
        Paragraph(f"Data: {entry['data']}", styles["Small"]),
        Spacer(1, 3),
        Paragraph(entry["resumo"], styles["BodyText2"]),
    ]
    if entry.get("mudancas"):
        block.append(ListFlowable(
            [ListItem(Paragraph(m, styles["BulletText"]), leftIndent=6, bulletColor=PRIMARY)
             for m in entry["mudancas"]],
            bulletType="bullet", start="•", leftIndent=14, spaceBefore=2, spaceAfter=4,
        ))
    story.append(KeepTogether(block))
    story.append(Spacer(1, 10))

doc = SimpleDocTemplate(
    OUTPUT_PATH, pagesize=A4,
    topMargin=2.2 * cm, bottomMargin=2 * cm, leftMargin=2 * cm, rightMargin=2 * cm,
    title="Viajaí Bolso - Documentação Técnica e Funcional",
    author="Joel Cordeiro",
)


def add_footer(canvas, doc_):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(TEXT_GREY)
    canvas.drawString(2 * cm, 1.2 * cm, "Viajaí Bolso — Documentação do Projeto")
    canvas.drawRightString(A4[0] - 2 * cm, 1.2 * cm, f"Página {doc_.page}")
    canvas.restoreState()


doc.build(story, onFirstPage=lambda c, d: None, onLaterPages=add_footer)
print(f"PDF gerado em: {OUTPUT_PATH}")
