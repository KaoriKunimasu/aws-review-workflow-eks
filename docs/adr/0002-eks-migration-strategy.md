# 0002. EKS migration strategy: keep business logic, swap the transport layer

## Status
Accepted

## Context
The original app runs as four AWS Lambda handlers behind API Gateway (HTTP API)
with a Cognito JWT authorizer and a DynamoDB single-table model
(PK/SK, REQUEST#{id} / METADATA). The target is Amazon EKS, which requires a
long-running HTTP server rather than per-request Lambda handlers.

## Decision
- Extract validation, item building, and DynamoDB access from the handlers into
  a transport-agnostic service layer (app/api/service.py).
- Expose it through FastAPI, reusing the existing DynamoDB data model unchanged.
- Replace API Gateway-specific concerns (event parsing, JWT claim extraction,
  Lambda proxy response shape) with FastAPI request models, dependencies, and
  exception handlers.
- Defer real Cognito JWT verification; for now an X-User-Id header stub maps to
  the original 'sub' claim, isolated in app/api/deps.py.
- Local validation uses DynamoDB Local with the base table only; the existing
  GSI1 is not created because no current handler queries it.

## Consequences
- Business logic and data model are preserved, keeping the migration low-risk.
- The transport boundary is small and well isolated, so swapping the auth stub
  for Cognito verification later is a localized change.
- Trade-offs vs serverless (cold start, idle cost, ops burden) are documented
  separately for the EKS deployment.
