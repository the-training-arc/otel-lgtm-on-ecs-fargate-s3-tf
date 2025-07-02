resource "aws_ecs_cluster" "main" {
  name = "${var.service_prefix}-ecs-cluster"
}


resource "aws_ecs_service" "loki" {
  name            = "${var.service_prefix}-loki-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.loki.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = local.public_subnet_ids
    security_groups  = [aws_security_group.monitoring.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.loki.arn
    container_name   = "loki"
    container_port   = 3100
  }

  depends_on = [aws_lb_listener.loki]
}

resource "aws_ecs_service" "prometheus" {
  name            = "${var.service_prefix}-prometheus-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.prometheus.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = local.public_subnet_ids
    security_groups  = [aws_security_group.monitoring.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus.arn
    container_name   = "prometheus"
    container_port   = 9090
  }

  health_check_grace_period_seconds = 60

  depends_on = [aws_lb_listener.prometheus]
}

resource "aws_ecs_service" "grafana" {
  name            = "${var.service_prefix}-grafana-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.grafana.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = local.public_subnet_ids
    security_groups  = [aws_security_group.monitoring.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.grafana.arn
    container_name   = "grafana"
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.grafana]
}

resource "aws_ecs_service" "tempo" {
  name            = "${var.service_prefix}-tempo-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.tempo.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = local.public_subnet_ids
    security_groups  = [aws_security_group.monitoring.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tempo.arn
    container_name   = "tempo"
    container_port   = 3200
  }

  # load_balancer {
  #   target_group_arn = aws_lb_target_group.tempo_otlp_grpc.arn
  #   container_name   = "tempo"
  #   container_port   = 4317
  # }

  load_balancer {
    target_group_arn = aws_lb_target_group.tempo_otlp_http.arn
    container_name   = "tempo"
    container_port   = 4318
  }

  depends_on = [aws_lb_listener.tempo, aws_lb_listener.tempo_otlp_http, aws_ecs_service.prometheus]
}