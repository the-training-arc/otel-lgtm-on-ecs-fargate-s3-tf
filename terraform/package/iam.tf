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

# IAM Policy Document for S3 Read Access (reusable)
resource "aws_iam_policy" "s3_config_read_policy_document" {
  name        = "${var.service_prefix}-s3-config-read"
  description = "Allows ECS tasks to read configuration files from the S3 bucket"

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
      },
    ]
  })
}

# NEW: IAM Role for other Monitoring Tasks (Loki, Grafana, Tempo)
resource "aws_iam_role" "monitoring_task_role" {
  name = "${var.service_prefix}-monitoring-task-role"

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

  tags = {
    Environment = "development"
    Project     = "Monitoring"
  }
}

# NEW: Attach S3 config read policy to the monitoring task role
resource "aws_iam_role_policy_attachment" "monitoring_task_role_s3_access" {
  role       = aws_iam_role.monitoring_task_role.name
  policy_arn = aws_iam_policy.s3_config_read_policy_document.arn
}

# NEW: Attach S3 config read policy to the Prometheus task role
resource "aws_iam_role_policy_attachment" "prometheus_role_s3_access" {
  role       = aws_iam_role.prometheus_role.name
  policy_arn = aws_iam_policy.s3_config_read_policy_document.arn
}

