Workload access with IRSA
============================

The FastAPI Pod needs to read and write one DynamoDB table. Getting that access right meant deciding between the EKS node's IAM role and something more specific — this page covers why IRSA won, and what it does and doesn't actually secure.

The problem with the node role
---------------------------------

By default, anything running on an EKS worker node can assume that node's IAM role. If the node role can reach DynamoDB, every Pod scheduled on that node can too, including Pods that have nothing to do with this table, now or after a future deployment adds unrelated workloads to the same node group. Permissions end up scoped to "whatever runs on this machine," not to a specific application.

Binding the role to a Pod instead
-------------------------------------

IAM Roles for Service Accounts binds an IAM role to a Kubernetes ServiceAccount rather than to a node. The cluster's OIDC identity provider issues a token for that ServiceAccount; AWS STS trusts that token specifically, scoped to the ``default:review-api`` identity in ``infra/environments/dev/irsa.tf``. A Pod using a different ServiceAccount gets no access, regardless of which node it lands on.

In this repository that's three pieces working together: a bare ServiceAccount in the base Kustomize layer, an EKS overlay that patches in the role-arn annotation, and the Terraform IAM role itself, trusted by the cluster's OIDC provider. The reference pages on :doc:`../reference/kubernetes-resources` and :doc:`../reference/terraform-infrastructure` cover each piece mechanically; this page is about why they're split that way rather than defined in one place.

What the attached policy actually allows
--------------------------------------------

Five actions, scoped to the workflow table and its indexes: ``GetItem``, ``Query``, ``Scan``, ``PutItem``, ``UpdateItem``. Nothing broader — this matches what the service layer actually does, since nothing in ``app/api/service.py`` deletes an item, so ``DeleteItem`` was never granted.

Where this doesn't help
---------------------------

IRSA scopes what the *Pod* can do against AWS. It says nothing about which *user's data* an authenticated API caller may touch. As covered in :doc:`migrating-from-lambda-to-eks`, the FastAPI app now verifies a Cognito access token on every endpoint, so a caller has to prove *who* they are, and changing a request's status also takes the ``reviewer`` group. What's still missing is any scoping by owner: a signed-in user can read and create requests across the whole queue, and a reviewer can act on anyone's request, not only the ones they filed. Narrowing the IRSA role doesn't touch this. It governs the Pod's access to AWS; who may act on whose data is a separate layer, and neither IRSA nor token verification closes it.

How this was verified
------------------------

From inside a running Pod, ``boto3.client('sts').get_caller_identity()`` returns the IRSA role's ARN, not the node group's role, confirmed against a live EKS deployment rather than just ``kind`` (see ``docs/demo/eks/02-irsa-verification.png``). :doc:`../how-to/investigate-a-failed-pod` covers what to check if that identity comes back wrong instead.