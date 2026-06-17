# Frontend Authentication

## Overview

The frontend authenticates users through the Cognito Hosted UI using the
OAuth 2.0 Authorization Code flow with PKCE (`S256`). No client secret is
stored in the browser, and all Cognito endpoints and client IDs are supplied
via environment variables (`VITE_COGNITO_*`), never hardcoded.

Flow:

1. `startHostedUiLogin` generates a PKCE verifier/challenge and a random
   `state`, stores them in `sessionStorage`, and redirects to the Hosted UI.
2. On callback, `completeHostedUiLogin` validates the returned `state`
   against the stored value, then exchanges the authorization code for tokens
   at the `/oauth2/token` endpoint using the PKCE verifier.
3. The resulting session (access token, optional id/refresh token, expiry) is
   persisted and used to authorize API calls.

## Design decisions and trade-offs

### Token storage: `localStorage`

The established session is stored in `localStorage`, while the short-lived
PKCE state is kept in `sessionStorage` and cleared immediately after the code
exchange.

`localStorage` is chosen here for simplicity in a single-page app: it survives
page reloads and is straightforward to read from the API client. The known
trade-off is exposure to XSS — any injected script can read `localStorage`.
This is accepted for this project because:

- The app ships no third-party runtime scripts and has a small, reviewed
  dependency surface, limiting XSS vectors.
- Tokens are short-lived; `getStoredSession` checks `expiresAt` on every read
  and discards expired sessions.
- The token grants access only to this user's own request records, scoped by
  the backend authorizer (see below).

A production hardening step would be to move tokens to `httpOnly`, `Secure`,
`SameSite` cookies (eliminating script access) and pair them with CSRF
protection, or to keep tokens in memory only and rely on a refresh-token
rotation flow.

### Client-side JWT decoding

`decodeJwtPayload` base64url-decodes the JWT payload **without verifying the
signature**. This is intentional and safe in this design: the decoded claims
are used only for display purposes (e.g. showing the signed-in user). The
browser never makes a trust decision based on these claims.

All authorization is enforced server-side: every protected route sits behind
the API Gateway JWT authorizer, which validates the token signature, issuer,
and expiry against Cognito before any Lambda runs. A tampered token is
rejected at the gateway regardless of what the client decoded.

## Summary

| Concern            | Current approach                     | Production hardening                          |
| ------------------ | ------------------------------------ | --------------------------------------------- |
| Auth flow          | Authorization Code + PKCE (`S256`)   | unchanged                                     |
| Token storage      | `localStorage`, expiry-checked       | `httpOnly` cookies + CSRF, or in-memory       |
| JWT trust on client| decode-only, display use             | unchanged (authz stays server-side)           |
| Authorization      | API Gateway JWT authorizer           | unchanged                                     |
