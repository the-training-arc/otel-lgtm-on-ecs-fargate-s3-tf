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

  # Add explicit dependency to ensure proper deletion order
  depends_on = [aws_lb_target_group.tempo]
}

# Add a new listener for Tempo OTLP HTTP
resource "aws_lb_listener" "tempo_otlp_http" {
  load_balancer_arn = aws_lb.tempo.arn
  port              = 4318
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tempo_otlp_http.arn
  }

  depends_on = [aws_lb_target_group.tempo_otlp_http]
}


resource "aws_lb_listener" "otel_collector_otlp_http" {
  load_balancer_arn = aws_lb.otel_collector.arn
  port              = 4318
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.otel_collector_otlp_http.arn
  }
}