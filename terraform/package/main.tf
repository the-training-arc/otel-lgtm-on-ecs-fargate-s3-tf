# Fetch the specific VPC by ID
data "aws_vpc" "selected" {
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

resource "aws_ecs_cluster" "main" {
  name = "${var.service_prefix}-ecs-cluster"
}

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

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.service_prefix}-app"
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = "256"
  memory                  = "512"
  execution_role_arn      = aws_iam_role.task_exec_role.arn

  container_definitions = jsonencode([
    {
      name      = "my-app"
      image     = "nginx:latest"
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
    }
  ])
}

# Security group for ECS service
resource "aws_security_group" "ecs_service" {
  name_prefix = "${var.service_prefix}-ecs-sg"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_lb" "app" {
  name               = "${var.service_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_service.id]
  subnets            = local.public_subnet_ids
}

resource "aws_lb_target_group" "app" {
  name     = "${var.service_prefix}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.selected.id
  target_type = "ip"
}

resource "aws_lb_listener" "app" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_ecs_service" "app" {
  name            = "${var.service_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = local.public_subnet_ids
    security_groups = [aws_security_group.ecs_service.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "my-app"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.app]
}
