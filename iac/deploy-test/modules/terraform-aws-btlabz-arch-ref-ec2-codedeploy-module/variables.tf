variable "tags" {
  description = "Additional tags. E.g. environment, backup tags etc"
  type        = map
  default     = {}
}

variable "role_arn" {
  type = string
}
