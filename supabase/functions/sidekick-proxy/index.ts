// Seminary Sidekick — xAI (Grok) proxy.
//
// Holds the xAI API key server-side (as the `XAI_API_KEY` function secret) so
// it is NEVER shipped in the app binary, and prepends an authoritative safety
// system prompt that holds even if a tampered client alters its own prompts.
//
// Deploy:   supabase functions deploy sidekick-proxy
// Secrets:  supabase secrets set XAI_API_KEY=xai-...
//           supabase secrets set REVENUECAT_SECRET_KEY=sk_...   (entitlement gate)
// JWT:      verify_jwt stays ON (default) — the app's anonymous Supabase
//           session authorizes the call via supabase_flutter functions.invoke.
//
// Entitlement gate: when REVENUECAT_SECRET_KEY is set, every request must
// include the caller's RevenueCat `app_user_id`, and the function verifies the
// `premium` entitlement via the RevenueCat REST API (cached ~15 min per user)
// before spending xAI tokens. Without the secret the check is SKIPPED (dev
// environments) and a warning is logged.
//
// Request body:  { messages: [...], temperature?: number, max_tokens?: number,
//                  app_user_id?: string }
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

const RC_SUBSCRIBERS_URL = "https://api.revenuecat.com/v1/subscribers/";
const RC_ENTITLEMENT = "premium";
const RC_CACHE_TTL_MS = 15 * 60 * 1000;

// appUserId -> cache expiry (ms epoch). Edge isolates are ephemeral, so this
// is best-effort: worst case we re-check with RevenueCat.
const entitlementCache = new Map<string, number>();

async function hasPremiumEntitlement(
  appUserId: string,
  rcKey: string,
): Promise<boolean> {
  const cached = entitlementCache.get(appUserId);
  if (cached && cached > Date.now()) return true;

  const res = await fetch(
    RC_SUBSCRIBERS_URL + encodeURIComponent(appUserId),
    { headers: { Authorization: `Bearer ${rcKey}` } },
  );
  if (!res.ok) return false;

  const data = await res.json();
  const ent = data?.subscriber?.entitlements?.[RC_ENTITLEMENT];
  const active = !!ent &&
    (!ent.expires_date ||
      new Date(ent.expires_date).getTime() > Date.now());

  if (active) entitlementCache.set(appUserId, Date.now() + RC_CACHE_TTL_MS);
  return active;
}

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
    app_user_id?: unknown;
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

  // Premium entitlement gate — Sidekick AI is a paid feature. Enforced only
  // when the RevenueCat secret is configured, so dev/CI setups keep working.
  const rcKey = Deno.env.get("REVENUECAT_SECRET_KEY");
  if (rcKey) {
    const appUserId =
      typeof payload.app_user_id === "string" ? payload.app_user_id : "";
    let entitled = false;
    if (appUserId) {
      try {
        entitled = await hasPremiumEntitlement(appUserId, rcKey);
      } catch (e) {
        console.error(`RevenueCat entitlement check failed: ${e}`);
      }
    }
    if (!entitled) {
      return json(
        { error: "A premium subscription is required to use the Sidekick." },
        403,
      );
    }
  } else {
    console.warn(
      "REVENUECAT_SECRET_KEY not set — skipping premium entitlement check.",
    );
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
    // Normalize provider overload / rate-limit responses so the client can
    // treat them as retryable (FLUTTER-6: raw 529 was reported as a crash).
    if (upstream.status === 429 ||
      upstream.status === 502 ||
      upstream.status === 503 ||
      upstream.status === 529) {
      return json(
        {
          error:
            "The Sidekick is briefly unavailable. Please try again in a moment.",
          code: "upstream_unavailable",
          retryable: true,
        },
        503,
      );
    }
    // Pass other upstream statuses + bodies through so the client can
    // surface real errors (auth, validation, etc.).
    return new Response(text, {
      status: upstream.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (e) {
    return json({ error: `Upstream request failed: ${e}` }, 502);
  }
});
