module "vpc" {
  source = "./modules/vpc"

  vpc_cidr = "10.0.0.0/16"
  vpc_private_subnets = { us-west-2a = "10.0.0.0/24"} #{ us-west-2a = "10.0.0.0/24", us-west-2b = "10.0.1.0/24" }
  vpc_public_subnets = { us-west-2a = "10.0.3.0/26"} #{ us-west-2a = "10.0.3.0/26", us-west-2b = "10.0.3.64/26" }
  vpc_designation = "demo"
}