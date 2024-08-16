## PRODUCER EC2
resource "aws_instance" "producer_ec2" {
  provider        = aws.producer
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.producer_subnet.id
  security_groups = [aws_security_group.producer_ec2_sg.id]

  tags = {
    Name = "producer-ec2-instance"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
    http_protocol_ipv6          = "disabled"
  }

  iam_instance_profile = aws_iam_instance_profile.producer_instance_profile.name

  user_data = templatefile("tpl/producer.tpl", {
    public_key             = var.public_key
    aws_region             = var.aws_region
    sqs_dns_name           = aws_sqs_queue.vulnerable_queue.url
    flask_script           = file("${path.module}/scripts/flask-jndi.py")
    startup_script         = file("${path.module}/scripts/producer_startup.sh")
    sqs_sql_attack         = file("${path.module}/scripts/producer_sqs_sql_attack.py")
    random_sqs_messages    = file("${path.module}/scripts/random_sqs_messages.sh")
    guardduty_agent_script = file("${path.module}/scripts/install_guardduty_agent.sh")
    cloudwatch_config      = file("${path.module}/scripts/cloudwatch-agent.json")
  })
}

## CONSUMER EC2
resource "aws_instance" "consumer_ec2" {
  provider        = aws.consumer
  ami             = var.ami_id
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.consumer_subnet.id
  security_groups = [aws_security_group.consumer_ec2_sg.id]

  tags = {
    Name = "consumer-ec2-instance"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
    http_protocol_ipv6          = "disabled"
  }

  iam_instance_profile = aws_iam_instance_profile.consumer_instance_profile.name

  user_data = templatefile("tpl/consumer.tpl", {
    public_key             = var.public_key
    aws_region             = var.aws_region
    vpc_endpoint_dns_name  = aws_vpc_endpoint.consumer_privatelink_endpoint.dns_entry[0].dns_name
    s3_bucket_dns_name     = aws_s3_bucket.producer_public_bucket.bucket_regional_domain_name
    sqs_dns_name           = aws_sqs_queue.vulnerable_queue.url
    startup_script         = file("${path.module}/scripts/consumer_startup.sh")
    sqs_mysql              = file("${path.module}/scripts/consumer_sqs_vuln.py")
    payload_txt            = file("${path.module}/scripts/payload.sh")
    strutsxploit           = file("${path.module}/scripts/strutsxploit.sh")
    guardduty_agent_script = file("${path.module}/scripts/install_guardduty_agent.sh")
    cloudwatch_config      = file("${path.module}/scripts/cloudwatch-agent.json")
  })
}

## ELASTIC IP
resource "aws_eip" "producer_ec2_eip" {
  provider = aws.producer
  instance = aws_instance.producer_ec2.id
  domain   = "vpc"
}

resource "aws_eip" "consumer_ec2_eip" {
  provider = aws.consumer
  instance = aws_instance.consumer_ec2.id
  domain   = "vpc"
}

output "producer_ec2_public_ip" {
  value = aws_eip.producer_ec2_eip.public_ip
}

output "consumer_ec2_public_ip" {
  value = aws_eip.consumer_ec2_eip.public_ip
}
