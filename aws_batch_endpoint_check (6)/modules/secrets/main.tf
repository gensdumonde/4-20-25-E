variable "s3_bucket" {}
variable "userid" {}
variable "password" {}
variable "endpoint_urls" {}

resource "aws_secretsmanager_secret" "app_secret" {
  name = "batch_app_secret"
}

resource "aws_secretsmanager_secret_version" "app_secret_version" {
  secret_id     = aws_secretsmanager_secret.app_secret.id
  secret_string = jsonencode({
    s3_bucket     = var.s3_bucket,
    userid        = var.userid,
    password      = var.password,
    endpoint_urls = var.endpoint_urls
  })
}

output "secret_name" {
  value = aws_secretsmanager_secret.app_secret.name
}
