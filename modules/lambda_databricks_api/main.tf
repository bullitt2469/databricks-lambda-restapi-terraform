locals {
  name = "${var.name_prefix}-dbx-api-${var.stage_name}"

  lambda_log_group_name     = "/aws/lambda/${local.name}-fn"
  api_access_log_group_name = "/aws/apigateway/${local.name}-access"

  cors_allow_origins_yaml = join("\n", [for origin in var.cors_allow_origins : "    - \"${origin}\""])
  cors_allow_methods_yaml = join("\n", [for method in var.cors_allow_methods : "    - \"${method}\""])
  cors_allow_headers_yaml = join("\n", [for header in var.cors_allow_headers : "    - \"${header}\""])
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms" {
  count = var.enable_customer_managed_kms ? 1 : 0

  statement {
    sid       = "AllowRootKeyAdministration"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  dynamic "statement" {
    for_each = length(var.additional_kms_key_administrator_arns) > 0 ? [1] : []
    content {
      sid       = "AllowAdditionalKeyAdmins"
      effect    = "Allow"
      actions   = ["kms:*"]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.additional_kms_key_administrator_arns
      }
    }
  }

  statement {
    sid    = "AllowCloudWatchLogsUse"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.name}.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "var.federal_compliance_mode"
      values   = [tostring(var.federal_compliance_mode)]
    }
  }

  statement {
    sid    = "AllowLambdaAndSecretsManagerServiceUse"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants"
    ]
    resources = ["*"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
        "secretsmanager.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "var.federal_compliance_mode"
      values   = [tostring(var.federal_compliance_mode)]
    }
  }

  dynamic "statement" {
    for_each = length(var.additional_kms_key_user_arns) > 0 ? [1] : []
    content {
      sid    = "AllowAdditionalKeyUsers"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:ReEncrypt*",
        "kms:GenerateDataKey*",
        "kms:DescribeKey"
      ]
      resources = ["*"]

      principals {
        type        = "AWS"
        identifiers = var.additional_kms_key_user_arns
      }
    }
  }
}

resource "aws_kms_key" "this" {
  count                   = var.enable_customer_managed_kms ? 1 : 0
  description             = "CMK for ${local.name} encryption at rest"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms[0].json
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  count         = var.enable_customer_managed_kms ? 1 : 0
  name          = "alias/${local.name}-cmk"
  target_key_id = aws_kms_key.this[0].key_id
}

locals {
  kms_key_arn = var.enable_customer_managed_kms ? aws_kms_key.this[0].arn : null
}

# --- Secrets Manager: store Databricks PAT ---
resource "aws_secretsmanager_secret" "databricks_pat" {
  name        = "${local.name}-databricks-pat"
  description = "Databricks PAT for Lambda to call Databricks APIs"
  kms_key_id  = local.kms_key_arn
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
  name                 = "${local.name}-lambda-role"
  assume_role_policy   = data.aws_iam_policy_document.lambda_assume.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_logs" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "xray" {
  count      = var.enable_xray_tracing ? 1 : 0
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
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

  dynamic "statement" {
    for_each = var.enable_customer_managed_kms ? [1] : []
    content {
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]
      resources = [aws_kms_key.this[0].arn]
    }
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

# --- Optional account-level role for API Gateway execution logs ---
resource "aws_iam_role" "apigw_cloudwatch" {
  count = var.create_api_gateway_cloudwatch_role ? 1 : 0

  name                 = "${local.name}-apigw-cloudwatch-role"
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "apigw_cloudwatch" {
  count = var.create_api_gateway_cloudwatch_role ? 1 : 0

  role       = aws_iam_role.apigw_cloudwatch[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

locals {
  api_gateway_cloudwatch_role_arn_effective = var.api_gateway_cloudwatch_role_arn != null ? var.api_gateway_cloudwatch_role_arn : try(aws_iam_role.apigw_cloudwatch[0].arn, null)
}

resource "aws_api_gateway_account" "this" {
  count = var.enable_api_execution_logging ? 1 : 0

  cloudwatch_role_arn = local.api_gateway_cloudwatch_role_arn_effective

  lifecycle {
    precondition {
      condition     = var.federal_compliance_mode || !var.federal_compliance_mode
      error_message = "API execution logging requires an API Gateway CloudWatch role ARN."
    }
  }

  depends_on = [aws_iam_role_policy_attachment.apigw_cloudwatch]
}

# --- Package Lambda code ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_src"
  output_path = "${path.module}/lambda_build/${local.name}.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = local.lambda_log_group_name
  retention_in_days = var.cloudwatch_log_retention_days
  kms_key_id        = local.kms_key_arn
  tags              = var.tags
}

resource "aws_lambda_function" "this" {
  function_name = "${local.name}-fn"
  role          = aws_iam_role.lambda.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime     = var.lambda_runtime
  handler     = var.lambda_handler
  timeout     = var.lambda_timeout_seconds
  memory_size = var.lambda_memory_mb
  kms_key_arn = local.kms_key_arn

  tracing_config {
    mode = var.enable_xray_tracing ? "Active" : "PassThrough"
  }

  environment {
    variables = {
      DATABRICKS_HOST           = var.databricks_host
      DATABRICKS_WAREHOUSE_ID   = var.databricks_warehouse_id
      DATABRICKS_CATALOG        = var.databricks_catalog
      DATABRICKS_SCHEMA         = var.databricks_schema
      DATABRICKS_DEFAULT_QUERY  = var.databricks_default_query
      DATABRICKS_PAT_SECRET_ARN = aws_secretsmanager_secret.databricks_pat.arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
  tags       = var.tags
}

# --- API Gateway REST API from OpenAPI template ---
locals {
  lambda_invoke_arn = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.this.arn}/invocations"

  openapi_body = templatefile("${path.module}/openapi.tftpl", {
    api_title               = var.api_title
    api_description         = var.api_description
    lambda_invoke_arn       = local.lambda_invoke_arn
    cors_allow_origins_yaml = local.cors_allow_origins_yaml
    cors_allow_methods_yaml = local.cors_allow_methods_yaml
    cors_allow_headers_yaml = local.cors_allow_headers_yaml
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

resource "aws_cloudwatch_log_group" "api_access" {
  name              = local.api_access_log_group_name
  retention_in_days = var.api_access_log_retention_days
  kms_key_id        = local.kms_key_arn
  tags              = var.tags
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

  xray_tracing_enabled = var.enable_xray_tracing

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      errorMessage   = "$context.error.message"
      integrationErr = "$context.integrationErrorMessage"
    })
  }

  depends_on = [aws_api_gateway_account.this]
  tags       = var.tags
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = var.enable_api_execution_logging ? "INFO" : "OFF"
    data_trace_enabled = var.enable_api_execution_logging
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}
