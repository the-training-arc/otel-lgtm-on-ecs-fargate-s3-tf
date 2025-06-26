# Monitoring Stack with S3 Configuration Storage

This Terraform configuration deploys a complete monitoring stack on AWS ECS using S3 for configuration storage instead of EFS. The stack includes:

- **Grafana**: Dashboard and visualization platform
- **Prometheus**: Metrics collection and storage
- **Loki**: Log aggregation and storage
- **Tempo**: Distributed tracing backend

## Architecture

### S3 Configuration Storage
Instead of using EFS for configuration files, this setup uses S3 to store:
- Loki configuration (`loki/loki-config.yaml`)
- Prometheus configuration (`prometheus/prometheus.yml`)
- Grafana datasources (`grafana/datasources.yml`)
- Tempo configuration (`tempo/tempo-config.yaml`)

### ECS Task Definitions
Each service uses an init container pattern:
1. **Init Container**: Downloads configuration from S3 using AWS CLI
2. **Main Container**: Runs the actual service with the downloaded configuration

### Service Discovery
Prometheus is configured with EC2 service discovery to automatically detect and scrape metrics from EC2 instances tagged with `Name: My Node Service`.

### Distributed Tracing
Tempo provides distributed tracing capabilities with support for:
- **OTLP**: OpenTelemetry Protocol (gRPC and HTTP)
- **Jaeger**: Jaeger protocol support
- **Service Graphs**: Automatic service dependency mapping
- **Span Metrics**: Metrics generation from traces

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.2.0
- Existing VPC with public subnets

## Deployment

1. **Initialize Terraform**:
   ```bash
   cd terraform
   terraform init
   ```

2. **Plan the deployment**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Configuration Files

### Loki Configuration
Stored in S3 at `s3://{bucket}/loki/loki-config.yaml`
- Single-node Loki setup
- File-based storage for development
- No authentication enabled

### Prometheus Configuration
Stored in S3 at `s3://{bucket}/prometheus/prometheus.yml`
- 15-second scrape intervals
- EC2 service discovery enabled
- Self-monitoring configured

### Grafana Configuration
Stored in S3 at `s3://{bucket}/grafana/datasources.yml`
- Prometheus datasource configured
- Loki datasource configured
- Auto-provisioned on startup

## Accessing Services

After deployment, you can access the services via their load balancer DNS names:

- **Grafana**: `http://{grafana-alb-dns}` (admin/admin123)
- **Prometheus**: `http://{prometheus-alb-dns}`
- **Loki**: `http://{loki-alb-dns}`
- **Tempo**: `http://{tempo-alb-dns}`

### Tempo Endpoints

Tempo exposes multiple endpoints for different protocols:

- **HTTP API**: Port 3200 (main API)
- **OTLP gRPC**: Port 4317 (OpenTelemetry Protocol)
- **OTLP HTTP**: Port 4318 (OpenTelemetry Protocol)
- **Jaeger gRPC**: Port 14250 (Jaeger protocol)
- **Jaeger HTTP**: Port 14268 (Jaeger protocol)
- **Jaeger UI**: Port 16686 (Jaeger UI - if needed)

## Key Differences from EFS Approach

1. **Configuration Management**: Configs are stored in S3 and downloaded at container startup
2. **No EFS Dependencies**: Eliminates the need for EFS mount targets and file system management
3. **Version Control**: S3 versioning enables configuration version tracking
4. **Cost Optimization**: S3 is typically more cost-effective than EFS for configuration storage
5. **Scalability**: S3 provides better scalability for configuration distribution

## Security

- S3 bucket has public access blocked
- IAM roles with minimal required permissions
- Security groups restrict access to necessary ports only
- All communication between services uses internal load balancers

## Monitoring Your Applications

To monitor your applications:

1. **Tag your EC2 instances** with `Name: My Node Service`
2. **Expose metrics endpoint** at `/api/metrics` on port 3000
3. **Send logs to Loki** using the Loki API endpoint
4. **Send traces to Tempo** using OTLP or Jaeger protocols

### Distributed Tracing Setup

To send traces to Tempo from your applications:

**Using OpenTelemetry (Recommended)**:
```javascript
// Node.js example
const { NodeTracerProvider } = require('@opentelemetry/sdk-trace-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

const provider = new NodeTracerProvider();
const exporter = new OTLPTraceExporter({
  url: 'http://{tempo-alb-dns}:4318/v1/traces'
});
```

**Using Jaeger**:
```javascript
// Node.js example
const { Tracer } = require('jaeger-client');

const config = {
  serviceName: 'my-service',
  sampler: {
    type: 'const',
    param: 1
  },
  reporter: {
    agentHost: '{tempo-alb-dns}',
    agentPort: 14268
  }
};
```

## Troubleshooting

### Check S3 Configuration
```bash
aws s3 ls s3://{bucket-name}/ --recursive
```

### View ECS Logs
```bash
aws logs describe-log-groups --log-group-name-prefix "/ecs/{service-prefix}"
```

### Verify Service Discovery
Check Prometheus targets page at `http://{prometheus-alb-dns}/targets`

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

**Note**: This will delete all data stored in S3 and ECS services. 