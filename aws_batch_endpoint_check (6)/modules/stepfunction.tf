resource "aws_iam_role" "step_function_role" {
  name = "stepFunctionBatchMonitorRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "states.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "step_function_policy" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBatchFullAccess"
}

resource "aws_sfn_state_machine" "batch_monitor" {
  name     = "BatchJobMonitor"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    StartAt = "Submit Job",
    States = {
      "Submit Job" = {
        Type       = "Task",
        Resource   = "arn:aws:states:::batch:submitJob.sync",
        Parameters = {
          JobName       = "monitored-job",
          JobQueue      = "${module.batch.job_queue_name}",
          JobDefinition = "${module.batch.job_definition_name}"
        },
        End = true
      }
    }
  })
}
