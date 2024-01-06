#This solution, non-production-ready template describes AWS Codepipeline based CICD Pipeline for terraform code deployment.
#© 2023 Amazon Web Services, Inc. or its affiliates. All Rights Reserved.
#This AWS Content is provided subject to the terms of the AWS Customer Agreement available at
#http://aws.amazon.com/agreement or other written agreement between Customer and either
#Amazon Web Services, Inc. or Amazon Web Services EMEA SARL or both.

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.20.1"
    }
  }
  backend "local" {
    path = "terraform.tfstate"  # 상태 파일 경로
  }
}

#Module for creating a new S3 bucket for storing pipeline artifacts
module "s3_artifacts_bucket" {
  source                = "./modules/s3"
  project_name          = var.project_name
  kms_key_arn           = module.codepipeline_kms.arn
  codepipeline_role_arn = module.codepipeline_iam_role.role_arn
  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }
}

# Resources

# Module for Infrastructure Source code repository
module "codecommit_infrastructure_source_repo" {
  source = "./modules/codecommit"

  create_new_repo          = var.create_new_repo
  source_repository_name   = var.source_repo_name
  source_repository_branch = var.source_repo_branch
  repo_approvers_arn       = var.repo_approvers_arn
  kms_key_arn              = module.codepipeline_kms.arn
  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }

}

# Module for Infrastructure Validation - CodeBuild
module "codebuild_terraform" {
  depends_on = [
    module.codecommit_infrastructure_source_repo
  ]
  source = "./modules/codebuild"

  project_name                        = var.project_name
  role_arn                            = module.codepipeline_iam_role.role_arn
  s3_bucket_name                      = module.s3_artifacts_bucket.bucket
  build_projects                      = var.build_projects
  build_project_source                = var.build_project_source
  builder_compute_type                = var.builder_compute_type
  builder_image                       = var.builder_image
  builder_image_pull_credentials_type = var.builder_image_pull_credentials_type
  builder_type                        = var.builder_type
  kms_key_arn                         = module.codepipeline_kms.arn
  sonarQube_dns_name = module.sonarQube.dns_name

  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }
}

module "codepipeline_kms" {
  source                = "./modules/kms"
  codepipeline_role_arn = module.codepipeline_iam_role.role_arn
  ec2_role_name = aws_iam_instance_profile.whs_ec2_role_iac.name
  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }

}

module "codepipeline_iam_role" {
  source                     = "./modules/iam-role"
  project_name               = var.project_name
  create_new_role            = var.create_new_role
  codepipeline_iam_role_name = var.create_new_role == true ? "${var.project_name}-codepipeline-role" : var.codepipeline_iam_role_name
  source_repository_name     = var.source_repo_name
  kms_key_arn                = module.codepipeline_kms.arn
  s3_bucket_arn              = module.s3_artifacts_bucket.arn
  lambda_arn = module.lambda_function_existing_package_local.lambda_function_arn
  codeDeploy_group_arn = module.btlabz-arch-ref-ec2-codedeploy-module.codedeploy_deployment_group_arn
  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }
}
# Module for Infrastructure Validate, Plan, Apply and Destroy - CodePipeline
module "codepipeline_terraform" {
  depends_on = [
    module.codebuild_terraform,
    module.s3_artifacts_bucket
  ]
  source = "./modules/codepipeline"

  project_name          = var.project_name
  source_repo_name      = var.source_repo_name
  source_repo_branch    = var.source_repo_branch
  s3_bucket_name        = module.s3_artifacts_bucket.bucket
  codepipeline_role_arn = module.codepipeline_iam_role.role_arn
  stages                = var.stage_input
  kms_key_arn           = module.codepipeline_kms.arn
  tags = {
    Project_Name = var.project_name
    Environment  = var.environment
    Account_ID   = local.account_id
    Region       = local.region
  }
}

module "btlabz-arch-ref-ec2-codedeploy-module" {
  source  = "./modules/terraform-aws-btlabz-arch-ref-ec2-codedeploy-module"
  role_arn = module.codepipeline_iam_role.role_arn
}

module "sonarQube" {
  source = "./sonarQube" 
}

module "owasp-zap" {
  source = "./owasp-zap"
  vpc_id = module.vpc.vpc_id
  public_subnet_id = module.vpc.public_subnets[1]
  private_subnet_id = module.vpc.private_subnets[1]
}

module "lambda_function_existing_package_local" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "ImportVulToSecurityHub_test"
  description   = ""
  handler       = "import_findings_security_hub.lambda_handler"
  runtime       = "python3.10"
  timeout = 60

  create_package         = false
  local_existing_package = "./lambdaFunc.zip"

}