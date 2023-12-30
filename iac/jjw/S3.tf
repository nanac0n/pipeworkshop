resource "aws_s3_bucket" "tf-aws-waf-s3-bucket"{
  bucket = "aws-waf-logs-terraform-test"
  force_destroy = true
}