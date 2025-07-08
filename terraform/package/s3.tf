resource "aws_s3_bucket" "config" {
  bucket        = "${var.service_prefix}-monitoring-config"
  force_destroy = true
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

resource "aws_s3_bucket" "loki_data" {
  bucket        = "${var.service_prefix}-loki-data-storage"
  force_destroy = true
}

resource "aws_s3_bucket" "tempo_data" {
  bucket        = "${var.service_prefix}-tempo-data-storage"
  force_destroy = true
}

resource "aws_s3_bucket" "prometheus_data" {
  bucket        = "${var.service_prefix}-prometheus-data-storage"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "prometheus_data" {
  bucket = aws_s3_bucket.prometheus_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "prometheus_data" {
  bucket = aws_s3_bucket.prometheus_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}