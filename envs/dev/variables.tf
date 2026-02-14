variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" { type = string }
variable "stage_name"  { type = string }

variable "lambda_runtime" {
  type    = string
  default = "python3.11"
}

variable "lambda_handler" {
  type    = string
  default = "app.handler"
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
  type      = string
  sensitive = true
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

variable "tags" {
  type    = map(string)
  default = {}
}
