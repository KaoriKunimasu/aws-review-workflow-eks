import { authConfig, authEndpoints } from "./config";
import { createPkcePair, createRandomString } from "./pkce";

const PKCE_STORAGE_KEY = "review-workflow.auth.pkce";
const SESSION_STORAGE_KEY = "review-workflow.auth.session";

type StoredPkceState = {
  codeVerifier: string;
  state: string;
};

type TokenResponse = {
  access_token: string;
  id_token?: string;
  refresh_token?: string;
  expires_in: number;
  token_type: string;
  scope?: string;
};

export type AuthSession = {
  accessToken: string;
  idToken: string | null;
  refreshToken: string | null;
  tokenType: string;
  expiresAt: number;
  claims: Record<string, unknown>;
};

function savePkceState(pkceState: StoredPkceState): void {
  sessionStorage.setItem(PKCE_STORAGE_KEY, JSON.stringify(pkceState));
}

function getPkceState(): StoredPkceState | null {
  const raw = sessionStorage.getItem(PKCE_STORAGE_KEY);

  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw) as StoredPkceState;
  } catch {
    sessionStorage.removeItem(PKCE_STORAGE_KEY);
    return null;
  }
}

function clearPkceState(): void {
  sessionStorage.removeItem(PKCE_STORAGE_KEY);
}

function decodeJwtPayload(token: string | null | undefined): Record<string, unknown> {
  if (!token) {
    return {};
  }

  const parts = token.split(".");

  if (parts.length < 2) {
    return {};
  }

  const payload = parts[1]
    .replace(/-/g, "+")
    .replace(/_/g, "/")
    .padEnd(Math.ceil(parts[1].length / 4) * 4, "=");

  try {
    const decoded = atob(payload);
    return JSON.parse(decoded) as Record<string, unknown>;
  } catch {
    return {};
  }
}

function saveSession(session: AuthSession): void {
  localStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(session));
}

export function clearStoredSession(): void {
  localStorage.removeItem(SESSION_STORAGE_KEY);
}

export function getStoredSession(): AuthSession | null {
  const raw = localStorage.getItem(SESSION_STORAGE_KEY);

  if (!raw) {
    return null;
  }

  try {
    const session = JSON.parse(raw) as AuthSession;

    if (!session.expiresAt || session.expiresAt <= Date.now()) {
      clearStoredSession();
      return null;
    }

    return session;
  } catch {
    clearStoredSession();
    return null;
  }
}

export async function startHostedUiLogin(): Promise<void> {
  const { codeVerifier, codeChallenge } = await createPkcePair();
  const state = createRandomString(32);

  savePkceState({
    codeVerifier,
    state,
  });

  const url = new URL(authEndpoints.authorize);

  url.searchParams.set("response_type", "code");
  url.searchParams.set("client_id", authConfig.clientId);
  url.searchParams.set("redirect_uri", authConfig.redirectUri);
  url.searchParams.set("scope", authConfig.scope);
  url.searchParams.set("state", state);
  url.searchParams.set("code_challenge_method", "S256");
  url.searchParams.set("code_challenge", codeChallenge);

  window.location.assign(url.toString());
}

export async function completeHostedUiLogin(params: {
  code: string;
  state: string;
}): Promise<AuthSession> {
  const pkceState = getPkceState();

  if (!pkceState) {
    throw new Error("Login session was not found. Please try signing in again.");
  }

  if (pkceState.state !== params.state) {
    clearPkceState();
    throw new Error("Login state validation failed. Please try signing in again.");
  }

  const body = new URLSearchParams({
    grant_type: "authorization_code",
    client_id: authConfig.clientId,
    code: params.code,
    redirect_uri: authConfig.redirectUri,
    code_verifier: pkceState.codeVerifier,
  });

  const response = await fetch(authEndpoints.token, {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: body.toString(),
  });

  const text = await response.text();

  if (!response.ok) {
    clearPkceState();
    throw new Error(`Token exchange failed: ${text || response.statusText}`);
  }

  let tokenResponse: TokenResponse;

  try {
    tokenResponse = JSON.parse(text) as TokenResponse;
  } catch {
    clearPkceState();
    throw new Error("Token response could not be parsed.");
  }

  const session: AuthSession = {
    accessToken: tokenResponse.access_token,
    idToken: tokenResponse.id_token ?? null,
    refreshToken: tokenResponse.refresh_token ?? null,
    tokenType: tokenResponse.token_type,
    expiresAt: Date.now() + tokenResponse.expires_in * 1000,
    claims: decodeJwtPayload(tokenResponse.id_token ?? tokenResponse.access_token),
  };

  saveSession(session);
  clearPkceState();

  return session;
}

export function logoutFromHostedUi(): void {
  clearPkceState();
  clearStoredSession();

  const url = new URL(authEndpoints.logout);

  url.searchParams.set("client_id", authConfig.clientId);
  url.searchParams.set("logout_uri", authConfig.logoutUri);

  window.location.assign(url.toString());
}
