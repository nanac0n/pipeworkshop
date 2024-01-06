output "app_name" {
  description = "CodeDeploy Application Name"
  value       = aws_codedeploy_app.main.name
}

output "codedeploy_deployment_group_arn" {
  value = aws_codedeploy_deployment_group.main.arn
}

