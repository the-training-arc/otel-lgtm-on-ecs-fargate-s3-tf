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
  content = templatefile("${path.module}/configs/tempo-config.yaml.tftpl", {
    tempo_data_bucket_name = aws_s3_bucket.tempo_data.bucket
    aws_region             = "ap-southeast-1"
  })
  content_type = "application/x-yaml"
} 