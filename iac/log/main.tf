provider "aws" {
  region = "ap-northeast-2"
}

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
resource "aws_s3_bucket" "tf-aws-waf-s3-bucket"{
  bucket = "aws-waf-logs-bucket2"
  force_destroy = true
}

resource "aws_s3_bucket" "tf-gd-s3" {
  bucket        = "aws-gd-logs-bucket"
  force_destroy = true
}

# CloudTrail 로그를 저장할 S3 버킷
/*
resource "aws_s3_bucket" "tf-cloudtrail-s3" {
  bucket = "data.aws_s3_bucket"
  force_destroy = true
}*/

resource "aws_s3_bucket" "tf-cloudtrail-s3" {
  bucket = "tf-cloudtrail-s3"
  force_destroy = true
}


# CloudTrail policy
/*
resource "aws_s3_bucket_policy" "tf-cloudtrail-bucket-policy" {
  bucket = "aws_s3_bucket."
  policy = data.aws_iam_policy_document.tf-cloudtrail-bucket-policy.json
}*/
resource "aws_s3_bucket_policy" "tf-cloudtrail-bucket-policy" {
  bucket = aws_s3_bucket.tf-cloudtrail-s3.bucket
  policy = data.aws_iam_policy_document.tf-cloudtrail-bucket-policy.json
}

