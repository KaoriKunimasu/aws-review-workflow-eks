# Frontend Authentication

> **EKS migration note:** this document was written for the original
> Cognito + API Gateway deployment, where an API Gateway JWT authorizer
> verified tokens before any handler ran. That authorizer does not exist on
> EKS, so the verification was moved into the app: with `AUTH_MODE=cognito`,
> `app/api/deps.py` now verifies the Cognito access token sent in the
> `Authorization: Bearer` header and derives the caller's identity from its
> verified `sub` claim. The frontend sends that token on every API call
> (`app/frontend/src/lib/api/client.ts`); the old `X-User-Id` header stub is
> gone. `AUTH_MODE=none` (local development only) skips verification and
> returns a fixed placeholder identity.
>
> **Authentication is enforced; authorization is partial.** Submitting,
> listing, and reading requests only require a valid token — this is a
> shared review queue, so any authenticated user can see and create requests
> in it. Changing a request's status additionally requires membership in the
> Cognito `reviewer` group, checked in `app/api/deps.py:require_reviewer`, so
> an authenticated non-reviewer cannot approve or reject anything, including
> their own submission. There is still no per-owner scoping on reads, and no
> bootstrap path into the reviewer group — membership is granted manually.
> See `docs/adr/0002-eks-migration-strategy.md` and
> `docs/adr/0005-reviewer-group-authorization.md`.

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

On EKS this trade-off still matters. The backend now verifies the token, so
a caller can no longer fabricate an identity. What a stolen token buys an
attacker depends on whose it is: any token lets them read and create
requests, and a reviewer's token lets them approve or reject every request
in the queue, since nothing scopes a reviewer to their own filings. So a
short-lived token in `localStorage` is a real exposure, and most so for
reviewer accounts, until token storage is hardened.

A production hardening step would be to move tokens to `httpOnly`, `Secure`,
`SameSite` cookies (eliminating script access) and pair them with CSRF
protection, or to keep tokens in memory only and rely on a refresh-token
rotation flow.

### Client-side JWT decoding

`decodeJwtPayload` base64url-decodes the JWT payload **without verifying the
signature**. This is intentional and safe in this design: the decoded claims
are used only for display purposes (e.g. showing the signed-in user). The
browser never makes a trust decision based on these claims.

In the original Lambda/API Gateway deployment, token verification was enforced
by the API Gateway JWT authorizer before any handler ran. **On EKS that layer
does not exist**, so the equivalent check now lives in the app:
`app/api/deps.py` verifies the Cognito access token (signature, issuer,
expiry) and derives identity from its `sub` claim. Proving identity is
authentication; deciding what that identity may do is authorization, and
only the status-change endpoint checks the latter, via the token's `groups`
claim (see the migration note).

## Summary

| Concern            | Current approach                                  | Production hardening                    |
| ------------------ | -------------------------------------------------- | ---------------------------------------- |
| Auth flow          | Authorization Code + PKCE (`S256`)                 | unchanged                                |
| Token storage      | `localStorage`, expiry-checked                     | `httpOnly` cookies + CSRF, or in-memory  |
| JWT trust on client| decode-only, display use                           | unchanged                                |
| Authentication     | Cognito access token verified in `app/api/deps.py` | unchanged                                |
| Authorization      | status changes require `reviewer` group; reads/create are unscoped | add per-owner scoping on reads |
