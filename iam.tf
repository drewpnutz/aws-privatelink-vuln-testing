## IAM FOR PRODUCER VM
resource "aws_iam_policy" "producer_policy" {
  provider    = aws.producer
  name        = "ProducerPolicy"
  description = "Policy for producer EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VPCEndpointAccess"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeNetworkInterfaces",
          "ec2messages:*",
          "ssmmessages:*",
          "cloudwatch:*",
          "logs:*",
          "guardduty:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.sid}-*",
          "arn:aws:s3:::${var.sid}-*/*",
          "arn:aws:s3:::593207742271-us-east-1-guardduty-agent-rpm-artifacts*",
          "arn:aws:s3:::733349766148-us-west-2-guardduty-agent-rpm-artifacts*",
        ]
      },
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "producer_role" {
  provider = aws.producer
  name     = "ProducerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "producer_policy_attachment" {
  provider   = aws.producer
  role       = aws_iam_role.producer_role.name
  policy_arn = aws_iam_policy.producer_policy.arn
}

resource "aws_iam_instance_profile" "producer_instance_profile" {
  provider = aws.producer
  name     = "ProducerInstanceProfile"
  role     = aws_iam_role.producer_role.name
}

## IAM FOR CONSUMER VM
resource "aws_iam_policy" "consumer_policy" {
  provider    = aws.consumer
  name        = "ConsumerPolicy"
  description = "Policy for consumer EC2 instances"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "VPCEndpointAccess"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeNetworkInterfaces",
          "ec2messages:*",
          "ssmmessages:*",
          "cloudwatch:*",
          "logs:*",
          "guardduty:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.sid}-*",
          "arn:aws:s3:::${var.sid}-*/*",
          "arn:aws:s3:::593207742271-us-east-1-guardduty-agent-rpm-artifacts*",
          "arn:aws:s3:::733349766148-us-west-2-guardduty-agent-rpm-artifacts*",
        ]
      },
      {
        Sid    = "SQSAccess"
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "consumer_role" {
  provider = aws.consumer
  name     = "ConsumerRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "consumer_policy_attachment" {
  provider   = aws.consumer
  role       = aws_iam_role.consumer_role.name
  policy_arn = aws_iam_policy.consumer_policy.arn
}

resource "aws_iam_instance_profile" "consumer_instance_profile" {
  provider = aws.consumer
  name     = "ConsumerInstanceProfile"
  role     = aws_iam_role.consumer_role.name
}

## FLOW LOGS IAM

resource "aws_iam_role" "consumer_flow_logs_role" {
  provider = aws.consumer
  name     = "flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com",
        },
      },
    ],
  })
}


resource "aws_iam_role" "producer_flow_logs_role" {
  provider = aws.producer
  name     = "flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_policy" "consumer_flow_logs_policy" {
  provider = aws.consumer
  name     = "flow-logs-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "consumer_flow_logs_role_attachment" {
  provider   = aws.consumer
  role       = aws_iam_role.consumer_flow_logs_role.name
  policy_arn = aws_iam_policy.consumer_flow_logs_policy.arn
}


resource "aws_iam_policy" "producer_flow_logs_policy" {
  provider = aws.producer
  name     = "flow-logs-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Effect   = "Allow",
        Resource = "*",
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "producer_flow_logs_role_attachment" {
  provider   = aws.producer
  role       = aws_iam_role.producer_flow_logs_role.name
  policy_arn = aws_iam_policy.producer_flow_logs_policy.arn
}

# SQS Resource Policy
resource "aws_sqs_queue_policy" "vulnerable_queue_policy" {
  provider  = aws.consumer
  queue_url = aws_sqs_queue.vulnerable_queue.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowProducerRole",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.producer.account_id}:role/ProducerRole"
        },
        Action   = "sqs:SendMessage",
        Resource = "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.consumer.account_id}:vulnerable-orders-queue"
      }
    ]
  })
}

# IAM Policy
resource "aws_iam_policy" "suricata_policy" {
  provider    = aws.producer
  name        = "suricata_policy"
  path        = "/"
  description = "IAM policy for Suricata VM"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.producer_public_bucket.arn}",
          "${aws_s3_bucket.producer_public_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/AmazonCloudWatch-*"
      }
    ]
  })
}

# IAM Role
resource "aws_iam_role" "suricata_role" {
  provider = aws.producer
  name     = "suricata_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      } 
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "suricata_policy_attach" {
  provider   = aws.producer
  policy_arn = aws_iam_policy.suricata_policy.arn
  role       = aws_iam_role.suricata_role.name
}

# Instance Profile
resource "aws_iam_instance_profile" "suricata_profile" {
  provider = aws.producer
  name     = "suricata_profile"
  role     = aws_iam_role.suricata_role.name
}