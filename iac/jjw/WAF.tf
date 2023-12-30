#Web-ACL 생성
resource "aws_wafv2_web_acl" "tf-web-acl"{
  name = "aws-web-acl"
  scope = "REGIONAL"
  default_action {
    allow {
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "WAF_Common_Protections"
    sampled_requests_enabled   = true
  }

  #AWSManagedRulesCommonRuleSet
  rule{
    name = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 0
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }
  #AWSManagedRulesSQLiRuleSet
  rule{
    name = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesPHPRuleSet
  rule{
    name = "AWS-AWSManagedRulesPHPRuleSet"
    priority = 2
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesPHPRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesPHPRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesWordPressRuleSet
  rule{
    name = "AWS-AWSManagedRulesWordPressRuleSet"
    priority = 3
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesWordPressRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesWordPressRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesAdminProtectionRuleSet
  rule{
    name = "AWS-AWSManagedRulesAdminProtectionRuleSet"
    priority = 4
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesAdminProtectionRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAdminProtectionRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesAmazonIpReputationList
  rule{
    name = "AWS-AWSManagedRulesAmazonIpReputationList"
    priority = 5
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesKnownBadInputsRuleSet
  rule{
    name = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 6
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #AWSManagedRulesLinuxRuleSet
  rule{
    name = "AWS-AWSManagedRulesLinuxRuleSet"
    priority = 7
    override_action {
      none {}
    }
    statement{
      managed_rule_group_statement {
        name        = "AWSManagedRulesLinuxRuleSet"
        vendor_name = "AWS"

      }

    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesLinuxRuleSet"
      sampled_requests_enabled   = true
    }
  }

  #속도 기반 규칙에 따라 동일 IP에서 5분에 200번 이상 접속을 요청하면 차단하는 규칙
  rule{
    name = "RateBasedRule"
    priority = 10

    action{
      block {
      }
    }
    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit = 200
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "RateBasedRule"
      sampled_requests_enabled   = false
    }
  }

  tags = merge(
    local.common_tags, {
      customer = "wafv2-web-acl"
    }
  )
}

resource "aws_wafv2_web_acl_association" "wafv2_association"{

  resource_arn = aws_lb.tf-alb.arn
  web_acl_arn  = aws_wafv2_web_acl.tf-web-acl.arn

}

resource "aws_wafv2_web_acl_logging_configuration" "wafv2_logging_configuration" {
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.tf-waf-firehose-stream.arn]
  resource_arn            = aws_wafv2_web_acl.tf-web-acl.arn
}