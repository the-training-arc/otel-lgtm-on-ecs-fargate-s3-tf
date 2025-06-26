# Loki Configuration
resource "aws_s3_object" "loki_config" {
  bucket = aws_s3_bucket.config.id
  key    = "loki/loki-config.yaml"
  content = yamlencode({
    auth_enabled = false
    server = {
      http_listen_port = 3100
    }
    ingester = {
      lifecycler = {
        address = "127.0.0.1"
        ring = {
          kvstore = {
            store = "inmemory"
          }
          replication_factor = 1
        }
        final_sleep = "0s"
      }
      chunk_idle_period = "5m"
      chunk_retain_period = "30s"
    }
    schema_config = {
      configs = [
        {
          from = "2020-05-15"
          store = "boltdb-shipper"
          object_store = "filesystem"
          schema = "v11"
          index = {
            prefix = "index_"
            period = "24h"
          }
        }
      ]
    }
    storage_config = {
      boltdb_shipper = {
        active_index_directory = "/tmp/loki/boltdb-shipper-active"
        cache_location = "/tmp/loki/boltdb-shipper-cache"
        cache_ttl = "24h"
        shared_store = "filesystem"
      }
      filesystem = {
        directory = "/tmp/loki/chunks"
      }
    }
    limits_config = {
      enforce_metric_name = false
      reject_old_samples = true
      reject_old_samples_max_age = "168h"
    }
    chunk_store_config = {
      max_look_back_period = "0s"
    }
    table_manager = {
      retention_deletes_enabled = false
      retention_period = "0s"
    }
  })
  content_type = "application/x-yaml"
}

# Prometheus Configuration
resource "aws_s3_object" "prometheus_config" {
  bucket = aws_s3_bucket.config.id
  key    = "prometheus/prometheus.yml"
  content = yamlencode({
    global = {
      scrape_interval = "15s"
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
        job_name = "ec2-instances"
        metrics_path = "/api/metrics"
        ec2_sd_configs = [
          {
            region = "ap-southeast-1"
            port = 3000
            filters = [
              {
                name = "tag:Name"
                values = ["My Node Service"]
              }
            ]
          }
        ]
        relabel_configs = [
          {
            source_labels = ["__meta_ec2_instance_id"]
            action = "replace"
            target_label = "instance_id"
          },
          {
            source_labels = ["__meta_ec2_private_ip"]
            action = "replace"
            target_label = "ip"
          },
          {
            source_labels = ["__meta_ec2_tag_Name"]
            action = "replace"
            target_label = "instance_name"
          },
          {
            source_labels = ["__meta_ec2_tag_Environment"]
            action = "replace"
            target_label = "environment"
          },
          {
            source_labels = ["__meta_ec2_availability_zone"]
            action = "replace"
            target_label = "availability_zone"
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
        name = "Prometheus"
        type = "prometheus"
        access = "proxy"
        url = "http://${aws_lb.prometheus.dns_name}"
        isDefault = true
      },
      {
        name = "Loki"
        type = "loki"
        access = "proxy"
        url = "http://${aws_lb.loki.dns_name}"
      },
      {
        name = "Tempo"
        type = "tempo"
        access = "proxy"
        url = "http://${aws_lb.tempo.dns_name}"
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
          source = "tempo"
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
      max_block_bytes = 1000000
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
        max_results_limit = 100
      }
    }
  })
  content_type = "application/x-yaml"
} 