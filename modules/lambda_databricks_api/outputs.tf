output "invoke_url" {
  value = aws_api_gateway_stage.this.invoke_url
}

output "lambda_name" {
  value = aws_lambda_function.this.function_name
}

output "databricks_secret_arn" {
  value = aws_secretsmanager_secret.databricks_pat.arn
}
