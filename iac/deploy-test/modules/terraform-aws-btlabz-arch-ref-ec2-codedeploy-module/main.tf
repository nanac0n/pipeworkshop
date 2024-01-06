resource "aws_codedeploy_app" "main" {
  compute_platform = "Server"
  name             = local.groupname
}

resource "aws_codedeploy_deployment_config" "main" {
  deployment_config_name = local.groupname
  minimum_healthy_hosts {
    type  = "HOST_COUNT"
    value = 1
  }
}


resource "aws_codedeploy_deployment_group" "main" {
  app_name              = aws_codedeploy_app.main.name
  deployment_group_name = local.groupname

  service_role_arn = var.role_arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = "dev"
    }

    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = local.ec2_name_tag
    }
  }

  /*
  trigger_configuration {
    trigger_events     = ["DeploymentFailure"]
    trigger_name       = "example-trigger"
    trigger_target_arn = aws_sns_topic.example.arn
  }
  */

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  /*
  alarm_configuration {
    alarms  = ["my-alarm-name"]
    enabled = true
  }
  */
}

