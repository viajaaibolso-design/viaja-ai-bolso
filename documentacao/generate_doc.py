#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Gerador da documentação técnica e funcional do projeto Viajaí Bolso (viaja_ai_app).
Reconstrói o PDF cumulativo a partir do estado atual descrito abaixo + changelog_data.json.

Uso:
    python3 generate_doc.py
Gera: documentacao_projeto.pdf
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
# (atualizada na v4 para a paleta "Mapa & Bússola" do protótipo de telas)
PRIMARY = colors.HexColor("#2B4C6F")
PRIMARY_LIGHT = colors.HexColor("#5C8374")
TEXT_DARK = colors.HexColor("#2A2E35")
TEXT_GREY = colors.HexColor("#6B7178")
BG_LIGHT = colors.HexColor("#F6F2EA")
WARN = colors.HexColor("#B96550")

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
        ["supabase_flutter", "Cliente oficial do Supabase: autenticação, banco de dados (Postgres) e armazenamento de arquivos"],
        ["image_picker / image_picker_for_web", "Seleção de fotos (perfil, viagem e comprovante de despesa), enviadas ao Supabase Storage"],
        ["intl", "Suporte a internacionalização/formatação (incluído, uso pontual)"],
        ["http (v4)", "Consulta à API pública de câmbio (open.er-api.com) usada na conversão de moeda da tela inicial"],
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
    "<b>constants.dart</b> — configurações globais: URL/chave do projeto Supabase e paleta de cores do app.",
    "<b>models/</b> — classes de dados puras (Despesa, Categoria, Usuario, Viagem), cada uma com "
    "método <font face='Courier'>fromJson</font> para converter a resposta do banco.",
    "<b>services/</b> — camada de acesso ao Supabase (AuthService, ViagemService, DespesaService, "
    "DashboardService, StorageService) e à API de câmbio (CurrencyService, v4), usando "
    "<font face='Courier'>supabase_flutter</font> e <font face='Courier'>http</font>.",
    "<b>utils/</b> (v4) — funções auxiliares puras, sem estado: lista de moedas e formatação de valores "
    "(moedas.dart) e geração do CSV de exportação de despesas (exportacao.dart).",
    "<b>screens/</b> — telas do app, que chamam os services diretamente (não há camada intermediária "
    "de controller/repository).",
])
body(
    "<b>Atualização (v2):</b> o app não depende mais de um servidor próprio — desde a migração para o "
    "Supabase (seção 7, versão 2), o backend é hospedado, acessado sempre via HTTPS, com a segurança de "
    "cada usuário só acessar os próprios dados garantida por políticas de Row Level Security (RLS) "
    "diretamente no banco (ver <font face='Courier'>supabase/schema.sql</font>)."
)

h2("1.3 Acesso direto ao app (versão web)")
body(
    "<b>Atualização (v3):</b> a cada atualização enviada ao repositório, o GitHub Actions gera "
    "automaticamente a versão web do app e publica no GitHub Pages, gerando um link direto para "
    "acesso pelo navegador, sem necessidade de instalar nada — útil para demonstração na banca "
    "(ver seção 7, versão 3):"
)
bullets([
    "<font face='Courier'>https://viajaaibolso-design.github.io/viaja-ai-bolso/</font>",
])

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
        ["idDespesa", "String?", "Identificador único (uuid gerado pelo Supabase)"],
        ["descricao", "String", "Descrição da despesa"],
        ["valor", "double", "Valor gasto"],
        ["data / hora", "String / String?", "Data e hora do gasto"],
        ["formaPagamento", "String", "Ex.: Cartão de crédito, Débito, Dinheiro, Pix, Outros"],
        ["idViagem / idCategoria", "String", "Referências (uuid) à viagem e categoria associadas"],
        ["categoria / icone", "String? / String?", "Nome e ícone da categoria (via join com categorias)"],
        ["fotoUrl (v4)", "String?", "URL do comprovante anexado (Supabase Storage), RF22"],
    ],
    [4.5 * cm, 3 * cm, 8 * cm],
)
body("A classe <b>Categoria</b> representa uma categoria de despesa (id, nome, ícone), lida do banco.")

