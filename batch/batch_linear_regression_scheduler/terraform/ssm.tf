# Various SSM used by anguyenbus
resource "aws_ssm_parameter" "slack_hook" {
  name        = "/anguyenbus/${var.id}/batch-linear-regression/slack-web-hook"
  description = "Slack hook"
  type        = "SecureString"
  value       = "https://hooks.slack.com/services/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"

  tags = {
    environment = "${var.environment}"
  }
}

resource "aws_ssm_parameter" "batch_linear_extraction_customers" {
  name        = "/anguyenbus/${var.id}/batch-linear-regression/d61/customers"
  description = "Comma separated list of customers"
  type        = "String"
  value       = var.customers

  tags = {
    environment = "${var.environment}"
  }
}

resource "aws_ssm_parameter" "batch_linear_extraction_customers_bucket_pattern" {
  name        = "/anguyenbus/${var.id}/batch-linear-regression/d61/customers-bucket-pattern"
  description = "Comma separated list of customers"
  type        = "String"
  value       = "data-${var.environment}-${local.region_short_name}-{}"

  tags = {
    environment = "${var.environment}"
  }
}
