output "integration_service" {
  value = {
    aws : {
      ecs : module.ecs
    }
  }
}

output "s3_config_bucket" {
  description = "S3 bucket name for configuration files"
  value       = module.ecs.s3_config_bucket
}

output "loki_load_balancer_dns" {
  description = "The DNS name of the load balancer for the Loki service"
  value       = module.ecs.loki_load_balancer_dns
}

output "prometheus_load_balancer_dns" {
  description = "The DNS name of the load balancer for the Prometheus service"
  value       = module.ecs.prometheus_load_balancer_dns
}

output "grafana_load_balancer_dns" {
  description = "The DNS name of the load balancer for the Grafana service"
  value       = module.ecs.grafana_load_balancer_dns
}

output "tempo_load_balancer_dns" {
  description = "The DNS name of the load balancer for the Tempo service"
  value       = module.ecs.tempo_load_balancer_dns
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = module.ecs.ecs_cluster_name
}

# output "tempo_otlp_grpc_endpoint" {
#   description = "The OTLP gRPC endpoint for Tempo"
#   value       = module.ecs.tempo_otlp_grpc_endpoint
# }

output "tempo_otlp_http_endpoint" {
  description = "The OTLP HTTP endpoint for Tempo"
  value       = module.ecs.tempo_otlp_http_endpoint
}
