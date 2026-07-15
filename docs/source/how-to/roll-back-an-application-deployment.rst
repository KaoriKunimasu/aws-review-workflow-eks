Roll back a deployment
========================

Reverts ``review-api`` to a previous revision.

Check the rollout history
----------------------------

.. code-block:: console

   $ kubectl rollout history deployment/review-api

This lists the revisions Kubernetes has retained, most recent last.

Roll back to the previous revision
--------------------------------------

.. code-block:: console

   $ kubectl rollout undo deployment/review-api
   $ kubectl rollout status deployment/review-api

To target a specific revision instead of the immediately preceding one:

.. code-block:: console

   $ kubectl rollout undo deployment/review-api --to-revision=<n>

Use the revision number from ``kubectl rollout history``.

Confirm the rollback
-----------------------

.. code-block:: console

   $ kubectl get pods -o wide
   $ kubectl port-forward svc/review-api 8080:80

In another terminal:

.. code-block:: console

   $ curl localhost:8080/health
   $ curl localhost:8080/reviews

If the Pods aren't healthy after the rollback, see :doc:`investigate-a-failed-pod`.