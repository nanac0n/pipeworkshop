#s3 bucket
resource "aws_s3_bucket" "zap" {
  bucket = "zap-tbucket"

  ## 실수로 S3 버킷을 삭제하는 것을 방지
  #lifecycle {
  #  prevent_destroy = true
  #}

  tags = {
    Name        = "zap-tbucket"
  }
}