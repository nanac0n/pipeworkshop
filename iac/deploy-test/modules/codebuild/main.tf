#This solution, non-production-ready template describes AWS Codepipeline based CICD Pipeline for terraform code deployment.
#© 2023 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
#This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
#http://aws.amazon.com/agreement or other written agreement between Customer and either
#Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

resource "aws_codebuild_project" "terraform_codebuild_project" {

  count = length(var.build_projects)

  name           = "${var.project_name}-${var.build_projects[count.index]}"
  service_role   = var.role_arn
  encryption_key = var.kms_key_arn
  tags           = var.tags
  artifacts {
    type = var.build_project_source
  }
  environment {
    compute_type                = "BUILD_GENERAL1_LARGE"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = var.builder_type
    privileged_mode             = true
    image_pull_credentials_type = var.builder_image_pull_credentials_type

    dynamic "environment_variable" {
      for_each = var.build_projects[count.index] == "sast" ? [1] : []
      content {
        name  = "SONAR_QUBE_KEY"
        value = "sqp_6a10b0f08fd566a8d6ec8b9802dfd6c06aaac0b6"  # 소나큐브에서 project key 설정후 실제 값으로 변경
      }
    }

    dynamic "environment_variable" {
      for_each = var.build_projects[count.index] == "sast" ? [1] : []
      content {
        name  = "SONAR_QUBE_PROJECT"
        value = "sonarqube"  # 소나큐브에서 project 설정후 실제 값으로 변경
      }
    }

    dynamic "environment_variable" {
      for_each = var.build_projects[count.index] == "sast" ? [1] : []
      content {
        name  = "SONAR_QUBE_URL"
        value = "http://${var.sonarQube_dns_name}:9000"  # 실제 값으로 변경
      }
    }
  }
  logs_config {
    cloudwatch_logs {
      status = "ENABLED"
    }
  }
  source {
    type      = var.build_project_source
    buildspec = "./buildspec_${var.build_projects[count.index]}.yml"
  }
}
