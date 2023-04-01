terraform {
  required_version = ">= 1.0.0"
  backend "s3" {}
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.14.0"
    }
    mysql = {
      source  = "terraform-providers/mysql"
      version = "~> 1.8.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "aws" { region = var.aws_region }

provider "mysql" {
  endpoint              = data.aws_ssm_parameter.rds_address.value 
  username              = data.aws_ssm_parameter.rds_admin_username.value 
  password              = data.aws_ssm_parameter.rds_admin_password.value 
  
  max_conn_lifetime_sec = 60
  max_open_conns        = 10
}
