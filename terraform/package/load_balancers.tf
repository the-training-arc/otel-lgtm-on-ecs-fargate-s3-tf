# Load Balancers
resource "aws_lb" "loki" {
  name               = "${var.service_prefix}-loki-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.monitoring.id]
  subnets            = local.public_subnet_ids
}

resource "aws_lb" "prometheus" {
  name               = "${var.service_prefix}-prometheus-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.monitoring.id]
  subnets            = local.public_subnet_ids
}

resource "aws_lb" "grafana" {
  name               = "${var.service_prefix}-grafana-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.monitoring.id]
  subnets            = local.public_subnet_ids
}

resource "aws_lb" "tempo" {
  name               = "${var.service_prefix}-tempo-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.monitoring.id]
  subnets            = local.public_subnet_ids
}

# Target Groups
resource "aws_lb_target_group" "loki" {
  name        = "${var.service_prefix}-loki-tg"
  port        = 3100
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    path                = "/ready"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "prometheus" {
  name        = "${var.service_prefix}-prometheus-tg"
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    path                = "/-/healthy"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "grafana" {
  name        = "${var.service_prefix}-grafana-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "tempo" {
  name        = "${var.service_prefix}-tempo-tg"
  port        = 3200
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    path                = "/ready"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

# Listeners
resource "aws_lb_listener" "loki" {
  load_balancer_arn = aws_lb.loki.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.loki.arn
  }
}

resource "aws_lb_listener" "prometheus" {
  load_balancer_arn = aws_lb.prometheus.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus.arn
  }
}

resource "aws_lb_listener" "grafana" {
  load_balancer_arn = aws_lb.grafana.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana.arn
  }
}

resource "aws_lb_listener" "tempo" {
  load_balancer_arn = aws_lb.tempo.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tempo.arn
  }
}
