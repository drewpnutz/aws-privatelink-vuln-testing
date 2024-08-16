## PRODUCER S3
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Create Buckets
resource "aws_s3_bucket" "producer_public_bucket" {
  provider      = aws.producer
  bucket        = "producer-public-bucket-${random_string.suffix.result}"
  force_destroy = true

  tags = {
    Name = "producer-public-bucket"
  }
}

resource "aws_s3_bucket" "producer_exfil_bucket" {
  provider      = aws.producer
  bucket        = "databricks-${random_string.suffix.result}"
  force_destroy = true

  tags = {
    Name = "consumer-private-bucket"
    Sid  = "${var.sid}"
  }
}

resource "aws_s3_bucket" "consumer_private_bucket" {
  provider      = aws.consumer
  bucket        = "consumer-private-bucket-${random_string.suffix.result}"
  force_destroy = true

  tags = {
    Name = "consumer-private-bucket"
    Sid  = "${var.sid}"
  }
}

# Explicitly disable ACLs
resource "aws_s3_bucket_ownership_controls" "producer_public_bucket_ownership" {
  provider = aws.producer
  bucket   = aws_s3_bucket.producer_public_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }

  depends_on = [aws_s3_bucket.producer_public_bucket]
}

resource "aws_s3_bucket_ownership_controls" "producer_exfil_bucket_ownership" {
  provider = aws.producer
  bucket   = aws_s3_bucket.producer_exfil_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }

  depends_on = [aws_s3_bucket.producer_exfil_bucket]
}

resource "aws_s3_bucket_ownership_controls" "consumer_private_bucket_ownership" {
  provider = aws.consumer
  bucket   = aws_s3_bucket.consumer_private_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
  depends_on = [aws_s3_bucket.consumer_private_bucket]
}


# Allow public access for the public bucket
resource "aws_s3_bucket_public_access_block" "producer_public_bucket_access" {
  provider = aws.producer
  bucket   = aws_s3_bucket.producer_public_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  depends_on = [aws_s3_bucket.producer_public_bucket, aws_s3_bucket_ownership_controls.producer_public_bucket_ownership]

}

resource "aws_s3_bucket_public_access_block" "producer_exfil_bucket_access" {
  provider = aws.producer
  bucket   = aws_s3_bucket.producer_exfil_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  depends_on = [aws_s3_bucket.producer_exfil_bucket, aws_s3_bucket_ownership_controls.producer_exfil_bucket_ownership]
}

resource "aws_s3_bucket_public_access_block" "consumer_private_bucket_access" {
  provider = aws.consumer
  bucket   = aws_s3_bucket.consumer_private_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket.consumer_private_bucket, aws_s3_bucket_ownership_controls.consumer_private_bucket_ownership]
}


resource "aws_s3_object" "public_object" {
  provider = aws.producer
  bucket   = aws_s3_bucket.producer_public_bucket.bucket
  key      = "payload.sh"
  source   = "${path.module}/scripts/payload.sh"

  tags = {
    Name = "public-object"
  }

  depends_on = [aws_s3_bucket.producer_public_bucket, aws_s3_bucket_public_access_block.producer_public_bucket_access]
}

# resource "aws_s3_object" "public_exfil_object" {
#   provider = aws.producer
#   bucket   = aws_s3_bucket.producer_exfil_bucket.bucket
#   key      = "hackerscript.sh"
#   source   = "${path.module}/scripts/payload.sh"

#   tags = {
#     Name = "public-object"
#   }

#   depends_on = [aws_s3_bucket.producer_exfil_bucket, aws_s3_bucket_public_access_block.producer_exfil_bucket_access]
# }

# resource "aws_s3_object" "private_object" {
#   provider = aws.consumer
#   bucket   = aws_s3_bucket.consumer_private_bucket.bucket
#   key      = "private-object.txt"
#   source   = "${path.module}/scripts/payload.sh"

#   tags = {
#     Name = "private-object"
#   }

#   depends_on = [aws_s3_bucket.consumer_private_bucket, aws_s3_bucket_public_access_block.consumer_private_bucket_access]
# }

# Define bucket policy
resource "aws_s3_bucket_policy" "producer_public_bucket_policy" {
  provider = aws.producer
  bucket   = aws_s3_bucket.producer_public_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid : "SecureID",
        Effect : "Allow",
        Principal : "*",
        Action : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ]
        Resource = [
          "${aws_s3_bucket.producer_public_bucket.arn}/*",
          "${aws_s3_bucket.producer_public_bucket.arn}",
        ]
        Condition : {
          IpAddress : {
            "aws:SourceIp" : "${var.s3_source}"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.producer_public_bucket,
    aws_s3_bucket_ownership_controls.producer_public_bucket_ownership,
    aws_s3_bucket_public_access_block.producer_public_bucket_access,
    aws_s3_object.public_object
  ]
}

resource "aws_s3_bucket_policy" "producer_exfil_bucket_policy" {
  provider = aws.producer
  bucket   = aws_s3_bucket.producer_exfil_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid : "SecureID",
        Effect : "Allow",
        Principal : "*",
        Action : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
        ]
        Resource = [
          "${aws_s3_bucket.producer_exfil_bucket.arn}/*",
          "${aws_s3_bucket.producer_exfil_bucket.arn}",
        ],
        Condition : {
          IpAddress : {
            "aws:SourceIp" : "${var.s3_source}"
          }
        }
      }
    ]
  })

  depends_on = [
    aws_s3_bucket.producer_exfil_bucket,
    aws_s3_bucket_ownership_controls.producer_exfil_bucket_ownership,
    aws_s3_bucket_public_access_block.producer_exfil_bucket_access,
    # aws_s3_object.public_exfil_object
  ]
}

# output "public_bucket_name" {
#   value       = aws_s3_bucket.producer_public_bucket.bucket
#   description = "The name of the public S3 bucket"
# }

# output "exfil_bucket_name" {
#   value       = aws_s3_bucket.producer_public_bucket.bucket
#   description = "The name of the private exfil S3 bucket"
# }

# output "private_bucket_name" {
#   value       = aws_s3_bucket.consumer_private_bucket.bucket
#   description = "The name of the private S3 bucket"
# }

# output "public_object_virtual_hosted_url" {
#   value       = "https://${aws_s3_bucket.producer_public_bucket.bucket_regional_domain_name}/${aws_s3_object.public_object.key}"
#   description = "The Virtual Hosted Style URL of the public S3 object"
# }

# output "public_object_path_style_url" {
#   value       = "https://s3.${var.aws_region}.amazonaws.com/${aws_s3_bucket.producer_public_bucket.id}/${aws_s3_object.public_object.key}"
#   description = "The Path Style URL of the public S3 object"
# }

# output "private_object_virtual_hosted_url" {
#   value       = "https://${aws_s3_bucket.consumer_private_bucket.bucket_regional_domain_name}/${aws_s3_object.private_object.key}"
#   description = "The Virtual Hosted Style URL of the private S3 object"
# }

# output "private_object_path_style_url" {
#   value       = "https://s3.${var.aws_region}.amazonaws.com/${aws_s3_bucket.consumer_private_bucket.id}/${aws_s3_object.private_object.key}"
#   description = "The Path Style URL of the private S3 object"
# }
