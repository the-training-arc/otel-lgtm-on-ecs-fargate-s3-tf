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

resource "aws_lb" "otel_collector" {
  name               = "${var.service_prefix}-otel-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.monitoring.id]
  subnets            = local.public_subnet_ids
}
