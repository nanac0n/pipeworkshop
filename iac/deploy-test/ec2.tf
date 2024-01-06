resource "aws_instance" "ec2_instance" {
  ami                    = "ami-086cae3329a3f7d75"
  instance_type          = "t2.medium"
  key_name               = "whs-iac-pair"
  monitoring             = true
  vpc_security_group_ids = [module.vote_service_sg.security_group_id]
  subnet_id              = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install ruby -y
              wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install
              chmod +x ./install
              sudo ./install auto
              sudo apt install openjdk-17-jre-headless -y
              EOF

  iam_instance_profile = aws_iam_instance_profile.whs_ec2_role_iac.name  # 변경 필요

  tags = {
    Name        = "deployByIac"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_iam_instance_profile" "whs_ec2_role_iac" {
  name = aws_iam_role.whs_ec2_role_iac.name
  role = aws_iam_role.whs_ec2_role_iac.name
}

resource "aws_iam_role" "whs_ec2_role_iac" {
  name               = "whs_ec2_role_iac"

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
  path               = "/"
}

resource "aws_iam_role_policy_attachment" "admin_attachment" {
  role       = aws_iam_role.whs_ec2_role_iac.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_readOnly_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"  # 적절한 정책 ARN으로 변경
  role       = aws_iam_role.whs_ec2_role_iac.name
}