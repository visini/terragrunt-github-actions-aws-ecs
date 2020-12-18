######################################
# Parameters
######################################

resource "random_password" "SECRET_KEY" {
  length = 64
  special = true
}

resource "aws_ssm_parameter" "SECRET_KEY" {
  type  = "SecureString"
  name  = "/${var.app_name}/${var.environment}/api/secrets/SECRET_KEY"
  value = random_password.SECRET_KEY.result
  tags = {
    app_name = var.app_name
    environment = var.environment
  }
}