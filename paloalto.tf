# Load Public Key
resource "aws_key_pair" "ssh_key" {
  provider   = aws.producer
  key_name   = "ssh-public-key"
  public_key = var.public_key
}

# Create ENIs for Palo Alto
resource "aws_network_interface" "pa_mgmt_eni" {
  provider          = aws.producer
  count             = var.pa_vm_count
  subnet_id         = aws_subnet.pa_mgmt_subnet.id
  security_groups   = [aws_security_group.palo_alto_sg.id]
  source_dest_check = "false"

  tags = {
    Name = "palo-alto-mgmt-eni_${count.index + 1}"
  }
}

resource "aws_network_interface" "pa_dp_eni" {
  provider          = aws.producer
  count             = var.pa_vm_count
  subnet_id         = aws_subnet.gwlb_dp_subnet.id
  security_groups   = [aws_security_group.palo_alto_sg.id]
  source_dest_check = "false"

  tags = {
    Name = "palo-alto-mgmt-eni_${count.index + 1}"
  }
}

# Palo Alto VM Instances
resource "aws_instance" "palo_alto_vms" {
  provider      = aws.producer
  count         = var.pa_vm_count
  ami           = "ami-07cf682a004a7de64"
  instance_type = "m4.xlarge"

  network_interface {
    network_interface_id = aws_network_interface.pa_dp_eni[count.index].id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.pa_mgmt_eni[count.index].id
    device_index         = 1
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
    http_protocol_ipv6          = "disabled"
  }

  user_data = "op-command-modes=mgmt-interface-swap,plugin-op-commands=aws-gwlb-inspect:enable,plugin-op-commands=aws-gwlb-overlay-routing:enable"

  key_name = aws_key_pair.ssh_key.key_name

  tags = {
    Name = "palo-alto-vm-${count.index + 1}"
  }
}

## ELASTIC IP
resource "aws_eip" "paloalto_vm_eip" {
  count             = var.pa_vm_count
  provider          = aws.producer
  network_interface = aws_network_interface.pa_mgmt_eni[count.index].id
  domain            = "vpc"

  depends_on = [aws_instance.palo_alto_vms]
}

resource "aws_lb" "nlb_ids" {
  provider           = aws.producer
  name               = "nlb-ids"
  internal           = true
  load_balancer_type = "network"
  # security_groups    = [aws_security_group.producer_lb_sg.id]
  subnets = [aws_subnet.gwlb_dp_subnet.id]

  tags = {
    Name = "nlb-ids"
  }
}

resource "aws_lb_target_group" "nlb_ids" {
  provider    = aws.producer
  name        = "nlb-ids"
  port        = 4789
  protocol    = "UDP"
  vpc_id      = aws_vpc.producer_vpc.id
  target_type = "ip"

  health_check {
    port                = 443
    protocol            = "TCP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "nlb-ids"
  }
}

resource "aws_lb_target_group_attachment" "nlb_ids_attachments" {
  provider         = aws.producer
  count            = length(aws_network_interface.pa_dp_eni)
  target_group_arn = aws_lb_target_group.nlb_ids.arn
  target_id        = element(aws_network_interface.pa_dp_eni[*].private_ip, count.index)
  port             = 4789
}

resource "aws_lb_listener" "nlb_ids_listener" {
  provider          = aws.producer
  load_balancer_arn = aws_lb.nlb_ids.arn
  port              = 4789
  protocol          = "UDP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_ids.arn
  }
}

output "paloalto_vm_public_ips" {
  value = {
    for idx, eip in aws_eip.paloalto_vm_eip :
    "paloalto_vm_${idx + 1}" => eip.public_ip
  }
  description = "Map of Palo Alto VM names to their public IPs"
}

# # Register Palo Alto VMs with GWLB Target Group (updated for instance mode)
# resource "aws_lb_target_group_attachment" "palo_alto_tg_attachment" {
#   count            = 1
#   provider         = aws.producer
#   target_group_arn = aws_lb_target_group.gwlb_tg.arn
#   target_id        = aws_instance.palo_alto_vms[count.index].id
#   port             = 6081
# }