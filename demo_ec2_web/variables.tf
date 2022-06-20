locals {
  tags = {
    "Terraformed" = true,
    "Environment" = terraform.workspace
  }
}

variable "intance_count" {
  default     = 2
  description = "Number of web instances"
}

variable "instance_type" {
  default = "t2.micro"
}
variable "instance_key" {
  default = "jaspuruadm"
} 