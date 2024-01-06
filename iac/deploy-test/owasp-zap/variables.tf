variable "your_key_pair_name" {
  description = "Name of the key pair for EC2 instance"
  # EC2 인스턴스에 사용할 키 페어 이름 설정
  default     = "wasp-zap"
}

variable "vpc_id" {
  type = string
  default = ""
}

variable "public_subnet_id" {
  type = string
  default = ""
}

variable "private_subnet_id" {
  type = string
  default = ""
}