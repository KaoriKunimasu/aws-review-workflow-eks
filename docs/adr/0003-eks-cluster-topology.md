# 0003. EKS cluster topology and tooling choices

## Status
Accepted

## Context
The containerized review API needs a Kubernetes platform. The cluster must be 
reproducible, low-cost for a dev/demo environment, use current AWS-recommended
access control, and not disturb the existing serverless resources in this
environment.

## Decision
- Use the community terraform-aws-modules/eks module instead of hand-writing
  EKS resources, for correct defaults on the OIDC provider, node groups, and
  access entries with less surface area.
- Pin the EKS module to the v20.x line. The existing serverless stack pins the
  AWS provider to ~> 5.0, and the latest EKS module (v21) requires AWS provider
  >= 6.x. Upgrading the provider major version is deferred to its own scope to
  avoid unplanned diffs on existing Lambda/API Gateway/Cognito/DynamoDB
  resources. v20.x is compatible with AWS provider 5.x.
- Run a managed node group (t3.small x2) rather than Fargate, to keep node
  operations visible and the setup simple.
- Use EKS access entries (enable_cluster_creator_admin_permissions) rather than
  the deprecated aws-auth ConfigMap.
- Provision a dedicated VPC with a single NAT gateway to limit dev cost.
- Tag subnets for future AWS Load Balancer Controller discovery, even though
  Ingress is deferred.

## Consequences
- The cluster is reproducible via Terraform and uses current access control.
- Staying on EKS module v20.x is a deliberate trade-off: not the newest module,
  but it avoids a risky provider upgrade to the existing stack. The provider
  upgrade can be done later as an isolated change.
- Single NAT gateway is a cost/availability trade-off acceptable for dev only.
- IRSA for DynamoDB access and Ingress are handled in follow-up work.
