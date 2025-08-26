output "ecr_repo_url" {
  value = "507737351904.dkr.ecr.ap-southeast-1.amazonaws.com/devsecops-demo"
}

output "apprunner_service_url" {
  value = "grtgntca2w.ap-southeast-1.awsapprunner.com"
}

output "github_actions_role_arn" {
  value = "arn:aws:iam::507737351904:role/devsecops-demo-github-actions-role"
}

output "apprunner_service_arn" {
  value = "arn:aws:apprunner:ap-southeast-1:507737351904:service/devsecops-demo/23eb5226c8894e74ad68633ab6a863f0"
}