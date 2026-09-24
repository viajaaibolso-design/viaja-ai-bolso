// Edge Function "extrair-nota" (Supabase, Deno) — RF48–RF51.
//
// Mesma ideia de segurança do "chat-ia": a chave de API de IA nunca pode
// ir para o app Flutter. O app manda a foto da nota fiscal (em base64)
// pra cá, esta função pede ao Gemini (multimodal — lê texto e imagem
// juntos) pra extrair os dados, e devolve um JSON pronto pra
// pré-preencher o formulário de despesa. Reaproveita o MESMO secret
// GEMINI_API_KEY já configurado para o assistente de IA — não precisa
// cadastrar chave nova nenhuma.
//
// Deploy (mesmo processo do chat-ia — ver documentação do projeto):
//   supabase functions deploy extrair-nota

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
// Mesmo modelo padrão do chat-ia (gratuito no tier free do Google AI
// Studio). Trocável pelo secret GEMINI_MODEL, sem mexer no código.
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

const PROMPT_EXTRACAO =
  "Você é um sistema de leitura de notas fiscais e recibos de viagem. " +
  "Analise a imagem enviada e tente identificar: o nome do " +
  "estabelecimento, o valor total pago, a data da compra e a categoria " +
  "de despesa de viagem que melhor se encaixa. Para a categoria, " +
  `escolha EXATAMENTE uma destas opções: ${CATEGORIAS_VALIDAS.join(", ")}. ` +
  "Responda APENAS com um objeto JSON válido, sem nenhum texto antes ou " +
  "depois, sem marcação markdown (sem ```), exatamente neste formato: " +
  '{"estabelecimento": string ou null, "valor": número ou null (use ' +
  'ponto como separador decimal, nunca vírgula), "data": string no ' +
  'formato AAAA-MM-DD ou null, "categoria": uma das opções acima ou ' +
  'null, "confianca": "alta", "media" ou "baixa"}. Se a imagem não for ' +
  "uma nota fiscal ou recibo legível, ou se não conseguir identificar o " +
  'valor com segurança, responda "confianca": "baixa" e use null nos ' +
  "campos que não conseguir extrair. Nunca invente valores — na dúvida, " +
  "é sempre melhor devolver null do que um dado errado.";

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
    const imagemBase64 = body?.imagemBase64;
    const mimeType =
      typeof body?.mimeType === "string" ? body.mimeType : "image/jpeg";

    if (typeof imagemBase64 !== "string" || imagemBase64.length === 0) {
      return responder(400, { sucesso: false, erro: "Nenhuma imagem enviada." });
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
          {
            role: "user",
            parts: [
              { text: PROMPT_EXTRACAO },
              { inline_data: { mime_type: mimeType, data: imagemBase64 } },
            ],
          },
        ],
      }),
    });

    if (!respostaGemini.ok) {
      const erroTexto = await respostaGemini.text();
      console.error(
        "Erro da API do Gemini (extrair-nota):",
        respostaGemini.status,
        erroTexto,
      );
      return responder(200, {
        sucesso: false,
        erro:
          "Não foi possível analisar a imagem agora. Preencha manualmente.",
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
          "Não conseguimos ler os dados da nota com confiança suficiente. " +
          "Confira a foto ou preencha manualmente.",
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
    console.error("Erro inesperado na Edge Function extrair-nota:", e);
    return responder(500, {
      sucesso: false,
      erro: "Erro inesperado no servidor.",
    });
  }
});
