Deploy an application version
===============================

Builds a new image, pushes it to ECR, and rolls it out to the EKS cluster.

Point kubectl at the right cluster
-------------------------------------

.. code-block:: console

   $ aws eks update-kubeconfig --region ap-southeast-2 --name review-workflow-dev
   $ kubectl config current-context

Confirm the context is the EKS cluster, not ``kind`` or anything else you may have configured locally.

Build and push the image
---------------------------

.. code-block:: console

   $ docker build --platform linux/amd64 -t <ecr-repo-url>:<tag> .
   $ docker push <ecr-repo-url>:<tag>

Always include ``--platform linux/amd64``. An image built for a different architecture (for example, on Apple Silicon without this flag) will push successfully and the Pod will start, but it will crash-loop once scheduled on a node.

Use an explicit tag such as ``v1``, ``v2``, and so on rather than ``latest``. A rollback needs a specific prior tag to return to; ``latest`` doesn't give you one.

Update the image tag and apply
---------------------------------

Set the new tag in ``k8s/overlays/eks/kustomization.yaml`` under ``images[].newTag``, then apply the overlay:

.. code-block:: console

   $ kubectl apply -k k8s/overlays/eks
   $ kubectl rollout status deployment/review-api

``kubectl rollout status`` blocks until the rollout finishes or fails, so wait for it before checking further.

Confirm the new version is running
-------------------------------------

.. code-block:: console

   $ kubectl get pods -o wide

Both replicas should show ``Running`` and ``2/2`` or ``1/1`` ready, depending on your probe configuration. If a Pod is stuck instead, see :doc:`investigate-a-failed-pod`.