module "lambda_databricks_api" {
  source = "../../modules/lambda_databricks_api"

  name_prefix = var.name_prefix
  stage_name  = var.stage_name

  lambda_runtime = var.lambda_runtime
  lambda_handler = var.lambda_handler
  lambda_timeout_seconds = var.lambda_timeout_seconds
  lambda_memory_mb       = var.lambda_memory_mb
  enable_xray_tracing    = var.enable_xray_tracing

  databricks_host          = var.databricks_host
  databricks_warehouse_id  = var.databricks_warehouse_id
  databricks_catalog       = var.databricks_catalog
  databricks_schema        = var.databricks_schema
  databricks_default_query = var.databricks_default_query

  databricks_pat_value = var.databricks_pat_value

  api_title       = var.api_title
  api_description = var.api_description

  cors_allow_origins = var.cors_allow_origins
  cors_allow_methods = var.cors_allow_methods
  cors_allow_headers = var.cors_allow_headers

  enable_customer_managed_kms       = var.enable_customer_managed_kms
  kms_deletion_window_in_days       = var.kms_deletion_window_in_days
  cloudwatch_log_retention_days     = var.cloudwatch_log_retention_days
  api_access_log_retention_days     = var.api_access_log_retention_days
  create_api_gateway_cloudwatch_role = var.create_api_gateway_cloudwatch_role
  api_gateway_cloudwatch_role_arn   = var.api_gateway_cloudwatch_role_arn
  enable_api_execution_logging       = var.enable_api_execution_logging
  permissions_boundary_arn           = var.permissions_boundary_arn
  required_tag_keys                  = var.required_tag_keys
  federal_compliance_mode            = var.federal_compliance_mode
  additional_kms_key_administrator_arns = var.additional_kms_key_administrator_arns
  additional_kms_key_user_arns          = var.additional_kms_key_user_arns

  tags = var.tags
}

module "federal_compliance_services" {
  source = "../../modules/federal_compliance_services"

  name_prefix = var.name_prefix
  stage_name  = var.stage_name

  enable_aws_config                               = var.enable_aws_config
  enable_security_hub                             = var.enable_security_hub
  enable_foundational_best_practices_standard     = var.enable_foundational_best_practices_standard
  create_config_bucket                            = var.create_config_bucket
  config_bucket_name                              = var.config_bucket_name
  config_bucket_prefix                            = var.config_bucket_prefix
  config_s3_kms_key_arn                           = var.config_s3_kms_key_arn != null ? var.config_s3_kms_key_arn : module.lambda_databricks_api.kms_key_arn
  create_config_service_role                      = var.create_config_service_role
  config_service_role_arn                         = var.config_service_role_arn
  config_delivery_frequency                       = var.config_delivery_frequency

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

output "api_gateway_rest_api_id" {
  value = module.lambda_databricks_api.api_gateway_rest_api_id
}

output "api_gateway_stage_name" {
  value = module.lambda_databricks_api.api_gateway_stage_name
}

output "lambda_log_group_name" {
  value = module.lambda_databricks_api.lambda_log_group_name
}

output "api_access_log_group_name" {
  value = module.lambda_databricks_api.api_access_log_group_name
}

output "kms_key_arn" {
  value = module.lambda_databricks_api.kms_key_arn
}

output "config_bucket_name" {
  value = module.federal_compliance_services.config_bucket_name
}

output "config_configuration_recorder_name" {
  value = module.federal_compliance_services.config_configuration_recorder_name
}

output "security_hub_enabled" {
  value = module.federal_compliance_services.security_hub_enabled
}

output "security_hub_foundational_standard_subscription_arn" {
  value = module.federal_compliance_services.security_hub_foundational_standard_subscription_arn
}
