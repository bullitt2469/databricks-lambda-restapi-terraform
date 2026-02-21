output "invoke_url" {
  value = aws_api_gateway_stage.this.invoke_url
}

output "lambda_name" {
  value = aws_lambda_function.this.function_name
}

output "databricks_secret_arn" {
  value = aws_secretsmanager_secret.databricks_pat.arn
}

output "api_gateway_rest_api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "api_gateway_stage_name" {
  value = aws_api_gateway_stage.this.stage_name
}

output "lambda_log_group_name" {
  value = aws_cloudwatch_log_group.lambda.name
}

output "api_access_log_group_name" {
  value = aws_cloudwatch_log_group.api_access.name
}

output "kms_key_arn" {
  value = var.enable_customer_managed_kms ? aws_kms_key.this[0].arn : null
}
