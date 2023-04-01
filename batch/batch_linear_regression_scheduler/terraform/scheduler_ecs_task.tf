locals {
  ecs_events_iam_name = "${var.aws_region}-${var.brain_id}-${var.service_name}-ecs-events"
}

resource "aws_ecs_task_definition" "service" {
  family                = "batch-skill-extraction-scheduler"
  container_definitions = file("../.buildkite/task-definition.json")
  execution_role_arn = local.execution_role_arn
  task_role_arn = module.task_role_scheduler.iam_role_arn
}

# TODO: use terraform in the processor service to create this SSM
resource "aws_ssm_parameter" "batch_ecs_service_processor" {
  name        = "/anguyenbus/${var.brain_id}/batch-skill-extraction/ecs-service-processor"
  description = "Name of the ECS service for batch skill processor"
  type        = "String"
  value       = "batch-skill-extraction-processor"

  tags = {
    environment = "${var.environment}"
  }
}

# TODO: use terraform in the writer service to create this SSM
resource "aws_ssm_parameter" "batch_ecs_service_writer" {
  name        = "/anguyenbus/${var.brain_id}/batch-skill-extraction/ecs-service-writer"
  description = "Name of the ECS service for batch skill writer"
  type        = "String"
  value       = "batch-skill-extraction-writer"

  tags = {
    environment = "${var.environment}"
  }
}

resource "aws_cloudwatch_event_rule" "every_tuesday_rule" {
  name                = "${var.aws_region}-${var.brain_id}-${var.service_name}-every-tuesday-runner"
  description         = "Run batch skill extraction every week on Tuesday at 1am utc"
  is_enabled          = true
  schedule_expression = "cron(0 1 ? * 3 *)"
}

resource "aws_cloudwatch_event_target" "every_tuesday_runner" {
  target_id = "${var.aws_region}-${var.brain_id}-${var.service_name}-every-tuesday-runner"
  arn       = data.aws_ssm_parameter.ecs_cluster_arn.value
  rule      = aws_cloudwatch_event_rule.every_tuesday_rule.name
  role_arn  = aws_iam_role.ecs_events.arn

  ecs_target {
    task_definition_arn = aws_ecs_task_definition.service.arn
  }
}

resource "aws_iam_role" "ecs_events" {
  name               = local.ecs_events_iam_name
  assume_role_policy = data.aws_iam_policy_document.ecs_events_assume_role_policy.json
  tags               = { environment = "${var.environment}" }
}

data "aws_iam_policy_document" "ecs_events_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "ecs_events" {
  name        = local.ecs_events_iam_name
  policy      = data.aws_iam_policy.ecs_events.policy
}

data "aws_iam_policy" "ecs_events" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

resource "aws_iam_role_policy_attachment" "ecs_events" {
  role       = aws_iam_role.ecs_events.name
  policy_arn = aws_iam_policy.ecs_events.arn
}
