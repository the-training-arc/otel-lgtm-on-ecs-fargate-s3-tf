# Loki Configuration
resource "aws_s3_object" "loki_config" {
  bucket = aws_s3_bucket.config.id
  key    = "loki/loki-config.yaml"
  content = templatefile("${path.module}/configs/loki-config.yaml.tftpl", {
    loki_data_bucket_name = aws_s3_bucket.loki_data.bucket
    aws_region            = "ap-southeast-1"
  })
  content_type = "application/x-yaml"
}

# Prometheus Configuration
resource "aws_s3_object" "prometheus_config" {
  bucket = aws_s3_bucket.config.id
  key    = "prometheus/prometheus.yml"
  content = templatefile("${path.module}/configs/prometheus-config.yaml.tftpl", {
    otel_collector_lb_dns_name = aws_lb.otel_collector.dns_name
  })
  content_type = "application/x-yaml"
}

# Grafana Datasources Configuration
resource "aws_s3_object" "grafana_datasources" {
  bucket = aws_s3_bucket.config.id
  key    = "grafana/datasources.yml"
  content = yamlencode({
    apiVersion = 1
    datasources = [
      {
        name      = "Prometheus"
        type      = "prometheus"
        access    = "proxy"
        uid       = "prometheus"
        url       = "http://${aws_lb.prometheus.dns_name}"
        isDefault = true
        jsonData = {
          httpMethod = "GET"
        }
      },
      {
        name   = "Loki"
        type   = "loki"
        access = "proxy"
        url    = "http://${aws_lb.loki.dns_name}"
      },
      {
        name   = "Tempo"
        type   = "tempo"
        access = "proxy"
        uid    = "tempo"
        url    = "http://${aws_lb.tempo.dns_name}"
        jsonData = {
          httpMethod = "GET"
          serviceMap = {
            datasourceUid = "prometheus"
          }
        }
      }
    ]
  })
  content_type = "application/x-yaml"
}

# Tempo Configuration
resource "aws_s3_object" "tempo_config" {
  bucket = aws_s3_bucket.config.id
  key    = "tempo/tempo-config.yaml"
  content = templatefile("${path.module}/configs/tempo-config.yaml.tftpl", {
    tempo_data_bucket_name = aws_s3_bucket.tempo_data.bucket
    aws_region             = "ap-southeast-1"
    prometheus_lb_dns_name = aws_lb.prometheus.dns_name
  })
  content_type = "application/x-yaml"
}

# OpenTelemetry Collector Configuration
resource "aws_s3_object" "otel_collector_config" {
  bucket = aws_s3_bucket.config.id
  key    = "otel-collector/otel-collector-config.yaml"
  content = templatefile("${path.module}/configs/otel-collector-config.yaml.tftpl", {
    tempo_lb_dns_name      = aws_lb.tempo.dns_name
    loki_lb_dns_name       = aws_lb.loki.dns_name
    prometheus_lb_dns_name = aws_lb.prometheus.dns_name
  })
  content_type = "application/x-yaml"
} 