h2("2.2 Usuario — usuario.dart")
make_table(
    ["Campo", "Tipo", "Descrição"],
    [
        ["idUsuario", "String", "Identificador do usuário (uuid do Supabase Auth)"],
        ["nome / email", "String", "Dados básicos de cadastro"],
        ["fotoUrl", "String?", "URL pública da foto de perfil no Supabase Storage"],
        ["moedaPadrao", "String", "Moeda padrão do usuário (default: 'BRL') — RF29, também usada na conversão da home (RF46)"],
        ["viagemAtivaId (v4)", "String?", "Viagem escolhida manualmente como ativa no dashboard (RF14); null = automático"],
    ],
    [4.5 * cm, 3 * cm, 8 * cm],
)

h2("2.3 Viagem — viagem.dart")
make_table(
    ["Campo", "Tipo", "Descrição"],
    [
        ["idViagem", "String?", "Identificador da viagem (uuid)"],
        ["nome / destino", "String", "Nome e destino da viagem"],
        ["fotoUrl", "String?", "URL pública da foto da viagem no Supabase Storage"],
        ["dataInicio / dataFim", "String", "Período da viagem (AAAA-MM-DD)"],
        ["orcamento", "double", "Orçamento definido para a viagem"],
        ["totalGasto / percentualGasto", "double", "Valores agregados, calculados pela view viagens_resumo no banco"],
        ["idUsuario", "String?", "Dono da viagem"],
        ["moedaLocal (v4)", "String", "Moeda do destino (default: 'BRL') — RF45, definida ao cadastrar a viagem"],
    ],
    [4.5 * cm, 3 * cm, 8 * cm],
)

story.append(PageBreak())

# =========================================================================
# 3. SERVIÇOS (SUPABASE)
# =========================================================================
h1("3. Serviços — Integração com o Supabase (lib/services)")
body(
    "Desde a versão 2 (seção 7), os serviços não fazem mais requisições HTTP a um servidor próprio: "
    "eles usam o cliente <font face='Courier'>supabase_flutter</font> para falar direto com a "
    "autenticação, o banco Postgres e o armazenamento de arquivos do projeto Supabase. A segurança — "
    "cada usuário só acessa os próprios dados — é garantida por políticas de Row Level Security (RLS) "
    "no banco, não por checagens manuais no app (ver <font face='Courier'>supabase/schema.sql</font>)."
)

h2("3.1 AuthService — autenticação e perfil")
make_table(
    ["Método", "Recurso do Supabase", "Função"],
    [
        ["cadastrar(nome, email, senha)", "auth.signUp", "Cria uma nova conta (dispara e-mail de confirmação)"],
        ["login(email, senha)", "auth.signInWithPassword", "Autentica o usuário"],
        ["logoff()", "auth.signOut", "Encerra a sessão (local e no Supabase)"],
        ["recuperarSenha(email)", "auth.resetPasswordForEmail", "Envia código de recuperação por e-mail"],
        ["redefinirSenha(...)", "auth.verifyOTP + auth.updateUser", "Valida o código e define a nova senha"],
        ["getPerfil(idUsuario)", "tabela profiles", "Busca os dados do perfil"],
        ["atualizarPerfil(...)", "tabela profiles + auth.updateUser", "Atualiza nome, e-mail, moeda e/ou foto"],
        ["alterarSenha(...)", "auth.signInWithPassword + auth.updateUser", "Reautentica e troca a senha"],
        ["uploadFotoPerfil(...)", "Storage (bucket fotos)", "Envia a foto de perfil e devolve a URL pública"],
    ],
    [5 * cm, 4.7 * cm, 5.8 * cm],
)

