
variable "springlog_bucket_name" {
  description = "Name of the S3 bucket for Spring logs."
  default     = "pipeline-spring-server"
}

variable "opensearch_host" {
  description = "The endpoint of the OpenSearch cluster."
  default = "https://search-<opensearch-domain-name>-<random-string>.ap-northeast-2.es.amazonaws.com"
}


# IAM Role for the Lambda Function
data "aws_iam_role" "s3lambdatoes" {
  name = "s3lambdatoes"
}

# Lambda Function
resource "aws_lambda_function" "springtoes_lambda" {
  function_name = "springtoes_lambda_function"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.s3lambdatoes_role.arn
  runtime       = "python3.8"
  filename         = "${path.module}/spring_lambda.zip"
  source_code_hash  = filebase64sha256("./spring_lambda.zip")
  
  environment {
    variables = {
      REGION    = "ap-northeast-2",
      SERVICE   = "es",
      ES_HOST   = var.opensearch_host, 
      INDEX     = "spring-logs"
    }
  }
}

# S3 Bucket Notification for the Lambda Trigger
resource "aws_s3_bucket_notification" "spring_s3_notification" {
  bucket = var.springlog_bucket_name

  lambda_function {
    lambda_function_arn = aws_lambda_function.springtoes_lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# Permissions for S3 to invoke Lambda Function
resource "aws_lambda_permission" "spring_s3_invoke" {
  statement_id  = "AllowS3Invocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.springtoes_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${var.springlog_bucket_name}"
}
