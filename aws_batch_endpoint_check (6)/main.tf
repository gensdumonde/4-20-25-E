module "network" {
  source = "./modules/network"
}

module "security" {
  source = "./modules/security"
  vpc_id = module.network.vpc_id
}

module "iam" {
  source = "./modules/iam"
}

module "sns" {
  alert_email = var.alert_email
  source = "./modules/sns"
}

module "secrets" {
  s3_bucket = var.s3_bucket
  userid = var.userid
  password = var.password
  endpoint_urls = var.endpoint_urls
  source = "./modules/secrets"
}

module "batch" {
  source                  = "./modules/batch"
  subnet_id               = module.network.subnet_id
  security_group_id       = module.security.security_group_id
  ecs_instance_profile_arn = module.iam.ecs_instance_profile_arn
  batch_service_role_arn  = module.iam.batch_service_role_arn
  ecs_instance_role_arn   = module.iam.ecs_instance_role_arn
}
