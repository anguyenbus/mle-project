data "aws_caller_identity" "this" {}

data "terraform_remote_state" "default_environment" {
  backend = "s3"

  workspace = "${var.account}-ap-southeast-2"

  config = {
    region               = "ap-southeast-2"
    bucket               = "${var.account}-terraform-remote-state"
    key                  = "global/environment/terraform.tfstate"
    workspace_key_prefix = "account"
  }
}

data "terraform_remote_state" "environment" {
  backend   = "s3"
  workspace = "${var.account}-${var.aws_region}"

  config = {
    region               = "ap-southeast-2"
    bucket               = "${var.account}-terraform-remote-state"
    key                  = "global/environment/terraform.tfstate"
    workspace_key_prefix = "account"
  }
}

data "aws_ssm_parameter" "amazon_linux_ecs" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "template_file" "user_data_ecs_gpu" {
  template = file("${path.module}/templates/user-data.sh")

  vars = {
    cluster_name = "${var.brain_name}-batch-linear-regression"
    region       = var.aws_region
  }
}

data "aws_ssm_parameter" "rds_address" {
  name = "/anguyenbus/${var.brain_id}/rds/address"
  with_decryption = false
}
data "aws_ssm_parameter" "rds_sg" {
  name = "/anguyenbus/${var.brain_id}/rds/sg"
  with_decryption = false
}
data "aws_ssm_parameter" "brain_rds_resource_id" {
  name = "/anguyenbus/${var.brain_id}/rds/resource-id"
  with_decryption = false
}
data "aws_ssm_parameter" "rds_admin_username" {
  name = "/anguyenbus/${var.brain_id}/rds/username"
  with_decryption = false
}
data "aws_ssm_parameter" "rds_admin_password" {
  name = "/anguyenbus/${var.brain_id}/rds/password"
  with_decryption = true
}
data "aws_ssm_parameter" "customer_kms_key_id" {
  count = length(local.customers_list)
  name = "/customer/${local.customers_list[count.index]}/kms-key-id"
}
data "aws_ssm_parameter" "ecs_cluster_arn" {
  name = "/anguyenbus/${var.brain_id}/ecs-cluster/arn"
  with_decryption = true
}
