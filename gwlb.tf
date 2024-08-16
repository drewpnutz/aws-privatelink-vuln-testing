# Gateway Load Balancer
resource "aws_lb" "gwlb" {
  provider           = aws.producer
  name               = "gwlb-IDS"
  internal           = false
  load_balancer_type = "gateway"
  subnets            = [aws_subnet.producer_subnet.id]

  tags = {
    Name = "gwlb-IDS"
  }
}

# Target Group for GWLB
resource "aws_lb_target_group" "gwlb_tg" {
  provider    = aws.producer
  name        = "gwlb-ids-tg"
  port        = 6081
  protocol    = "GENEVE"
  target_type = "instance"
  vpc_id      = aws_vpc.producer_vpc.id

  health_check {
    port                = 6969
    protocol            = "TCP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
  }
}

# GWLB Listener
resource "aws_lb_listener" "gwlb_listener" {
  provider          = aws.producer
  load_balancer_arn = aws_lb.gwlb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gwlb_tg.arn
  }
}

# Register Suricata VMs with GWLB Target Group (updated for instance mode)
resource "aws_lb_target_group_attachment" "suricata_tg_attachment" {
  count            = 1
  provider         = aws.producer
  target_group_arn = aws_lb_target_group.gwlb_tg.arn
  target_id        = aws_instance.suricata_vms[count.index].id
  port             = 6081
}

# GWLB Endpoint
resource "aws_vpc_endpoint" "gwlb_endpoint" {
  provider          = aws.producer
  service_name      = aws_vpc_endpoint_service.gwlb_endpoint_service.service_name
  subnet_ids        = [aws_subnet.producer_subnet.id]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = aws_vpc.producer_vpc.id
}

# GWLB Endpoint Service
resource "aws_vpc_endpoint_service" "gwlb_endpoint_service" {
  provider                   = aws.producer
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]
}

# Output GWLB Endpoint Service Name
output "gwlb_endpoint_service_name" {
  value = aws_vpc_endpoint_service.gwlb_endpoint_service.service_name
}