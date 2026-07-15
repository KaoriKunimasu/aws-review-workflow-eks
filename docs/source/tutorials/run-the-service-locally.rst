Run the service locally
=========================

This tutorial runs the FastAPI service and DynamoDB Local with Docker Compose, creates a workflow request, and reads it back. It does not touch AWS.

Prerequisites
--------------

- Docker and Docker Compose
- Python 3.12, with ``requirements-dev.txt`` installed if you also want to run the test suite
- A terminal in the root of this repository

Start the service
-------------------

.. code-block:: console

   $ docker compose up --build -d

``docker-compose.yml`` defines two containers: ``dynamodb`` (``amazon/dynamodb-local``, in-memory, port 8000) and ``api`` (built from the repository ``Dockerfile``, port 8080). The ``api`` container points at DynamoDB Local through ``DYNAMODB_ENDPOINT_URL=http://dynamodb:8000``, with placeholder credentials (``local``/``local``) that DynamoDB Local accepts without checking.

Check both containers are running:

.. code-block:: console

   $ docker compose ps

Create the local table
------------------------

DynamoDB Local starts empty. Create the table the API expects:

.. code-block:: console

   $ python scripts/create_local_table.py
   Table created: review-workflow-local

``scripts/create_local_table.py`` creates a table named ``review-workflow-local`` with a composite key of ``PK`` (partition) and ``SK`` (sort). This matches the key schema the API uses in ``app/api/service.py``. A ``ResourceInUseException`` here just means the table already exists from a previous run; skip this step and move on.

Confirm the service is healthy
---------------------------------

.. code-block:: console

   $ curl localhost:8080/health
   {"status":"ok"}

A ``200`` here only confirms the container started. It doesn't touch DynamoDB, so it says nothing about whether the API can actually reach the table.

Create a workflow request
----------------------------

.. code-block:: bash

   $ curl -X POST localhost:8080/reviews \
       -H "Content-Type: application/json" \
       -d '{
             "title": "Confirm glossary term for onboarding flow",
             "requestType": "terminology",
             "sourceLanguage": "en",
             "targetLanguage": "ja",
             "sourceText": "onboarding"
           }'

``title``, ``requestType``, ``sourceLanguage``, ``targetLanguage``, and ``sourceText`` are required (see ``app/api/schemas.py``); everything else is optional. A successful response returns ``201`` with the created item, including a generated ``requestId`` and a ``status`` of ``"OPEN"``.

List and fetch it back
-------------------------

.. code-block:: console

   $ curl localhost:8080/reviews

   $ curl localhost:8080/reviews/<requestId>

Use the ``requestId`` from the previous response. ``GET /reviews`` returns items newest-first and supports pagination through ``limit`` and ``cursor`` query parameters.

Run the tests
---------------

.. code-block:: console

   $ pip install -r requirements-dev.txt
   $ pytest -q

Stop the service
------------------

.. code-block:: console

   $ docker compose down

Both containers stop. DynamoDB Local keeps everything in memory, so the table and its contents disappear along with it. There's nothing to clean up separately.