data "aws_iam_policy_document" "tf-cloudtrail-bucket-policy" {
  statement {
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.tf-cloudtrail-s3.arn]
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }

  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.tf-cloudtrail-s3.arn}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
  }
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
          parameter_value = "${aws_lambda_function.tf-waf-logs-lambda.arn}:$LATEST"
        }
      }
    }

    s3_configuration {
      bucket_arn = aws_s3_bucket.tf-aws-waf-s3-bucket.arn
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

resource "aws_lambda_function" "tf-waf-logs-lambda"{
  function_name = "waf-lambda"
  role = aws_iam_role.tf-lambda.arn
  runtime = "python3.8"
  handler = "lambda_function.lambda_handler"
  filename = "aws-waf-logs-lambda.zip"
  timeout = 900

}

resource "aws_iam_role" "tf-lambda" {
  name = "aws-lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_policy"
  role = aws_iam_role.tf-lambda.id


  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
#Web-ACL 생성
resource "aws_wafv2_web_acl" "tf-web-acl"{
  name = "aws-web-acl"
  scope = "REGIONAL"
  default_action {
    allow {
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAF_Common_Protections"
    sampled_requests_enabled   = true
  }

  #AWSManagedRulesCommonRuleSet
  rule{
    name = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 0
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
  #AWSManagedRulesSQLiRuleSet
  rule{
    name = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesPHPRuleSet
  rule{
    name = "AWS-AWSManagedRulesPHPRuleSet"
    priority = 2
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesPHPRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesPHPRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesWordPressRuleSet
  rule{
    name = "AWS-AWSManagedRulesWordPressRuleSet"
    priority = 3
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesWordPressRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesWordPressRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesAdminProtectionRuleSet
  rule{
    name = "AWS-AWSManagedRulesAdminProtectionRuleSet"
    priority = 4
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAdminProtectionRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesAmazonIpReputationList
  rule{
    name = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 5
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesKnownBadInputsRuleSet
  rule{
    name = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 6
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesLinuxRuleSet
  rule{
    name = "AWS-AWSManagedRulesLinuxRuleSet"
    priority = 7
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #속도 기반 규칙에 따라 동일 IP에서 5분에 200번 이상 접속을 요청하면 차단하는 규칙
  rule{
    name = "RateBasedRule"
    priority = 10

    action{
      block {
      }
    }
    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit = 200
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "RateBasedRule"
      sampled_requests_enabled   = false
    }
  }

}

resource "aws_wafv2_web_acl_association" "wafv2_association"{

  resource_arn = aws_lb.tf-alb.arn
  web_acl_arn  = aws_wafv2_web_acl.tf-web-acl.arn

}

resource "aws_wafv2_web_acl_logging_configuration" "wafv2_logging_configuration" {
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.tf-waf-firehose-stream.arn]
  resource_arn            = aws_wafv2_web_acl.tf-web-acl.arn
}
resource "aws_cloudwatch_log_resource_policy" "tf-cloudtrail-to-cloudwatch-log-policy" {
  policy_name     = "aws-cloudtrail-to-cloudwatch-log-policy"
  policy_document = data.aws_iam_policy_document.tf-cloudtrail-bucket-policy.json
}

data "aws_iam_policy_document" "tf-cloudtrail-to-cloudwatch-log-policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = ["${aws_cloudwatch_log_group.tf-cloudtrail-to-cloudwatch-log-group.arn}/*"] 
  }
}


# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "tf-cloudtrail-to-cloudwatch-log-group" {
  name = "aws-cloudtrail-to-cloudwatch-log-group"
}


# CloudWatch 로그를 처리할 IAM role
resource "aws_iam_role" "tf-cloudwatch-iam-role" {
  name = "aws-cloudwatch-iam-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = ["cloudtrail.amazonaws.com"]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_iam_policy_document" "tf-cloudwatch-iam-policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]

    resources = [
          "arn:aws:logs:*:*:log-group:*:*" #"arn:aws:logs:*:*:log-group:/aws/cloudtrail/*"
    ]
  }
}

resource "aws_iam_role_policy" "tf-cloudwatch-iam-policy" {
  name   = "cloudwatch-policy"
  role   = aws_iam_role.tf-cloudwatch-iam-role.id
  policy = data.aws_iam_policy_document.tf-cloudwatch-iam-policy.json
}
# CloudTrail 추적 생성 및 활성화
resource "aws_cloudtrail" "tf-cloudtrail" {
    name                          = "aws-cloudtrail"
    s3_bucket_name = aws_s3_bucket.tf-cloudtrail-s3.bucket

    include_global_service_events = true
    is_multi_region_trail         = true
    enable_logging                = true

    cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.tf-cloudtrail-to-cloudwatch-log-group.arn}:*" # CloudTrail requires the Log Stream wildcard
    cloud_watch_logs_role_arn  = aws_iam_role.tf-cloudwatch-iam-role.arn

    depends_on = [ aws_s3_bucket_policy.tf-cloudtrail-bucket-policy, aws_iam_role.tf-cloudwatch-iam-role, aws_cloudwatch_log_group.tf-cloudtrail-to-cloudwatch-log-group ]
}



#GuardDuty 생성
data "aws_guardduty_detector" "existing" {
}
resource "aws_guardduty_detector" "DevSecOpsDetector" {
  count = length(data.aws_guardduty_detector.existing.id) > 0 ? 0 : 1

  enable = true

  finding_publishing_frequency = "FIFTEEN_MINUTES"

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
}



# CloudTrail log -> OpenSearch Lambda 함수 생성
resource "aws_lambda_function" "tf-cloudtrail-logs-lambda" {
  function_name = "aws-cloudtrail-logs-lambda"
  handler       = "index.handler" # 이 부분은 Lambda 함수의 핸들러에 따라 변경
  runtime       = "python3.8"     # 사용할 런타임

  # Lambda 함수 코드 (예: S3에서 코드를 가져오거나, 파일을 직접 포함)
  filename   = "cloudtrail-logs-lambda.zip"

  # IAM 역할 설정
  role = aws_iam_role.tf-cloudtrail-lambda-role.arn
}

# IAM 역할 생성
resource "aws_iam_role" "tf-cloudtrail-lambda-role" {
  name = "aws-cloudtrail-lambda-role"


  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
      },
    ],
  })
}



# IAM 역할에 대한 정책 연결
resource "aws_iam_role_policy" "tf-cloudtrail-lambda-policy" {
  name   = "aws-cloudtrail-lambda-policy"
  role   = aws_iam_role.tf-cloudtrail-lambda-role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:GetLogEvents",  
          "es:ESHttpPost",
          "es:ESHttpPut",
          "logs:PutSubscriptionFilter"
        ],
        Resource = "*",
        Effect = "Allow"
      }
    ]
  })
}
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tf-cloudtrail-logs-lambda.function_name
  principal     = "logs.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.tf-cloudtrail-to-cloudwatch-log-group.arn}:*"
}


# CloudWatch 로그 그룹과 Lambda 연결
resource "aws_cloudwatch_log_subscription_filter" "tf-cloudtrail-log-filter" {
  name            = "aws-cloudtrail-log-filter"
  log_group_name  = aws_cloudwatch_log_group.tf-cloudtrail-to-cloudwatch-log-group.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.tf-cloudtrail-logs-lambda.arn
}