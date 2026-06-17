import os

import pytest

# Set env vars before the app imports its settings.
os.environ.setdefault("WORKFLOW_TABLE_NAME", "review-workflow-test")
os.environ.setdefault("AWS_REGION", "ap-southeast-2")


@pytest.fixture
def client():
    from fastapi.testclient import TestClient
    from app.api.main import app
    return TestClient(app)
