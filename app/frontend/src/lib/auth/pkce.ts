const PKCE_CHARSET =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";

function toBase64Url(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  let binary = "";

  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }

  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

export function createRandomString(length = 64): string {
  const values = crypto.getRandomValues(new Uint8Array(length));

  return Array.from(values, (value) => PKCE_CHARSET[value % PKCE_CHARSET.length]).join("");
}

export async function createCodeChallenge(verifier: string): Promise<string> {
  const encoded = new TextEncoder().encode(verifier);
  const digest = await crypto.subtle.digest("SHA-256", encoded);

  return toBase64Url(digest);
}

export async function createPkcePair(): Promise<{
  codeVerifier: string;
  codeChallenge: string;
}> {
  const codeVerifier = createRandomString(64);
  const codeChallenge = await createCodeChallenge(codeVerifier);

  return {
    codeVerifier,
    codeChallenge,
  };
}
