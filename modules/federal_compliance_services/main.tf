locals {
  name = "${var.name_prefix}-fed-compliance-${var.stage_name}"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

locals {
  config_bucket_name = coalesce(
    var.config_bucket_name,
    "${var.config_bucket_prefix}-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.name}-${var.stage_name}"
  )

  config_service_role_arn_effective = var.config_service_role_arn != null ? var.config_service_role_arn : try(aws_iam_role.config[0].arn, null)
}

resource "aws_s3_bucket" "config" {
  count = var.enable_aws_config && var.create_config_bucket ? 1 : 0

  bucket = local.config_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "config" {
  count = var.enable_aws_config && var.create_config_bucket ? 1 : 0

  bucket = aws_s3_bucket.config[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count = var.enable_aws_config && var.create_config_bucket ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.config_s3_kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.config_s3_kms_key_arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  count = var.enable_aws_config && var.create_config_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.config[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config" {
  count = var.enable_aws_config ? 1 : 0

  bucket = local.config_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:${data.aws_partition.current.partition}:s3:::${local.config_bucket_name}"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = "arn:${data.aws_partition.current.partition}:s3:::${local.config_bucket_name}"
        Condition = {
          StringEquals = {
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "arn:${data.aws_partition.current.partition}:s3:::${local.config_bucket_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/Config/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "AWS:SourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.config,
    aws_s3_bucket_public_access_block.config
  ]
}

resource "aws_iam_role" "config" {
  count = var.enable_aws_config && var.create_config_service_role ? 1 : 0

  name = "${local.name}-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config_managed" {
  count = var.enable_aws_config && var.create_config_service_role ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_configuration_recorder" "this" {
  count = var.enable_aws_config ? 1 : 0

  name     = "${local.name}-recorder"
  role_arn = local.config_service_role_arn_effective

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  lifecycle {
    precondition {
      condition     = local.config_service_role_arn_effective != null
      error_message = "AWS Config requires config_service_role_arn or create_config_service_role=true."
    }
  }

  depends_on = [aws_iam_role_policy_attachment.config_managed]
}

resource "aws_config_delivery_channel" "this" {
  count = var.enable_aws_config ? 1 : 0

  name           = "${local.name}-delivery"
  s3_bucket_name = local.config_bucket_name

  snapshot_delivery_properties {
    delivery_frequency = var.config_delivery_frequency
  }

  depends_on = [aws_s3_bucket_policy.config]
}

resource "aws_config_configuration_recorder_status" "this" {
  count = var.enable_aws_config ? 1 : 0

  name       = aws_config_configuration_recorder.this[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0
}

resource "aws_securityhub_standards_subscription" "aws_foundational" {
  count = var.enable_security_hub && var.enable_foundational_best_practices_standard ? 1 : 0

  standards_arn = "arn:${data.aws_partition.current.partition}:securityhub:${data.aws_region.current.name}::standards/aws-foundational-security-best-practices/v/1.0.0"

  depends_on = [aws_securityhub_account.this]
}
