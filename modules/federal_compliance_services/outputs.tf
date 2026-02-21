output "config_bucket_name" {
  value = var.enable_aws_config ? local.config_bucket_name : null
}

output "config_configuration_recorder_name" {
  value = var.enable_aws_config ? aws_config_configuration_recorder.this[0].name : null
}

output "config_delivery_channel_name" {
  value = var.enable_aws_config ? aws_config_delivery_channel.this[0].name : null
}

output "security_hub_enabled" {
  value = var.enable_security_hub
}

output "security_hub_foundational_standard_subscription_arn" {
  value = var.enable_security_hub && var.enable_foundational_best_practices_standard ? aws_securityhub_standards_subscription.aws_foundational[0].standards_subscription_arn : null
}
