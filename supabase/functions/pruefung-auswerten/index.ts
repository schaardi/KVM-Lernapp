// Edge Function „pruefung-auswerten“: KI-Auswertung der Original-Prüfungen mit
// Claude Sonnet 5.5. Ablauf und Prüfauftrag stehen in kern.ts, Nutzung und
// Tageslimit in docs/supabase-ki-auswertung.sql, Einrichtung in
// SUPABASE_SETUP.md (Abschnitt 12).
//
// Der API-Key steht nur hier, als Secret ANTHROPIC_API_KEY (Supabase ›
// Edge Functions › Secrets) – nie in der App oder im Repository. Ohne ihn
// antwortet die Funktion mit 503 „nicht_eingerichtet“.
import Anthropic from "npm:@anthropic-ai/sdk@0.131.0";
import { createClient } from "npm:@supabase/supabase-js@2.117.2";
import { base64, type Bild, handler, MODELL, type Pruefung } from "./kern.ts";

const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false, autoRefreshToken: false },
});
const KEY = Deno.env.get("ANTHROPIC_API_KEY") || "";
// Ein Versuch, höchstens 115 s: Die App wiederholt selbst, und die Anfrage
// bleibt unter der Zeitgrenze der Edge Functions (150 s).
const claude = KEY ? new Anthropic({ apiKey: KEY, timeout: 115_000, maxRetries: 0 }) : null;

// pruefungen.json aus dem privaten Bucket, 10 Minuten zwischengespeichert.
type Paket = { pruefungen: Map<string, Pruefung>; anlagen: Record<string, { f?: unknown; t?: unknown }> };
let paket: { zeit: number; daten: Promise<Paket> } | null = null;
function laden(): Promise<Paket> {
  if (paket && Date.now() - paket.zeit < 10 * 60_000) return paket.daten;
  const daten = (async () => {
    const { data, error } = await sb.storage.from("pruefungen").download("pruefungen.json");
    if (error || !data) throw new Error("pruefungen.json: " + (error?.message || "fehlt"));
    const roh = JSON.parse(await data.text());
    const m = new Map<string, Pruefung>();
    for (const p of Array.isArray(roh?.pruefungen) ? roh.pruefungen : []) {
      if (p && typeof p.id === "string" && Array.isArray(p.steps)) m.set(p.id, p);
    }
    return { pruefungen: m, anlagen: roh?.anlagen && typeof roh.anlagen === "object" ? roh.anlagen : {} };
  })();
  paket = { zeit: Date.now(), daten };
  daten.catch(() => {
    if (paket?.daten === daten) paket = null;
  });
  return daten;
}

// Abbildungen unter anlagen/ im Bucket, als Base64 zwischengespeichert.
const TYPEN: Record<string, Bild["media_type"]> = {
  jpg: "image/jpeg",
  jpeg: "image/jpeg",
  png: "image/png",
  webp: "image/webp",
  gif: "image/gif",
};
const bilder = new Map<string, Bild>();
async function bild(ref: string): Promise<Bild | null> {
  const schon = bilder.get(ref);
  if (schon) return schon;
  const a = (await laden()).anlagen[ref];
  if (!a || typeof a.f !== "string") return null;
  const typ = TYPEN[(a.f.split(".").pop() || "").toLowerCase()];
  if (!typ) return null;
  const { data, error } = await sb.storage.from("pruefungen").download("anlagen/" + a.f);
  if (error || !data) return null;
  const b: Bild = {
    media_type: typ,
    data: base64(new Uint8Array(await data.arrayBuffer())),
    titel: typeof a.t === "string" ? a.t : "",
  };
  if (bilder.size >= 40) bilder.delete(bilder.keys().next().value!);
  bilder.set(ref, b);
  return b;
}

async function rpc<T>(fn: string, args: Record<string, unknown>): Promise<T> {
  const { data, error } = await sb.rpc(fn, args);
  if (error) throw new Error(`${fn}: ${error.message}`);
  return data as T;
}

Deno.serve(handler({
  claude,
  async nutzer(req) {
    const jwt = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
    if (!jwt) return null;
    const { data, error } = await sb.auth.getUser(jwt);
    return error || !data?.user ? null : data.user.id;
  },
  pruefung: async (id) => (await laden()).pruefungen.get(id) || null,
  bild,
  beginnen: (user, pruefung, anzahl) => rpc("ki_beginnen", { p_user: user, p_pruefung: pruefung, p_anzahl: anzahl }),
  aufruf: (id, user, pruefung) => rpc("ki_aufruf", { p_id: id, p_user: user, p_pruefung: pruefung }),
  aufgabe: (id, nr, punkte, max, eingabe, ausgabe) =>
    rpc("ki_aufgabe", {
      p_id: id,
      p_nr: nr,
      p_punkte: punkte,
      p_max: max,
      p_modell: MODELL,
      p_eingabe: eingabe,
      p_ausgabe: ausgabe,
    }),
  fehlschlag: async (id, eingabe, ausgabe, fehler) => {
    await rpc("ki_fehlschlag", { p_id: id, p_eingabe: eingabe, p_ausgabe: ausgabe, p_fehler: fehler });
  },
}));
