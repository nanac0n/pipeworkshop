#탄력적 IP
resource "aws_eip" "elasticip" {
    instance = aws_instance.zap_instance.id
}