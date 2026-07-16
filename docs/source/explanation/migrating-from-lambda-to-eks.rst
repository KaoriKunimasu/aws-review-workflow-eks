Migrating from Lambda to EKS
==============================

The original implementation ran as four Lambda functions behind API Gateway, with a Cognito JWT authorizer handling auth and a DynamoDB single-table model storing everything. Here's what moved, what didn't, and what got left out on purpose.

What stayed the same
----------------------

The DynamoDB data model didn't move. Items still use ``PK``/``SK`` with ``REQUEST#{id}``/``METADATA``, and the validation and business logic (create, list, get, update status) were extracted from the Lambda handlers into a transport-agnostic service layer, ``app/api/service.py``, rather than rewritten. ``docs/adr/0002-eks-migration-strategy.md`` documents this as the deliberate scope: keep the domain logic and the table, replace the transport.

Swapping the transport layer
--------------------------------

API Gateway's event parsing, the Lambda proxy response shape, and the JWT authorizer are gone. In their place: a FastAPI app with Pydantic request models, dependency injection, and exception handlers. The four Lambda handlers became four route functions calling the same service layer.

One thing was initially left out and later restored. Real Cognito JWT verification was not carried over in the first cut of the migration; the app briefly trusted an ``X-User-Id`` header stub. That gap has since been closed: ``app/api/deps.py`` now verifies the Cognito access token (with ``AUTH_MODE=cognito``) and derives the caller's identity from its ``sub`` claim. What remains open is *authorization* — there is still no per-owner scoping, so any authenticated caller can act on any request. See :doc:`workload-access-with-irsa` for how DynamoDB access is scoped, the Kubernetes-resources reference for the auth-related config, and the README's security notes.

Trade-offs that came with the move
--------------------------------------

Container images are portable across environments, dependency versions are pinned at build time rather than resolved by the Lambda runtime, and local development runs the same container that ships to production rather than a separate emulation layer. Autoscaling is explicit (replica counts, resource requests) rather than implicit in the Lambda execution model.

Against that: a cluster has a control plane, a node group, and a NAT gateway running whether or not a single request comes in. Lambda's per-invocation billing has no equivalent baseline. Operating EKS also means someone owns node patching, cluster upgrades, and Kubernetes version deprecations, none of which existed under Lambda. ``docs/adr/0003-eks-cluster-topology.md`` and ``docs/adr/0004-terraform-version-constraints-and-ci.md`` cover the concrete decisions made to keep this manageable for a dev environment: a single managed node group, a single NAT gateway, staying on an older EKS module version to avoid an unplanned AWS provider upgrade across the whole stack.

When Lambda would have been the better call
-----------------------------------------------

For a workload at this traffic level, with this few endpoints, Lambda's operational simplicity is a real advantage this migration gives up. The trade-off only earns its cost if there's a reason to want a long-running process, container portability, or Kubernetes-specific tooling, none of which this project strictly needed. See :doc:`serverless-and-kubernetes-trade-offs` for where that line sits in general, not just for this repository.