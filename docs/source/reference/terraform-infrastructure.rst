Terraform infrastructure
==========================

All infrastructure for this environment is defined in ``infra/environments/dev``. Reusable modules in ``infra/modules`` (api, cognito, dynamodb, lambda-function) support the original serverless stack; the EKS-specific resources — VPC, cluster, ECR, IRSA — are defined directly in the environment root instead of as separate modules.

Terraform layout
------------------

- ``infra/modules/`` holds the reusable pieces: ``api``, ``cognito``, ``dynamodb``, ``lambda-function``.
- ``infra/environments/dev/`` is the root module. It calls those modules and additionally defines the EKS resources inline.

Network resources
--------------------

The VPC comes from the community module ``terraform-aws-modules/vpc/aws`` (``~> 5.13``), configured inside ``eks.tf``: CIDR ``10.0.0.0/16``, two availability zones, two private subnets (``10.0.1.0/24``, ``10.0.2.0/24``) and two public ones (``10.0.101.0/24``, ``10.0.102.0/24``). NAT is enabled but with ``single_nat_gateway = true`` — a comment in the file calls this out as a cost decision for dev, not a highly-available setup. The subnets are also pre-tagged for the AWS Load Balancer Controller (``kubernetes.io/role/elb`` and its internal-elb counterpart), even though that controller isn't installed anywhere in this repository.

Amazon EKS
-----------

Also in ``eks.tf``: ``terraform-aws-modules/eks/aws``, pinned to ``20.24.0``, cluster version ``1.31``. Nodes sit in the private subnets from above. One managed node group (``default``), ``t3.small`` instances, sized 2/3/2. The public endpoint is open but restricted by ``var.eks_cluster_endpoint_public_access_cidrs`` — the example tfvars sets this to one placeholder IP and includes a comment warning explicitly against ``0.0.0.0/0``.

Amazon ECR
-----------

The registry itself lives in ``ecr.tf``; see :doc:`system-architecture` for its settings (mutability, scanning, encryption, lifecycle) rather than repeating them here.

IAM and IRSA
-------------

``irsa.tf`` holds two things: an IAM policy document scoped to five DynamoDB actions (``GetItem``, ``Query``, ``Scan``, ``PutItem``, ``UpdateItem``) on the workflow table and its indexes, and the IAM role that policy is attached to — created via ``terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks`` (``~> 5.44``), trusted by the cluster's OIDC provider and scoped to the ``default:review-api`` ServiceAccount identity.

DynamoDB
---------

The ``dynamodb`` module (``infra/modules/dynamodb``) provisions the table, called from ``main.tf``. Billing mode, point-in-time recovery, deletion protection, table class, streams, and TTL are all just passed through as variables — see ``variables.tf`` and ``terraform.tfvars.example`` for what the dev environment actually sets them to.

Environment configuration
----------------------------

``terraform.tfvars.example`` lays out the dev environment's defaults, and it needs to be copied and edited, not applied as-is. Two values in it are placeholders that must change before this goes anywhere near a real account: ``allowed_account_ids`` and the EKS public access CIDR.

Terraform state
-----------------

There is no remote backend configured in ``versions.tf`` or ``providers.tf`` — no S3 bucket, no DynamoDB lock table. CI only proves this doesn't matter for ``terraform validate``, which runs with ``init -backend=false``. It says nothing about ``apply``. Running ``terraform apply`` outside CI writes state to a local ``.tfstate`` file unless someone configures a backend first.