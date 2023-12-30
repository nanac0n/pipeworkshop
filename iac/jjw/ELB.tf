#로드 밸런서 보안 그룹 생성
resource "aws_security_group" "lb-sg"{
  name = "lb_sg"
  vpc_id = aws_vpc.main.id
  #인바운드 규칙
  ingress{
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks =["0.0.0.0/0"]
  }

  #아웃바운드 규칙
  egress{
    from_port = 0
    to_port = 0
    protocol = "-1" // 모든 프로토콜
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb_sg"
  }
}

#vpc생성
resource "aws_vpc" "main"{
  cidr_block = "10.0.0.0/16"
}

#vpc 서브넷 생성
resource "aws_subnet" "public" {
  count = 2 // 서브넷을 2개 생성
  vpc_id = aws_vpc.main.id
  cidr_block = count.index == 0 ? "10.0.1.0/24" : "10.0.2.0/24"
  map_public_ip_on_launch = true // 인스턴스가 시작할 때 마다 public ip 주소 할당
  availability_zone = count.index == 0 ? "ap-northeast-2a" : "ap-northeast-2c"
  tags = {
    Name = "public_subnet_${count.index}"
  }
}

#application load balancer 생성
resource "aws_lb" "application-load-balancer"{
  name = "albTerraform"
  internal = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id] // public 서브넷 내의 모든 서브넷 ID를 가져옴

  enable_deletion_protection = true

  tags = {
    Name = "application_load_balancer"
  }
}

#인터넷 게이트웨이 생성
resource "aws_internet_gateway" "igw"{
  vpc_id = aws_vpc.main.id
}

#라우트 테이블 생성
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

#라우트 테이블과 서브넷 연결
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# 대상 그룹 생성
resource "aws_lb_target_group" "example" {
  name     = "example-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

# 리스너 생성 및 로드 밸런서와 대상 그룹 연결
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.application-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }
}