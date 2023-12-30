resource "aws_s3_bucket" "tf-aws-s3-bucket"{
  bucket = "aws-waf-logs-terraform-test"
  force_destroy = true
}