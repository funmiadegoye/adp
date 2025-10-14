provider "aws" {
  region  = "eu-west-2"
  profile = "tutu"
}
terraform {
  backend "s3" {
    bucket       = "funmi-2025"
    key          = "vault-jenkins/terraform.tfstate"
    region       = "eu-west-2"
    profile      = "tutu"
    encrypt      = true
    use_lockfile = true
  }
}