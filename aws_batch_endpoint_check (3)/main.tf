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
  source = "./modules/sns"
}

module "secrets" {
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
