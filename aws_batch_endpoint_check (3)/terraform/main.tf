
module "vpc" {
  source = "./modules/vpc"
}

module "s3" {
  source = "./modules/s3"
}

module "sns" {
  source = "./modules/sns"
}

module "secretsmanager" {
  source = "./modules/secretsmanager"
}

module "ecr" {
  source = "./modules/ecr"
}

module "iam" {
  source = "./modules/iam"
  sns_topic_arn = module.sns.topic_arn
}

module "batch" {
  source = "./modules/batch"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.subnet_ids
  security_group_id = module.vpc.security_group_id
  ecr_repo_url = module.ecr.repo_url
  job_role_arn = module.iam.job_role_arn
}

output "sns_topic_arn" {
  value = module.sns.topic_arn
}
