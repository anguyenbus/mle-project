resource "aws_kinesis_stream" "profile_update_input_from_batch_skill_process" {
  name             = "${var.brain_name}-${var.service_name}-profile-update-input-from-batch-skill-process"

  retention_period = 120
  shard_count      = 2

  encryption_type = "KMS"
  kms_key_id      = "alias/aws/kinesis"

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags = merge({ Name = "profile-update-input-from-batch-skill-process" }, local.tags)
}

resource "aws_lambda_event_source_mapping" "example" {
  event_source_arn  = aws_kinesis_stream.profile_update_input_from_batch_skill_process.arn
  # TODO: fetch the ARN dynamically. Created via CFN https://github.com/anguyenbus/data-pipeline/blob/843a7ba90d4b94ffe6e9c06662960682721635ff/infrastructure/template.yaml#L486-L516
  function_name     = "arn:aws:lambda:${var.aws_region}:${var.account_id}:function:data-pipeline-ProfileUpdate"
  starting_position = "LATEST"
}

resource "aws_ssm_parameter" "profile_update_input_from_batch_skill_process" {
  name        = "/anguyenbus/${var.brain_id}/batch-linear-regression/d61/kinesis/profile-update"
  description = "Profile updates"
  type        = "String"
  value       = aws_kinesis_stream.profile_update_input_from_batch_skill_process.name

  tags = {
    environment = "${var.environment}"
  }
}
