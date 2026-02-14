module "lambda_databricks_api" {
  source = "../../modules/lambda_databricks_api"

  name_prefix = var.name_prefix
  stage_name  = var.stage_name

  lambda_runtime = var.lambda_runtime
  lambda_handler = var.lambda_handler

  databricks_host          = var.databricks_host
  databricks_warehouse_id  = var.databricks_warehouse_id
  databricks_catalog       = var.databricks_catalog
  databricks_schema        = var.databricks_schema
  databricks_default_query = var.databricks_default_query

  databricks_pat_value = var.databricks_pat_value

  api_title       = var.api_title
  api_description = var.api_description

  tags = var.tags
}

output "invoke_url" {
  value = module.lambda_databricks_api.invoke_url
}

output "lambda_name" {
  value = module.lambda_databricks_api.lambda_name
}

output "databricks_pat_secret_arn" {
  value = module.lambda_databricks_api.databricks_secret_arn
}
