resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.name}/${var.service_name}"
  retention_in_days = 365
  tags              = merge(local.tags, { Name = "${var.service_name}" })
}
