#opensearch 생성
resource "aws_elasticsearch_domain" "domain" {
  domain_name = "opensearch-test"
  elasticsearch_version = "OpenSearch_2.11"


  cluster_config {
    instance_type = "m6g.large.elasticsearch"
    instance_count = 2
  }
  ebs_options {
    ebs_enabled = true
    volume_size = 35
  }
}

resource "aws_elasticsearch_domain_policy" "main"{
  domain_name = aws_elasticsearch_domain.domain.domain_name

  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": {
                "AWS": ["*"]
            },
            "Effect": "Allow",
            "Condition": {
                "IpAddress": {"aws:SourceIp": ["106.101.196.171/32", "58.224.82.92/32"]}
            },
            "Resource": "${aws_elasticsearch_domain.domain.arn}/*"
        }
    ]
}
POLICIES
}