project_name       = "whs-pipeline-from-IaC"
environment        = "dev"
source_repo_name   = "whs-repo-from-IaC"
source_repo_branch = "master"
create_new_repo    = true
repo_approvers_arn = "arn:aws:sts::851077919242:assumed-role/CodeCommitReview/" #Update ARN (IAM Role/User/Group) of Approval Members
create_new_role    = true
#codepipeline_iam_role_name = <Role name> - Use this to specify the role name to be used by codepipeline if the create_new_role flag is set to false.
stage_input = [
  { name = "build", category = "Build", owner = "AWS", provider = "CodeBuild", input_artifacts = "SourceOutput", output_artifacts = "BuildOutput" },
  { name = "sca", category = "Test", owner = "AWS", provider = "CodeBuild", input_artifacts = "BuildOutput", output_artifacts = "ScaOutput" },
  {name = "sast", category = "Test", owner = "AWS", provider = "CodeBuild", input_artifacts = "BuildOutput", output_artifacts = "SastOutput" },
  { name = "dast", category = "Test", owner = "AWS", provider = "CodeBuild", input_artifacts = "BuildOutput", output_artifacts = "DastOutput" }
]
build_projects = ["build", "sca", "sast", "dast"]
