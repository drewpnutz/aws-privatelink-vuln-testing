###  PRODUCER SECURITY GROUPS

resource "aws_security_group" "producer_ec2_sg" {
  name        = "producer-ec2-sg"
  description = "Allow traffic to/from ec2"
  vpc_id      = aws_vpc.producer_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.source_ssh_networks
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/24"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "producer_lb_sg" {
  name        = "producer-lb-sg"
  description = "Allow traffic to/from load balancer"
  vpc_id      = aws_vpc.producer_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.10.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

###  CONSUMER SECURITY GROUPS

resource "aws_security_group" "consumer_ec2_sg" {
  name        = "consumer-ec2-sg"
  description = "Allow traffic to/from ec2"
  vpc_id      = aws_vpc.consumer_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.source_ssh_networks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "consumer_privatelink_sg" {
  name        = "consumer-privatelink-sg"
  description = "Allow traffic to/from privatelink endpoint"
  vpc_id      = aws_vpc.consumer_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.69.0.0/24"]
  }

}
