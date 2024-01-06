variable "name" {
  type        = string
  description = "Code Deploy objects name prefix"
  default     = "webGoat"
}

variable "ec2_name_tag" {
  type  = string
  description = "ec2 name tag"
  default = "deployByIac"
}

locals {
  groupname = var.name
  ec2_name_tag = var.ec2_name_tag
}
