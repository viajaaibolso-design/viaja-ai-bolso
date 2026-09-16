// Edge Function "chat-ia" (Supabase, Deno) — RF33–RF40.
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
          parts: [{ text: montarSystemPrompt(contextoViagem) }],
        },
        contents: conteudosGemini,
        generationConfig: { maxOutputTokens: 1024 },
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
