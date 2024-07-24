
resource "aws_vpc_endpoint_service" "producer_privatelink_service" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.app-nlb.arn]
}

resource "aws_vpc_endpoint" "consumer_privatelink_endpoint" {
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