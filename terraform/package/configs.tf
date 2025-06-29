# Loki Configuration
resource "aws_s3_object" "loki_config" {
  bucket = aws_s3_bucket.config.id
  key    = "loki/loki-config.yaml"
  content = templatefile("${path.module}/loki-config.yaml.tftpl", {
    loki_data_bucket_name = aws_s3_bucket.loki_data.bucket
    aws_region            = "ap-southeast-1"
  })
  content_type = "application/x-yaml"
}

# Prometheus Configuration
resource "aws_s3_object" "prometheus_config" {
  bucket = aws_s3_bucket.config.id
  key    = "prometheus/prometheus.yml"
  content = yamlencode({
    global = {
      scrape_interval     = "15s"
      evaluation_interval = "15s"
    }
    rule_files = []
    scrape_configs = [
      {
        job_name = "prometheus"
        static_configs = [
          {
            targets = ["localhost:9090"]
          }
        ]
      },
      {
        job_name     = "ec2-instances"
        metrics_path = "/api/metrics"
        ec2_sd_configs = [
          {
            region = "ap-southeast-1"
            port   = 3000
            filters = [
              {
                name   = "tag:Name"
                values = ["My Node Service"]
              }
            ]
          }
        ]
        relabel_configs = [
          {
            source_labels = ["__meta_ec2_instance_id"]
            action        = "replace"
            target_label  = "instance_id"
          },
          {
            source_labels = ["__meta_ec2_private_ip"]
            action        = "replace"
            target_label  = "ip"
          },
          {
            source_labels = ["__meta_ec2_tag_Name"]
            action        = "replace"
            target_label  = "instance_name"
          },
          {
            source_labels = ["__meta_ec2_tag_Environment"]
            action        = "replace"
            target_label  = "environment"
          },
          {
            source_labels = ["__meta_ec2_availability_zone"]
            action        = "replace"
            target_label  = "availability_zone"
          }
        ]
      }
    ]
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
        url       = "http://${aws_lb.prometheus.dns_name}"
        isDefault = true
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
  content = yamlencode({
    server = {
      http_listen_port = 3200
    }
    storage = {
      trace = {
        backend = "local"
        local = {
          path = "/tmp/tempo/blocks"
        }
        wal = {
          path = "/tmp/tempo/wal"
        }
      }
    }
    metrics_generator = {
      registry = {
        external_labels = {
          source  = "tempo"
          cluster = "${var.service_prefix}"
        }
      }
    }
    overrides = {
      defaults = {
        metrics_generator = {
          processors = ["service-graphs", "span-metrics"]
        }
      }
    }
    ingester = {
      max_block_bytes    = 1000000
      max_block_duration = "5m"
    }
    compactor = {
      compaction = {
        block_retention = "1h"
      }
    }
    distributor = {
      receivers = {
        otlp = {
          protocols = {
            grpc = {
              endpoint = "0.0.0.0:4317"
            }
            http = {
              endpoint = "0.0.0.0:4318"
            }
          }
        }
        jaeger = {
          protocols = {
            thrift_http = {
              endpoint = "0.0.0.0:14268"
            }
            grpc = {
              endpoint = "0.0.0.0:14250"
            }
          }
        }
      }
    }
    query_frontend = {
      search = {
        default_results_limit = 20
        max_results_limit     = 100
      }
    }
  })
  content_type = "application/x-yaml"
} 