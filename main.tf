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
  subnet_ids = module.vpc.private_subnet_ids
  key_name   = module.vpc.public_key_name
}

module "bastion" {
  source    = "./module/bastion"
  name      = local.name
  vpc_id    = module.vpc.vpc_id
  subnets   = module.vpc.public_subnet_ids
  keypair   = module.vpc.public_key_name
  privatekey = module.vpc.private_key_pem
  nr-key    = "NRAK-EALLCYVB0O491YGB6UW105ED8ZT"
  nr-acc-id = "7181908"
  region    = "eu-west-2"
}