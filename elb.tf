resource "aws_lb" "app-nlb" {
  name               = "app-nlb"
  internal           = true
  load_balancer_type = "network"
  security_groups    = [aws_security_group.producer_lb_sg.id]
  subnets            = [aws_subnet.producer_subnet.id]

  tags = {
    Name = "app-nlb"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "app-tg"
  port        = 80
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
    Name = "app-tg"
  }
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app-nlb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }

  tags = {
    Name = "app-nlb-listener"
  }
}

resource "aws_lb_target_group_attachment" "app" {
  count            = 2
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.producer_ec2.id
  port             = 80

}
