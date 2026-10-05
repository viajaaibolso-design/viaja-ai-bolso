// Edge Function "extrair-nota-qrcode" (Supabase, Deno) — RF48–RF51 (v7).
//
// Variação do "extrair-nota": em vez de receber uma FOTO da nota e pedir
// pro Gemini "enxergar" os dados (visão computacional), esta função
// recebe o CONTEÚDO DO QR CODE já decodificado no aparelho (lido
// localmente pela tela EscanearQrcodeScreen, sem IA e sem rede nesse
// passo — ver mobile_scanner). O QR Code de uma NFC-e sempre aponta pra
// uma URL de consulta oficial da SEFAZ do estado emissor; esta função
// busca essa página no servidor e pede ao Gemini (modo texto, sem
// visão — mais barato e rápido) pra ler os dados nela, em vez de supor a
// partir de pixels de uma foto. Reaproveita o MESMO secret GEMINI_API_KEY
// já configurado para o chat-ia e a extrair-nota — não precisa cadastrar
// chave nova nenhuma.
//
// Cobertura atual: só notas emitidas na Paraíba (PB), estado de testes
// do projeto (ver UF_SUPORTADAS). Pra qualquer outro estado, ou se a
// consulta falhar, devolve sucesso:false com um erro claro — a tela de
// despesas já cai automaticamente pro fluxo de foto/manual nesse caso,
// então nada trava para o usuário.
//
// Deploy (mesmo processo das outras funções — ver documentação do projeto):
//   supabase functions deploy extrair-nota-qrcode

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
// Mesmo modelo padrão das outras funções (gratuito no tier free do
// Google AI Studio). Trocável pelo secret GEMINI_MODEL, sem mexer no código.
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.5-flash";

const CATEGORIAS_VALIDAS = [
  "Alimentação",
  "Transporte",
  "Hospedagem",
  "Lazer",
  "Compras",
  "Saúde",
  "Outros",
];

// Código de UF (2 primeiros dígitos da chave de acesso de 44 dígitos),
// conforme tabela do IBGE usada pela SEFAZ em todo o Brasil.
const UF_POR_CODIGO: Record<string, string> = {
  "11": "RO", "12": "AC", "13": "AM", "14": "RR", "15": "PA", "16": "AP",
  "17": "TO", "21": "MA", "22": "PI", "23": "CE", "24": "RN", "25": "PB",
  "26": "PE", "27": "AL", "28": "SE", "29": "BA", "31": "MG", "32": "ES",
  "33": "RJ", "35": "SP", "41": "PR", "42": "SC", "43": "RS", "50": "MS",
  "51": "MT", "52": "GO", "53": "DF",
};

// Estados cuja página de consulta já sabemos buscar e interpretar. Dá
// pra somar outros estados aqui no futuro, sem mudar o resto da função.
const UF_SUPORTADAS = new Set(["PB"]);

function montarPrompt(textoPagina: string): string {
  return (
    "Você é um sistema de leitura de notas fiscais de viagem. O texto " +
    "abaixo foi extraído da página oficial de consulta de uma Nota " +
    "Fiscal de Consumidor Eletrônica (NFC-e) no site da Receita " +
    "Estadual. Identifique: o nome do estabelecimento emissor (o " +
    "vendedor, não o comprador), o valor TOTAL da nota, a data de " +
    "emissão e a categoria de despesa de viagem que melhor se encaixa. " +
    `Para a categoria, escolha EXATAMENTE uma destas opções: ${CATEGORIAS_VALIDAS.join(", ")}. ` +
    "Responda APENAS com um objeto JSON válido, sem nenhum texto antes " +
    "ou depois, sem marcação markdown (sem ```), exatamente neste " +
    'formato: {"estabelecimento": string ou null, "valor": número ou ' +
    "null (use ponto como separador decimal, nunca vírgula), \"data\": " +
    'string no formato AAAA-MM-DD ou null, "categoria": uma das opções ' +
    'acima ou null, "confianca": "alta", "media" ou "baixa"}. Se o ' +
    "texto não parecer conter os dados de uma nota fiscal válida (por " +
    'exemplo, página de erro ou "nota não encontrada"), responda ' +
    '"confianca": "baixa" e use null nos campos que não conseguir ' +
    "identificar. Nunca invente valores — na dúvida, é sempre melhor " +
    "devolver null do que um dado errado.\n\nTexto da página:\n" +
    `"""\n${textoPagina}\n"""`
  );
}

// Remove tags/scripts/estilos de um HTML e devolve só o texto visível,
// pra mandar bem menos ruído (e menos tokens) pro Gemini.
function htmlParaTexto(html: string): string {
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<!--[\s\S]*?-->/g, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/\s+/g, " ")
    .trim();
}

