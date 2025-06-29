# Loki Task Definition
resource "aws_ecs_task_definition" "loki" {
  family                   = "${var.service_prefix}-loki"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.task_exec_role.arn
  task_role_arn            = aws_iam_role.loki_task_role.arn

  lifecycle {
    create_before_destroy = true
  }

  volume {
    name = "config-volume"
  }

  volume {
    name = "loki-data"
  }

  container_definitions = jsonencode([
    {
      name      = "config-sync"
      image     = "public.ecr.aws/aws-cli/aws-cli:latest"
      essential = false
      command = [
        "s3", "cp", "s3://${aws_s3_bucket.config.bucket}/loki/loki-config.yaml", "/config/loki-config.yaml"
      ]
      mountPoints = [
        {
          sourceVolume  = "config-volume"
          containerPath = "/config"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_prefix}-loki"
          awslogs-region        = "ap-southeast-1"
          awslogs-stream-prefix = "config-sync"
        }
      }
    },
    {
      name = "loki-init"
      image = "public.ecr.aws/docker/library/busybox:stable"
      essential = false
      user = "root"
      command = [
        "sh",
        "-c",
        "chown -R 10001:10001 /data && chmod -R 755 /data"
      ],
      mountPoints = [
        {
          sourceVolume  = "loki-data"
          containerPath = "/data"
          readOnly      = false
        }
      ],
      dependsOn = [
        {
          containerName = "config-sync"
          condition     = "SUCCESS"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_prefix}-loki"
          awslogs-create-group  = "true"
          awslogs-region        = "ap-southeast-1"
          awslogs-stream-prefix = "loki-init"
        }
      }
    },
    {
      name      = "loki"
      image     = "grafana/loki:3.5"
      essential = true
      dependsOn = [
        {
          containerName = "loki-init"
          condition     = "SUCCESS"
        }
      ]
      portMappings = [{
        containerPort = 3100
        hostPort      = 3100
      }]
      command = [
        "--config.file=/config/loki-config.yaml"
      ]
      mountPoints = [
        {
          sourceVolume  = "config-volume"
          containerPath = "/config"
          readOnly      = true
        },
        {
          sourceVolume  = "loki-data"
          containerPath = "/data",
          readOnly =  false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_prefix}-loki"
          awslogs-create-group  = "true"
          awslogs-region        = "ap-southeast-1"
          awslogs-stream-prefix = "loki"
        }
      }
    }
  ])
}

# Prometheus Task Definition
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.service_prefix}-prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.task_exec_role.arn
  task_role_arn            = aws_iam_role.prometheus_role.arn

  lifecycle {
    create_before_destroy = true
  }

  volume {
    name = "config-volume"
  }

  container_definitions = jsonencode([
    {
      name      = "config-sync"
      image     = "amazon/aws-cli:latest"
      essential = false
      command = [
        "s3", "cp", "s3://${aws_s3_bucket.config.bucket}/prometheus/prometheus.yml", "/config/prometheus.yml"
      ]
      mountPoints = [
        {
          sourceVolume  = "config-volume"
          containerPath = "/config"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_prefix}-prometheus-config-sync"
          awslogs-create-group  = "true"
          awslogs-region        = "ap-southeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name      = "prometheus"
      image     = "public.ecr.aws/bitnami/prometheus:latest"
      essential = true
      dependsOn = [
        {
          containerName = "config-sync"
          condition     = "SUCCESS"
        }
      ]
      portMappings = [{
        containerPort = 9090
        hostPort      = 9090
      }]
      command = [
        "--config.file=/config/prometheus.yml"
      ]
      mountPoints = [
        {
          sourceVolume  = "config-volume"
          containerPath = "/config"
          readOnly      = true
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_prefix}-prometheus"
          awslogs-create-group  = "true"
          awslogs-region        = "ap-southeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Grafana Task Definition
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${var.service_prefix}-grafana"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.task_exec_role.arn
  task_role_arn            = aws_iam_role.monitoring_task_role.arn

  lifecycle {
    create_before_destroy = true
  }

  volume {
    name = "config-volume" # UPDATED: Removed docker_volume_configuration block
  }

  container_definitions = jsonencode([
    {
      name      = "config-sync"
      image     = "amazon/aws-cli:latest"
      essential = false
      command = [
        "s3", "cp", "s3://${aws_s3_bucket.config.bucket}/grafana/datasources.yml", "/config/datasources.yml"
      ]
      mountPoints = [
        {
          sourceVolume  = "config-volume"
          containerPath = "/config"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_prefix}-grafana-config-sync"
          awslogs-create-group  = "true"
          awslogs-region        = "ap-southeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name      = "grafana"
      image     = "public.ecr.aws/bitnami/grafana:12.0.2-debian-12-r1"
      essential = true
      dependsOn = [
        {
          containerName = "config-sync"
          condition     = "SUCCESS"
        }
      ]
      portMappings = [{
        containerPort = 3000
        hostPort      = 3000
      }]
      environment = [
        {
          name  = "GF_SECURITY_ADMIN_PASSWORD"
          value = "admin123"
        }
      ]
      command = [
        "/bin/bash", "-c",
        "cp /config/datasources.yml /opt/bitnami/grafana/conf/provisioning/datasources/datasources.yml && exec /opt/bitnami/scripts/grafana/run.sh"
      ]
      mountPoints = [
        {
          sourceVolume  = "config-volume"
          containerPath = "/config"
          readOnly      = true
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_prefix}-grafana"
          awslogs-create-group  = "true"
          awslogs-region        = "ap-southeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Tempo Task Definition
resource "aws_ecs_task_definition" "tempo" {
  family                   = "${var.service_prefix}-tempo"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = aws_iam_role.task_exec_role.arn
  task_role_arn            = aws_iam_role.monitoring_task_role.arn

  lifecycle {
    create_before_destroy = true
  }

  volume {
    name = "config-volume"
  }

  container_definitions = jsonencode([
    {
      name      = "config-sync"
      image     = "amazon/aws-cli:latest"
      essential = false
      command = [
        "s3", "cp", "s3://${aws_s3_bucket.config.bucket}/tempo/tempo-config.yaml", "/config/tempo-config.yaml"
      ]
      mountPoints = [
        {
          sourceVolume  = "config-volume"
          containerPath = "/config"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_prefix}-tempo-config-sync"
          awslogs-create-group  = "true"
          awslogs-region        = "ap-southeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name      = "tempo"
      image     = "public.ecr.aws/bitnami/grafana-tempo:2.4.1"
      essential = true
      dependsOn = [
        {
          containerName = "config-sync"
          condition     = "SUCCESS"
        }
      ]
      portMappings = [
        {
          containerPort = 3200
          hostPort      = 3200
        },
        {
          containerPort = 4317
          hostPort      = 4317
        },
        {
          containerPort = 4318
          hostPort      = 4318
        },
        {
          containerPort = 14250
          hostPort      = 14250
        },
        {
          containerPort = 14268
          hostPort      = 14268
        },
        {
          containerPort = 16686
          hostPort      = 16686
        }
      ]
      command = [
        "--config.file=/config/tempo-config.yaml"
      ]
      mountPoints = [
        {
          sourceVolume  = "config-volume"
          containerPath = "/config"
          readOnly      = true
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_prefix}-tempo"
          awslogs-create-group  = "true"
          awslogs-region        = "ap-southeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
