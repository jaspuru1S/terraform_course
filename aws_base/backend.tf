terraform {
  backend "s3" {
    bucket         = "jaspuru-terraform-state"
    key            = "infra/bootstrap"
    region         = "us-west-2"
    dynamodb_table = "terraform"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-west-2"
}
