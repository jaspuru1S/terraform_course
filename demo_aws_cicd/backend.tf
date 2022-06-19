terraform {
  backend "s3" {
    bucket         = "jaspuru-terraform-state"
    key            = "infra/repos"
    region         = "us-west-2"
    dynamodb_table = "terraform"
  }
}

# Configure the AWS Provider
provider "aws" {
  region  = "us-west-2"
  profile = "jaspuruadm"
}
