// Edge Function "chat-ia" (Supabase, Deno) — RF33–RF47 (Agente de vIAgens).
//
// Tem DOIS modos, no mesmo endpoint (pra reaproveitar toda a parte de
// autenticação/segredo/chamada ao Gemini, sem duplicar nada):
//   - modo "chat" (padrao, quando o campo "modo" nao vem no corpo): o
//     assistente de perguntas e respostas sobre a viagem ativa, que ja
//     existia desde a v5.
//   - modo "roteiro" (v9): o usuario preenche uma pequena entrevista
//     (destino, datas, orcamento, meio de transporte, preferencias) na
//     tela do Agente de vIAgens, e esta funcao devolve um roteiro com
//     estimativa de custos e sugestoes de passagem/hospedagem/
//     restaurante (e dicas de estrada, se for de carro) — tudo em
//     texto, estimado pela IA, sem consultar nenhum preco real.
//
// Esta função existe por um motivo de segurança: a chave da API de IA é
// um segredo de verdade (diferente da anonKey do Supabase, que é
// pública por design e protegida por RLS). Ela NUNCA pode entrar no
// código do app Flutter — especialmente na versão web, onde qualquer
// pessoa consegue abrir o DevTools do navegador e ler todo o código
// JavaScript/Wasm gerado, inclusive strings "escondidas" nele.
//
// Por isso a chave fica só aqui, guardada como "secret" do projeto
// Supabase (nunca commitada no Git), e só o servidor do Google é
// chamado a partir daqui. O app Flutter chama esta função pelo SDK do
// Supabase (que já manda o token do usuário logado automaticamente), e
// o Supabase só deixa a função rodar se o usuário estiver autenticado
// (comportamento padrão — não precisa de código extra pra isso).
//
// Provedor de IA: Gemini (Google AI Studio), escolhido no lugar da
// Anthropic porque o Google AI Studio dá uma chave de API gratuita sem
// exigir cartão de crédito no cadastro — mais simples para um projeto
// de TCC. A arquitetura (chave só no servidor) é a mesma de qualquer
// provedor; se um dia for preciso trocar de novo, só este arquivo muda.
//
// Deploy (ver instruções completas na documentação do projeto):
//   supabase functions deploy chat-ia
//   supabase secrets set GEMINI_API_KEY=...

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY");
// Gemini 3.5 Flash: modelo rápido e gratuito no tier free do Google AI
// Studio, mais que suficiente pra um assistente de perguntas sobre
// gastos de viagem. Pra trocar de modelo, basta configurar o secret
// GEMINI_MODEL no Supabase (não precisa mexer no código).
const GEMINI_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.5-flash";

function montarSystemPromptRoteiro(entrevista: Record<string, unknown>): string {
  const meioTransporte =
    typeof entrevista?.meioTransporte === "string" ? entrevista.meioTransporte : "";

  let base =
    "Você é o Agente de vIAgens do app Viajaí Bolso. O usuário está planejando uma viagem nova e " +
    "respondeu a uma pequena entrevista (dados no JSON abaixo). Responda em PORTUGUÊS DO BRASIL, em " +
    "TEXTO SIMPLES, sem markdown (nada de **, #, numeração \"1.\", nem ```). Organize a resposta " +
    "EXATAMENTE nestas seções, cada uma começando com o título em maiúsculas seguido de dois-pontos, " +
    "com uma linha em branco antes de cada seção, e itens de lista usando \"- \" no início da linha:\n\n" +
    "ROTEIRO SUGERIDO: um roteiro dia a dia (Dia 1, Dia 2...) com 1 a 3 atividades por dia, coerente " +
    "com o destino e as preferências informadas. Se não houver datas, sugira um roteiro de 3 a 5 dias.\n" +
    "ESTIMATIVA DE CUSTOS: estimativa aproximada de gasto por categoria (passagem, hospedagem, " +
    "alimentação, passeios) e um total estimado; compare com o orçamento informado, se houver.\n" +
    "SUGESTÕES DE PASSAGEM: tipo de trajeto mais comum até o destino e uma faixa de preço aproximada.\n" +
    "SUGESTÕES DE HOSPEDAGEM: 2 ou 3 tipos de hospedagem (ex.: hostel, pousada, hotel) com faixa de " +
    "preço aproximada por noite.\n" +
    "SUGESTÕES DE RESTAURANTES: 2 ou 3 tipos de comida/experiência gastronômica típica do destino, com " +
    "faixa de preço aproximada por refeição.\n";

  if (meioTransporte.toLowerCase().includes("carro")) {
    base +=
      "DICAS PARA VIAGEM DE CARRO: já que o usuário vai de carro, dê dicas práticas sobre o trecho " +
      "aproximado, pedágios estimados, pontos de parada recomendados e documentação básica do veículo " +
      "a verificar antes de viajar.\n";
  }

  base +=
    "\nDeixe claro, em pelo menos uma frase, que os valores são ESTIMATIVAS geradas por IA, sem " +
    "consulta a preços reais/atuais, e que o usuário deve confirmar antes de comprar algo. Nunca " +
    "invente nomes de hotéis, companhias aéreas ou restaurantes específicos — fale sempre em termos " +
    "gerais (tipo de hospedagem, tipo de passagem, tipo de restaurante), nunca marcas reais.";

  base += "\n\nDados informados pelo usuário na entrevista (JSON):\n" + JSON.stringify(entrevista);

  return base;
}

