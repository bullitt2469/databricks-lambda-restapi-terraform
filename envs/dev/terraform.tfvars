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

# CORS should be explicitly scoped for federal workloads.
cors_allow_origins = ["https://app.dev.example.gov"]

# Create API Gateway CloudWatch role unless your org provides a shared role ARN.
create_api_gateway_cloudwatch_role = true
# api_gateway_cloudwatch_role_arn  = "arn:aws:iam::<account-id>:role/<shared-apigw-cloudwatch-role>"

tags = {
  environment         = "dev"
  system              = "databricks-lambda-api"
  owner               = "platform-team"
  data_classification = "CUI"
  fips_199_impact     = "moderate"
}

# Continuous compliance services (federal baseline)
enable_aws_config                           = true
enable_security_hub                         = true
enable_foundational_best_practices_standard = true
create_config_bucket                        = true
create_config_service_role                  = true
config_delivery_frequency                   = "TwentyFour_Hours"
