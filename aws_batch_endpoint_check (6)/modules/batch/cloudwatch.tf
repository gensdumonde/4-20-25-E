resource "aws_cloudwatch_log_group" "batch_logs" {
  name              = "/aws/batch/job-logs"
  retention_in_days = 7
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.batch_logs.name
}
