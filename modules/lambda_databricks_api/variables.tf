variable "name_prefix" { type = string }
variable "stage_name"  { type = string }

variable "lambda_runtime" { type = string }
variable "lambda_handler" { type = string }

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

variable "tags" {
  type    = map(string)
  default = {}
}
