variable "region"{
  description = "한국 리전"
}

variable "aws_lb_arn"{
  description = "로드밸런서 arn"
}

variable "web_acl_name"{
  description = "WEB-ACL 이름"
  type = string
}

variable "windows_rule_set_name"{
  description = "WindowsRuleSet"
  type = string
}

variable "rate_based_rule_name"{
  description = "RateBasedRule"
  type = string
}