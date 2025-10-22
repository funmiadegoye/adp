locals {
  name = "adp"
}

module "vpc" {
  source   = "./module/vpc"
  name     = local.name
  key_name = "${local.name}-key"  
}

module "nexus" {
  source     = "./module/nexus"
  name       = local.name
  vpc_id     = module.vpc.vpc_id
  subnet_id  = module.vpc.private_subnet_ids[0]
  key_name   = module.vpc.public_key_name
}