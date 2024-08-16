# VPC Traffic Mirror
resource "aws_ec2_traffic_mirror_filter" "traffic_mirror_filter" {
  provider         = aws.producer
  description      = "Traffic mirror filter for IDS"
  network_services = ["amazon-dns"]

  tags = {
    Name = "traffic-mirror-filter"
  }
}

resource "aws_ec2_traffic_mirror_filter_rule" "outbound_rule" {
  provider                 = aws.producer
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.traffic_mirror_filter.id
  description              = "Outbound traffic"
  rule_number              = 1
  rule_action              = "accept"
  destination_cidr_block   = "0.0.0.0/0"
  source_cidr_block        = "0.0.0.0/0"
  traffic_direction        = "egress"
}

resource "aws_ec2_traffic_mirror_filter_rule" "inbound_rule" {
  provider                 = aws.producer
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.traffic_mirror_filter.id
  description              = "Inbound traffic"
  rule_number              = 2
  rule_action              = "accept"
  destination_cidr_block   = "0.0.0.0/0"
  source_cidr_block        = "0.0.0.0/0"
  traffic_direction        = "ingress"
}

resource "aws_ec2_traffic_mirror_target" "nlb_target" {
  provider                  = aws.producer
  description               = "NLB target"
  network_load_balancer_arn = aws_lb.nlb_ids.arn
}

resource "aws_ec2_traffic_mirror_target" "gwlb_target" {
  provider                          = aws.producer
  description                       = "GWLB endpoint target"
  gateway_load_balancer_endpoint_id = aws_vpc_endpoint.gwlb_endpoint.id
}

resource "aws_ec2_traffic_mirror_session" "gwlb_mirror_session" {
  provider                 = aws.producer
  description              = "GWLB-Suricata Traffic mirror session for producer EC2"
  network_interface_id     = aws_instance.producer_ec2.primary_network_interface_id
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.traffic_mirror_filter.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.gwlb_target.id
  session_number           = 2

  depends_on = [aws_instance.producer_ec2]
}

resource "aws_ec2_traffic_mirror_session" "palo_mirror_session" {
  provider                 = aws.producer
  description              = "NLB PaloAlto Traffic mirror session for producer EC2"
  network_interface_id     = aws_instance.producer_ec2.primary_network_interface_id
  traffic_mirror_filter_id = aws_ec2_traffic_mirror_filter.traffic_mirror_filter.id
  traffic_mirror_target_id = aws_ec2_traffic_mirror_target.nlb_target.id
  session_number           = 1

  depends_on = [aws_instance.producer_ec2]
}
