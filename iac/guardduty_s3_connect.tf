
#data "aws_caller_identity" "current" {}

#data "aws_region" "current" {}


data "aws_s3_bucket" "gd_bucket" {
  bucket = aws_s3_bucket.tf-gd-s3.bucket
}
data "aws_iam_policy_document" "bucket_pol" {
  statement {
    sid = "Allow PutObject"
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${data.aws_s3_bucket.gd_bucket.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid = "Allow GetBucketLocation"
    actions = [
      "s3:GetBucketLocation"
    ]

    resources = [
      data.aws_s3_bucket.gd_bucket.arn
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "kms_pol" {
  statement {
    sid = "Allow GuardDuty to encrypt findings"
    actions = [
      "kms:GenerateDataKey"
    ]

    resources = [
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["guardduty.amazonaws.com"]
    }
  }

  statement {
    sid = "Allow all users to modify/delete key (test only)"
    actions = [
      "kms:*"
    ]

    resources = [
      "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }
}

resource "aws_s3_bucket_policy" "gd_bucket_policy" {
  bucket = data.aws_s3_bucket.gd_bucket.id
  policy = data.aws_iam_policy_document.bucket_pol.json
}

resource "aws_kms_key" "tf_gd_key" {
  description             = "Temporary key for AccTest of TF"
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.kms_pol.json
}

resource "aws_guardduty_publishing_destination" "test" {
  detector_id     = data.aws_guardduty_detector.existing.id
  destination_arn = data.aws_s3_bucket.gd_bucket.arn
  kms_key_arn     = aws_kms_key.tf_gd_key.arn

  depends_on = [
    aws_s3_bucket_policy.gd_bucket_policy,
  ]
}