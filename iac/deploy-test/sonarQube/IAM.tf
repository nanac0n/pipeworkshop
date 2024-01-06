resource "aws_iam_role" "SonarQubeTaskRole" {
  name = "SonarQubeTaskRole1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}
resource "aws_iam_role" "SonarQubeTaskExecutionRole" {
  name = "SonarQubeTaskExecutionRole1"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly", "arn:aws:iam::aws:policy/AWSOpsWorksCloudWatchLogs"]
  inline_policy {
    name = "sonarqube-task"
    policy = jsonencode({
      Version = "2012-10-17"
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "kms:Decrypt",
            "secretsmanager:GetSecretValue"
          ],
          "Resource" : [
            "${aws_kms_key.sonarqube_key.arn}",
            "${data.aws_secretsmanager_secret.cluster_secret.arn}"
          ]
        }
      ]
    })
  }
}
