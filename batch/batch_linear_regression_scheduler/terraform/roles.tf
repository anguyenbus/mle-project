# Scheduler requires more permissions (scaling ASG and ECS, creating Kinesis)
module "task_role_scheduler" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com",
  ]

  trusted_role_arns = [
    "arn:aws:iam::${var.account_id}:role/devops/ecs-deploy-execution-role",
  ]

  create_role           = true
  role_name             = "${var.name}-${var.service_name}-scheduler-task-exe"
  role_description      = "ECS Task Role for svc-${var.service_name} scheduler in ${var.name}"
  force_detach_policies = true
  role_requires_mfa     = false
  role_path             = "/"
  tags                  = merge(local.tags, { Name = "${var.name}-${var.service_name}-task-exe" })
}
resource "aws_iam_role_policy" "task_policy_scheduler" {
  role = module.task_role_scheduler.iam_role_name
  name = "${var.name}-${var.service_name}-scheduler-policy"
  policy = jsonencode({
    Statement = [
      {
        Sid    = "KmsKeyUsage"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [data.terraform_remote_state.default_environment.outputs.s3key_kms_key_arn]
      },
      {
        Sid    = "KinesisStreamInput"
        Effect = "Allow"
        Action = [
          "kinesis:CreateStream",
          "kinesis:DescribeStream",
          "kinesis:DeleteStream",
          "kinesis:PutRecord"
        ]
        Resource = [
          for customer in local.customers_list:
            "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/batch-linear-regression-input-${customer}"
        ]
      },
      {
        Sid    = "KinesisStreamOutput"
        Effect = "Allow"
        Action = [
          "kinesis:CreateStream",
          "kinesis:DeleteStream",
          "kinesis:DescribeStream",
        ]
        Resource = [
          for customer in local.customers_list:
            "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/batch-linear-regression-output-${customer}"
        ]
      },
      {
        Sid    = "TokenIamCustomerDB"
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          for customer in local.customers_list:
            "arn:aws:rds-db:${var.aws_region}:${var.account_id}:dbuser:${data.aws_ssm_parameter.rds_resource_id.value}/${mysql_user.customer_db[index(local.customers_list, customer)].user}"
        ]
      },
      {
        Sid    = "TokenIamBatchDataProcessingDB"
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = [
          "arn:aws:rds-db:${var.aws_region}:${var.account_id}:dbuser:${data.aws_ssm_parameter.rds_resource_id.value}/${mysql_user.user.user}"
        ]
      },
      {
        Sid    = "ECSScaling"
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices",
          "ecs:ListContainerInstances"
        ]
        Resource = [
          aws_ecs_cluster.ecs_cluster_gpu.arn,
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:service/${var.name}-${var.service_name}/batch-linear-regression-processor",
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:service/${var.name}-${var.service_name}/batch-linear-regression-writer"
        ]

      },
      {
        Sid    = "EC2AutoScalingGroupUpdate"
        Effect = "Allow"
        Action = [
          "autoscaling:Describe*",
          "autoscaling:UpdateAutoScalingGroup"
        ]
        Resource = [ module.autoscaling_ec2_instances_gpu.this_autoscaling_group_arn ]
      },
      {
        Sid    = "SNSPublish"
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = [aws_sns_topic.notifications.arn]
      },
      {
        Sid    = "SSMWrite"
        Effect = "Allow"
        Action = [
          "ssm:PutParameter"
        ]
        Resource = ["arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/anguyenbus/${var.id}/batch-linear-regression/d61/kinesis*"]
      },
      {
        Sid    = "SSMGet"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = ["arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/anguyenbus/${var.id}/batch-linear-regression/*"]
      }
    ]
  })
}
# normal tasks need less permissions (only DB and read/write Kinesis)

module "task_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"

  trusted_role_services = [
    "ecs-tasks.amazonaws.com",
  ]

  trusted_role_arns = [
    "arn:aws:iam::${var.account_id}:role/devops/ecs-deploy-execution-role",
  ]

  create_role           = true
  role_name             = "${var.name}-${var.service_name}-task-exe"
  role_description      = "ECS Task Role for svc-${var.service_name} in ${var.name}"
  force_detach_policies = true
  role_requires_mfa     = false
  role_path             = "/"
  tags                  = merge(local.tags, { Name = "${var.name}-${var.service_name}-task-exe" })
}

resource "aws_iam_role_policy" "task_policy" {
  role = module.task_role.iam_role_name
  name = "${var.name}-${var.service_name}-policy"
  policy = jsonencode({
    Statement = [
      {
        Sid    = "KmsKeyUsage"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = [data.terraform_remote_state.default_environment.outputs.s3key_kms_key_arn]
      },
      {
        Sid    = "KinesisStreamOutput"
        Effect = "Allow"
        Action = [
          "kinesis:Get*",
          "kinesis:DescribeStream",
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = [
          for customer in local.customers_list:
            "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/batch-linear-regression-output-${customer}"
        ]
      },
      {
        Sid    = "KinesisStreamInput"
        Effect = "Allow"
        Action = [
          "kinesis:Get*",
          "kinesis:DescribeStream",
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = [
          for customer in local.customers_list:
            "arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/batch-linear-regression-input-${customer}"
        ]
      },
      {
        Sid    = "KinesisStreamProfileUpdate"
        Effect = "Allow"
        Action = [
          "kinesis:Get*",
          "kinesis:DescribeStream",
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = ["arn:aws:kinesis:${var.aws_region}:${var.account_id}:stream/${var.name}-${var.service_name}-profile-update-input-from-batch-process"]
      },
      {
        Sid    = "TokenIamBatchDataProcessingDB"
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        Resource = ["arn:aws:rds-db:${var.aws_region}:${var.account_id}:dbuser:${data.aws_ssm_parameter.rds_resource_id.value}/${mysql_user.user.user}"]
      },
      {
        Sid    = "CustomerDataS3Access"
        Effect = "Allow"
        Action = [
          "s3:Put*",
          "s3:Get*",
          "s3:ListBucket"
        ]
        Resource = flatten([
            for customer in local.customers_list:[
              "arn:aws:s3:::data-${var.environment}-${local.region_short_name}-${customer}/*",
              "arn:aws:s3:::data-${var.environment}-${local.region_short_name}-${customer}"
            ]
          ])
      }
    ]
  })
}
resource "aws_kms_grant" "customer_kms_key_scheduler" {
  count = length(local.customers_list)
  key_id            = data.aws_ssm_parameter.customer_kms_key_id[count.index].value
  grantee_principal = module.task_role_scheduler.iam_role_arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

resource "aws_kms_grant" "customer_kms_key_writer_processor" {
  count = length(local.customers_list)
  key_id            = data.aws_ssm_parameter.customer_kms_key_id[count.index].value
  grantee_principal = module.task_role.iam_role_arn
  operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
}

resource "aws_ssm_parameter" "task_role_arn" {
  name        = "/anguyenbus/${var.id}/batch-linear-regression/task-role-arn"
  description = "The ARN for the  ECS task role"
  type        = "String"
  value       = module.task_role.iam_role_arn

  tags = {
    environment = "${var.environment}"
  }
}
