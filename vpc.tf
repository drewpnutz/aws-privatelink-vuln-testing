provider "aws" {
  region = var.aws_region
}

###  PRODUCER VPC
resource "aws_vpc" "producer_vpc" {
  cidr_block = var.producer_vpc_cidr

  tags = {
    Name = "aws-producer-vpc"
  }
}

resource "aws_subnet" "producer_subnet" {
  vpc_id            = aws_vpc.producer_vpc.id
  cidr_block        = var.producer_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "producer-subnet"
  }
}

resource "aws_internet_gateway" "producer_igw" {
  vpc_id = aws_vpc.producer_vpc.id

  tags = {
    Name = "producer-igw"
  }
}

resource "aws_route_table" "producer_rt_1" {
  vpc_id = aws_vpc.producer_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.producer_igw.id
  }

  tags = {
    Name = "producer-route-table-1"
  }
}

resource "aws_route_table_association" "producer_rta_1" {
  subnet_id      = aws_subnet.producer_subnet.id
  route_table_id = aws_route_table.producer_rt_1.id
}

###  CONSUMER VPC
resource "aws_vpc" "consumer_vpc" {
  cidr_block = var.consumer_vpc_cidr

  tags = {
    Name = "aws-consumer-vpc"
  }
}

resource "aws_subnet" "consumer_subnet" {
  vpc_id            = aws_vpc.consumer_vpc.id
  cidr_block        = var.consumer_subnet_cidr
  availability_zone = var.availability_zone

  tags = {
    Name = "consumer-subnet"
  }
}

resource "aws_internet_gateway" "consumer_igw" {
  vpc_id = aws_vpc.consumer_vpc.id

  tags = {
    Name = "consumer-igw"
  }
}

resource "aws_route_table" "consumer_rt_1" {
  vpc_id = aws_vpc.consumer_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.consumer_igw.id
  }

  tags = {
    Name = "consumer-route-table-1"
  }
}

resource "aws_route_table_association" "consumer_rta_1" {
  subnet_id      = aws_subnet.consumer_subnet.id
  route_table_id = aws_route_table.consumer_rt_1.id
}