h2("3.2 ViagemService, DespesaService e DashboardService")
make_table(
    ["Classe / Método", "Recurso do Supabase", "Função"],
    [
        ["ViagemService.listar(idUsuario)", "view viagens_resumo", "Lista as viagens do usuário (já com totais calculados)"],
        ["ViagemService.cadastrar / atualizar / remover", "tabela viagens", "CRUD de viagens"],
        ["ViagemService.definirViagemAtiva(...) (v4)", "tabela profiles", "RF14 — grava a viagem escolhida como ativa"],
        ["DespesaService.listar(idViagem)", "tabela despesas (+ join categorias)", "Lista despesas de uma viagem"],
        ["DespesaService.listarCategorias()", "tabela categorias", "Lista categorias disponíveis"],
        ["DespesaService.cadastrar / atualizar / remover", "tabela despesas", "CRUD de despesas (agora inclui foto_url)"],
        ["DashboardService.getDashboard(idUsuario)", "consultas combinadas", "Monta viagem ativa (manual ou automática, v4), gastos de hoje, maior gasto e últimas despesas"],
        ["StorageService.upload(...)", "Storage (bucket fotos)", "Upload genérico (fotos de perfil/viagem, comprovantes e exportações CSV)"],
    ],
    [5.8 * cm, 4.7 * cm, 5 * cm],
)
body(
    "<b>Observação técnica:</b> a checagem de dono dos dados (usuário só vê as próprias viagens/despesas) "
    "agora é feita pelo banco via RLS, não pelo código do app — isso reduz o risco de um bug no client "
    "expor dados de outro usuário. Erros ainda são tratados de forma genérica nas telas (mensagem fixa "
    "\"Erro de conexão com o servidor\"); mensagens mais específicas por tipo de erro continuam sendo um "
    "ponto de melhoria."
)

h2("3.3 CurrencyService (v4) — conversão de câmbio")
body(
    "Novo serviço que consulta a API pública e gratuita <font face='Courier'>open.er-api.com</font> "
    "(sem necessidade de chave) para converter o total gasto da viagem (na moeda local) para a moeda "
    "padrão do usuário, usada na tela inicial (RF45/RF46). As cotações ficam em cache na memória do "
    "app por 6 horas, guardando também o horário da última consulta para exibir ao usuário (RNF23). Se "
    "a API estiver indisponível, a tela inicial mostra \"Conversão indisponível no momento\" em vez de "
    "travar ou quebrar (RNF17)."
)

story.append(PageBreak())

# =========================================================================
# 4. TELAS E FUNCIONALIDADES
# =========================================================================
h1("4. Telas e Funcionalidades (lib/screens)")

