data "aws_vpc" "selected" { # rnd vpc
  id = "vpc-02c4d6c4d3e3e2545"
}

# Fetch all public subnets in the VPC (those with 'public' in the name)
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

data "aws_subnet" "public_a" {
  vpc_id = data.aws_vpc.selected.id
  availability_zone = "ap-southeast-1a"
  filter {
    name   = "tag:Name"
    values = ["ap-southeast-1a-public-subnet"]
  }
}
data "aws_subnet" "public_b" {
  vpc_id = data.aws_vpc.selected.id
  availability_zone = "ap-southeast-1b"
  filter {
    name   = "tag:Name"
    values = ["ap-southeast-1b-public-subnet"]
  }
}
data "aws_subnet" "public_c" {
  vpc_id = data.aws_vpc.selected.id
  availability_zone = "ap-southeast-1c"
  filter {
    name   = "tag:Name"
    values = ["ap-southeast-1c-public-subnet"]
  }
}

locals {
  public_subnet_ids = [
    data.aws_subnet.public_a.id,
    data.aws_subnet.public_b.id,
    data.aws_subnet.public_c.id
  ]
}

# S3 Bucket for configuration files
resource "aws_s3_bucket" "config" {
  bucket = "${var.service_prefix}-monitoring-config"
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  bucket = aws_s3_bucket.config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "task_exec_role" {
  name = "${var.service_prefix}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_role_policy" "cloudwatch_logs" {
  name = "${var.service_prefix}-cloudwatch-logs"
  role = aws_iam_role.task_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:ap-southeast-1:*:log-group:/ecs/*",
          "arn:aws:logs:ap-southeast-1:*:log-group:/ecs/*:*"
        ]
      }
    ]
  })
}

# IAM Role for Prometheus Service Discovery
resource "aws_iam_role" "prometheus_role" {
  name = "${var.service_prefix}-prometheus-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# IAM Policy for Prometheus Service Discovery
resource "aws_iam_role_policy" "prometheus_service_discovery" {
  name = "${var.service_prefix}-prometheus-service-discovery"
  role = aws_iam_role.prometheus_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ecs:ListClusters",
          "ecs:DescribeClusters",
          "ecs:ListContainerInstances",
          "ecs:DescribeContainerInstances",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeTasks"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Policy for S3 access
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.service_prefix}-s3-access"
  role = aws_iam_role.task_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.config.arn,
          "${aws_s3_bucket.config.arn}/*"
        ]
      }
    ]
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.service_prefix}-ecs-cluster"
}

# Security Groups
resource "aws_security_group" "monitoring" {
  name_prefix = "${var.service_prefix}-monitoring-sg"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3100
    to_port     = 3100
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Tempo ports
  ingress {
    from_port   = 3200
    to_port     = 3200
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 4318
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 14250
    to_port     = 14250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 14268
    to_port     = 14268
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 16686
    to_port     = 16686
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Loki Task Definition
resource "aws_ecs_task_definition" "loki" {
  family                   = "${var.service_prefix}-loki"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = "1024"
  memory                  = "3072"
  execution_role_arn      = aws_iam_role.task_exec_role.arn
  task_role_arn           = aws_iam_role.task_exec_role.arn

  # Force new deployment to resolve dockerVolumeConfiguration issue
  lifecycle {
    create_before_destroy = true
  }

  volume {
    name = "config-volume"
    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "local"
    }
  }

  container_definitions = jsonencode([
    {
      name      = "config-sync"
      image     = "public.ecr.aws/amazonlinux/amazonlinux:2"
      essential = false
      command = [
        "sh", "-c",
        "yum install -y aws-cli && aws s3 cp s3://${aws_s3_bucket.config.bucket}/loki/loki-config.yaml /config/loki-config.yaml"
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
          awslogs-group         = "/ecs/${var.service_prefix}-loki-config-sync"
          awslogs-create-group  = "true"
          awslogs-region        = "ap-southeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    {
      name      = "loki"
      image     = "public.ecr.aws/bitnami/grafana-loki:2.9.7"
      essential = true
      dependsOn = [
        {
          containerName = "config-sync"
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
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.service_prefix}-loki"
          awslogs-create-group  = "true"
          awslogs-region        = "ap-southeast-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Prometheus Task Definition
resource "aws_ecs_task_definition" "prometheus" {
  family                   = "${var.service_prefix}-prometheus"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = "512"
  memory                  = "1024"
  execution_role_arn      = aws_iam_role.task_exec_role.arn
  task_role_arn           = aws_iam_role.prometheus_role.arn

  # Force new deployment to resolve dockerVolumeConfiguration issue
  lifecycle {
    create_before_destroy = true
  }

  volume {
    name = "config-volume"
    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "local"
    }
  }

  container_definitions = jsonencode([
    {
      name      = "config-sync"
      image     = "public.ecr.aws/amazonlinux/amazonlinux:2"
      essential = false
      command = [
        "sh", "-c",
        "yum install -y aws-cli && aws s3 cp s3://${aws_s3_bucket.config.bucket}/prometheus/prometheus.yml /config/prometheus.yml"
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
  network_mode            = "awsvpc"
  cpu                     = "512"
  memory                  = "1024"
  execution_role_arn      = aws_iam_role.task_exec_role.arn
  task_role_arn           = aws_iam_role.task_exec_role.arn

  # Force new deployment to resolve dockerVolumeConfiguration issue
  lifecycle {
    create_before_destroy = true
  }

  volume {
    name = "config-volume"
    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "local"
    }
  }

  container_definitions = jsonencode([
    {
      name      = "config-sync"
      image     = "public.ecr.aws/amazonlinux/amazonlinux:2"
      essential = false
      command = [
        "sh", "-c",
        "yum install -y aws-cli && aws s3 cp s3://${aws_s3_bucket.config.bucket}/grafana/datasources.yml /config/datasources.yml"
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
      image     = "public.ecr.aws/ubuntu/grafana:11.0.0-22.04_stable"
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
        "sh", "-c",
        "mkdir -p /etc/grafana/provisioning/datasources && cp /config/datasources.yml /etc/grafana/provisioning/datasources/datasources.yml && exec /run.sh"
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
  network_mode            = "awsvpc"
  cpu                     = "1024"
  memory                  = "2048"
  execution_role_arn      = aws_iam_role.task_exec_role.arn
  task_role_arn           = aws_iam_role.task_exec_role.arn

  # Force new deployment to resolve dockerVolumeConfiguration issue
  lifecycle {
    create_before_destroy = true
  }

  volume {
    name = "config-volume"
    docker_volume_configuration {
      scope         = "shared"
      autoprovision = true
      driver        = "local"
    }
  }

  container_definitions = jsonencode([
    {
      name      = "config-sync"
      image     = "public.ecr.aws/amazonlinux/amazonlinux:2"
      essential = false
      command = [
        "sh", "-c",
        "yum install -y aws-cli && aws s3 cp s3://${aws_s3_bucket.config.bucket}/tempo/tempo-config.yaml /config/tempo-config.yaml"
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
      image     = "public.ecr.aws/bitnami/grafana-tempo:latest"
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
  name     = "${var.service_prefix}-loki-tg"
  port     = 3100
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    path                = "/ready"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "prometheus" {
  name     = "${var.service_prefix}-prometheus-tg"
  port     = 9090
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    path                = "/-/healthy"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "grafana" {
  name     = "${var.service_prefix}-grafana-tg"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id
  target_type = "ip"

  health_check {
    path                = "/api/health"
    healthy_threshold   = 2
    unhealthy_threshold = 10
  }
}

resource "aws_lb_target_group" "tempo" {
  name     = "${var.service_prefix}-tempo-tg"
  port     = 3200
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id
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

# ECS Services
resource "aws_ecs_service" "loki" {
  name            = "${var.service_prefix}-loki-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.loki.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = local.public_subnet_ids
    security_groups = [aws_security_group.monitoring.id]
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
    subnets         = local.public_subnet_ids
    security_groups = [aws_security_group.monitoring.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.prometheus.arn
    container_name   = "prometheus"
    container_port   = 9090
  }

  depends_on = [aws_lb_listener.prometheus]
}

resource "aws_ecs_service" "grafana" {
  name            = "${var.service_prefix}-grafana-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.grafana.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = local.public_subnet_ids
    security_groups = [aws_security_group.monitoring.id]
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
    subnets         = local.public_subnet_ids
    security_groups = [aws_security_group.monitoring.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tempo.arn
    container_name   = "tempo"
    container_port   = 3200
  }

  depends_on = [aws_lb_listener.tempo]
}
