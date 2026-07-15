Investigate a failed Pod
==========================

The failure modes most likely to show up on this service, in the order worth checking them.

Start here
-----------

.. code-block:: console

   $ kubectl get pods
   $ kubectl describe pod <pod-name>
   $ kubectl logs <pod-name>

``describe``'s Events section at the bottom usually names the problem directly. Match what you see there to a section below.

Image pull failures
----------------------

**Symptom:** ``ImagePullBackOff`` or ``ErrImagePull``.

Check whether the tag actually exists in ECR:

.. code-block:: console

   $ aws ecr list-images --repository-name review-workflow-dev-review-api --region ap-southeast-2

If it doesn't, the overlay is pointing at a tag that was never pushed — see :doc:`deploy-an-application-version`.

If the tag exists, check the node role can pull from ECR:

.. code-block:: console

   $ aws iam list-attached-role-policies --role-name <node-group-role-name>

It should include ``AmazonEC2ContainerRegistryReadOnly``. Otherwise, look for a typo in the account ID, region, or repository name in the overlay's image reference.

Readiness and liveness failures
-----------------------------------

**Symptom:** Pod status is ``Running`` but shows ``0/1`` ready, or the rollout never finishes.

.. code-block:: console

   $ kubectl describe pod <pod-name>

Look for failed readiness or liveness probe events. Then check the health endpoint directly from inside the cluster:

.. code-block:: console

   $ kubectl exec deploy/review-api -- \
       python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/health').read())"

If that fails, check that the ConfigMap values are actually present — a missing ``WORKFLOW_TABLE_NAME`` doesn't stop the Pod from becoming ready, but it does make the data routes return ``500``:

.. code-block:: console

   $ kubectl get configmap review-api-config -o yaml
   $ kubectl exec deploy/review-api -- env | grep -E "WORKFLOW_TABLE_NAME|AWS_REGION"

IRSA not taking effect
--------------------------

**Symptom:** the Pod is authenticating to AWS as the node role instead of the dedicated IRSA role.

.. code-block:: console

   $ kubectl exec deploy/review-api -- \
       python -c "import boto3; print(boto3.client('sts').get_caller_identity()['Arn'])"

A correct result looks like ``assumed-role/review-workflow-dev-review-api-irsa/...``. If it still shows the node group's role, check these in order.

The ServiceAccount must carry the role annotation:

.. code-block:: console

   $ kubectl get serviceaccount review-api -o yaml

Look for ``eks.amazonaws.com/role-arn: arn:aws:iam::<account-id>:role/review-workflow-dev-review-api-irsa``. If it's missing, the Kustomize patch didn't apply — check the rendered output directly:

.. code-block:: console

   $ kubectl kustomize k8s/overlays/eks | grep role-arn

The Deployment must reference that ServiceAccount:

.. code-block:: console

   $ kubectl get pod -l app=review-api -o jsonpath="{.items[0].spec.serviceAccountName}"

This should print ``review-api``, not ``default``.

IRSA's environment variables are only injected when a Pod is created, not patched into a running one. After fixing the annotation, recreate the Pods:

.. code-block:: console

   $ kubectl rollout restart deployment/review-api
   $ kubectl rollout status deployment/review-api
   $ kubectl exec deploy/review-api -- env | grep AWS

You should now see ``AWS_ROLE_ARN`` and ``AWS_WEB_IDENTITY_TOKEN_FILE`` in the output.

Logs and further inspection
-------------------------------

.. code-block:: console

   $ kubectl logs deploy/review-api --tail=50
   $ kubectl logs deploy/review-api -f
   $ kubectl get events --sort-by=.lastTimestamp

A local smoke test through port-forward, without going through any Service or Ingress:

.. code-block:: console

   $ kubectl port-forward svc/review-api 8080:80

In another terminal:

.. code-block:: console

   $ curl localhost:8080/health
   $ curl localhost:8080/reviews