# Kubernetes manifests

Manifests for running the review API on Kubernetes.

## Layout
- `base/` — Deployment, Service (ClusterIP), and ConfigMap, composed with kustomize.

## Local validation (kind)
\`\`\`
kind create cluster --name review-dev
docker build -t review-api:local ..
kind load docker-image review-api:local --name review-dev
kubectl apply -k base
kubectl rollout status deployment/review-api
\`\`\`

The `/health` endpoint does not touch DynamoDB, so pods become Ready on kind
without AWS access. Real DynamoDB access on EKS is handled via IRSA (follow-up).

## EKS
The image reference in `base/deployment.yaml` is replaced with the ECR image
URI (see `infra/environments/dev` outputs) before applying to EKS.
