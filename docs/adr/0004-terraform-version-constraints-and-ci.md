# ADR 0004: Terraform version constraints and CI scope

## Status
Accepted

## Context
This repository began as a serverless application whose Terraform pins the AWS
provider to `~> 5.0`. The EKS migration adds an EKS cluster, ECR, a dedicated
VPC, and an IRSA role to the same `infra/environments/dev` configuration, so the
new infrastructure has to coexist with the existing serverless resources under a
single provider configuration.

Two concrete constraints surfaced during implementation:

1. **EKS community module vs. AWS provider version.** The latest
   `terraform-aws-modules/eks` (v21) requires AWS provider `>= 6.x`. Upgrading
   the provider to 6.x would force a re-plan of all existing serverless
   resources (Lambda, API Gateway, Cognito, DynamoDB) and risk unintended
   diffs.

2. **Stricter variable validation in newer Terraform.** Newer Terraform rejects
   `validation` blocks whose `condition` references a variable other than the
   one being validated. The inherited `infra/modules/api` module used
   cross-variable validations (e.g. requiring `jwt_authorizer_audience` only
   when `create_jwt_authorizer` is true). These passed on the original tooling
   but failed `terraform validate` in CI.

A third decision concerns what CI should do: full deploy vs. validation only.

## Decision

1. **Keep AWS provider `~> 5.0` and use the EKS module v20.x.** The migration
   stays on the v20.x line of `terraform-aws-modules/eks`, which is compatible
   with AWS provider 5.x. The EKS module also requires the `tls` and `time`
   providers, which are declared in `versions.tf`.

2. **Remove the cross-variable validations from the api module.** The dropped
   checks were convenience guards; the actual behavior (only creating the JWT
   authorizer and its requirements when enabled) is enforced by the conditional
   logic in `main.tf`. Self-referential validations are retained.

3. **CI is build-and-validation only, not deploy.** The GitHub Actions pipeline
   runs `pytest`, a Docker image build, `terraform fmt`/`init -backend=false`/
   `validate`, and `kubectl kustomize` on the EKS overlay. It does not apply
   Terraform or push images to ECR.

## Consequences

- The existing serverless resources are not disturbed by the EKS work; plans
  show only additions. The trade-off is staying one major version behind on the
  EKS module until the provider is upgraded deliberately.
- Validation that a JWT authorizer is fully configured now lives with the
  caller (the environment configuration) rather than the module. This should be
  documented for anyone reusing the module.
- CI requires no AWS credentials and is safe to run on every PR, but it does not
  prove that a real `apply` succeeds. Deploy correctness is verified manually
  (and could later be added via an OIDC-based workflow without long-lived keys).

## Notes
- A future migration to EKS module v21 / AWS provider 6.x should be done as an
  isolated change with a careful plan review of the serverless resources.
