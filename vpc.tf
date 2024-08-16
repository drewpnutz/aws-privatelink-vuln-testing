###  PRODUCER VPC
resource "aws_vpc" "producer_vpc" {
  provider             = aws.producer
  cidr_block           = var.producer_vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "aws-producer-vpc"
  }
}

resource "aws_subnet" "producer_subnet" {
  provider             = aws.producer
  vpc_id               = aws_vpc.producer_vpc.id
  cidr_block           = var.producer_subnet_cidr
  availability_zone_id = var.az_id

  tags = {
    Name = "producer-subnet"
  }
}

resource "aws_subnet" "pa_mgmt_subnet" {
  provider             = aws.producer
  vpc_id               = aws_vpc.producer_vpc.id
  cidr_block           = var.pa_mgmt_subnet_cidr
  availability_zone_id = var.az_id

  tags = {
    Name = "pa-mgmt-subnet"
  }
}

resource "aws_subnet" "gwlb_dp_subnet" {
  provider             = aws.producer
  vpc_id               = aws_vpc.producer_vpc.id
  cidr_block           = var.gwlb_dp_subnet_cidr
  availability_zone_id = var.az_id

  tags = {
    Name = "gwlb-dp-subnet"
  }
}

resource "aws_internet_gateway" "producer_igw" {
  provider = aws.producer
  vpc_id   = aws_vpc.producer_vpc.id

  tags = {
    Name = "producer-igw"
  }
}

resource "aws_route_table" "producer_rt_1" {
  provider = aws.producer
  vpc_id   = aws_vpc.producer_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.producer_igw.id
  }

  tags = {
    Name = "producer-route-table-1"
  }
}

resource "aws_route_table_association" "producer_rta_1" {
  provider       = aws.producer
  subnet_id      = aws_subnet.producer_subnet.id
  route_table_id = aws_route_table.producer_rt_1.id
}

resource "aws_route_table_association" "producer_rta_2" {
  provider       = aws.producer
  subnet_id      = aws_subnet.pa_mgmt_subnet.id
  route_table_id = aws_route_table.producer_rt_1.id
}

resource "aws_route_table_association" "producer_rta_3" {
  provider       = aws.producer
  subnet_id      = aws_subnet.gwlb_dp_subnet.id
  route_table_id = aws_route_table.producer_rt_1.id
}

resource "aws_cloudwatch_log_group" "producer_vpc_flow_log_group" {
  provider          = aws.producer
  name              = "/aws/vpc/producer-flow-logs"
  retention_in_days = 1
}

resource "aws_flow_log" "producer_vpc_flow_log" {
  provider             = aws.producer
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.producer_vpc_flow_log_group.arn
  iam_role_arn         = aws_iam_role.producer_flow_logs_role.arn
  vpc_id               = aws_vpc.producer_vpc.id
  traffic_type         = "ALL"
}

###  CONSUMER VPC
resource "aws_vpc" "consumer_vpc" {
  provider             = aws.consumer
  cidr_block           = var.consumer_vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "aws-consumer-vpc"
  }
}

resource "aws_subnet" "consumer_subnet" {
  provider             = aws.consumer
  vpc_id               = aws_vpc.consumer_vpc.id
  cidr_block           = var.consumer_subnet_cidr
  availability_zone_id = var.az_id

  tags = {
    Name = "consumer-subnet"
  }
}

resource "aws_internet_gateway" "consumer_igw" {
  provider = aws.consumer
  vpc_id   = aws_vpc.consumer_vpc.id

  tags = {
    Name = "consumer-igw"
  }
}

resource "aws_route_table" "consumer_rt_1" {
  provider = aws.consumer
  vpc_id   = aws_vpc.consumer_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.consumer_igw.id
  }

  tags = {
    Name = "consumer-route-table-1"
  }
}

resource "aws_route_table_association" "consumer_rta_1" {
  provider       = aws.consumer
  subnet_id      = aws_subnet.consumer_subnet.id
  route_table_id = aws_route_table.consumer_rt_1.id
}

resource "aws_cloudwatch_log_group" "consumer_vpc_flow_log_group" {
  provider          = aws.consumer
  name              = "/aws/vpc/consumer-flow-logs"
  retention_in_days = 1
}

resource "aws_flow_log" "consumer_vpc_flow_log" {
  provider             = aws.consumer
  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.consumer_vpc_flow_log_group.arn
  iam_role_arn         = aws_iam_role.consumer_flow_logs_role.arn
  vpc_id               = aws_vpc.consumer_vpc.id
  traffic_type         = "ALL"
}
