locals {
  module_tags = merge(
    var.inherited_tags,
    {
      "VPC Name"    = local.vpc_name,
      "Terraformed" = true,
      "Environment" = terraform.workspace
    },
  )

  vpc_name      = "aws-vpc-${terraform.workspace}-${var.vpc_designation}"
  expanded_name = "${terraform.workspace}-${var.vpc_designation}"
  # Default Private subnets
  default_private_az0        = { "us-west-2a" = cidrsubnet(var.vpc_cidr, 8, 0) }
  default_private_az1        = { "us-west-2b" = cidrsubnet(var.vpc_cidr, 8, 1) }
  default_private_subnet_map = merge(local.default_private_az0, local.default_private_az1)

  private_subnets = length(var.vpc_private_subnets) > 0 ? var.vpc_private_subnets : local.default_private_subnet_map

  // Default public, carve out a single CIDR range for public subnets
  default_public_subnet_cidr = cidrsubnet(var.vpc_cidr, 8, 2)

  // Default Public subnets
  default_public_az0        = { "us-west-2a" = cidrsubnet(local.default_public_subnet_cidr, 2, 0) }
  default_public_az1        = { "us-west-2b" = cidrsubnet(local.default_public_subnet_cidr, 2, 1) }
  default_public_subnet_map = merge(local.default_public_az0, local.default_public_az1)

  public_subnets = length(var.vpc_public_subnets) > 0 ? var.vpc_public_subnets : local.default_public_subnet_map
}

variable "vpc_cidr" {
  description = "CIDR notation for VPC (ie, '10.222.0.0/22')"
}

variable "vpc_private_subnets" {
  description = "Map of AZ -> Private subnets with their CIDRs (ie, { 'us-west-2a': '10.222.0.0/24', 'us-west-2b': '10.222.6.0/24' })"
  default     = {}
}

variable "vpc_public_subnets" {
  description = "Map of AZ -> Public subnets with their CIDRs (ie, { 'us-west-2a': '10.222.0.0/24', 'us-west-2b': '10.222.6.0/24' })"
  default     = {}
}

variable "inherited_tags" {
  description = "A map of inherited tags to apply to all resources within this module"
  default     = {}
}

variable "inherited_public_subnet_tags" {
  default = {}
}

variable "inherited_private_subnet_tags" {
  default = {}
}

variable "vpc_designation" {
  description = "Designation to give to vpc"
  default     = "TesterPOC"
}