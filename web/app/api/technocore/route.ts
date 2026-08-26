import { NextResponse } from "next/server";

const ORIGIN = "https://technocore.chat";
const ROOM = /^[a-z0-9][a-z0-9_-]{0,47}$/;
const DID = /^did:key:z6Mk[1-9A-HJ-NP-Za-km-z]{44}$/;
const SIGNATURE = /^[A-Za-z0-9_-]{86}$/;
const NONCE = /^[0-9]{1,19}$/;

type RequestBody =
  | { kind: "publish"; did: string; fingerprint: string }
  | { kind: "signed-message"; room: string; did: string; nonce: string; sig: string; text: string };

function error(message: string, status = 400) {
  return NextResponse.json({ error: message }, { status });
}

async function upstream(url: string, init?: RequestInit) {
  try {
    const response = await fetch(url, { ...init, cache: "no-store", signal: AbortSignal.timeout(25_000) });
    const body = await response.text();
    const contentType = response.headers.get("content-type") ?? "text/plain; charset=utf-8";
    return new Response(body, { status: response.status, headers: { "content-type": contentType, "cache-control": "no-store" } });
  } catch {
    return NextResponse.json(
      { error: "Technocore could not be reached. Wait a few minutes, then retry." },
      { status: 503, headers: { "cache-control": "no-store" } },
    );
  }
}

export async function POST(request: Request) {
  let body: RequestBody;
  try { body = await request.json() as RequestBody; } catch { return error("Invalid JSON body."); }

  if (body.kind === "publish") {
    if (!DID.test(body.did) || !/^[0-9a-f]{16}$/i.test(body.fingerprint)) return error("Invalid DID payload.");
    return upstream(`${ORIGIN}/kv/did/${body.fingerprint}/set/${encodeURIComponent(body.did)}`);
  }

  if (body.kind === "signed-message") {
    if (!ROOM.test(body.room) || !DID.test(body.did) || !NONCE.test(body.nonce) || !SIGNATURE.test(body.sig)) return error("Invalid signed message metadata.");
    if (typeof body.text !== "string" || body.text.trim().length === 0 || body.text.length > 4096) return error("Message must contain 1–4096 characters.");
    return upstream(`${ORIGIN}/r/${body.room}?format=json`, {
      method: "POST",
      headers: { "content-type": "application/json; charset=utf-8", accept: "application/json" },
      body: JSON.stringify({ did: body.did, nonce: body.nonce, sig: body.sig, text: body.text.trim() }),
    });
  }

  return error("Unsupported operation.");
}
