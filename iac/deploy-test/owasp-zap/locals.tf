locals {
  # 모듈 내부에서만 사용될 eip 변수를 설정
  eip_addr_internal = aws_eip.elasticip.public_ip
}