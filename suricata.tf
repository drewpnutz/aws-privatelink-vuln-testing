# Suricata EC2 Instance
resource "aws_instance" "suricata_vms" {
  provider      = aws.producer
  count         = var.suricata_vm_count
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.gwlb_dp_subnet.id

  vpc_security_group_ids = [aws_security_group.suricata_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.suricata_profile.name

  user_data = templatefile("tpl/suricata.tpl", {
    public_key           = var.public_key
    aws_region           = var.aws_region
    cloudwatch_log_group = aws_cloudwatch_log_group.suricata.name
    cloudwatch_config    = file("${path.module}/scripts/cloudwatch-agent.json")
    custom_rules         = file("${path.module}/scripts/suricata/custom.rules")
  })

  tags = {
    Name = "suricata-vm-${count.index + 1}"
  }

  depends_on = [aws_cloudwatch_log_group.suricata]
}

## CloudWatch log group for GuardDuty
resource "aws_cloudwatch_log_group" "suricata" {
  provider          = aws.producer
  name              = "/aws/suricata/findings"
  retention_in_days = 1
}

## ELASTIC IP
resource "aws_eip" "suricata_vm_eip" {
  count    = var.suricata_vm_count
  provider = aws.producer
  instance = aws_instance.suricata_vms[count.index].id
  domain   = "vpc"
}

output "suricata_vm_public_ips" {
  value = {
    for idx, eip in aws_eip.suricata_vm_eip :
    "suricata_vm_${idx + 1}" => eip.public_ip
  }
  description = "Map of Suricata VM names to their public IPs"
}
