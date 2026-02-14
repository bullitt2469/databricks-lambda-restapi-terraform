locals {
  name = "${var.name_prefix}-dbx-api-${var.stage_name}"
}

data "aws_region" "current" {}

# --- Secrets Manager: store Databricks PAT ---
resource "aws_secretsmanager_secret" "databricks_pat" {
  name        = "${local.name}-databricks-pat"
  description = "Databricks PAT for Lambda to call Databricks APIs"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "databricks_pat" {
  secret_id     = aws_secretsmanager_secret.databricks_pat.id
  secret_string = var.databricks_pat_value
}

# --- IAM Role for Lambda ---
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${local.name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_logs" {
  role      = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy_document" "lambda_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.databricks_pat.arn]
  }
}

resource "aws_iam_policy" "lambda_secrets" {
  name   = "${local.name}-secrets-policy"
  policy = data.aws_iam_policy_document.lambda_secrets.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_secrets" {
  role       = aws_iam_role.lambda.name
  policy_arn = aws_iam_policy.lambda_secrets.arn
}

# --- Package Lambda code ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda_build/${local.name}.zip"
}

resource "aws_lambda_function" "this" {
  function_name = "${local.name}-fn"
  role          = aws_iam_role.lambda.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime      = var.lambda_runtime
  handler      = var.lambda_handler
  timeout      = 30
  memory_size  = 256

  environment {
    variables = {
      DATABRICKS_HOST            = var.databricks_host
      DATABRICKS_WAREHOUSE_ID    = var.databricks_warehouse_id
      DATABRICKS_CATALOG         = var.databricks_catalog
      DATABRICKS_SCHEMA          = var.databricks_schema
      DATABRICKS_DEFAULT_QUERY   = var.databricks_default_query
      DATABRICKS_PAT_SECRET_ARN  = aws_secretsmanager_secret.databricks_pat.arn
    }
  }

  tags = var.tags
}

# --- API Gateway REST API from OpenAPI template ---
locals {
  lambda_invoke_arn = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.this.arn}/invocations"

  openapi_body = templatefile("${path.module}/openapi.tftpl", {
    api_title         = var.api_title
    api_description   = var.api_description
    lambda_invoke_arn = local.lambda_invoke_arn
  })
}

resource "aws_api_gateway_rest_api" "this" {
  name = "${local.name}-rest"
  body = local.openapi_body

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = var.tags
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(local.openapi_body)
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "this" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = var.stage_name

  tags = var.tags
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
