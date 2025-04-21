resource "aws_sns_topic" "app_alerts" {
  name = "app_alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.app_alerts.arn
  protocol  = "email"
  endpoint  = "app-team@example.com"
}

output "sns_topic_arn" {
  value = aws_sns_topic.app_alerts.arn
}
