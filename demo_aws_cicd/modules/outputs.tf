output "repository_arn" {
  value = aws_codecommit_repository.repo.arn
}

output "repository_id" {
  value = aws_codecommit_repository.repo.repository_id
}

output "repository_name" {
  value = var.repo_name
}

output "repository_http_url" {
  value = aws_codecommit_repository.repo.clone_url_http
}

output "repository_ssh_url" {
  value = aws_codecommit_repository.repo.clone_url_ssh
}
