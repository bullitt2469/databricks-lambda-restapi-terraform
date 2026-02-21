import os
import json
import importlib.util
from pathlib import Path
from unittest.mock import Mock

# Ensure boto3 has a default region during test import
os.environ.setdefault("AWS_DEFAULT_REGION", "us-west-2")

APP_PATH = Path(__file__).resolve().parents[1] / "lambda_src" / "app.py"
SPEC = importlib.util.spec_from_file_location("lambda_app", APP_PATH)
app = importlib.util.module_from_spec(SPEC)
assert SPEC and SPEC.loader
SPEC.loader.exec_module(app)


def test_health_ok():
    event = {"path": "/health", "httpMethod": "GET"}
    resp = app.handler(event, None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body.get("ok") is True


def test_query_success(monkeypatch):
    monkeypatch.setenv("DATABRICKS_HOST", "https://fake.dbx")
    monkeypatch.setenv("DATABRICKS_WAREHOUSE_ID", "wh-123")
    monkeypatch.setenv("DATABRICKS_DEFAULT_QUERY", "SELECT 1")
    monkeypatch.setenv("DATABRICKS_PAT_SECRET_ARN", "fake-arn")

    # Mock Secrets Manager client used in the module
    mock_secrets = Mock()
    mock_secrets.get_secret_value.return_value = {"SecretString": "fake-token"}
    monkeypatch.setattr(app, "secrets", mock_secrets)

    # Fake HTTP response for urllib.request.urlopen context manager
    class DummyResp:
        def __init__(self, data):
            self._data = data

        def read(self):
            return self._data

        def __enter__(self):
            return self

        def __exit__(self, exc_type, exc, tb):
            return False

    def fake_urlopen(req, timeout=20):
        return DummyResp(b'{"result": "ok"}')

    monkeypatch.setattr(app.urllib.request, "urlopen", fake_urlopen)

    event = {"path": "/query", "httpMethod": "POST", "body": json.dumps({"sql": "SELECT 1"})}
    resp = app.handler(event, None)
    assert resp["statusCode"] == 200
    body = json.loads(resp["body"])
    assert body.get("result") == "ok"