function montarSystemPrompt(contextoViagem: unknown): string {
  let base =
    "Você é o assistente de viagens do app Viajaí Bolso, um aplicativo de " +
    "controle de gastos em viagens. Responda sempre em português do " +
    "Brasil, de forma curta, direta e simpática (poucos parágrafos, sem " +
    "listas longas). Ajude o usuário a entender os gastos da viagem, " +
    "planejar o orçamento e dar dicas práticas de economia. Se a " +
    "pergunta não tiver relação com viagens, gastos ou o uso do app, " +
    "diga educadamente que esse não é o seu foco. Nunca invente valores: " +
    "use somente os dados fornecidos abaixo sobre a viagem ativa do " +
    "usuário; se a informação pedida não estiver nesses dados, diga que " +
    "não tem essa informação disponível.";

  if (contextoViagem) {
    base +=
      "\n\nDados da viagem ativa do usuário no app agora (JSON):\n" +
      JSON.stringify(contextoViagem);
  } else {
    base += "\n\nO usuário não tem nenhuma viagem ativa cadastrada no momento.";
  }

  return base;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (!GEMINI_API_KEY) {
      return new Response(
        JSON.stringify({
          erro:
            "GEMINI_API_KEY não configurada no servidor. Configure o " +
            "secret no Supabase antes de usar o assistente (ver documentação).",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const body = await req.json();
    const mensagensRecebidas = Array.isArray(body?.mensagens)
      ? body.mensagens
      : [];
    const contextoViagem = body?.contextoViagem ?? null;
    // v9 — modo "roteiro": entrevista de planejamento de viagem (RF33-47),
    // em vez do chat livre sobre a viagem ativa (modo padrão "chat").
    const modo = body?.modo === "roteiro" ? "roteiro" : "chat";
    const entrevista =
      modo === "roteiro" && typeof body?.entrevista === "object" && body?.entrevista !== null
        ? body.entrevista as Record<string, unknown>
        : {};

    if (mensagensRecebidas.length === 0) {
      return new Response(
        JSON.stringify({ erro: "Nenhuma mensagem enviada." }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // A API do Gemini usa role "user" (igual ao nosso "papel") e "model"
    // (em vez do nosso "assistant") — só esse mapeamento muda.
    const conteudosGemini = mensagensRecebidas
      .filter(
        (m: Record<string, unknown>) =>
          typeof m?.conteudo === "string" &&
          (m.papel === "user" || m.papel === "assistant"),
      )
      .map((m: Record<string, unknown>) => ({
        role: m.papel === "assistant" ? "model" : "user",
        parts: [{ text: String(m.conteudo) }],
      }));

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
        systemInstruction: {
          parts: [{
            text: modo === "roteiro"
              ? montarSystemPromptRoteiro(entrevista)
              : montarSystemPrompt(contextoViagem),
          }],
        },
        contents: conteudosGemini,
        // O roteiro tem várias seções (custos, passagem, hospedagem,
        // restaurante, às vezes carro) e precisa de mais espaço que uma
        // resposta de chat comum.
        generationConfig: { maxOutputTokens: modo === "roteiro" ? 2048 : 1024 },
      }),
    });

    if (!respostaGemini.ok) {
      const erroTexto = await respostaGemini.text();
      console.error(
        "Erro da API do Gemini:",
        respostaGemini.status,
        erroTexto,
      );
      return new Response(
        JSON.stringify({
          erro:
            "O assistente de IA não respondeu agora. Tente novamente em instantes.",
        }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const dados = await respostaGemini.json();
    const partes = dados?.candidates?.[0]?.content?.parts ?? [];
    const texto = partes
      .filter((p: Record<string, unknown>) => typeof p?.text === "string")
      .map((p: Record<string, unknown>) => p.text)
      .join("\n")
      .trim();

    return new Response(
      JSON.stringify({
        resposta: texto || "Não consegui gerar uma resposta agora.",
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    console.error("Erro inesperado na Edge Function chat-ia:", e);
    return new Response(
      JSON.stringify({ erro: "Erro inesperado no servidor." }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
