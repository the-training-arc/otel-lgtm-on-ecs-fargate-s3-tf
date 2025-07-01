output "s3_config_bucket" {
  description = "S3 bucket name for configuration files"
  value       = aws_s3_bucket.config.bucket
}

output "loki_load_balancer_dns" {
  description = "The DNS name of the load balancer for the Loki service"
  value       = aws_lb.loki.dns_name
}

output "prometheus_load_balancer_dns" {
  description = "The DNS name of the load balancer for the Prometheus service"
  value       = aws_lb.prometheus.dns_name
}

output "grafana_load_balancer_dns" {
  description = "The DNS name of the load balancer for the Grafana service"
  value       = aws_lb.grafana.dns_name
}

output "tempo_load_balancer_dns" {
  description = "The DNS name of the load balancer for the Tempo service"
  value       = aws_lb.tempo.dns_name
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "tempo_otlp_grpc_endpoint" {
  description = "The OTLP gRPC endpoint for Tempo"
  value       = "http://${aws_lb.tempo.dns_name}:4317"
}

output "tempo_otlp_http_endpoint" {
  description = "The OTLP HTTP endpoint for Tempo"
  value       = "http://${aws_lb.tempo.dns_name}:4318"
} 