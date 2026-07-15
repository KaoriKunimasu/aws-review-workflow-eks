Introduction
============

What this is
-------------

This is an internal tool for reviewing technical terminology and documents. It used to run entirely on Lambda, behind API Gateway, with Cognito handling auth. This repository moves the API onto EKS — nothing else. The domain logic and the DynamoDB table are untouched; only the transport layer changed, from API Gateway events to a FastAPI app.

The old Lambda code is still in the repo (``app/functions/``), sitting next to the new service rather than replaced by it.

Who this is for
-----------------

Engineers who need to run the service locally, deploy or roll back a version on EKS, or dig into a failing Pod. Docker, Kubernetes, and the AWS CLI are assumed knowledge; nothing about this specific project is.

Scope
-----

Covered here: running the FastAPI service locally against DynamoDB Local, provisioning EKS/ECR/IAM with Terraform, and deploying, rolling back, and troubleshooting on EKS.

Not covered: the original Lambda/API Gateway/Cognito stack, except where it directly explains a migration decision.

What's actually been validated
---------------------------------

Locally, with Docker Compose and DynamoDB Local, and with a local Kubernetes cluster (``kind``) — both work. On the infrastructure side, ``infra/environments/dev`` provisions a VPC, an EKS cluster, an ECR repository, and an IRSA role. CI (``.github/workflows/ci.yml``) runs Python tests, a Docker build, ``terraform validate``, and a Kustomize build on every pull request — but it doesn't push images, apply Terraform, or apply Kubernetes manifests.

Where a page says something was only checked in ``kind``, or only by CI rather than a live AWS deployment, it says so directly instead of leaving that vague.