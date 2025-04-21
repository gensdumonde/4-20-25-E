resource "aws_cloudwatch_metric_alarm" "batch_job_failures" {
  alarm_name          = "BatchJobFailuresAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "JobsFailed"
  namespace           = "AWS/Batch"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alarm if more than 1 Batch job fails in 5 minutes"
  alarm_actions       = [module.sns.sns_topic_arn]
  dimensions = {
    JobQueue = module.batch.job_queue_name
  }
}
