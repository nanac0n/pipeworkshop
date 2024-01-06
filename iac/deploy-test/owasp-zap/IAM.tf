# AmazonEC2RoleforAWSCodeDeploy 정책 생성
resource "aws_iam_policy" "code_deploy_policy" {
  name        = "CodeDeployPolicy"
  description = "Policy for AWS CodeDeploy"
  
 # AmazonEC2RoleforAWSCodeDeploy 정책 JSON 내용
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:ListBucket"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

# S3
resource "aws_iam_policy" "s3_access_policy" {
  name        = "S3AccessPolicy"
  description = "Allow S3 access for CodeBuild"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Statement1",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:ListBucket"
      ],
      "Resource": [
        "*",
        "arn:aws:s3:::codebuild-test-hbucket",
        "arn:aws:s3:::codebuild-test-hbucket/*"
      ]
    }
  ]
}
EOF
}

# AmazonEC2RoleforSSM 정책 생성
resource "aws_iam_policy" "ssm_policy" {
  name        = "SSMPolicy"
  description = "Policy for AWS Systems Manager (SSM)"
  
  # AmazonEC2RoleforSSM 정책 JSON 내용
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetManifest",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:PutMetricData"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeInstanceStatus"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ds:CreateComputer",
                "ds:DescribeDirectories"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetBucketLocation",
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetEncryptionConfiguration",
                "s3:AbortMultipartUpload",
                "s3:ListMultipartUploadParts",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

# AmazonSSMFullAccess, AmazonSSMManagedInstanceCore 정책은 AWS에서 제공되는 정책이므로 직접 정의하지 않고 ARN을 가져옵니다.
data "aws_iam_policy" "ssm_full_access" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

data "aws_iam_policy" "ssm_managed_instance_core" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "ec2_role_for_aws_code_deploy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

data "aws_iam_policy" "ec2_role_for_ssm" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

data "aws_iam_policy" "s3_access_policy" {
  arn = aws_iam_policy.s3_access_policy.arn
}

# 서비스 역할 생성 및 정책 연결
resource "aws_iam_role" "service_role" {
  name = "zap-terraform-service-role"
  
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

# 서비스 역할에 정책 부착
resource "aws_iam_role_policy_attachment" "code_deploy_attachment" {
  policy_arn = data.aws_iam_policy.ec2_role_for_aws_code_deploy.arn
  role       = aws_iam_role.service_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_attachment" {
  policy_arn = data.aws_iam_policy.ec2_role_for_ssm.arn
  role       = aws_iam_role.service_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_full_access_attachment" {
  policy_arn = data.aws_iam_policy.ssm_full_access.arn
  role       = aws_iam_role.service_role.name
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core_attachment" {
  policy_arn = data.aws_iam_policy.ssm_managed_instance_core.arn
  role       = aws_iam_role.service_role.name
}

resource "aws_iam_role_policy_attachment" "s3_access_policy_attachment" {
  policy_arn = data.aws_iam_policy.s3_access_policy.arn
  role       = aws_iam_role.service_role.name
}

# IAM 인스턴스 프로파일 생성
resource "aws_iam_instance_profile" "zap_instance_profile" {
  name = "zap-terraform-service-role"
  role = aws_iam_role.service_role.name
}