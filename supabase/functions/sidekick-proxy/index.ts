// Seminary Sidekick — xAI (Grok) proxy.
//
// Holds the xAI API key server-side (as the `XAI_API_KEY` function secret) so
// it is NEVER shipped in the app binary, and prepends an authoritative safety
// system prompt that holds even if a tampered client alters its own prompts.
//
// Deploy:   supabase functions deploy sidekick-proxy
// Secret:   supabase secrets set XAI_API_KEY=xai-...
// JWT:      verify_jwt stays ON (default) — the app's anonymous Supabase
//           session authorizes the call via supabase_flutter functions.invoke.
//
// Request body:  { messages: [...], temperature?: number, max_tokens?: number }
// Response:      the raw xAI/OpenAI-format chat-completion JSON.

import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const XAI_URL = "https://api.x.ai/v1/chat/completions";
const MODEL = "grok-3-mini";

// Authoritative safety guardrails — kept in sync with `_safetyGuardrails` in
// lib/services/sidekick_service.dart. Prepended to every request server-side.
const SAFETY_SYSTEM = `SAFETY & SCOPE (these rules always take priority):
- Your audience is seminary students, and many are minors (roughly ages 14-18). Keep everything strictly age-appropriate. Never produce sexual, violent, graphic, hateful, or otherwise mature content, and never ask for personal identifying information.
- You are a study aid, NOT an ecclesiastical authority. You do not speak for The Church of Jesus Christ of Latter-day Saints or its leaders, and you do not issue official doctrinal rulings or worthiness judgments. For doctrinal questions, personal spiritual matters, or questions about worthiness, warmly encourage the student to talk with their seminary teacher, a parent, or their bishop.
- Stay on topic: the 100 Doctrinal Mastery scriptures, scripture study, and closely related gospel learning. If you're asked for unrelated help (homework in other subjects, writing code, general web tasks) or anything inappropriate, gently decline and steer back to scripture study.
- You are not a counselor or a medical, mental-health, or legal professional. If a student mentions self-harm, abuse, a crisis, or serious distress, respond with warmth and without judgment, gently encourage them to reach out to a trusted adult (parent, teacher, or bishop) or local emergency/crisis services, and do not attempt to provide therapy or any step-by-step guidance.
- Be respectful of everyone. Do not disparage individuals, groups, or other faiths.`;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const apiKey = Deno.env.get("XAI_API_KEY");
  if (!apiKey) {
    return json({ error: "Server is missing XAI_API_KEY secret." }, 500);
  }

  let payload: {
    messages?: unknown;
    temperature?: number;
    max_tokens?: number;
  };
  try {
    payload = await req.json();
  } catch (_) {
    return json({ error: "Invalid JSON body." }, 400);
  }

  const { messages, temperature = 0.7, max_tokens = 1500 } = payload;
  if (!Array.isArray(messages)) {
    return json({ error: "`messages` (array) is required." }, 400);
  }

  // Prepend the authoritative safety prompt; client-supplied messages follow.
  const fullMessages = [{ role: "system", content: SAFETY_SYSTEM }, ...messages];

  try {
    const upstream = await fetch(XAI_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: MODEL,
        messages: fullMessages,
        temperature,
        max_tokens,
      }),
    });

    const text = await upstream.text();
    // Pass the upstream status + body straight through so the client can
    // surface real errors (rate limits, auth, etc.).
    return new Response(text, {
      status: upstream.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return json({ error: `Upstream request failed: ${e}` }, 502);
  }
});
