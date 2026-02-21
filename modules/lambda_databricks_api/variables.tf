variable "name_prefix" { type = string }
variable "stage_name"  { type = string }

variable "lambda_runtime" { type = string }
variable "lambda_handler" { type = string }
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

variable "databricks_host"          { type = string }
variable "databricks_warehouse_id"  { type = string }
variable "databricks_catalog"       { type = string }
variable "databricks_schema"        { type = string }
variable "databricks_default_query" { type = string }

variable "databricks_pat_value" {
  type      = string
  sensitive = true
}

variable "api_title"       { type = string }
variable "api_description" { type = string }

variable "cors_allow_origins" {
  type        = list(string)
  default     = ["https://example.gov"]
  description = "Allowed CORS origins for API Gateway."
}

variable "cors_allow_methods" {
  type        = list(string)
  default     = ["GET", "POST", "OPTIONS"]
  description = "Allowed CORS methods for API Gateway."
}

variable "cors_allow_headers" {
  type        = list(string)
  default     = ["Content-Type", "Authorization"]
  description = "Allowed CORS headers for API Gateway."
}

variable "enable_customer_managed_kms" {
  type        = bool
  default     = true
  description = "Whether to create and use a customer-managed KMS key."
}

variable "kms_deletion_window_in_days" {
  type        = number
  default     = 30
  description = "Pending deletion window for KMS key."
}

variable "cloudwatch_log_retention_days" {
  type        = number
  default     = 365
  description = "Lambda CloudWatch log retention in days."
}

variable "api_access_log_retention_days" {
  type        = number
  default     = 365
  description = "API Gateway access log retention in days."
}

variable "create_api_gateway_cloudwatch_role" {
  type        = bool
  default     = false
  description = "Create account-level API Gateway CloudWatch role."
}

variable "api_gateway_cloudwatch_role_arn" {
  type        = string
  default     = null
  description = "Existing account-level API Gateway CloudWatch role ARN."
}

variable "enable_api_execution_logging" {
  type        = bool
  default     = true
  description = "Enable API Gateway execution logs and metrics."

  validation {
    condition = (
      var.enable_api_execution_logging == false ||
      var.create_api_gateway_cloudwatch_role ||
      var.api_gateway_cloudwatch_role_arn != null
    )
    error_message = "To enable API execution logging, set create_api_gateway_cloudwatch_role=true or provide api_gateway_cloudwatch_role_arn."
  }
}

variable "permissions_boundary_arn" {
  type        = string
  default     = null
  description = "Optional IAM permissions boundary ARN for created roles."
}

variable "required_tag_keys" {
  type        = list(string)
  default     = ["environment", "system", "owner", "data_classification", "fips_199_impact"]
  description = "Tag keys required on all resources to support compliance and inventory."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags to apply to all resources."

  validation {
    condition     = alltrue([for key in var.required_tag_keys : contains(keys(var.tags), key)])
    error_message = "tags must include all keys listed in required_tag_keys."
  }
}

variable "federal_compliance_mode" {
  type        = bool
  default     = true
  description = "When enabled, disallow wildcard CORS origins."

  validation {
    condition     = var.federal_compliance_mode == false || !contains(var.cors_allow_origins, "*")
    error_message = "Wildcard CORS origin is not allowed when federal_compliance_mode is true."
  }
}

variable "additional_kms_key_administrator_arns" {
  type        = list(string)
  default     = []
  description = "Additional IAM principal ARNs that can administer the customer-managed KMS key."
}

variable "additional_kms_key_user_arns" {
  type        = list(string)
  default     = []
  description = "Additional IAM principal ARNs that can use the customer-managed KMS key."
}
