Kubernetes resources
======================

The base Kubernetes configuration in ``k8s/base`` defines a Deployment, a Service, a ConfigMap, and a ServiceAccount, composed with Kustomize. The EKS overlay in ``k8s/overlays/eks`` patches two of them at deploy time.

Deployment
-----------

``k8s/base/deployment.yaml`` is the only workload resource in this repository.

.. list-table::
   :header-rows: 1

   * - Field
     - Value
   * - Name
     - ``review-api``
   * - Replicas
     - 2
   * - Container port
     - 8080
   * - Service account
     - ``review-api``
   * - Image (base)
     - ``review-api:local`` (replaced per environment; see below)

Environment variables come in through ``envFrom.configMapRef``, pointing at the ``review-api-config`` ConfigMap.

Both probes hit ``GET /health`` on port 8080, just with different timing:

.. list-table::
   :header-rows: 1

   * - Probe
     - initialDelaySeconds
     - periodSeconds
   * - readinessProbe
     - 5
     - 10
   * - livenessProbe
     - 10
     - 15

Resource requests and limits:

.. list-table::
   :header-rows: 1

   * -
     - CPU
     - Memory
   * - requests
     - 100m
     - 128Mi
   * - limits
     - 500m
     - 256Mi

The security context is locked down: ``runAsNonRoot: true``, ``runAsUser: 10001``, ``allowPrivilegeEscalation: false``, ``readOnlyRootFilesystem: true``.

Service
--------

``k8s/base/service.yaml`` fronts the Deployment as a plain ``ClusterIP``. There is no Ingress or LoadBalancer resource in this repository, so the service is not reachable from outside the cluster.

.. list-table::
   :header-rows: 1

   * - Field
     - Value
   * - Name
     - ``review-api``
   * - Type
     - ``ClusterIP``
   * - Port
     - 80
   * - Target port
     - 8080
   * - Selector
     - ``app: review-api``

ConfigMap
----------

``review-api-config`` (``k8s/base/configmap.yaml``) carries six non-secret values, and comments in the file are explicit that they need to match ``infra/environments/dev``:

.. list-table::
   :header-rows: 1

   * - Key
     - Value
   * - ``WORKFLOW_TABLE_NAME``
     - ``review-workflow-dev-workflow``
   * - ``AWS_REGION``
     - ``ap-southeast-2``
   * - ``LOG_LEVEL``
     - ``INFO``
   * - ``AUTH_MODE``
     - ``cognito`` (verify a Cognito access token on every request; ``none`` disables verification, local dev only)
   * - ``COGNITO_USER_POOL_ID``
     - ``terraform output cognito_user_pool_id``
   * - ``COGNITO_CLIENT_ID``
     - ``terraform output cognito_client_id``

The pool ID and client ID are not secrets, but they are environment-specific: with ``AUTH_MODE=cognito`` the app fails at startup if either is missing (``app/api/config.py``).

ServiceAccount
---------------

The base ServiceAccount (``k8s/base/serviceaccount.yaml``) is deliberately bare — no IRSA annotation. That gets added only by the EKS overlay, below.

Kustomize structure
---------------------

Kustomize ties these four files together in two layers. ``k8s/base/kustomization.yaml`` composes the ServiceAccount, ConfigMap, Deployment, and Service listed above into one unit.

``k8s/overlays/eks/kustomization.yaml`` sits on top of ``base`` and does two things: it swaps in an ECR image reference under ``images`` (the ``newName``/``newTag`` values in the file are placeholders — the real ECR URL comes from ``terraform output``), and it patches the ``review-api`` ServiceAccount to add the ``eks.amazonaws.com/role-arn`` annotation pointing at the IRSA role (the ARN in the file is also a placeholder, not a real account ID).

The ``eks`` overlay is the only overlay defined in this repository.