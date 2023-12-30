resource "aws_s3_bucket" "aws-waf-logs-terraform-test"{
  bucket = "aws-waf-logs-terraform-test"
  force_destroy = true

  tags = {
    Name = "waf-logs-bucket"
  }
}