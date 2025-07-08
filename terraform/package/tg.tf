
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
    unhealthy_threshold = 5
    timeout             = 30
    interval            = 60
    matcher             = "200"
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

  # Add lifecycle to handle deletion order
  lifecycle {
    create_before_destroy = true
  }
}

# Add a new target group for Tempo OTLP HTTP
resource "aws_lb_target_group" "tempo_otlp_http" {
  name        = "${var.service_prefix}-tempo-http-tg"
  port        = 4318
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    port                = "3200"
    path                = "/ready"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "otel_collector_otlp_http" {
  name        = "${var.service_prefix}-otel-http-tg"
  port        = 4318
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    enabled             = true
    port                = "13133" # health_check extension port
    path                = "/"     # health_check extension endpoint
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399" # more flexible matcher
    protocol            = "HTTP"
  }
}
