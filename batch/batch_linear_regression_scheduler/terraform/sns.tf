resource "aws_sns_topic" "notifications" {
  name = "brain-${var.brain_name}-batch-linear-regression"
}

resource "aws_ssm_parameter" "sns_topic_notifications_arn" {
  name        = "/anguyenbus/${var.brain_id}/batch-linear-regression/sns-topic-notification-arn"
  description = "SNS topic notification for batch skill extraction"
  type        = "String"
  value       = aws_sns_topic.notifications.arn

  tags = {
    environment = "${var.environment}"
  }
}
