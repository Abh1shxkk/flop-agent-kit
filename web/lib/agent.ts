import nacl from "tweetnacl";

export type AgentKey = {
  private_key: string;
  public_key: string;
  did: string;
  created_at: string;
};

const alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
const encoder = new TextEncoder();

export function bytesToHex(bytes: Uint8Array) {
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, "0")).join("");
}

export function hexToBytes(hex: string) {
  if (!/^[0-9a-f]{64}$/i.test(hex)) throw new Error("Private key must be 32 bytes of hexadecimal data.");
  return new Uint8Array(hex.match(/.{1,2}/g)!.map((byte) => Number.parseInt(byte, 16)));
}

export function base58Encode(bytes: Uint8Array) {
  let value = 0n;
  for (const byte of bytes) value = (value << 8n) + BigInt(byte);
  let output = "";
  while (value > 0n) {
    output = alphabet[Number(value % 58n)] + output;
    value /= 58n;
  }
  let leadingZeroes = 0;
  while (leadingZeroes < bytes.length && bytes[leadingZeroes] === 0) leadingZeroes++;
  return "1".repeat(leadingZeroes) + output;
}

export function didFromPublicKey(publicKey: Uint8Array) {
  return `did:key:z${base58Encode(new Uint8Array([0xed, 0x01, ...publicKey]))}`;
}

export function createAgentKey(): AgentKey {
  const pair = nacl.sign.keyPair();
  const privateKey = pair.secretKey.slice(0, 32);
  return {
    private_key: bytesToHex(privateKey),
    public_key: bytesToHex(pair.publicKey),
    did: didFromPublicKey(pair.publicKey),
    created_at: new Date().toISOString().replace(/\.\d{3}Z$/, "Z"),
  };
}

export function readAgentKey(value: unknown): AgentKey {
  if (!value || typeof value !== "object") throw new Error("Invalid key file.");
  const key = value as Partial<AgentKey>;
  if (typeof key.private_key !== "string") throw new Error("Key file has no private_key.");
  const pair = nacl.sign.keyPair.fromSeed(hexToBytes(key.private_key));
  const did = didFromPublicKey(pair.publicKey);
  if (key.did && key.did !== did) throw new Error("Key file DID does not match its private key.");
  return { private_key: bytesToHex(pair.secretKey.slice(0, 32)), public_key: bytesToHex(pair.publicKey), did, created_at: key.created_at ?? new Date().toISOString() };
}

export function signPayload(key: AgentKey, room: string, nonce: string, text: string) {
  const pair = nacl.sign.keyPair.fromSeed(hexToBytes(key.private_key));
  const signature = nacl.sign.detached(encoder.encode(`${room}|${nonce}|${text}`), pair.secretKey);
  let binary = "";
  for (const byte of signature) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export function didFingerprint(did: string) {
  return crypto.subtle.digest("SHA-256", encoder.encode(did)).then((hash) =>
    Array.from(new Uint8Array(hash), (byte) => byte.toString(16).padStart(2, "0")).join("").slice(0, 16),
  );
}

export function downloadKey(key: AgentKey) {
  const file = new Blob([JSON.stringify(key, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(file);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = "agent_key.json";
  anchor.click();
  URL.revokeObjectURL(url);
}
