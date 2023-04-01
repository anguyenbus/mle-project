#-----------------------------------------------------------------------------------------------------------------------
# Common Variables
#-----------------------------------------------------------------------------------------------------------------------
variable "aws_region" {
  type        = string
  description = "AWS Region to create resources in"
}

variable "account" {
  type        = string
  description = "Name of the account."
}

variable "account_id" {
  type        = string
  description = "ID of the AWS account."
}

variable "environment" {
  type        = string
  description = "Environment resources are being created for"
}

#-----------------------------------------------------------------------------------------------------------------------
# Application Specific Variables
#-----------------------------------------------------------------------------------------------------------------------
variable "service_name" {
  type        = string
  description = "Name of the services being created"
  default     = "batch-linear-regression"
}

#-----------------------------------------------------------------------------------------------------------------------
# brain Specific Variables
#-----------------------------------------------------------------------------------------------------------------------
variable "id" {
  type        = string
  description = "brain ID"
}

variable "name" {
  type        = string
  description = "An identification name used inside the project to identify env, region and id"
}

variable "customers" {
  type        = string
  description = "Comma separated list of customer to batch linear regression"
}

variable "ecs_instance_type" {
  type        = string
  description = "Instance type to use when deploying ECS clusters"
  default     = "t3.large"
}

variable "ecs_ami_id" {
  type        = string
  description = "AMI ID for ecs cluster"
  default     = ""
}

locals {
  # region_short_names_city = {
  #   "ap-southeast-2" = "syd"
  #   "us-east-1"      = "nva"
  # }
  # name  = "${var.environment}-${local.region_short_names_city[var.aws_region]}-${var.id}"

  tags = {
    Service     = var.service_name
    Environment = var.environment
    Team        = "application"
    Version     = "1.0.0"
  }

  execution_role_arn = "arn:aws:iam::${var.account_id}:role/devops/ecs-deploy-execution-role"

  region_short_names = {
    "ap-southeast-1" = "apse1"
    "ap-southeast-2" = "apse2"
    "us-east-1"      = "use1"
    "eu-west-1"      = "euw1"
    "eu-west-2"      = "euw2"
  }

  loc_short_names = {
    "ap-southeast-1" = "sin"
    "ap-southeast-2" = "syd"
    "us-east-1"      = "nva"
    "eu-west-1"      = "irl"
    "eu-west-2"      = "lon"
  }

  region_short_name = lookup(local.region_short_names, var.aws_region, null)
  loc_short_name    = lookup(local.loc_short_names, var.aws_region, null)

  customers_list = split(",", var.customers)

}
