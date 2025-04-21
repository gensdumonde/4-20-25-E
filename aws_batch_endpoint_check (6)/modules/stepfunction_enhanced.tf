resource "aws_dynamodb_table" "batch_job_status" {
  name           = "BatchJobStatus"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "JobId"

  attribute {
    name = "JobId"
    type = "S"
  }

  tags = {
    Environment = "production"
  }
}

resource "aws_s3_bucket" "batch_job_logs" {
  bucket = "batch-job-logs-storage"
  force_destroy = true

  tags = {
    Environment = "production"
  }
}

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

resource "aws_iam_policy" "step_function_extra" {
  name = "StepFunctionExtraPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect: "Allow",
        Action: [
          "dynamodb:PutItem"
        ],
        Resource: "${aws_dynamodb_table.batch_job_status.arn}"
      },
      {
        Effect: "Allow",
        Action: [
          "s3:PutObject"
        ],
        Resource: "${aws_s3_bucket.batch_job_logs.arn}/*"
      },
      {
        Effect: "Allow",
        Action: [
          "sns:Publish"
        ],
        Resource: "${module.sns.sns_topic_arn}"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_step_function_extra" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_extra.arn
}

resource "aws_sfn_state_machine" "batch_monitor" {
  name     = "BatchJobMonitor"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    StartAt = "Submit Job",
    States = {
      "Submit Job" = {
        Type = "Task",
        Resource = "arn:aws:states:::batch:submitJob.sync",
        Parameters = {
          JobName       = "monitored-job",
          JobQueue      = "${module.batch.job_queue_name}",
          JobDefinition = "${module.batch.job_definition_name}"
        },
        ResultPath = "$.jobResult",
        Next = "Store Result in DynamoDB"
      },
      "Store Result in DynamoDB" = {
        Type = "Task",
        Resource = "arn:aws:states:::aws-sdk:dynamodb:putItem",
        Parameters = {
          TableName = "${aws_dynamodb_table.batch_job_status.name}",
          Item = {
            JobId = { S = "$.jobResult.JobId" },
            Status = { S = "$.jobResult.Status" }
          }
        },
        Next = "Upload to S3"
      },
      "Upload to S3" = {
        Type = "Task",
        Resource = "arn:aws:states:::aws-sdk:s3:putObject",
        Parameters = {
          Bucket = "${aws_s3_bucket.batch_job_logs.bucket}",
          Key = "results/batch-output-$.jobResult.JobId.json",
          Body = "Job result: $.jobResult"
        },
        Next = "Check Status"
      },
      "Check Status" = {
        Type = "Choice",
        Choices = [
          {
            Variable = "$.jobResult.Status",
            StringEquals = "SUCCEEDED",
            Next = "Success Notification"
          }
        ],
        Default = "Failure Notification"
      },
      "Success Notification" = {
        Type = "Task",
        Resource = "arn:aws:states:::aws-sdk:sns:publish",
        Parameters = {
          TopicArn = "${module.sns.sns_topic_arn}",
          Message = "Batch job succeeded",
          Subject = "Batch Job Success"
        },
        End = true
      },
      "Failure Notification" = {
        Type = "Task",
        Resource = "arn:aws:states:::aws-sdk:sns:publish",
        Parameters = {
          TopicArn = "${module.sns.sns_topic_arn}",
          Message = "Batch job failed",
          Subject = "Batch Job Failure"
        },
        End = true
      }
    }
  })
}
