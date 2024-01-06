resource "aws_lb" "sonarqube_lb" {
  name               = "sonarqube-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sonarqube_lb.id]
  subnets            = [aws_subnet.sonarqube_public_subnet_2a.id, aws_subnet.sonarqube_public_subnet_2b.id, aws_subnet.sonarqube_public_subnet_2c.id]

  enable_deletion_protection = false

  tags = {
    Environment = "sonarqube"
  }
}


# target group
resource "aws_lb_target_group" "sonarqube" {
  name        = "sonarqube-tg"
  port        = 9000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.sonarqube_vpc.id
}
# listener
resource "aws_lb_listener" "sonarqube_listener" {
  load_balancer_arn = aws_lb.sonarqube_lb.arn
  port              = "9000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sonarqube.arn
  }
}
