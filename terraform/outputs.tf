output "ecr_repo_url" {
  value = aws_ecr_repository.app.repository_url
}

output "apprunner_service_url" {
  value = aws_apprunner_service.svc.service_url
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
