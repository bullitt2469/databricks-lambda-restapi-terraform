import json
import os
import boto3
import urllib.request
import urllib.error

secrets = boto3.client("secretsmanager")

def _get_pat() -> str:
    arn = os.environ["DATABRICKS_PAT_SECRET_ARN"]
    resp = secrets.get_secret_value(SecretId=arn)
    return resp["SecretString"]

def _dbx_request(method: str, path: str, body=None):
    host = os.environ["DATABRICKS_HOST"].rstrip("/")
    url = f"{host}{path}"

    token = _get_pat()
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }

    data = None
    if body is not None:
        data = json.dumps(body).encode("utf-8")

    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as r:
            return json.loads(r.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8") if hasattr(e, "read") else ""
        raise RuntimeError(f"Databricks HTTPError {e.code}: {err_body}") from e
    except urllib.error.URLError as e:
        raise RuntimeError(f"Databricks URLError: {e.reason}") from e

def _run_query(sql: str):
    warehouse_id = os.environ["DATABRICKS_WAREHOUSE_ID"]
    catalog = os.environ.get("DATABRICKS_CATALOG") or None
    schema  = os.environ.get("DATABRICKS_SCHEMA") or None

    payload = {
        "warehouse_id": warehouse_id,
        "statement": sql,
        "wait_timeout": "10s"
    }
    if catalog:
        payload["catalog"] = catalog
    if schema:
        payload["schema"] = schema

    # Databricks SQL Statement Execution API (v2.0)
    return _dbx_request("POST", "/api/2.0/sql/statements/", payload)

def _response(code: int, body: dict):
    return {
        "statusCode": code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }

def handler(event, context):
    path = event.get("path", "")
    method = event.get("httpMethod", "")

    if path.endswith("/health") and method == "GET":
        return _response(200, {"ok": True})

    if path.endswith("/query") and method == "POST":
        body = {}
        if event.get("body"):
            try:
                body = json.loads(event["body"])
            except json.JSONDecodeError:
                body = {}

        sql = body.get("sql") or os.environ["DATABRICKS_DEFAULT_QUERY"]
        try:
            result = _run_query(sql)
            return _response(200, result)
        except Exception as e:
            return _response(500, {"error": str(e)})

    return _response(404, {"error": "not found"})
