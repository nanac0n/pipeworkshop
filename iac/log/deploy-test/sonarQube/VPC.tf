terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-northeast-2"
}

# Create a VPC
resource "aws_vpc" "sonarqube_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "sonarqube-vpc"
  }
}
# Create a subnet
resource "aws_subnet" "sonarqube_public_subnet_2a" {

  vpc_id = aws_vpc.sonarqube_vpc.id

  cidr_block = "10.0.0.0/20"

  availability_zone = "ap-northeast-2a"

  tags = {

    Name = "sonarqube_public_subnet_2a"

  }

}
resource "aws_subnet" "sonarqube_public_subnet_2b" {

  vpc_id = aws_vpc.sonarqube_vpc.id

  cidr_block = "10.0.16.0/20"

  availability_zone = "ap-northeast-2b"

  tags = {

    Name = "sonarqube_public_subnet_2b"

  }

}
resource "aws_subnet" "sonarqube_public_subnet_2c" {

  vpc_id = aws_vpc.sonarqube_vpc.id

  cidr_block = "10.0.32.0/20"

  availability_zone = "ap-northeast-2c"

  tags = {

    Name = "sonarqube_public_subnet_2c"

  }

}
resource "aws_subnet" "sonarqube_private_subnet_2a" {

  vpc_id = aws_vpc.sonarqube_vpc.id

  cidr_block = "10.0.128.0/20"

  availability_zone = "ap-northeast-2a"

  tags = {

    Name = "sonarqube_private_subnet_2a"

  }

}
resource "aws_subnet" "sonarqube_private_subnet_2b" {

  vpc_id = aws_vpc.sonarqube_vpc.id

  cidr_block = "10.0.144.0/20"

  availability_zone = "ap-northeast-2b"

  tags = {

    Name = "sonarqube_private_subnet_2b"

  }

}
resource "aws_subnet" "sonarqube_private_subnet_2c" {

  vpc_id = aws_vpc.sonarqube_vpc.id

  cidr_block = "10.0.160.0/20"

  availability_zone = "ap-northeast-2c"

  tags = {

    Name = "sonarqube_private_subnet_2c"

  }

}

# internet gateway
resource "aws_internet_gateway" "sonarqube_igw" {
  vpc_id = aws_vpc.sonarqube_vpc.id

  tags = {
    Name = "sonarqube_igw"
  }
}

# eip
resource "aws_eip" "sonarqube_eip" {
  domain = "vpc"
}

# NAT
resource "aws_nat_gateway" "sonarqube_nat" {
  allocation_id = aws_eip.sonarqube_eip.id
  subnet_id     = aws_subnet.sonarqube_public_subnet_2a.id

  tags = {
    Name = "sonarqube_nat"
  }

  depends_on = [aws_internet_gateway.sonarqube_igw]
}

# Route Table
resource "aws_route_table" "sonarqube_route_table" {
  vpc_id = aws_vpc.sonarqube_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sonarqube_igw.id
  }

  tags = {
    Name = "sonarqube_route_table"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sonarqube_public_subnet_2a.id
  route_table_id = aws_route_table.sonarqube_route_table.id
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.sonarqube_public_subnet_2b.id
  route_table_id = aws_route_table.sonarqube_route_table.id
}
resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.sonarqube_public_subnet_2c.id
  route_table_id = aws_route_table.sonarqube_route_table.id
}

resource "aws_route_table" "sonarqube_private_route_table_a" {
  vpc_id = aws_vpc.sonarqube_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sonarqube_nat.id
  }


  tags = {
    Name = "sonarqube_private_route_table_a"
  }
}
resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.sonarqube_private_subnet_2a.id
  route_table_id = aws_route_table.sonarqube_private_route_table_a.id
}
resource "aws_route_table" "sonarqube_private_route_table_b" {
  vpc_id = aws_vpc.sonarqube_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sonarqube_nat.id
  }

  tags = {
    Name = "sonarqube_private_route_table_b"
  }
}

resource "aws_route_table_association" "b1" {
  subnet_id      = aws_subnet.sonarqube_private_subnet_2b.id
  route_table_id = aws_route_table.sonarqube_private_route_table_b.id
}

resource "aws_route_table" "sonarqube_private_route_table_c" {
  vpc_id = aws_vpc.sonarqube_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sonarqube_nat.id
  }


  tags = {
    Name = "sonarqube_private_route_table_c"
  }
}

resource "aws_route_table_association" "c1" {
  subnet_id      = aws_subnet.sonarqube_private_subnet_2c.id
  route_table_id = aws_route_table.sonarqube_private_route_table_c.id
}

# S3 endpoint
resource "aws_vpc_endpoint" "s3" {
  vpc_id          = aws_vpc.sonarqube_vpc.id
  service_name    = "com.amazonaws.ap-northeast-2.s3"
  route_table_ids = [aws_route_table.sonarqube_private_route_table_a.id, aws_route_table.sonarqube_private_route_table_b.id, aws_route_table.sonarqube_private_route_table_c.id]
}

# security_group
resource "aws_security_group" "sonarqube_default" {
  name        = "sonarqube_default"
  description = "sonarqube default group"
  vpc_id      = aws_vpc.sonarqube_vpc.id

  ingress {
    description     = "default"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.sonarqube_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all과 동일
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sonarqube_default_group"
  }
}
resource "aws_security_group" "sonarqube_db" {
  name        = "sonarqube_db"
  description = "sonarqube db group"
  vpc_id      = aws_vpc.sonarqube_vpc.id

  ingress {
    description     = "postgre sql"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sonarqube_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all과 동일
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sonarqube_db_group"
  }
}
resource "aws_security_group" "sonarqube_lb" {
  name        = "sonarqube_lb"
  description = "sonarqube loadbalancer group"
  vpc_id      = aws_vpc.sonarqube_vpc.id

  ingress {
    description = " "
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # your ip
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all과 동일
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sonarqube_lb_group"
  }
}
resource "aws_security_group" "sonarqube_sg" {
  name        = "sonarqube_sg"
  description = "sonarqube security group"
  vpc_id      = aws_vpc.sonarqube_vpc.id

  ingress {
    description     = "TLS from VPC"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.sonarqube_lb.id]
  }

  egress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sonarqube_sg_group"
  }
}
