output "instance_ip" {
  value = aws_instance.zap_instance.public_ip
}

output "eip" {
  value = [aws_eip.elasticip.public_ip]
}