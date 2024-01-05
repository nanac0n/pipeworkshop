provider "aws" {
  region     = "ap-northeast-2"
}
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.4.0" 
  name = "whs-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.10.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.111.0/24"] 

  enable_nat_gateway = true
  enable_vpn_gateway = true

  map_public_ip_on_launch = true

  tags = {
    Terraform    = "true"
    Environment = "dev"
  }
}


module "vote_service_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "whs-sg"
  description = "Web"
  vpc_id      = module.vpc.vpc_id

  use_name_prefix = false
  ingress_with_cidr_blocks = [ 
    {
      from_port   = 443                                #인바운드 시작 포트
      to_port     = 443                                #인바운드 끝나는 포트
      protocol    = "tcp"                              #사용할 프로토콜
      description = "https"                            #설명
      cidr_blocks = "0.0.0.0/0"                        #허용할 IP 범위
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "http"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "ssh"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      description = "http"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 9090
      to_port     = 9090
      protocol    = "tcp"
      description = "http"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  egress_with_cidr_blocks = [
    {
      from_port   = 0                                #아웃바운드 시작 포트
      to_port     = 0                                #아웃바운드 끝나는 포트
      protocol    = "-1"                             #사용할 프로토콜
      description = "all"                            #설명
      cidr_blocks = "0.0.0.0/0"                      #허용할 IP 범위
    }
  ]

}