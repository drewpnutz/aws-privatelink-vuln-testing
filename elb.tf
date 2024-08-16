resource "aws_lb" "app-nlb" {
  provider           = aws.producer
  name               = "app-nlb"
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.producer_lb_sg.id]
  subnets            = [aws_subnet.producer_subnet.id]

  tags = {
    Name = "app-nlb"
  }
}

resource "aws_lb_target_group" "struts" {
  provider    = aws.producer
  name        = "struts-tg"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = aws_vpc.producer_vpc.id
  target_type = "instance"

  health_check {
    protocol            = "TCP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "struts-tg"
  }
}

resource "aws_lb_target_group" "flask" {
  provider    = aws.producer
  name        = "flask-tg"
  port        = 9090
  protocol    = "TCP"
  vpc_id      = aws_vpc.producer_vpc.id
  target_type = "instance"

  health_check {
    protocol            = "TCP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "flask-tg"
  }
}


resource "aws_lb_listener" "struts" {
  provider          = aws.producer
  load_balancer_arn = aws_lb.app-nlb.arn
  port              = 8080
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.struts.arn
  }

  tags = {
    Name = "struts-nlb-listener"
  }
}

resource "aws_lb_listener" "flask" {
  provider          = aws.producer
  load_balancer_arn = aws_lb.app-nlb.arn
  port              = 9090
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.flask.arn
  }

  tags = {
    Name = "flask-nlb-listener"
  }
}

resource "aws_lb_target_group_attachment" "struts" {
  provider         = aws.producer
  count            = 2
  target_group_arn = aws_lb_target_group.struts.arn
  target_id        = aws_instance.producer_ec2.id
  port             = 8080
}


resource "aws_lb_target_group_attachment" "flask" {
  provider         = aws.producer
  count            = 2
  target_group_arn = aws_lb_target_group.flask.arn
  target_id        = aws_instance.producer_ec2.id
  port             = 9090
}
