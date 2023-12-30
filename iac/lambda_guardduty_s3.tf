
variable "guardduty_bucket_name" {
  description = "Name of the S3 bucket for GuardDuty logs."
  default     = "guarddutys3logbucket"
}

variable "opensearch_host" {
  description = "The endpoint of the OpenSearch cluster."
  default = "https://search-<opensearch-domain-name>-<random-string>.ap-northeast-2.es.amazonaws.com"
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

# Attach necessary policies to the IAM role
resource "aws_iam_role_policy_attachment" "lambda_exec" {
  role       = aws_iam_role.s3lambdatoes_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "s3_full_access" {
  role       = aws_iam_role.s3lambdatoes_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "open_search_full_access" {
  role       = aws_iam_role.s3lambdatoes_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonOpenSearchServiceFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_object_lambda_execution_role_policy" {
  role       = aws_iam_role.s3lambdatoes_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonS3ObjectLambdaExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "kms_provider_policy" {
    role = aws_iam_role.s3lambdatoes_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/ROSAKMSProviderPolicy"
}

# Lambda Function
resource "aws_lambda_function" "guardduty_lambda" {
  function_name = "guardduty_lambda_function"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.s3lambdatoes_role.arn
  runtime       = "python3.8"
  filename         = "${path.module}/guardduty_lambda.zip"
  source_code_hash  = filebase64sha256("./guardduty_lambda.zip")
  
  environment {
    variables = {
      REGION    = "ap-northeast-2",
      SERVICE   = "es",
      ES_HOST   = var.opensearch_host, 
      INDEX     = "guardduty-logs"
    }
  }
}

# S3 Bucket Notification for the Lambda Trigger
resource "aws_s3_bucket_notification" "s3_notification" {
  bucket = var.guardduty_bucket_name

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
  source_arn    = "arn:aws:s3:::${var.guardduty_bucket_name}"
}
