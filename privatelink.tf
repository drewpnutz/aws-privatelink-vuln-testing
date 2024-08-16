
resource "aws_vpc_endpoint_service" "producer_privatelink_service" {
  provider                   = aws.producer
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.app-nlb.arn]
  allowed_principals         = ["arn:aws:iam::${data.aws_caller_identity.consumer.account_id}:root"]

  tags = {
    Name = "producer-privatelink-service"
  }
}

resource "aws_vpc_endpoint" "consumer_privatelink_endpoint" {
  provider           = aws.consumer
  vpc_id             = aws_vpc.consumer_vpc.id
  service_name       = aws_vpc_endpoint_service.producer_privatelink_service.service_name
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.consumer_subnet.id]
  security_group_ids = [aws_security_group.consumer_privatelink_sg.id]

  tags = {
    Name = "consumer-vpc-endpoint"
  }

  depends_on = [
    aws_vpc_endpoint_service.producer_privatelink_service
  ]
}

resource "aws_vpc_endpoint" "s3_gateway" {
  provider        = aws.consumer
  vpc_id          = aws_vpc.consumer_vpc.id
  service_name    = "com.amazonaws.us-east-1.s3"
  route_table_ids = [aws_route_table.consumer_rt_1.id]

  tags = {
    Name = "s3-gateway-endpoint"
  }
}

locals {
  services = {
    ec2            = "com.amazonaws.${var.aws_region}.ec2"
    ec2messages    = "com.amazonaws.${var.aws_region}.ec2messages"
    logs           = "com.amazonaws.${var.aws_region}.logs"
    monitoring     = "com.amazonaws.${var.aws_region}.monitoring"
    sqs            = "com.amazonaws.${var.aws_region}.sqs"
    sns            = "com.amazonaws.${var.aws_region}.sns"
    ssm            = "com.amazonaws.${var.aws_region}.ssm"
    ssmmessages    = "com.amazonaws.${var.aws_region}.ssmmessages"
    guardduty-data = "com.amazonaws.${var.aws_region}.guardduty-data"
    kms            = "com.amazonaws.${var.aws_region}.kms"
  }
}

resource "aws_vpc_endpoint" "consumer_privatelink_endpoint_4loop" {
  provider            = aws.consumer
  for_each            = local.services
  vpc_id              = aws_vpc.consumer_vpc.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.consumer_subnet.id]
  security_group_ids  = [aws_security_group.consumer_privatelink_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${each.key}-interface-endpoint"
  }
}

resource "aws_vpc_endpoint_policy" "bad_vpc_endpoint_policy" {
  provider        = aws.consumer
  for_each        = local.services
  vpc_endpoint_id = aws_vpc_endpoint.consumer_privatelink_endpoint_4loop[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "*"
        Resource  = "*"
      }
    ]
  })
}

# output "vpc_endpoint_dns_names" {
#   value       = { for k, v in aws_vpc_endpoint.consumer_privatelink_endpoint_4loop : k => v.dns_entry[0].dns_name }
#   description = "The DNS names of the Consumer Privatelink Endpoints"
# }

# output "vpc_sqs_endpoint_dns" {
#   value       = aws_vpc_endpoint.consumer_privatelink_endpoint_4loop["sqs"].dns_entry[0].dns_name
#   description = "The DNS name of the SQS Queue"
# }

# output "vpc_endpoint_dns_name" {
#   value       = aws_vpc_endpoint.consumer_privatelink_endpoint.dns_entry[0].dns_name
#   description = "The DNS name of the Consumer Privatelink Endpoint"
# }

# output "producer_privatelink_service_name" {
#   value = aws_vpc_endpoint_service.producer_privatelink_service.service_name
# }