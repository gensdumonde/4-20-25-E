resource "aws_cloudwatch_dashboard" "batch_monitoring" {
  dashboard_name = "BatchJobMonitoringDashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0,
        y = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/Batch", "JobsSucceeded", "JobQueue", "${module.batch.job_queue_name}" ],
            [ ".", "JobsFailed", ".", "." ]
          ],
          view = "timeSeries",
          stacked = false,
          region = "us-east-1",
          title = "Batch Jobs - Success vs Failure"
        }
      },
      {
        type = "metric",
        x = 12,
        y = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/States", "ExecutionsSucceeded", "StateMachineArn", "${aws_sfn_state_machine.batch_monitor.arn}" ],
            [ ".", "ExecutionsFailed", ".", "." ]
          ],
          view = "timeSeries",
          stacked = false,
          region = "us-east-1",
          title = "Step Function Executions - Success vs Failure"
        }
      }
    ]
  })
}
