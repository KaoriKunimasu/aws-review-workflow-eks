System architecture
====================

This page covers how the review API's application layer, container image, registry, and EKS cluster fit together, based on the configuration in this repository.

Application service
--------------------

The API is a FastAPI application defined in ``app/api/main.py``. It exposes the following routes:

.. list-table::
   :header-rows: 1

   * - Method
     - Path
     - Purpose
   * - GET
     - ``/health``
     - Health check. Does not access DynamoDB.
   * - POST
     - ``/reviews``
     - Create a workflow request.
   * - GET
     - ``/reviews``
     - List workflow requests.
   * - GET
     - ``/reviews/{request_id}``
     - Get a single workflow request.
   * - PATCH
     - ``/reviews/{request_id}/status``
     - Update the status of a workflow request.

Because ``/health`` doesn't touch DynamoDB, a Pod can go Ready before AWS credentials are configured or even reachable.

Container image
-----------------

Built from the repository ``Dockerfile`` in two stages. The build stage (``python:3.12-slim``) installs dependencies from ``requirements.txt`` into a separate prefix; the runtime stage, also ``python:3.12-slim``, copies over only the installed dependencies and the ``app`` directory — nothing from the build stage's pip cache or toolchain makes it into the final image.

The runtime stage runs as a non-root user (``appuser``, UID 10001), exposes port 8080, and defines a Docker ``HEALTHCHECK`` that calls ``/health``. The entrypoint:

.. code-block:: text

   uvicorn app.api.main:app --host 0.0.0.0 --port 8080

Container image registry
--------------------------

Images live in an Amazon ECR repository provisioned by Terraform (``infra/environments/dev/ecr.tf``, resource ``aws_ecr_repository.review_api``): tag mutability is ``MUTABLE``, image scanning runs on push, encryption is ``AES256``, and a lifecycle policy expires anything past the most recent 10 images.

Amazon EKS
-----------

Provisioned by the ``eks`` module in ``infra/environments/dev/eks.tf``, cluster version ``1.31``. There's a single managed node group, ``default``, using ``t3.small`` instances sized 2/3/2 (min/max/desired). The cluster's public endpoint is reachable, but only from the CIDR blocks in ``eks_cluster_endpoint_public_access_cidrs`` — and the Terraform-running principal gets admin access through an EKS access entry rather than the older ``aws-auth`` ConfigMap approach.

Kubernetes resources
----------------------

See :doc:`kubernetes-resources` for the Deployment, Service, ConfigMap, and ServiceAccount themselves.

DynamoDB
---------

One table, read and written by the service. Its name reaches the container through the ``review-api-config`` ConfigMap as ``WORKFLOW_TABLE_NAME``, picked up in ``app/api/config.py``. The table itself is provisioned by the ``dynamodb`` module referenced in ``infra/environments/dev/main.tf``.

Identity and access
---------------------

The Pod authenticates to AWS through IAM Roles for Service Accounts (IRSA) — not the EKS node's IAM role. Three files make that work together: ``k8s/base/serviceaccount.yaml`` defines the ``review-api`` ServiceAccount with no role annotation at all; ``k8s/overlays/eks/kustomization.yaml`` patches in the ``eks.amazonaws.com/role-arn`` annotation; and ``infra/environments/dev/irsa.tf`` creates the IAM role that annotation points to, trusted by the cluster's OIDC provider and scoped specifically to the ``default:review-api`` identity. The attached policy only grants ``GetItem``, ``Query``, ``Scan``, ``PutItem``, and ``UpdateItem`` on the workflow table and its indexes — nothing broader.

Infrastructure provisioning
------------------------------

All of it comes from Terraform under ``infra/environments/dev``. See :doc:`terraform-infrastructure` for the resource-level breakdown.

Continuous integration
------------------------

``.github/workflows/ci.yml`` runs four jobs on every pull request and push to ``main``. Here's what each one actually checks:

- ``python`` installs dependencies and runs ``pytest -q``.
- ``docker`` builds the image (``docker build -t review-api:ci .``) but never pushes it anywhere.
- ``terraform`` runs ``fmt -check -recursive`` and ``validate``, initialized with ``-backend=false`` so it doesn't need AWS credentials or a configured backend to pass.
- ``kustomize`` runs ``kubectl kustomize k8s/overlays/eks`` to confirm the overlay builds — not that it applies cleanly to a live cluster.

None of these jobs touch AWS. Deployment is a separate, manual step, covered in the How-to guides.