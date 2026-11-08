// Edge Function: revenuecat-webhook
//
// Reçoit les webhooks RevenueCat et les enregistre dans public.subscription_events, pour
// que le serveur connaisse le statut Premium et le revenu net sans dépendre du client.
//
// Authentification : RevenueCat envoie l'en-tête `Authorization` configuré dans son
// dashboard ; il doit valoir exactement `Bearer <REVENUECAT_WEBHOOK_SECRET>`. La fonction
// est déployée avec verify_jwt = false (RevenueCat n'a pas de JWT Supabase).
//
// Idempotent : un événement déjà reçu (même event.id) est ignoré. Toujours 200 quand
// l'événement est enregistré ou déjà connu, pour que RevenueCat ne le renvoie pas.
//
// Secrets : REVENUECAT_WEBHOOK_SECRET (réglages des Edge Functions). SUPABASE_URL et
// SUPABASE_SERVICE_ROLE_KEY sont injectés par le runtime.

import { createClient } from "jsr:@supabase/supabase-js@2";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

type RcEvent = {
  id?: string;
  type?: string;
  app_user_id?: string;
  original_app_user_id?: string;
  aliases?: string[];
  product_id?: string;
  entitlement_ids?: string[] | null;
  period_type?: string;
  store?: string;
  environment?: string;
  price?: number | null;
  currency?: string | null;
  price_in_purchased_currency?: number | null;
  takehome_percentage?: number | null;
  country_code?: string | null;
  offer_code?: string | null;
  cancel_reason?: string | null;
  is_trial_conversion?: boolean | null;
  renewal_number?: number | null;
  presented_offering_id?: string | null;
  transaction_id?: string | null;
  original_transaction_id?: string | null;
  purchased_at_ms?: number | null;
  expiration_at_ms?: number | null;
  event_timestamp_ms?: number;
};

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  const secret = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");
  if (!secret) {
    return json({ error: "webhook_secret_not_configured" }, 503);
  }
  const auth = req.headers.get("authorization") ?? "";
  if (!timingSafeEqual(auth, `Bearer ${secret}`)) {
    return json({ error: "unauthorised" }, 401);
  }

  let body: { event?: RcEvent };
  try {
    body = await req.json();
  } catch {
    return json({ error: "invalid_json" }, 400);
  }
  const event = body.event;
  if (!event?.id || !event.type || !event.app_user_id || !event.event_timestamp_ms) {
    return json({ error: "invalid_event" }, 400);
  }

  const aliases = Array.isArray(event.aliases) ? event.aliases : [];
  const userId =
    [event.app_user_id, event.original_app_user_id, ...aliases].find(
      (candidate) => typeof candidate === "string" && UUID.test(candidate),
    ) ?? null;

  const row = {
    rc_event_id: event.id,
    type: event.type,
    app_user_id: event.app_user_id,
    original_app_user_id: event.original_app_user_id ?? null,
    user_id: userId,
    aliases,
    product_id: event.product_id ?? null,
    entitlement_ids: Array.isArray(event.entitlement_ids) ? event.entitlement_ids : [],
    period_type: event.period_type ?? null,
    store: event.store ?? null,
    environment: event.environment ?? null,
    price: event.price ?? null,
    currency: event.currency ?? null,
    price_in_purchased_currency: event.price_in_purchased_currency ?? null,
    takehome_percentage: event.takehome_percentage ?? null,
    country_code: event.country_code ?? null,
    offer_code: event.offer_code ?? null,
    cancel_reason: event.cancel_reason ?? null,
    is_trial_conversion: event.is_trial_conversion ?? null,
    renewal_number: event.renewal_number ?? null,
    presented_offering_id: event.presented_offering_id ?? null,
    transaction_id: event.transaction_id ?? null,
    original_transaction_id: event.original_transaction_id ?? null,
    purchased_at: msToIso(event.purchased_at_ms),
    expiration_at: msToIso(event.expiration_at_ms),
    event_ts: msToIso(event.event_timestamp_ms),
    raw: body,
  };

  const admin = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
  const { error } = await admin
    .from("subscription_events")
    .upsert(row, { onConflict: "rc_event_id", ignoreDuplicates: true });

  if (error) {
    console.error("subscription_events insert failed", error.message);
    return json({ error: "storage_failed" }, 500);
  }
  return json({ ok: true }, 200);
});

function msToIso(ms: number | null | undefined): string | null {
  if (typeof ms !== "number" || !Number.isFinite(ms)) return null;
  return new Date(ms).toISOString();
}

function timingSafeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const x = enc.encode(a);
  const y = enc.encode(b);
  if (x.length !== y.length) return false;
  let diff = 0;
  for (let i = 0; i < x.length; i++) diff |= x[i] ^ y[i];
  return diff === 0;
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
