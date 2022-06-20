locals {
  vpc_cidr = {
    dev = "10.0.0.0/16",
    qa  = "192.168.0.0/16"
  }
  vpc_private_subnets = {
    dev = { us-west-2a = "10.0.0.0/24", us-west-2b = "10.0.1.0/24" },
    qa  = { us-west-2a = "192.168.0.0/24" }
  }
  vpc_public_subnets = {
    dev = { us-west-2a = "10.0.3.0/26", us-west-2b = "10.0.3.64/26" },
    qa  = { us-west-2a = "192.168.3.0/26" }
  }
  vpc_designation = {
    dev = "demo",
    qa  = "demo"
  }
}