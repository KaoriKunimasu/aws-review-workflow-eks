# ADR 0005: Authorization via a Cognito reviewer group

## Status
Accepted

## Context
ADR 0002 and the README both document a known gap left over from the EKS
migration: `app/api/deps.py` verifies a Cognito access token (who the caller
is) but nothing checks what that caller is allowed to do. In practice, any
authenticated user could call `PATCH /reviews/{id}/status` and approve or
reject any request, including their own submission.

Two designs were considered for closing this gap:

1. **Per-owner scoping.** Add an owner attribute to each item and restrict
   reads/writes to the item's creator. Rejected: this breaks the point of a
   review workflow. If only the creator can change status, the creator can
   approve their own submission, and no one else's judgment is ever required.
2. **Role separation.** Split "submit a request" from "approve or reject a
   request" into two capabilities, and require the second to come from a
   distinct role, not just any authenticated identity.

Role separation was chosen. Within that, "does everyone with a Cognito
account get treated as a reviewer" was rejected too: the user pool has
self-service sign-up enabled (`allow_admin_create_user_only = false`) so that
anyone can try the app without an invite. If every signed-up account were
automatically a reviewer, "authorization" would be authentication with an
extra label — the same account that can create a request could immediately
approve it.

A technical wrinkle: Cognito's ID token carries `cognito:groups` by default,
but the **access token does not** — and `app/api/auth.py` verifies the access
token, per Cognito's own guidance for API authorization. Getting group
membership onto the access token requires a Pre Token Generation trigger
running in "advanced" mode (`LambdaVersion = V2_0`), which can write to
`accessTokenGeneration.claimsToAddOrOverride` separately from the ID token.

## Decision

- Add a `reviewer` Cognito user group (`infra/modules/cognito`,
  `aws_cognito_user_group.reviewer`). Group membership is managed manually
  (Cognito console or CLI) — there is no self-service path into the group,
  by design.
- Add a Pre Token Generation (V2_0) Lambda trigger
  (`app/functions/pre_token_generation`) that copies the caller's group
  membership onto the access token as a comma-joined `groups` claim, since
  custom claim values must be strings.
- `app/api/deps.py` gains `require_reviewer`, which resolves claims the same
  way `get_current_user_id` does but additionally checks the `groups` claim
  for membership. Only `PATCH /reviews/{id}/status` uses it.
- `POST /reviews`, `GET /reviews`, and `GET /reviews/{id}` are unchanged:
  any authenticated user (reviewer or not) can submit a request and see the
  full queue. This is a shared review queue, not a private inbox — narrowing
  reads to "your own requests only" was considered and rejected, because it
  would stop reviewers from seeing what needs review.

## Consequences

- Self-approval is no longer possible for anyone outside the reviewer group.
  A reviewer can still approve their own submission if they happen to also
  be the requester — this ADR does not add an "not the same person" check,
  because in this tool's domain reviewers are expected to review each
  other's work as a team, not to be blocked from their own queue item.
- The reviewer group has no bootstrap mechanism (no "first user becomes
  reviewer" flow). Someone with Cognito admin access has to add accounts to
  the group manually. Documented as a manual step, not automated, since this
  is a small internal-style tool, not a multi-tenant product.
- List and detail reads remain open to any authenticated account, including
  ones never added to the reviewer group. That is an intentional trade-off
  for this ADR, not an oversight — see the rejected per-owner design above.
- The frontend does not hide the approve/reject controls from non-reviewers.
  They still render for anyone, and a non-reviewer's click now fails with a
  `403` instead of succeeding. This is enforced correctly by the backend
  either way; hiding the controls client-side would be a UX improvement, not
  a security fix, and is not included here.
