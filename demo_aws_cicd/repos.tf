module "ec2_web_repo" {
  source = "./modules"

  repo_name = "ec2-web"
}

# module "ecs_web_repo" {
#   source = "./modules"

#   repo_name = "ecs-web"
# }