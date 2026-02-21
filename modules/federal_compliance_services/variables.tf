variable "name_prefix" {
  type = string
}

variable "stage_name" {
  type = string
}

variable "enable_aws_config" {
  type        = bool
  default     = true
  description = "Enable AWS Config recorder and delivery channel."
}

variable "enable_security_hub" {
  type        = bool
  default     = true
  description = "Enable AWS Security Hub account and standards subscription."
}

variable "enable_foundational_best_practices_standard" {
  type        = bool
  default     = true
  description = "Enable AWS Foundational Security Best Practices standard in Security Hub."
}

variable "create_config_bucket" {
  type        = bool
  default     = true
  description = "Create S3 bucket for AWS Config snapshots and history."
}

variable "config_bucket_name" {
  type        = string
  default     = null
  description = "Existing AWS Config delivery bucket name; if null and create_config_bucket=true, module creates one."
}

variable "config_bucket_prefix" {
  type        = string
  default     = "federal-config"
  description = "Prefix used when creating AWS Config S3 bucket."
}

variable "config_s3_kms_key_arn" {
  type        = string
  default     = null
  description = "Optional KMS key ARN for AWS Config S3 bucket SSE-KMS."
}

variable "create_config_service_role" {
  type        = bool
  default     = true
  description = "Create IAM role for AWS Config recorder."
}

variable "config_service_role_arn" {
  type        = string
  default     = null
  description = "Existing IAM role ARN for AWS Config recorder."
}

variable "config_delivery_frequency" {
  type        = string
  default     = "TwentyFour_Hours"
  description = "AWS Config snapshot delivery frequency."
}

variable "federal_compliance_mode" {
  type        = bool
  default     = true
  description = "Top-level federal compliance mode toggle used for condition checks."
}

variable "tags" {
  type    = map(string)
  default = {}
}
