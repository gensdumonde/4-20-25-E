
provider "aws" {
  region = var.aws_region
}

resource "aws_iam_role" "ecs_instance_role" {
  name = "ecsInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_policy" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_policy" "batch_job_policy" {
  name        = "batch-job-policy"
  description = "Policy for Batch job to access Secrets Manager, S3, and SNS"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "SecretsManagerAccess",
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = aws_secretsmanager_secret.sftp_credentials.arn
      },
      {
        Sid    = "SNSPublish",
        Effect = "Allow",
        Action = "sns:Publish",
        Resource = aws_sns_topic.batch_job_notifications.arn
      },
      {
        Sid    = "S3Upload",
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      }
    ]
  })
}

resource "aws_iam_role" "batch_job_role" {
  name = "batch-job-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "batch_job_role_attachment" {
  role       = aws_iam_role.batch_job_role.name
  policy_arn = aws_iam_policy.batch_job_policy.arn
}

resource "aws_iam_role" "batch_service_role" {
  name = "batch-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "batch.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "batch_service_role_attach" {
  role       = aws_iam_role.batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_batch_compute_environment" "batch_compute_env" {
  compute_environment_name = "batch-compute-ec2-env"
  type                     = "MANAGED"
  service_role             = aws_iam_role.batch_service_role.arn

  compute_resources {
    type                  = "EC2"
    instance_role         = aws_iam_instance_profile.ecs_instance_profile.arn
    instance_types        = ["c5.large", "m5.large"]
    allocation_strategy   = "BEST_FIT_PROGRESSIVE"
    min_vcpus             = 0
    max_vcpus             = 4
    desired_vcpus         = 0
    subnets               = var.subnet_ids
    security_group_ids    = var.security_group_ids
    ec2_key_pair          = var.key_pair_name
    tags = {
      Name = "Batch EC2 Compute"
    }
  }
}

resource "aws_logs_log_group" "batch_log_group" {
  name = "/aws/batch/job-logs"
}

resource "aws_batch_job_queue" "batch_job_queue" {
  name                 = "batch-job-queue"
  state                = "ENABLED"
  priority             = 1
  compute_environments = [aws_batch_compute_environment.batch_compute_env.arn]
}

resource "aws_batch_job_definition" "batch_job_definition" {
  name       = "batch-job-definition"
  type       = "container"
  platform_capabilities = ["EC2"]

  container_properties = jsonencode({
    image           = var.docker_image
    jobRoleArn      = aws_iam_role.batch_job_role.arn
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_logs_log_group.batch_log_group.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "batch-job"
      }
    }
  })
}

resource "aws_sns_topic" "batch_job_notifications" {
  name = "batch-job-notifications"
}

resource "aws_sfn_state_machine" "batch_job_step_function" {
  name     = "batch-job-step-function"
  role_arn = aws_iam_role.batch_service_role.arn

  definition = jsonencode({
    StartAt = "SubmitBatchJob",
    States = {
      SubmitBatchJob = {
        Type    = "Task",
        Resource = "arn:aws:states:::aws-sdk:batch.submitJob",
        Parameters = {
          JobQueue = aws_batch_job_queue.batch_job_queue.arn,
          JobDefinition = aws_batch_job_definition.batch_job_definition.arn,
          JobName = "batch-job"
        },
        Retry = [
          {
            ErrorEquals = ["States.ALL"],
            IntervalSeconds = 60,
            MaxAttempts = 3,
            BackoffRate = 2.0
          }
        ],
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next = "FailureNotification"
          }
        ],
        End = true
      },

      FailureNotification = {
        Type    = "Task",
        Resource = "arn:aws:states:::sns:publish",
        Parameters = {
          TopicArn = aws_sns_topic.batch_job_notifications.arn,
          Message  = "Batch job failed after retries.",
          Subject  = "Batch Job Failure Notification"
        },
        End = true
      }
    }
  })
}

resource "aws_cloudwatch_event_rule" "batch_schedule_rule" {
  name        = "batch-schedule-rule"
  description = "Trigger batch job every day at 5 AM"
  schedule_expression = "cron(0 5 * * ? *)"
}

resource "aws_cloudwatch_event_target" "batch_schedule_target" {
  rule = aws_cloudwatch_event_rule.batch_schedule_rule.name
  arn  = aws_sfn_state_machine.batch_job_step_function.arn
}

resource "aws_lambda_permission" "eventbridge_to_stepfunction" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_sfn_state_machine.batch_job_step_function.name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.batch_schedule_rule.arn
}

resource "aws_secretsmanager_secret" "sftp_credentials" {
  name = "sftp/credentials"

  secret_string = jsonencode({
    hostname = "sftp.example.com",
    username = "sftp-user",
    password = "sftp-password",
    port     = 22
  })
}