screens = [
    ("SplashScreen", "Tela inicial. Exibe a logo por 2 segundos e verifica se há uma sessão ativa no "
     "Supabase Auth. Se houver, leva direto ao MainScreen; senão, à tela de Login."),
    ("LoginScreen", "Login com e-mail e senha, opção de mostrar/ocultar senha, links para "
     "\"Esqueci minha senha\" e \"Cadastre-se\". Em caso de sucesso, o Supabase Auth já mantém a sessão "
     "salva automaticamente e o app abre o MainScreen."),
    ("CadastroScreen", "Cadastro de novo usuário (nome, e-mail, senha, confirmação de senha) com "
     "aceite obrigatório dos Termos de Uso — o texto \"Termos de Uso e Política de Privacidade\" agora "
     "é um link que abre a TermosScreen (v4)."),
    ("RecuperarSenhaScreen", "Fluxo de recuperação de senha em duas etapas: solicitar código por "
     "e-mail e, em seguida, informar o código recebido junto com a nova senha."),
    ("MainScreen", "Shell de navegação principal, com barra inferior de 4 abas: Início (Dashboard), "
     "Viagens, Despesas e Perfil."),
    ("DashboardScreen", "Tela inicial pós-login: saudação personalizada, resumo da viagem ativa — manual "
     "ou automática (RF14, v4) — na moeda local da viagem, com indicador circular de progresso (fica "
     "terracota quando o orçamento estoura), valor convertido para a moeda padrão do usuário com "
     "seletor de moeda e horário da cotação (RF45/RF46, v4), gastos do dia, maior gasto e lista das "
     "despesas mais recentes com botão \"Ver todas\" agora funcional (RF28, v4). Suporta pull-to-refresh."),
    ("ViagensScreen", "Lista todas as viagens cadastradas em cards (foto, nome, destino, datas, "
     "progresso do orçamento), com opções de editar e excluir cada viagem, marcar/desmarcar como "
     "viagem ativa do dashboard (ícone de estrela, RF14, v4), e botão para cadastrar uma nova."),
    ("NovaViagemScreen", "Formulário de criação/edição de viagem: foto (câmera/galeria), nome, "
     "destino, datas de início e fim, orçamento e moeda local do destino (RF45, v4)."),
    ("DespesasScreen", "Seleciona uma viagem e lista suas despesas, com filtro por categoria. "
     "Permite cadastrar, editar e excluir despesas por um formulário em painel deslizante, incluindo "
     "categoria, descrição, valor, data, forma de pagamento e comprovante anexado (RF22, v4). Mostra o "
     "total das despesas filtradas e permite exportá-las em CSV (RF23, v4, via link do Supabase Storage)."),
    ("PerfilScreen", "Exibe e permite editar os dados do usuário (foto, nome, e-mail), alterar a "
     "senha, escolher a moeda padrão (RF29, v4) e encerrar a sessão (logoff). Dá acesso às novas telas "
     "de Configurações, Sobre o app e Suporte (RF30/RF31/RF32, v4)."),
    ("ConfiguracoesScreen (v4)", "Preferência de notificações e atalho para os Termos de Uso (RF30)."),
    ("SobreScreen (v4)", "Informações sobre o app (versão, descrição, contexto do TCC) e atalho para "
     "os Termos de Uso (RF31)."),
    ("SuporteScreen (v4)", "Canal de contato (e-mail copiável) e perguntas frequentes (RF32)."),
    ("TermosScreen (v4)", "Conteúdo real dos Termos de Uso e Política de Privacidade, atendendo à LGPD "
     "(RF07/RNF14) — antes era só um texto estático sem tela própria."),
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
    "<b>Resolvido na v2:</b> o backend deixou de ser um servidor fixo em IP local — agora é o Supabase, "
    "acessado via HTTPS, com autenticação e regras de acesso reais (RLS).",
    "<b>Resolvido na v3:</b> o app passou a ter um link direto e público, gerado automaticamente a cada "
    "atualização do código (GitHub Actions + GitHub Pages) — não é mais necessário instalar nada para "
    "demonstrá-lo. Primeiro deploy já confirmado funcionando.",
    "<b>Resolvido na v4:</b> nova paleta de cores, câmbio na tela inicial, seleção manual de viagem "
    "ativa, seletor de moeda padrão, telas de Configurações/Sobre/Suporte, Termos de Uso com conteúdo "
    "real, anexo de comprovante e exportação de despesas em CSV — ver seção 7, versão 4.",
    "<b>Pendente de validação com o orientador:</b> o novo levantamento de requisitos do usuário inclui "
    "um assistente de viagem com IA (RF33–RF40) e leitura automática de notas fiscais por visão "
    "computacional (RF41–RF44). O próprio documento pede validação com o orientador antes de "
    "implementar essas duas frentes, então elas ainda não foram desenvolvidas.",
    "<b>Parcialmente testado:</b> o app já foi executado de verdade pela primeira vez fora deste ambiente — "
    "cadastro de usuário funcionou e o e-mail de confirmação do Supabase chegou normalmente. Login, "
    "upload de foto, CRUD completo de viagens/despesas e as novidades da v4 (câmbio, viagem ativa, "
    "comprovante, exportação) ainda não foram confirmados em uso real.",
    "Por padrão, o Supabase exige confirmação de e-mail para novas contas — vale revisar essa "
    "configuração no painel do projeto (Authentication) para decidir se isso é desejável na demonstração.",
    "Tratamento de erros de rede ainda é genérico (mensagem fixa) na maior parte das telas, sem "
    "diferenciar tipos de erro — exceção feita à conversão de câmbio, que já trata indisponibilidade "
    "da API separadamente (RNF17).",
    "RF23 (exportação) foi implementada em CSV, não em PDF — suficiente para abrir em Excel/Sheets, mas "
    "vale registrar essa escolha caso a banca pergunte especificamente por PDF.",
    "Não há persistência local (offline) dos dados de viagens/despesas — o app depende de conexão com "
    "o Supabase.",
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
