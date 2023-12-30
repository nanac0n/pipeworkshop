
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