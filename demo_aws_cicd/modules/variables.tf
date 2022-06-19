locals {
    module_tags = {
        Environment = "dev",
        Team = "infra",
        Terraform = true
    }
}

variable "repo_name" {
  description = "Name for codecommit repository"
  default     = "TestRepo"
}

variable "description" {
    default = "Test repo description"
}

variable "default_repo_branch" {
    default = "main"
}