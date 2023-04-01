
#-----------------------------------------------------------------------------------------------------------------------
# batch_data_processing DB access
#-----------------------------------------------------------------------------------------------------------------------
resource "mysql_user" "user" {
  user               = "batch_data_processing"
  host               = "%"
  auth_plugin        = "AWSAuthenticationPlugin"
}


resource "mysql_database" "batch_data_processing" {
  name = "batch_data_processing"
}

resource "mysql_grant" "user" {
  user     = mysql_user.user.user
  host     = mysql_user.user.host
  database = "batch_data_processing"
  privileges = [
    "ALL"
  ]
  # privileges = [
  #   "SELECT",
  #   "INSERT",
  #   "UPDATE"
  # ]
}

resource "aws_ssm_parameter" "db_name" {
  name        = "/anguyenbus/${var.brain_id}/batch-linear-regression/d61/database/dbname"
  description = "The batch_data_processing database dbname"
  type        = "String"
  value       = mysql_database.batch_data_processing.name

  tags = {
    environment = "${var.environment}"
  }
}

resource "aws_ssm_parameter" "db_username" {
  name        = "/anguyenbus/${var.brain_id}/batch-linear-regression/d61/database/username"
  description = "The batch_data_processing database username"
  type        = "String"
  value       = mysql_user.user.user

  tags = {
    environment = "${var.environment}"
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# CUSTOMER DB ACCESS from
#-----------------------------------------------------------------------------------------------------------------------
resource "mysql_user" "customer_db" {
  count = length(local.customers_list)
  user         = substr("${local.customers_list[count.index]}-batchskillextrac", 0, 32)
  host         = "%"
  # IAM authentication
  auth_plugin  = "AWSAuthenticationPlugin"
}

# TODO: specify which table instead of *. However this will fail if table does not exist yet
resource "mysql_grant" "brain_batch_extraction_grant" {
  count = length(local.customers_list)
  user       = mysql_user.customer_db[count.index].user
  host       = mysql_user.customer_db[count.index].host
  database   = local.customers_list[count.index]
  table      = "*"
  privileges = [
    "SELECT",
    "INSERT",
    "UPDATE"
  ]
}

resource "aws_ssm_parameter" "brain_batch_extraction_db_host" {
  count = length(local.customers_list)
  name        = "/anguyenbus/${var.brain_id}/batch-linear-regression/customer_db/${local.customers_list[count.index]}/host"
  type        = "SecureString"
  value       = data.aws_ssm_parameter.rds_address.value
  tags = {
    environment = "${var.environment}"
  }
}

resource "aws_ssm_parameter" "brain_batch_extraction_db_port" {
  count = length(local.customers_list)
  name        = "/anguyenbus/${var.brain_id}/batch-linear-regression/customer_db/${local.customers_list[count.index]}/port"
  type        = "SecureString"
  value       = 3306
  tags = {
    environment = "${var.environment}"
  }
}

resource "aws_ssm_parameter" "brain_batch_extraction_db_name" {
  count = length(local.customers_list)
  name        = "/anguyenbus/${var.brain_id}/batch-linear-regression/customer_db/${local.customers_list[count.index]}/database"
  type        = "SecureString"
  value       = local.customers_list[count.index]
  tags = {
    environment = "${var.environment}"
  }
}
resource "aws_ssm_parameter" "brain_batch_extraction_db_user" {
  count = length(local.customers_list)
  name        = "/anguyenbus/${var.brain_id}/batch-linear-regression/customer_db/${local.customers_list[count.index]}/user"
  type        = "SecureString"
  value       = mysql_user.customer_db[count.index].user
  tags = {
    environment = "${var.environment}"
  }
}


