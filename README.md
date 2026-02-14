# AWS Lambda REST API → Databricks (AWS-hosted) Data Integration (Terraform)

This repository provisions an **AWS API Gateway REST API** backed by an **AWS Lambda** function that queries an
**AWS-hosted Databricks SQL Warehouse** via the Databricks **SQL Statement Execution API**.

It includes:
- Modular Terraform (`modules/lambda_databricks_api`)
- Environment roots (`envs/dev`, `envs/prod`)
- OpenAPI spec templated with variables (`openapi.tftpl`)
- Lambda code (Python) that:
  - Reads a Databricks PAT from **AWS Secrets Manager**
  - Executes SQL against a specified Databricks **Warehouse (SQL endpoint)**
  - Exposes `/health` and `/query` endpoints

> Region note: This package defaults to **us-east-1** (US-East / N. Virginia).

---

## Architecture

```mermaid
flowchart LR
  Client[Client / App] -->|HTTPS| APIGW[API Gateway REST API]
  APIGW -->|Lambda proxy| L[Lambda: Databricks Query Handler]
  L -->|GetSecretValue| SM[Secrets Manager: Databricks PAT]
  L -->|HTTPS: /api/2.0/sql/statements| DBX[Databricks (AWS-hosted) SQL Warehouse]
  DBX -->|JSON Results| L --> APIGW --> Client
```

---

## Repo structure

```
.
├── .github/workflows/terraform.yml
├── envs/
│   ├── dev/
│   └── prod/
└── modules/
    └── lambda_databricks_api/
        ├── lambda_src/
        │   └── app.py
        ├── main.tf
        ├── openapi.tftpl
        ├── outputs.tf
        └── variables.tf
```

---

## Endpoints

After apply, Terraform outputs an `invoke_url` like:

`https://<api-id>.execute-api.us-east-1.amazonaws.com/dev`

### Health
`GET /health`

### Query
`POST /query`
Body:
```json
{ "sql": "SELECT current_date() AS today" }
```
If `sql` is omitted, Lambda runs `databricks_default_query`.

---

## Databricks requirements (AWS-hosted)

You need:
- `databricks_host` (workspace URL), e.g. `https://dbc-<id>.cloud.databricks.com`
- `databricks_warehouse_id` (SQL warehouse ID)
- A Databricks **PAT** with permission to use the warehouse

This PAT is stored in AWS Secrets Manager by Terraform and read by Lambda at runtime.

---

## Deploy (local)

1) Authenticate to AWS:
```bash
aws sts get-caller-identity
```

2) Deploy dev:
```bash
cd envs/dev
terraform init
terraform plan
terraform apply
```

3) Test:
```bash
curl -s "$(terraform output -raw invoke_url)/health"
curl -s -X POST "$(terraform output -raw invoke_url)/query"   -H "Content-Type: application/json"   -d '{"sql":"SELECT 1 AS one"}'
```

---

## CI/CD (GitHub Actions)

A workflow is included at `.github/workflows/terraform.yml` that runs:
- `fmt`, `validate`, `plan` on PRs
- `apply` on pushes to `main`

### Required GitHub secrets
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Optional (recommended if using session tokens):
- `AWS_SESSION_TOKEN`

Set `TF_ENV` as a GitHub Actions variable (`dev` or `prod`) to choose environment.

---

## Security notes
- Do **not** commit `databricks_pat_value` in `terraform.tfvars` for real use. Use GitHub secrets / TF_VAR_ vars.
- Consider VPC egress controls, NAT, or PrivateLink patterns if your environment requires private-only connectivity.
