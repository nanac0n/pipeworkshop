#opensearch 생성
resource "aws_elasticsearch_domain" "domain" {
  domain_name = "opensearch-test"
  elasticsearch_version = "OpenSearch_2.11"


  cluster_config {
    instance_type = "m6g.large.elasticsearch"
    instance_count = 2
  }
  ebs_options {
    ebs_enabled = true
    volume_size = 35
  }
}

resource "aws_elasticsearch_domain_policy" "main"{
  domain_name = aws_elasticsearch_domain.domain.domain_name

  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": {
                "AWS": ["*"]
            },
            "Effect": "Allow",
            "Condition": {
                "IpAddress": {"aws:SourceIp": ["106.101.196.171/32", "58.224.82.92/32", "223.131.104.134/32"]}
            },
            "Resource": "${aws_elasticsearch_domain.domain.arn}/*"
        }
    ]
}
POLICIES
}
#s3버킷 생성
resource "aws_s3_bucket" "tf-aws-s3-bucket"{
  bucket = "aws-waf-logs-bucket"
  force_destroy = true
}

resource "aws_s3_bucket" "tf-aws-s3-bucket" {
  bucket        = "aws-gd-logs-bucket"
  force_destroy = true
}
#로드 밸런서 보안 그룹 생성
resource "aws_security_group" "tf-lb-sg"{
  name = "aws-lb-sg"
  vpc_id = aws_vpc.tf-vpc.id
  #인바운드 규칙
  ingress{
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks =["0.0.0.0/0"]
  }

  #아웃바운드 규칙
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1" // 모든 프로토콜
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#vpc생성
resource "aws_vpc" "tf-vpc"{
  cidr_block = "10.0.0.0/16"
}

#vpc 서브넷 생성
resource "aws_subnet" "tf-subnet" {
  count = 2 // 서브넷을 2개 생성
  vpc_id = aws_vpc.tf-vpc.id
  cidr_block = count.index == 0 ? "10.0.1.0/24" : "10.0.2.0/24"
  map_public_ip_on_launch = true // 인스턴스가 시작할 때 마다 public ip 주소 할당
  availability_zone = count.index == 0 ? "ap-northeast-2a" : "ap-northeast-2c"
  tags = {
    Name = "public_subnet_${count.index}"
  }
}

#application load balancer 생성
resource "aws_lb" "tf-alb"{
  name = "aws-alb"
  internal = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf-lb-sg.id]
  subnets            = [for subnet in aws_subnet.tf-subnet : subnet.id] // public 서브넷 내의 모든 서브넷 ID를 가져옴

}

#인터넷 게이트웨이 생성
resource "aws_internet_gateway" "tf-igw"{
  vpc_id = aws_vpc.tf-vpc.id
}

#라우트 테이블 생성
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.tf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf-igw.id
  }
}

#라우트 테이블과 서브넷 연결
resource "aws_route_table_association" "tf-route-table-association" {
  count          = 2
  subnet_id      = aws_subnet.tf-subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

# 대상 그룹 생성
resource "aws_lb_target_group" "tf-tg" {
  name     = "tf-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.tf-vpc.id
}

# 리스너 생성 및 로드 밸런서와 대상 그룹 연결
resource "aws_lb_listener" "tf-listener" {
  load_balancer_arn = aws_lb.tf-alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf-tg.arn
  }
}

resource "aws_kinesis_firehose_delivery_stream" "tf-waf-firehose-stream"{
  name = "aws-waf-logs-firehose-stream"
  destination = "elasticsearch"

  elasticsearch_configuration {
    index_name = "aws-waf-logs"
    role_arn   = aws_iam_role.tf-firehose-role.arn
    domain_arn = aws_elasticsearch_domain.domain.arn
    s3_backup_mode = "AllDocuments"

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.aws_waf_logs_lambda_terraform.arn}:$LATEST"
        }
      }
    }

    s3_configuration {
      bucket_arn = aws_s3_bucket.tf-aws-s3-bucket.arn
      role_arn   = aws_iam_role.tf-firehose-role.arn
      buffering_size     = 10
      buffering_interval = 400
      compression_format = "UNCOMPRESSED"
    }
  }
}

#firehose iam, 다른 aws 서비스
resource "aws_iam_role" "tf-firehose-role" {
  name = "firehose_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "tf-firehose-policy" {
  name = "firehose_policy"
  role   = aws_iam_role.tf-firehose-role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject",
        "lambda:InvokeFunction",
        "es:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}