// A resposta do Gemini deveria vir só com o JSON, mas às vezes o modelo
// envolve em ```json ... ``` mesmo sendo instruído a não fazer isso —
// esta função limpa esses casos antes de tentar interpretar o texto.
function extrairJson(texto: string): Record<string, unknown> | null {
  let limpo = texto.trim();
  limpo = limpo.replace(/^```(json)?/i, "").replace(/```$/, "").trim();
  const inicio = limpo.indexOf("{");
  const fim = limpo.lastIndexOf("}");
  if (inicio === -1 || fim === -1 || fim < inicio) return null;
  limpo = limpo.slice(inicio, fim + 1);
  try {
    return JSON.parse(limpo);
  } catch {
    return null;
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const responder = (status: number, payload: Record<string, unknown>) =>
    new Response(JSON.stringify(payload), {
      status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });

  try {
    if (!GEMINI_API_KEY) {
      return responder(500, {
        sucesso: false,
        erro:
          "GEMINI_API_KEY não configurada no servidor (mesmo secret do " +
          "assistente de IA).",
      });
    }

    const body = await req.json();
    const qrContent = body?.qrContent;

    if (typeof qrContent !== "string" || qrContent.trim().length === 0) {
      return responder(400, { sucesso: false, erro: "QR Code vazio ou inválido." });
    }

    // O QR de uma NFC-e sempre traz a chave de acesso de 44 dígitos em
    // algum lugar da URL (em geral no parâmetro p=, mas isso varia por
    // estado) — em vez de tentar recompor a URL, procuramos os 44
    // dígitos direto no texto do QR.
    const chaveMatch = qrContent.match(/\d{44}/);
    if (!chaveMatch) {
      return responder(200, {
        sucesso: false,
        erro:
          "Esse QR Code não parece ser de uma nota fiscal eletrônica " +
          "(não encontrei a chave de acesso).",
      });
    }
    const codigoUf = chaveMatch[0].substring(0, 2);
    const uf = UF_POR_CODIGO[codigoUf];

    if (!uf || !UF_SUPORTADAS.has(uf)) {
      return responder(200, {
        sucesso: false,
        erro: uf
          ? `Leitura por QR Code ainda só é suportada para notas da Paraíba (PB). Esta nota foi emitida em ${uf} — use a opção de escanear por foto.`
          : "Não foi possível identificar o estado emissor da nota a partir do QR Code.",
      });
    }

    // A própria URL do QR é o link oficial de consulta gerado pela
    // SEFAZ para aquela nota específica — não tentamos reconstruí-la,
    // só seguimos o link que já veio impresso no cupom.
    let urlConsulta = qrContent.trim();
    if (!/^https?:\/\//i.test(urlConsulta)) {
      urlConsulta = `https://${urlConsulta}`;
    }

    let paginaResp: Response;
    try {
      paginaResp = await fetch(urlConsulta, {
        headers: {
          "User-Agent":
            "Mozilla/5.0 (compatible; ViajaiBolso/1.0; " +
            "+https://viajaaibolso-design.github.io/viaja-ai-bolso/)",
        },
      });
    } catch (e) {
      console.error("Erro ao consultar nota na SEFAZ:", e);
      return responder(200, {
        sucesso: false,
        erro:
          "Não foi possível consultar a nota no site da Receita agora. " +
          "Tente de novo ou use a leitura por foto.",
      });
    }

    if (!paginaResp.ok) {
      return responder(200, {
        sucesso: false,
        erro:
          "Não foi possível consultar a nota no site da Receita " +
          "(serviço indisponível ou chave não encontrada). Tente de " +
          "novo ou use a leitura por foto.",
      });
    }

    const html = await paginaResp.text();
    const textoPagina = htmlParaTexto(html).slice(0, 12000); // limite de segurança

    if (textoPagina.length < 40) {
      return responder(200, {
        sucesso: false,
        erro:
          "A página de consulta da nota voltou vazia. Pode ser " +
          "instabilidade do site da Receita — tente de novo em " +
          "instantes ou use a leitura por foto.",
      });
    }

    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/` +
      `${GEMINI_MODEL}:generateContent`;

    const respostaGemini = await fetch(url, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY,
      },
      body: JSON.stringify({
        contents: [
          { role: "user", parts: [{ text: montarPrompt(textoPagina) }] },
        ],
      }),
    });

    if (!respostaGemini.ok) {
      const erroTexto = await respostaGemini.text();
      console.error(
        "Erro da API do Gemini (extrair-nota-qrcode):",
        respostaGemini.status,
        erroTexto,
      );
      return responder(200, {
        sucesso: false,
        erro:
          "Não foi possível interpretar os dados da nota agora. " +
          "Preencha manualmente.",
      });
    }

    const dados = await respostaGemini.json();
    const partes = dados?.candidates?.[0]?.content?.parts ?? [];
    const textoResposta = partes
      .filter((p: Record<string, unknown>) => typeof p?.text === "string")
      .map((p: Record<string, unknown>) => p.text)
      .join("\n")
      .trim();

    const extraido = textoResposta ? extrairJson(textoResposta) : null;

    // RNF21 — sem confiança suficiente (ou nem valor foi reconhecido),
    // devolve sucesso:false pra tela cair no preenchimento manual, sem
    // travar o cadastro da despesa.
    const valorNumero =
      extraido && typeof extraido.valor === "number" ? extraido.valor : null;
    const confianca = extraido?.confianca;

    if (!extraido || valorNumero === null || confianca === "baixa") {
      return responder(200, {
        sucesso: false,
        erro:
          (typeof extraido?.erro === "string" ? extraido.erro + " " : "") +
          "Não conseguimos ler os dados dessa nota com confiança " +
          "suficiente. Confira pela foto ou preencha manualmente.",
      });
    }

    const categoria =
      typeof extraido.categoria === "string" &&
      CATEGORIAS_VALIDAS.includes(extraido.categoria)
        ? extraido.categoria
        : null;

    return responder(200, {
      sucesso: true,
      estabelecimento:
        typeof extraido.estabelecimento === "string"
          ? extraido.estabelecimento
          : null,
      valor: valorNumero,
      data: typeof extraido.data === "string" ? extraido.data : null,
      categoria,
    });
  } catch (e) {
    console.error("Erro inesperado na Edge Function extrair-nota-qrcode:", e);
    return responder(500, {
      sucesso: false,
      erro: "Erro inesperado no servidor.",
    });
  }
});
