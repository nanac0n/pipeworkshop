resource "aws_guardduty_detector" "DevSecOpsDetector" {
  count = length(data.aws_guardduty_detector.existing.id) > 0 ? 0 : 1

  enable = true

  datasources {
    s3_logs {
      enable = true
    }
    kubernetes {
      audit_logs {
        enable = false
      }
    }
    malware_protection {
      scan_ec2_instance_with_findings {
        ebs_volumes {
          enable = true
        }
      }
    }
  }
}
