# Enable GuardDuty
## Enable the producer account as a GuardDuty administrator
resource "aws_guardduty_organization_admin_account" "admin" {
  provider         = aws.producer
  admin_account_id = data.aws_caller_identity.producer.account_id
}

resource "aws_guardduty_detector" "producer" {
  provider                     = aws.producer
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

resource "aws_guardduty_detector_feature" "producer_s3_logs" {
  provider    = aws.producer
  detector_id = aws_guardduty_detector.producer.id
  name        = "S3_DATA_EVENTS"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "producer_malware_protection" {
  provider    = aws.producer
  detector_id = aws_guardduty_detector.producer.id
  name        = "EBS_MALWARE_PROTECTION"
  status      = "ENABLED"
}

resource "aws_guardduty_detector_feature" "producer_runtime_monitoring" {
  provider    = aws.producer
  detector_id = aws_guardduty_detector.producer.id
  name        = "RUNTIME_MONITORING"
  status      = "ENABLED"
}

## Create a GuardDuty member in the producer account for the consumer account
resource "aws_guardduty_member" "consumer" {
  provider           = aws.producer
  account_id         = data.aws_caller_identity.consumer.account_id
  detector_id        = aws_guardduty_detector.producer.id
  email              = var.consumer_email
  invite             = true
  invitation_message = "Please join my GuardDuty organization"
}

# IAM Policy
## Create an IAM role in the consumer account for GuardDuty
resource "aws_iam_role" "guardduty_consumer" {
  provider = aws.consumer
  name     = "guardduty-consumer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
      }
    ]
  })
}

## Attach the necessary policy to the IAM role
resource "aws_iam_role_policy_attachment" "guardduty_consumer" {
  provider   = aws.consumer
  role       = aws_iam_role.guardduty_consumer.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonGuardDutyFullAccess"
}


# IAM role for GuardDuty to publish findings to CloudWatch Logs
resource "aws_iam_role" "guardduty_cloudwatch" {
  provider = aws.producer
  name     = "guardduty-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
      }
    ]
  })
}

# Logging
## S3 bucket for GuardDuty findings
resource "aws_s3_bucket" "guardduty_findings" {
  provider = aws.producer
  bucket   = "guardduty-findings-${data.aws_caller_identity.producer.account_id}"
}

resource "aws_s3_bucket_versioning" "guardduty_findings" {
  provider = aws.producer
  bucket   = aws_s3_bucket.guardduty_findings.id
  versioning_configuration {
    status = "Enabled"
  }
}

## Add a bucket policy to allow GuardDuty to write to the S3 bucket
resource "aws_s3_bucket_policy" "guardduty_findings" {
  provider = aws.producer
  bucket   = aws_s3_bucket.guardduty_findings.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow GuardDuty to use the bucket"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.guardduty_findings.arn}/*"
      },
      {
        Sid    = "Allow GuardDuty to check bucket permission"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = "s3:GetBucketLocation"
        Resource = aws_s3_bucket.guardduty_findings.arn
      }
    ]
  })
}

## KMS key for encrypting GuardDuty findings
resource "aws_kms_key" "guardduty" {
  provider                = aws.producer
  description             = "KMS key for GuardDuty findings"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow GuardDuty to use the key"
        Effect = "Allow"
        Principal = {
          Service = "guardduty.amazonaws.com"
        }
        Action   = ["kms:GenerateDataKey", "kms:Encrypt"]
        Resource = "*"
      },
      {
        Sid    = "Allow key management"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.producer.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

# ## CloudWatch log group for GuardDuty
# resource "aws_cloudwatch_log_group" "guardduty" {
#   provider          = aws.producer
#   name              = "/aws/guardduty/findings"
#   retention_in_days = 1
# }

## GuardDuty publishing destination
resource "aws_guardduty_publishing_destination" "s3_destination" {
  provider         = aws.producer
  detector_id      = aws_guardduty_detector.producer.id
  destination_arn  = aws_s3_bucket.guardduty_findings.arn
  kms_key_arn      = aws_kms_key.guardduty.arn
  destination_type = "S3"
}

# # Outputs
# output "consumer_detector_id" {
#   value = aws_guardduty_detector.consumer.id
# }

# output "producer_detector_id" {
#   value = aws_guardduty_detector.producer.id
# }

# output "guardduty_findings_bucket" {
#   value = aws_s3_bucket.guardduty_findings.id
# }

# output "guardduty_kms_key_id" {
#   value = aws_kms_key.guardduty.key_id
# }

# output "guardduty_log_group" {
#   value = aws_cloudwatch_log_group.guardduty.name
# }