# Frontend Authentication

> **EKS migration note:** this document was written for the original
> Cognito + API Gateway deployment. The frontend still runs the Cognito
> Hosted UI / PKCE login flow described below to obtain a token, but the
> FastAPI backend on EKS does not verify that token at all: it trusts an
> `X-User-Id` header (`app/api/deps.py`), which the frontend populates from
> the client-decoded `sub` claim. There is no API Gateway JWT authorizer in
> this deployment, and only `POST /reviews` even reads the header — the
> other endpoints (`list_reviews`, `get_review`, `update_status`) accept no
> identity at all. See `docs/adr/0002-eks-migration-strategy.md`.

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

On EKS this trade-off is worse than it looks: the backend does not verify
the token or scope access by owner at all (see the migration note above),
so a stolen token — or simply any `X-User-Id` value a caller chooses to
send — grants full read/write access to every request in the shared queue,
not just the caller's own.

A production hardening step would be to move tokens to `httpOnly`, `Secure`,
`SameSite` cookies (eliminating script access) and pair them with CSRF
protection, or to keep tokens in memory only and rely on a refresh-token
rotation flow.

### Client-side JWT decoding

`decodeJwtPayload` base64url-decodes the JWT payload **without verifying the
signature**. This is intentional and safe in this design: the decoded claims
are used only for display purposes (e.g. showing the signed-in user). The
browser never makes a trust decision based on these claims.

In the original Lambda/API Gateway deployment, authorization was enforced by
the API Gateway JWT authorizer before any handler ran. **On EKS this layer
does not exist.** The FastAPI app performs no signature, issuer, or expiry
verification of any kind; `X-User-Id` is taken at face value. Wiring up real
Cognito JWT verification in `app/api/deps.py` is a planned follow-up, not
something already covered by a different layer.

## Summary

| Concern            | Current approach                                  | Production hardening                    |
| ------------------ | -------------------------------------------------- | ---------------------------------------- |
| Auth flow          | Authorization Code + PKCE (`S256`)                 | unchanged                                |
| Token storage      | `localStorage`, expiry-checked                     | `httpOnly` cookies + CSRF, or in-memory  |
| JWT trust on client| decode-only, display use                           | unchanged                                |
| Authentication     | none — `X-User-Id` header taken at face value      | verify Cognito JWT in `app/api/deps.py`  |
| Authorization      | none — shared queue, no owner scoping              | add per-owner/role-based access checks   |
