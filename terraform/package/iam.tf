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

resource "aws_iam_role_policy_attachment" "task_exec_s3_config_read" {
  role       = aws_iam_role.task_exec_role.name
  policy_arn = aws_iam_policy.s3_config_read_policy_document.arn
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
          "s3:ListBucket",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:HeadObject",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
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

# 2. Create an IAM policy that allows access to the bucket
data "aws_iam_policy_document" "loki_s3_access" {
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.loki_data.arn,
    ]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:HeadObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "${aws_s3_bucket.loki_data.arn}/*",
    ]
  }
}

resource "aws_iam_policy" "loki_s3_access" {
  name   = "${var.service_prefix}-loki-s3-access-policy"
  policy = data.aws_iam_policy_document.loki_s3_access.json
}

# 3. Create an IAM Role for your ECS Task
resource "aws_iam_role" "loki_task_role" {
  name = "${var.service_prefix}-loki-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}

# 4. Attach the S3 policy to the role
resource "aws_iam_role_policy_attachment" "loki_s3" {
  role       = aws_iam_role.loki_task_role.name
  policy_arn = aws_iam_policy.loki_s3_access.arn
}

# Attach the S3 config read policy to the loki task role
resource "aws_iam_role_policy_attachment" "loki_s3_config_read" {
  role       = aws_iam_role.loki_task_role.name
  policy_arn = aws_iam_policy.s3_config_read_policy_document.arn
}

