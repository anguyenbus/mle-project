# Create the ECS Cluster normal EC2
resource "aws_ecs_cluster" "ecs_cluster_gpu" {
  name               = "${var.brain_name}-batch-linear-regression"
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(local.tags, { Name = "${var.brain_name}-batch-linear-regression" })
}

# Create the ECS instance profile
module "ecs_instance_profile_role_gpu" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 4.3"

  role_name               = "${var.brain_name}-batch-linear-regression-ecs-instance-role"
  create_role             = true
  create_instance_profile = true
  role_requires_mfa       = false

  trusted_role_services = ["ec2.amazonaws.com"]
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/EC2InstanceConnect",
  ]
  number_of_custom_role_policy_arns = 4

  tags = merge(local.tags, { Name = "${var.brain_name}-batch-linear-regression-ecs-instance-role" })
}

// Launch configuration and autoscaling group
module "autoscaling_ec2_instances_gpu" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "${var.brain_name}-batch-linear-regression-ecs-instance"

  # Launch configuration
  lc_name = "${var.brain_name}-batch-linear-regression-ecs-instance"

  image_id = var.ecs_ami_id != "" ? var.ecs_ami_id : data.aws_ssm_parameter.amazon_linux_ecs.value
  instance_type        = var.ecs_instance_type
  security_groups      = [module.ecs_instance_sg_gpu.security_group_id]
  iam_instance_profile = module.ecs_instance_profile_role_gpu.iam_instance_profile_name
  user_data            = data.template_file.user_data_ecs_gpu.rendered

  # Auto scaling group
  create_asg                = true
  asg_name                  = "${var.brain_name}-batch-linear-regression-ecs-instance"
  vpc_zone_identifier       = data.terraform_remote_state.environment.outputs.private_subnets
  health_check_type         = "EC2"
  # The scheduler service will resize the ASG based on needs when process needs to start
  min_size                  = 0
  max_size                  = 0
  desired_capacity          = 0
  wait_for_capacity_timeout = 0
  termination_policies      = ["OldestLaunchConfiguration", "Default"]

  tags = concat(
    [
      {
        key                 = "Cluster"
        value               = "${var.brain_name}-batch-linear-regression"
        propagate_at_launch = true
      },
      {
        key                 = "Patch Group"
        value               = "ecs-hosts"
        propagate_at_launch = true
      },
      {
        key                 = "AwsInspector"
        value               = true
        propagate_at_launch = true
      }
    ],
    [for name, val in local.tags : { key = name, value = val, propagate_at_launch = true }]
  )
}

module "ecs_instance_sg_gpu" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.4"

  use_name_prefix = false
  name            = "${var.brain_name}-batch-linear-regression-ecs-instances-sg"
  description     = "Security group for ${var.brain_name} batch-linear-regression ecs instances."
  vpc_id          = data.terraform_remote_state.environment.outputs.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "all-all"
      source_security_group_id = data.terraform_remote_state.environment.outputs.bastion_server_security_group
    },
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  tags = merge(local.tags, { Name = "${var.brain_name}-batch-linear-regression-ecs-instances-sg" })
}

resource "aws_security_group_rule" "brain_rds_batch_linear_regression_sg" {
  description       = "batch-linear-regression access"
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = module.ecs_instance_sg_gpu.security_group_id
  security_group_id = data.aws_ssm_parameter.rds_sg.value
}

resource "aws_ssm_parameter" "ecs_cluster_name_gpu" {
  name        = "/anguyenbus/${var.brain_id}/batch-linear-regression/processing-ecs-cluster/name"
  description = "GPU ECS cluster name"
  type        = "String"
  value       = aws_ecs_cluster.ecs_cluster_gpu.name

  tags = {
    environment = "${var.environment}"
  }
}

resource "aws_ssm_parameter" "asg_gpu" {

  name        = "/anguyenbus/${var.brain_id}/batch-linear-regression/processing-ecs-cluster/asg"
  description = "GPU auto scaling group"
  type        = "String"
  value       = module.autoscaling_ec2_instances_gpu.this_autoscaling_group_name

  tags = {
    environment = "${var.environment}"
  }
}
