
variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "subnet_ids" {
  description = "List of subnet IDs for EC2 instances"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for EC2 instances"
  type        = list(string)
}

variable "key_pair_name" {
  description = "The EC2 Key Pair name"
  type        = string
}

variable "docker_image" {
  description = "Docker image for Batch job container"
  type        = string
}

variable "s3_bucket_name" {
  description = "The S3 bucket name to store output"
  type        = string
}
