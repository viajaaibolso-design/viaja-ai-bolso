#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Levantamento preliminar de Requisitos Funcionais (RF) e Não Funcionais (RNF)
do projeto Viajaí Bolso (viaja_ai_app), a partir da análise do código-fonte
do protótipo atual.

Uso:
    python3 requirements_doc.py
Gera: levantamento_requisitos.pdf
"""

import os
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle,
    ListFlowable, ListItem, HRFlowable
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY

HERE = os.path.dirname(os.path.abspath(__file__))
OUTPUT_PATH = os.path.join(HERE, "levantamento_requisitos.pdf")

PRIMARY = colors.HexColor("#007B6E")
PRIMARY_LIGHT = colors.HexColor("#00A896")
TEXT_DARK = colors.HexColor("#1A1A2E")
TEXT_GREY = colors.HexColor("#6B6B6B")
BG_LIGHT = colors.HexColor("#F5F5F5")
GREEN = "#1B7F4C"
AMBER = "#B45309"
RED = "#B3261E"
GREY = "#6B6B6B"

STATUS_COLOR = {
    "Implementado": GREEN,
    "Atendido": GREEN,
    "Parcial": AMBER,
    "A validar": AMBER,
    "Não implementado": RED,
    "Não atendido": RED,
    "Fora do escopo do cliente": GREY,
    "A avaliar": AMBER,
    "Não definido": RED,
}

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="CoverTitle", fontName="Helvetica-Bold", fontSize=25,
                           textColor=PRIMARY, alignment=TA_CENTER, leading=30, spaceAfter=6))
styles.add(ParagraphStyle(name="CoverSubtitle", fontName="Helvetica", fontSize=13,
                           textColor=TEXT_GREY, alignment=TA_CENTER, leading=18, spaceAfter=4))
styles.add(ParagraphStyle(name="CoverMeta", fontName="Helvetica", fontSize=10.5,
                           textColor=TEXT_DARK, alignment=TA_CENTER, leading=15))
styles.add(ParagraphStyle(name="H1", fontName="Helvetica-Bold", fontSize=16,
                           textColor=PRIMARY, spaceBefore=16, spaceAfter=8))
styles.add(ParagraphStyle(name="H2", fontName="Helvetica-Bold", fontSize=12,
                           textColor=TEXT_DARK, spaceBefore=12, spaceAfter=5))
styles.add(ParagraphStyle(name="BodyText2", fontName="Helvetica", fontSize=9.6,
                           textColor=TEXT_DARK, leading=13.6, alignment=TA_JUSTIFY, spaceAfter=6))
styles.add(ParagraphStyle(name="BulletText", fontName="Helvetica", fontSize=9.6,
                           textColor=TEXT_DARK, leading=13, alignment=TA_LEFT))
styles.add(ParagraphStyle(name="Small", fontName="Helvetica", fontSize=8.2,
                           textColor=TEXT_GREY, leading=11))
styles.add(ParagraphStyle(name="CellHead", fontName="Helvetica-Bold", fontSize=8.3,
                           textColor=colors.white, leading=10.5))
styles.add(ParagraphStyle(name="Cell", fontName="Helvetica", fontSize=8.4,
                           textColor=TEXT_DARK, leading=11))
styles.add(ParagraphStyle(name="CellId", fontName="Helvetica-Bold", fontSize=8.4,
                           textColor=PRIMARY, leading=11))

story = []


def h1(text):
    story.append(Paragraph(text, styles["H1"]))
    story.append(HRFlowable(width="100%", thickness=1, color=PRIMARY_LIGHT, spaceAfter=6))


def h2(text):
    story.append(Paragraph(text, styles["H2"]))


def body(text):
    story.append(Paragraph(text, styles["BodyText2"]))


def bullets(items):
    story.append(ListFlowable(
        [ListItem(Paragraph(i, styles["BulletText"]), leftIndent=6, bulletColor=PRIMARY) for i in items],
        bulletType="bullet", start="•", leftIndent=14, spaceBefore=2, spaceAfter=8,
    ))


def status_cell(status):
    color = STATUS_COLOR.get(status, TEXT_DARK)
    return Paragraph(f"<font color='{color}'><b>{status}</b></font>", styles["Cell"])


def req_table(rows):
    """rows: list of (id, descricao, prioridade, status)"""
    header = ["ID", "Descrição", "Prioridade", "Status"]
    data = [[Paragraph(h, styles["CellHead"]) for h in header]]
    for rid, desc, prio, status in rows:
        data.append([
            Paragraph(rid, styles["CellId"]),
            Paragraph(desc, styles["Cell"]),
            Paragraph(prio, styles["Cell"]),
            status_cell(status),
        ])
    t = Table(data, colWidths=[1.6 * cm, 9.4 * cm, 2.2 * cm, 3.3 * cm], repeatRows=1)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), PRIMARY),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, BG_LIGHT]),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#D9D9D9")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("TOPPADDING", (0, 0), (-1, -1), 4.5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 4.5),
        ("LEFTPADDING", (0, 0), (-1, -1), 5),
        ("RIGHTPADDING", (0, 0), (-1, -1), 5),
    ]))
    story.append(t)
    story.append(Spacer(1, 10))


# =========================================================================
# CAPA
# =========================================================================
story.append(Spacer(1, 5 * cm))
story.append(Paragraph("Levantamento de Requisitos", styles["CoverTitle"]))
story.append(Paragraph("Funcionais e Não Funcionais — Viajaí Bolso", styles["CoverSubtitle"]))
story.append(Spacer(1, 1 * cm))
story.append(Paragraph(
    "Análise preliminar elaborada a partir do código-fonte do protótipo atual, "
    "como apoio ao levantamento formal de requisitos do projeto.", styles["CoverMeta"]
))
story.append(Spacer(1, 2.5 * cm))
story.append(Paragraph("Documento complementar à Documentação Técnica e Funcional (documentacao_projeto.pdf)",
                        styles["Small"]))
story.append(PageBreak())

# =========================================================================
# METODOLOGIA
# =========================================================================
h1("1. Sobre este documento")
body(
    "Este levantamento foi elaborado a partir da análise estática do código-fonte do protótipo "
    "atual do <b>Viajaí Bolso</b> (telas, modelos de dados e serviços), identificando o que já "
    "está implementado, o que está parcialmente implementado (ex.: elementos de interface sem "
    "função real) e o que ainda não existe, mas é necessário para tornar o app funcional."
)
body(
    "<b>É importante deixar claro:</b> este é um ponto de partida gerado por IA para acelerar o "
    "levantamento formal de requisitos — ele não substitui a etapa de levantamento com o "
    "orientador/banca, usuários reais ou stakeholders do projeto. Recomenda-se revisar, ajustar "
    "prioridades e validar cada item antes de usá-lo como documento oficial do TCC."
)
h2("Legenda de status")
bullets([
    "<font color='%s'><b>Implementado / Atendido</b></font> — já existe e funciona no protótipo atual." % GREEN,
    "<font color='%s'><b>Parcial / A validar</b></font> — existe algo na interface, mas incompleto, "
    "ou precisa ser confirmado/medido." % AMBER,
    "<font color='%s'><b>Não implementado / Não atendido</b></font> — ainda não existe no protótipo; "
    "é um requisito a ser desenvolvido." % RED,
])
h2("Legenda de prioridade")
body(
    "<b>Alta</b> — essencial para o funcionamento básico do app. <b>Média</b> — importante para a "
    "experiência completa. <b>Baixa</b> — desejável, pode ficar para uma fase posterior."
)

story.append(PageBreak())

# =========================================================================
# 2. REQUISITOS FUNCIONAIS
# =========================================================================
h1("2. Requisitos Funcionais (RF)")

h2("2.1 Autenticação e Conta")
req_table([
    ("RF01", "Permitir que o usuário crie uma conta informando nome, e-mail e senha.", "Alta", "Implementado"),
    ("RF02", "Permitir que o usuário faça login com e-mail e senha.", "Alta", "Implementado"),
    ("RF03", "Manter o usuário autenticado entre sessões (login automático ao reabrir o app).", "Média", "Implementado"),
    ("RF04", "Permitir recuperação de senha via código enviado por e-mail.", "Alta", "Implementado"),
    ("RF05", "Permitir que o usuário altere a senha estando autenticado.", "Média", "Implementado"),
    ("RF06", "Permitir edição dos dados do perfil (nome, e-mail, foto).", "Média", "Implementado"),
    ("RF07", "Exigir aceite dos Termos de Uso no cadastro, com conteúdo real e acessível.", "Média", "Parcial"),
    ("RF08", "Permitir logout, encerrando a sessão local e no servidor.", "Alta", "Implementado"),
])

h2("2.2 Gestão de Viagens")
req_table([
    ("RF09", "Permitir cadastrar uma viagem (nome, destino, datas, orçamento, foto).", "Alta", "Implementado"),
    ("RF10", "Listar as viagens cadastradas pelo usuário.", "Alta", "Implementado"),
    ("RF11", "Permitir editar uma viagem existente.", "Alta", "Implementado"),
    ("RF12", "Permitir excluir uma viagem, com confirmação.", "Média", "Implementado"),
    ("RF13", "Exibir o progresso de gasto em relação ao orçamento de cada viagem.", "Alta", "Implementado"),
    ("RF14", "Permitir definir/selecionar manualmente qual viagem está \"ativa\" no dashboard.", "Média", "Não implementado"),
    ("RF15", "Permitir compartilhar/colaborar em uma viagem com outros usuários (viagem em grupo).", "Baixa", "Não implementado"),
])

h2("2.3 Gestão de Despesas")
req_table([
    ("RF16", "Permitir cadastrar uma despesa vinculada a uma viagem e a uma categoria.", "Alta", "Implementado"),
    ("RF17", "Listar despesas de uma viagem selecionada.", "Alta", "Implementado"),
    ("RF18", "Permitir filtrar despesas por categoria.", "Média", "Implementado"),
    ("RF19", "Permitir editar uma despesa existente.", "Alta", "Implementado"),
    ("RF20", "Permitir excluir uma despesa, com confirmação.", "Média", "Implementado"),
    ("RF21", "Exibir o total das despesas filtradas.", "Média", "Implementado"),
    ("RF22", "Permitir anexar comprovante/foto a uma despesa.", "Média", "Não implementado"),
    ("RF23", "Permitir exportar as despesas de uma viagem (PDF/planilha) para prestação de contas.", "Alta", "Não implementado"),
])

h2("2.4 Dashboard")
req_table([
    ("RF24", "Exibir resumo da viagem ativa (gasto acumulado vs. orçamento).", "Alta", "Implementado"),
    ("RF25", "Exibir o total gasto no dia atual.", "Média", "Implementado"),
    ("RF26", "Exibir a maior despesa e/ou a categoria com maior gasto.", "Média", "Implementado"),
    ("RF27", "Exibir as despesas mais recentes.", "Média", "Implementado"),
    ("RF28", "Permitir acessar a lista completa de despesas a partir do botão \"Ver todas\".", "Baixa", "Não implementado"),
])

h2("2.5 Configurações e Suporte")
req_table([
    ("RF29", "Permitir selecionar/alterar a moeda padrão do usuário.", "Baixa", "Não implementado"),
    ("RF30", "Disponibilizar tela de configurações gerais do app.", "Baixa", "Não implementado"),
    ("RF31", "Disponibilizar tela \"Sobre o app\".", "Baixa", "Não implementado"),
    ("RF32", "Disponibilizar canal de suporte/contato dentro do app.", "Baixa", "Não implementado"),
])

story.append(PageBreak())

# =========================================================================
# 3. REQUISITOS NÃO FUNCIONAIS
# =========================================================================
h1("3. Requisitos Não Funcionais (RNF)")
body(
    "Organizados por categoria de qualidade, com base no que foi observado no código do cliente "
    "Flutter (o backend não faz parte do código analisado, então alguns itens dependem de "
    "confirmação junto à implementação do servidor)."
)

h2("3.1 Usabilidade")
req_table([
    ("RNF01", "A interface deve seguir os padrões visuais do Material Design, com navegação consistente entre as telas.", "Alta", "Atendido"),
    ("RNF02", "O app deve fornecer feedback visual (carregamento, sucesso, erro) para toda ação do usuário.", "Alta", "Parcial"),
])

h2("3.2 Desempenho")
req_table([
    ("RNF03", "As telas devem responder e carregar dados em até 2 segundos em condições normais de rede.", "Média", "A validar"),
])

h2("3.3 Segurança")
req_table([
    ("RNF04", "Toda comunicação entre o app e o backend deve ser feita via HTTPS.", "Alta", "Atendido"),
    ("RNF05", "Senhas e dados sensíveis não devem ser armazenados em texto legível no dispositivo.", "Alta", "Atendido"),
    ("RNF06", "As senhas dos usuários devem ser armazenadas com hashing seguro no backend.", "Alta", "Atendido"),
])

h2("3.4 Confiabilidade e Disponibilidade")
req_table([
    ("RNF07", "O app deve informar mensagens de erro específicas e acionáveis em falhas de rede/servidor.", "Média", "Não atendido"),
    ("RNF08", "O app deve permitir consultar dados já carregados mesmo sem conexão (modo offline básico).", "Média", "Não atendido"),
])

h2("3.5 Portabilidade e Compatibilidade")
req_table([
    ("RNF09", "O app deve funcionar em Android, iOS e Web a partir da mesma base de código Flutter.", "Alta", "Atendido"),
    ("RNF10", "Devem ser definidas e documentadas as versões mínimas suportadas de Android/iOS.", "Baixa", "Não atendido"),
])

h2("3.6 Manutenibilidade e Configurabilidade")
req_table([
    ("RNF11", "O código deve manter separação clara entre dados, regras de negócio e interface.", "Média", "Parcial"),
    ("RNF12", "O endereço do backend deve ser configurável por ambiente (desenvolvimento/produção), não fixo no código.", "Alta", "Parcial"),
])

h2("3.7 Escalabilidade")
req_table([
    ("RNF13", "O backend deve suportar múltiplos usuários simultâneos sem degradação perceptível.", "Média", "Fora do escopo do cliente"),
])

h2("3.8 Conformidade Legal e Acessibilidade")
req_table([
    ("RNF14", "O tratamento de dados pessoais (nome, e-mail, foto) deve seguir a LGPD, com política de privacidade real e consentimento informado.", "Alta", "Não atendido"),
    ("RNF15", "O app deve garantir contraste adequado e tamanhos de fonte legíveis (acessibilidade básica).", "Média", "A validar"),
])

story.append(PageBreak())

# =========================================================================
# 4. PRÓXIMOS PASSOS SUGERIDOS
# =========================================================================
h1("4. Próximos Passos Sugeridos")
body(
    "Para orientar a priorização do que falta implementar, os itens marcados como \"Não "
    "implementado\"/\"Não atendido\" com prioridade Alta são os mais críticos para tornar o app "
    "verdadeiramente funcional:"
)
bullets([
    "<b>Atualização:</b> a migração do backend para o Supabase (ver Histórico de Alterações da "
    "documentação técnica, versão 2) já resolveu RNF04 (HTTPS) e RNF06 (hashing de senha); RNF12 "
    "melhorou (o backend deixou de ser um IP local), mas a URL do Supabase ainda está fixa no código "
    "em vez de configurada por ambiente.",
    "RF23 — Exportação de despesas (PDF/planilha), essencial para o caso de uso de \"prestação de "
    "contas\" que dá nome ao app.",
    "RNF14 — Conformidade com a LGPD (política de privacidade real), especialmente relevante numa "
    "apresentação/banca que avalie a maturidade do projeto.",
    "Testar de ponta a ponta o app já integrado ao Supabase (cadastro, login, upload de fotos, CRUD de "
    "viagens/despesas) antes da apresentação final.",
])
body(
    "Este documento deve ser revisado junto com você à medida que o levantamento formal de "
    "requisitos avançar, e as próximas implementações serão refletidas tanto aqui quanto no "
    "Histórico de Alterações da documentação técnica principal."
)

doc = SimpleDocTemplate(
    OUTPUT_PATH, pagesize=A4,
    topMargin=2.2 * cm, bottomMargin=2 * cm, leftMargin=2 * cm, rightMargin=2 * cm,
    title="Viajaí Bolso - Levantamento de Requisitos Funcionais e Não Funcionais",
    author="Joel Cordeiro",
)


def add_footer(canvas, doc_):
    canvas.saveState()
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(TEXT_GREY)
    canvas.drawString(2 * cm, 1.2 * cm, "Viajaí Bolso — Levantamento de Requisitos")
    canvas.drawRightString(A4[0] - 2 * cm, 1.2 * cm, f"Página {doc_.page}")
    canvas.restoreState()


doc.build(story, onFirstPage=lambda c, d: None, onLaterPages=add_footer)
print(f"PDF gerado em: {OUTPUT_PATH}")
