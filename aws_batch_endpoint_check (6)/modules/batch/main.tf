variable "subnet_id" {
  type = string
}

variable "security_group_id" {
  type = string
}

variable "ecs_instance_profile_arn" {
  type = string
}

variable "batch_service_role_arn" {
  type = string
}

variable "ecs_instance_role_arn" {
  type = string
}

resource "aws_ecs_cluster" "batch_cluster" {
  name = "aws-batch-cluster"
}

resource "aws_batch_compute_environment" "batch_compute" {
  compute_environment_name = "batch_compute_env"
  service_role             = var.batch_service_role_arn
  type                     = "MANAGED"

  compute_resources {
    max_vcpus          = 16
    min_vcpus          = 0
    desired_vcpus      = 0
    instance_types     = ["m4.large"]
    subnets            = [var.subnet_id]
    security_group_ids = [var.security_group_id]
    instance_role      = var.ecs_instance_profile_arn
    type               = "EC2"
  }
}

resource "aws_batch_job_queue" "batch_queue" {
  name                 = "batch_queue"
  state                = "ENABLED"
  priority             = 1
  compute_environments = [aws_batch_compute_environment.batch_compute.arn]
}

resource "aws_batch_job_definition" "batch_job" {
  name = "batch_job_def"
  type = "container"

  container_properties = jsonencode({
    image: "REPLACE_ME_WITH_ECR_URI",
    vcpus: 1,
    memory: 1024,
    environment: [
      {
        name  : "SECRET_NAME",
        value : "batch_app_secret"
      },
      {
        name  : "SNS_TOPIC_ARN",
        value : "REPLACE_ME_WITH_SNS_ARN"
      }
    ],
    jobRoleArn: var.ecs_instance_role_arn
  })
}

output "job_definition_name" {
  value = aws_batch_job_definition.batch_job.name
}

output "job_queue_name" {
  value = aws_batch_job_queue.batch_queue.name
}
