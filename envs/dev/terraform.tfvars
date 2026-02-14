aws_region  = "us-east-1"
name_prefix = "di-demo"
stage_name  = "dev"

# Databricks (AWS-hosted)
databricks_host         = "https://dbc-<workspace-id>.cloud.databricks.com"
databricks_warehouse_id = "<warehouse-id>"
databricks_catalog      = "main"
databricks_schema       = "public"

databricks_default_query = "SELECT current_timestamp() AS now_utc"

# DO NOT commit real PATs. Use TF_VAR_databricks_pat_value or CI secrets.
databricks_pat_value = "REPLACE_ME"

api_title       = "Databricks API (dev)"
api_description = "Example API calling Databricks SQL Warehouse (dev)."

tags = {
  env = "dev"
}
