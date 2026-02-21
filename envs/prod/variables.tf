variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" { type = string }
variable "stage_name" { type = string }

variable "lambda_runtime" {
  type    = string
  default = "python3.11"
}

variable "lambda_handler" {
  type    = string
  default = "app.handler"
}

variable "lambda_timeout_seconds" {
  type    = number
  default = 30
}

variable "lambda_memory_mb" {
  type    = number
  default = 256
}

variable "enable_xray_tracing" {
  type    = bool
  default = true
}

variable "databricks_host" {
  type        = string
  description = "Databricks workspace URL, e.g. https://dbc-xxxx.cloud.databricks.com"
}

variable "databricks_warehouse_id" { type = string }

variable "databricks_catalog" {
  type    = string
  default = ""
}

variable "databricks_schema" {
  type    = string
  default = ""
}

variable "databricks_default_query" {
  type        = string
  description = "Default SQL to run when /query request omits 'sql'."
}

variable "databricks_pat_value" {
  type        = string
  sensitive   = true
  description = "Databricks PAT stored into AWS Secrets Manager; provide via TF_VAR_ or CI secrets."
}

variable "api_title" {
  type    = string
  default = "Databricks Integration API"
}

variable "api_description" {
  type    = string
  default = "REST API backed by AWS Lambda calling Databricks SQL Warehouse."
}

variable "cors_allow_origins" {
  type    = list(string)
  default = ["https://example.gov"]
}

variable "cors_allow_methods" {
  type    = list(string)
  default = ["GET", "POST", "OPTIONS"]
}

variable "cors_allow_headers" {
  type    = list(string)
  default = ["Content-Type", "Authorization"]
}

variable "enable_customer_managed_kms" {
  type    = bool
  default = true
}

variable "kms_deletion_window_in_days" {
  type    = number
  default = 30
}

variable "cloudwatch_log_retention_days" {
  type    = number
  default = 365
}

variable "api_access_log_retention_days" {
  type    = number
  default = 365
}

variable "create_api_gateway_cloudwatch_role" {
  type    = bool
  default = true
}

variable "api_gateway_cloudwatch_role_arn" {
  type    = string
  default = null
}

variable "enable_api_execution_logging" {
  type    = bool
  default = true
}

variable "permissions_boundary_arn" {
  type    = string
  default = null
}

variable "required_tag_keys" {
  type    = list(string)
  default = ["environment", "system", "owner", "data_classification", "fips_199_impact"]
}

variable "federal_compliance_mode" {
  type    = bool
  default = true
}

variable "additional_kms_key_administrator_arns" {
  type    = list(string)
  default = []
}

variable "additional_kms_key_user_arns" {
  type    = list(string)
  default = []
}

variable "enable_aws_config" {
  type    = bool
  default = true
}

variable "enable_security_hub" {
  type    = bool
  default = true
}

variable "enable_foundational_best_practices_standard" {
  type    = bool
  default = true
}

variable "create_config_bucket" {
  type    = bool
  default = true
}

variable "config_bucket_name" {
  type    = string
  default = null
}

variable "config_bucket_prefix" {
  type    = string
  default = "federal-config"
}

variable "config_s3_kms_key_arn" {
  type    = string
  default = null
}

variable "create_config_service_role" {
  type    = bool
  default = true
}

variable "config_service_role_arn" {
  type    = string
  default = null
}

variable "config_delivery_frequency" {
  type    = string
  default = "TwentyFour_Hours"
}

variable "tags" {
  type = map(string)
  default = {
    environment         = "prod"
    system              = "databricks-lambda-api"
    owner               = "platform-team"
    data_classification = "CUI"
    fips_199_impact     = "moderate"
  }
}
