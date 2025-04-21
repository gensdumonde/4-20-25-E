resource "aws_secretsmanager_secret" "app_secret" {
  name = "batch_app_secret"
}

resource "aws_secretsmanager_secret_version" "app_secret_version" {
  secret_id     = aws_secretsmanager_secret.app_secret.id
  secret_string = jsonencode({
    s3_bucket     = "your-s3-bucket-name",
    userid        = "your_userid",
    password      = "your_password",
    endpoint_urls = "https://example.com/api/health"
  })
}

output "secret_name" {
  value = aws_secretsmanager_secret.app_secret.name
}
