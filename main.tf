locals {
  name = "adp"
}

module "vpc" {
  source   = "./module/vpc"
  name     = local.name
  key_name = "${local.name}-key"  

}