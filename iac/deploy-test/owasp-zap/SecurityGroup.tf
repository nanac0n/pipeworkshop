# security group
resource "aws_security_group" "zap_sg" {
  description = "ZAP security group"
  vpc_id = var.vpc_id

  ingress {
    description      = "tcp"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #cidr_blocks = local.eip_addr_internal #
  }

  ingress {
    description      = "ZAP CLI"
    from_port        = 8090
    to_port          = 8090
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #cidr_blocks = local.eip_addr_internal #
  }

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1" # all과 동일
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "zap_sg_group"
  }
}

