# Review Workflow on Amazon EKS

An internal workflow application for technical terminology and document review.
The API originally ran as AWS Lambda functions behind API Gateway; this repository migrates that API to a containerized service running on Amazon EKS, while keeping the existing DynamoDB single-table data model and business logic unchanged.

## What this project is

This is a migration of an existing serverless API onto Kubernetes. The goal was to run the same workflow on EKS without rewriting the domain logic:

- The create/list/get/update logic was extracted from the Lambda handlers into a transport-agnostic service layer and exposed through a FastAPI app.
- Only the transport layer changed: API Gateway event parsing and the Cognito JWT authorizer were replaced with FastAPI request models, dependencies, and an exception handler.
- The DynamoDB single-table model (PK/SK, `REQUEST#{id}` / `METADATA`) is reused as-is.

The original serverless infrastructure (Cognito, API Gateway, Lambda) still lives in `app/functions/` and `infra/` as the starting point of the migration.

## Architecture

The API runs as a Deployment on EKS managed node groups, fronted by a Service, configured via a ConfigMap, and authenticated to DynamoDB through IRSA (a dedicated least-privilege IAM role per Pod, assumed via the cluster OIDC provider). Infrastructure (VPC, EKS, ECR, IRSA) is provisioned with Terraform.

![EKS architecture diagram](diagrams/eks-architecture.png)

## Tech stack

- Python / FastAPI (API)
- Docker (multi-stage, non-root image)
- Amazon EKS (managed node groups)
- Amazon ECR (image registry)
- Amazon DynamoDB (single-table model)
- Terraform (VPC, EKS, ECR, IRSA)
- Kustomize (base + EKS overlay)
- GitHub Actions (build and validation CI)

## Repository structure

```text
aws-review-workflow-eks/
├─ app/
│  ├─ api/          # FastAPI service (containerized API)
│  └─ functions/    # original Lambda handlers (migration source)
├─ k8s/
│  ├─ base/         # Deployment, Service, ConfigMap, ServiceAccount
│  └─ overlays/eks/ # ECR image + IRSA role-arn annotation
├─ infra/
│  ├─ modules/      # reusable Terraform modules
│  └─ environments/dev/  # EKS, ECR, IRSA, plus original serverless resources
├─ scripts/         # local helpers (DynamoDB Local table creation)
├─ tests/           # service and API tests
├─ docs/
│  ├─ adr/          # architecture decision records
│  ├─ runbooks/     # operational procedures
│  └─ diagrams/     # architecture diagrams
└─ .github/workflows/  # CI
```

## Local development

Run the API and DynamoDB Local with Docker Compose:

```bash
docker compose up --build -d
python scripts/create_local_table.py
curl localhost:8080/health
curl localhost:8080/reviews
docker compose down
```

Run the tests:

```bash
pip install -r requirements-dev.txt
pytest -q
```

## Deploying to EKS

Provision the infrastructure (creates billable resources):

```bash
cd infra/environments/dev
terraform init
terraform plan
terraform apply
```

Point kubectl at the new cluster and confirm the nodes are ready:

```bash
aws eks update-kubeconfig --region ap-southeast-2 --name review-workflow-dev
kubectl get nodes
```

Build and push the image, then deploy:

```bash
docker build --platform linux/amd64 -t <ecr-repo-url>:v1 .
docker push <ecr-repo-url>:v1
kubectl apply -k k8s/overlays/eks
kubectl rollout status deployment/review-api
```

Verify, including DynamoDB access via IRSA:

```bash
kubectl exec deploy/review-api -- \
  python -c "import boto3; print(boto3.client('sts').get_caller_identity()['Arn'])"
kubectl port-forward svc/review-api 8080:80
# in another shell:
curl localhost:8080/health
curl localhost:8080/reviews
```

Tear everything down when finished:

```bash
cd infra/environments/dev
terraform destroy
```

> See `docs/runbooks/` for operational procedures (rollout, rollback, image-pull failures, IRSA troubleshooting, teardown).

## Security

- Per-Pod least-privilege IAM via IRSA; the Pod does not borrow the node role.
- No long-lived AWS credentials in source control.
- Container runs as a non-root user.
- Cognito JWT verification is stubbed at the FastAPI boundary (`app/api/deps.py`) and isolated so it can be wired up without touching the domain logic.

## Cost

EKS is not serverless, so it has an always-on baseline cost (control plane, node group, NAT gateway). The dev environment is provisioned with Terraform and destroyed after validation to avoid ongoing charges. The serverless vs. EKS trade-off is documented in `docs/adr/`.

## Status

- [x] Containerized FastAPI API with the original DynamoDB model
- [x] Local Kubernetes validation (kind)
- [x] Terraform-provisioned EKS, ECR, VPC, IRSA
- [x] Deployed to EKS with IRSA-backed DynamoDB access
- [x] Build and validation CI (pytest, docker build, terraform validate, kustomize)
