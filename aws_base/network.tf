module "vpc" {
  source = "./modules/vpc"

  vpc_cidr            = local.vpc_cidr[terraform.workspace]
  vpc_private_subnets = local.vpc_private_subnets[terraform.workspace]
  vpc_public_subnets  = local.vpc_public_subnets[terraform.workspace]
  vpc_designation     = local.vpc_designation[terraform.workspace]
}