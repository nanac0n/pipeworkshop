variable "guardduty_bucket_name" {
  description = "Name of the S3 bucket for GuardDuty logs."
  default     = "guarddutys3logbucket"
}

variable "opensearch_domain_name" {
  description = "Name of the OpenSearch domain."
  default     = "opensearch-test"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_opensearch_domain" "host_domain" {
  domain_name = aws_elasticsearch_domain.domain.domain_name
}



# IAM Role for the Lambda Function
resource "aws_iam_role" "s3lambdatoes_role" {
  name = "s3lambdatoes"

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

# Custom IAM Policy for Lambda Function
resource "aws_iam_policy" "lambda_s3_opensearch_policy" {
  name        = "LambdaS3OpenSearchPolicy"
  description = "IAM policy for Lambda to read S3 GuardDuty logs and write to OpenSearch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ],
        Resource = [
          "${data.aws_s3_bucket.gd_bucket.arn}",
          "${data.aws_s3_bucket.gd_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpGet"
        ],
        Resource = "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.opensearch_domain_name}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = aws_kms_key.tf_gd_key.arn
      }
    ]
  })
}

# Policy to the IAM Role
resource "aws_iam_role_policy_attachment" "lambda_custom_policy" {
  role       = aws_iam_role.s3lambdatoes_role.name
  policy_arn = aws_iam_policy.lambda_s3_opensearch_policy.arn
}

# Lambda Function
resource "aws_lambda_function" "guardduty_lambda" {
  function_name    = "guardduty_lambda_function"
  handler          = "guardduty_lambda.lambda_handler"
  role             = aws_iam_role.s3lambdatoes_role.arn
  runtime          = "python3.8"
  filename         = "${path.module}/guardduty_lambda.zip"
  source_code_hash = filebase64sha256("./guardduty_lambda.zip")
  timeout          = 90

  environment {
    variables = {
      REGION    = "ap-northeast-2",
      SERVICE   = "es",
      ES_HOST   = data.aws_opensearch_domain.host_domain.endpoint,
      INDEX     = "guardduty-logs"
    }
  }
}

# S3 Bucket Notification for the Lambda Trigger
resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = data.aws_s3_bucket.gd_bucket.bucket

  lambda_function {
    lambda_function_arn = aws_lambda_function.guardduty_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# Permissions for S3 to invoke Lambda Function
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardduty_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${data.aws_s3_bucket.gd_bucket.bucket}"
}
