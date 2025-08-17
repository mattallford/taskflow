# TaskFlow Environment Configuration Strategy

## Overview

This document outlines the comprehensive strategy for managing TaskFlow configurations across multiple deployment environments (Development, Staging, Production) using Octopus Deploy for enterprise CI/CD pipelines.

---

## 🎯 Environment Architecture

### Environment Definitions

| Environment | Purpose | Characteristics | Target Audience |
|-------------|---------|-----------------|-----------------|
| **Development** | Active development and testing | Minimal resources, debug logging, relaxed security | Developers, QA |
| **Staging** | Pre-production validation | Production-like, performance testing | QA, Stakeholders |
| **Production** | Live customer-facing | High availability, security, monitoring | End Users |

### Deployment Flow
```
Development → Staging → Production
     ↓           ↓          ↓
  Feature     Integration  Release
   Testing     Testing     Deployment
```

---

## 🔧 Configuration Management Strategy

### 1. Variable Hierarchy

#### Global Variables (All Environments)
```yaml
# Application Identity
App.Name: "TaskFlow"
App.Description: "Modern task management application"

# Container Registry
Container.Registry: "your-registry.azurecr.io"
Container.ImagePullPolicy: "IfNotPresent"  # Override per environment if needed

# Base Resource Templates
Resources.Database.BaseImage: "postgres"
Resources.Api.BaseImage: "mcr.microsoft.com/dotnet/aspnet"
Resources.Frontend.BaseImage: "nginx"
```

#### Environment-Specific Variable Sets

**Development Environment Variables**
```yaml
# Environment Configuration
Environment.Name: "Development"
Environment.ShortName: "dev"
Kubernetes.Namespace: "taskflow-dev"

# Application Configuration
App.Version: "#{Octopus.Release.Number}-dev"
AppSettings.AspNetCoreEnvironment: "Development"
Logging.DefaultLevel: "Debug"
Logging.MicrosoftLevel: "Information"
Logging.EntityFrameworkLevel: "Information"

# Resource Allocation (Minimal)
Api.ReplicaCount: 1
Frontend.ReplicaCount: 1
Database.ReplicaCount: 1

Api.CpuRequest: "100m"
Api.MemoryRequest: "128Mi"
Api.CpuLimit: "500m"
Api.MemoryLimit: "512Mi"

Frontend.CpuRequest: "50m"
Frontend.MemoryRequest: "64Mi"
Frontend.CpuLimit: "200m"
Frontend.MemoryLimit: "256Mi"

Database.CpuRequest: "100m"
Database.MemoryRequest: "256Mi"
Database.CpuLimit: "500m"
Database.MemoryLimit: "512Mi"

# Database Configuration
Database.Name: "taskflowdb_dev"
Database.Username: "taskflow_dev"
Database.Password: "[Sensitive] dev_password_123"  # Sensitive Variable
Database.Host: "taskflow-postgres-service"
Database.Port: "5432"
Database.Timeout: "30"
Database.StorageSize: "1Gi"
Database.StorageClass: "standard"
Database.UsePersistentStorage: false  # Use emptyDir for dev

# Networking Configuration
Ingress.Hostname: "taskflow-dev.your-company.com"
Ingress.ClassName: "nginx"
Ingress.SslRedirect: false
Ingress.EnableTls: false
Ingress.ForceSslRedirect: false

# Security Configuration
Security.AllowedHosts: "*"  # Relaxed for development
Cors.AllowedOrigins: "http://localhost:3000,http://localhost:5055,http://taskflow-dev.your-company.com"
Security.EnableNetworkPolicy: false

# Monitoring and Observability
Monitoring.PrometheusEnabled: false
Monitoring.LoggingLevel: "Debug"

# Feature Flags
Features.SwaggerEnabled: true
Features.DetailedErrors: true
Features.SeedData: true
```

**Staging Environment Variables**
```yaml
# Environment Configuration
Environment.Name: "Staging"
Environment.ShortName: "staging"
Kubernetes.Namespace: "taskflow-staging"

# Application Configuration
App.Version: "#{Octopus.Release.Number}-staging"
AppSettings.AspNetCoreEnvironment: "Staging"
Logging.DefaultLevel: "Information"
Logging.MicrosoftLevel: "Warning"
Logging.EntityFrameworkLevel: "Warning"

# Resource Allocation (Moderate)
Api.ReplicaCount: 2
Frontend.ReplicaCount: 2
Database.ReplicaCount: 1

Api.CpuRequest: "200m"
Api.MemoryRequest: "256Mi"
Api.CpuLimit: "1000m"
Api.MemoryLimit: "1Gi"

Frontend.CpuRequest: "100m"
Frontend.MemoryRequest: "128Mi"
Frontend.CpuLimit: "500m"
Frontend.MemoryLimit: "512Mi"

Database.CpuRequest: "200m"
Database.MemoryRequest: "512Mi"
Database.CpuLimit: "1000m"
Database.MemoryLimit: "1Gi"

# Database Configuration
Database.Name: "taskflowdb_staging"
Database.Username: "taskflow_staging"
Database.Password: "[Sensitive] staging_secure_password"  # Sensitive Variable
Database.Host: "taskflow-postgres-service"
Database.Port: "5432"
Database.Timeout: "60"
Database.StorageSize: "10Gi"
Database.StorageClass: "ssd"
Database.UsePersistentStorage: true

# Networking Configuration
Ingress.Hostname: "taskflow-staging.your-company.com"
Ingress.ClassName: "nginx"
Ingress.SslRedirect: true
Ingress.EnableTls: true
Ingress.TlsSecretName: "taskflow-staging-tls"
Ingress.TlsIssuer: "letsencrypt-staging"

# Security Configuration
Security.AllowedHosts: "taskflow-staging.your-company.com"
Cors.AllowedOrigins: "https://taskflow-staging.your-company.com"
Security.EnableNetworkPolicy: true

# Monitoring and Observability
Monitoring.PrometheusEnabled: true
Monitoring.MetricsPort: "8080"
Monitoring.MetricsPath: "/metrics"

# Feature Flags
Features.SwaggerEnabled: true
Features.DetailedErrors: false
Features.SeedData: false
```

**Production Environment Variables**
```yaml
# Environment Configuration
Environment.Name: "Production"
Environment.ShortName: "prod"
Kubernetes.Namespace: "taskflow-prod"

# Application Configuration
App.Version: "#{Octopus.Release.Number}"
AppSettings.AspNetCoreEnvironment: "Production"
Logging.DefaultLevel: "Warning"
Logging.MicrosoftLevel: "Error"
Logging.EntityFrameworkLevel: "Error"

# Resource Allocation (High Availability)
Api.ReplicaCount: 3
Frontend.ReplicaCount: 3
Database.ReplicaCount: 1  # Consider HA setup for critical production

Api.CpuRequest: "500m"
Api.MemoryRequest: "512Mi"
Api.CpuLimit: "2000m"
Api.MemoryLimit: "2Gi"

Frontend.CpuRequest: "200m"
Frontend.MemoryRequest: "256Mi"
Frontend.CpuLimit: "1000m"
Frontend.MemoryLimit: "1Gi"

Database.CpuRequest: "500m"
Database.MemoryRequest: "1Gi"
Database.CpuLimit: "2000m"
Database.MemoryLimit: "4Gi"

# Database Configuration
Database.Name: "taskflowdb_prod"
Database.Username: "taskflow_prod"
Database.Password: "[Sensitive] production_complex_password_2024!"  # Sensitive Variable
Database.Host: "taskflow-postgres-service"
Database.Port: "5432"
Database.Timeout: "120"
Database.StorageSize: "100Gi"
Database.StorageClass: "premium-ssd"
Database.UsePersistentStorage: true

# Networking Configuration
Ingress.Hostname: "taskflow.your-company.com"
Ingress.ClassName: "nginx"
Ingress.SslRedirect: true
Ingress.EnableTls: true
Ingress.ForceSslRedirect: true
Ingress.TlsSecretName: "taskflow-prod-tls"
Ingress.TlsIssuer: "letsencrypt-prod"

# Security Configuration
Security.AllowedHosts: "taskflow.your-company.com"
Cors.AllowedOrigins: "https://taskflow.your-company.com"
Security.EnableNetworkPolicy: true
Security.ApiKey: "[Sensitive] prod_api_key_2024"  # Sensitive Variable
Security.JwtSecret: "[Sensitive] prod_jwt_secret_complex_key"  # Sensitive Variable

# Monitoring and Observability
Monitoring.PrometheusEnabled: true
Monitoring.MetricsPort: "8080"
Monitoring.MetricsPath: "/metrics"
Monitoring.AlertingEnabled: true

# Feature Flags
Features.SwaggerEnabled: false  # Disabled in production
Features.DetailedErrors: false
Features.SeedData: false

# Performance Configuration
Api.DeploymentStrategy: "RollingUpdate"
Api.MaxSurge: "25%"
Api.MaxUnavailable: "25%"
Frontend.DeploymentStrategy: "RollingUpdate"
Frontend.MaxSurge: "50%"
Frontend.MaxUnavailable: "0"

# Health Check Configuration (Stricter in production)
Api.LivenessInitialDelay: 90
Api.LivenessPeriod: 60
Api.LivenessTimeout: 15
Api.LivenessFailures: 3
Api.ReadinessInitialDelay: 15
Api.ReadinessPeriod: 30
Api.ReadinessTimeout: 10
Api.ReadinessFailures: 3
```

---

## 🔐 Secret Management Strategy

### Octopus Deploy Sensitive Variables

#### Database Secrets
```
Database.Password.Dev = [Sensitive] dev_password_123
Database.Password.Staging = [Sensitive] staging_secure_password
Database.Password.Production = [Sensitive] production_complex_password_2024!

Database.ConnectionString.Dev = [Sensitive] Host=...;Database=taskflowdb_dev;...
Database.ConnectionString.Staging = [Sensitive] Host=...;Database=taskflowdb_staging;...
Database.ConnectionString.Production = [Sensitive] Host=...;Database=taskflowdb_prod;...
```

#### API Secrets
```
Security.ApiKey.Production = [Sensitive] prod_api_key_2024
Security.JwtSecret.Production = [Sensitive] prod_jwt_secret_complex_key
```

#### TLS Certificates
```
Ingress.TlsCertificate.Staging = [Sensitive] -----BEGIN CERTIFICATE-----...
Ingress.TlsCertificate.Production = [Sensitive] -----BEGIN CERTIFICATE-----...
Ingress.TlsPrivateKey.Staging = [Sensitive] -----BEGIN PRIVATE KEY-----...
Ingress.TlsPrivateKey.Production = [Sensitive] -----BEGIN PRIVATE KEY-----...
```

### External Secret Management Integration

For enterprise environments, integrate with external secret management:

#### AWS Secrets Manager
```yaml
# Example: External Secrets Operator
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: taskflow-secrets
spec:
  secretStoreRef:
    name: aws-secret-store
    kind: SecretStore
  target:
    name: taskflow-secrets
  data:
  - secretKey: postgres-password
    remoteRef:
      key: "taskflow/#{Environment.Name}/database/password"
```

#### Azure Key Vault
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: taskflow-secrets
spec:
  secretStoreRef:
    name: azure-keyvault
    kind: SecretStore
  target:
    name: taskflow-secrets
  data:
  - secretKey: postgres-password
    remoteRef:
      key: "taskflow-#{Environment.Name}-db-password"
```

---

## 🚀 Deployment Strategies

### Development Environment
- **Strategy**: Direct deployment from feature branches
- **Testing**: Unit tests, integration tests
- **Rollback**: Simple redeployment
- **Monitoring**: Basic logging, no alerting

### Staging Environment
- **Strategy**: Deployment from release candidates
- **Testing**: Full regression testing, performance testing
- **Rollback**: Automated rollback on failure
- **Monitoring**: Full monitoring stack, staging alerts

### Production Environment
- **Strategy**: Blue-green or canary deployment
- **Testing**: Smoke tests, health checks
- **Rollback**: Immediate rollback capability
- **Monitoring**: Full observability, production alerting

---

## 📊 Resource Planning

### Compute Resources by Environment

| Resource | Development | Staging | Production |
|----------|-------------|---------|------------|
| **API Pods** | 1 × (100m CPU, 128Mi RAM) | 2 × (200m CPU, 256Mi RAM) | 3 × (500m CPU, 512Mi RAM) |
| **Frontend Pods** | 1 × (50m CPU, 64Mi RAM) | 2 × (100m CPU, 128Mi RAM) | 3 × (200m CPU, 256Mi RAM) |
| **Database Pods** | 1 × (100m CPU, 256Mi RAM) | 1 × (200m CPU, 512Mi RAM) | 1 × (500m CPU, 1Gi RAM) |
| **Storage** | 1Gi (emptyDir) | 10Gi (SSD) | 100Gi (Premium SSD) |

### Network Configuration

| Setting | Development | Staging | Production |
|---------|-------------|---------|------------|
| **Hostname** | taskflow-dev.company.com | taskflow-staging.company.com | taskflow.company.com |
| **TLS** | Disabled | Let's Encrypt Staging | Let's Encrypt Production |
| **Network Policy** | Disabled | Enabled | Enabled |
| **CORS Origins** | Wildcard allowed | Staging domain only | Production domain only |

---

## 🔄 CI/CD Pipeline Integration

### Octopus Deploy Project Structure

```
TaskFlow Project
├── Development Environment
│   ├── Variable Set: TaskFlow-Development
│   ├── Sensitive Variables: TaskFlow-Dev-Secrets
│   └── Deployment Process: Deploy-Development
├── Staging Environment
│   ├── Variable Set: TaskFlow-Staging
│   ├── Sensitive Variables: TaskFlow-Staging-Secrets
│   └── Deployment Process: Deploy-Staging
└── Production Environment
    ├── Variable Set: TaskFlow-Production
    ├── Sensitive Variables: TaskFlow-Production-Secrets
    └── Deployment Process: Deploy-Production
```

### Deployment Process Steps

#### 1. Pre-deployment Validation
```powershell
# Validate prerequisites
if ($OctopusParameters["Environment.Name"] -eq "Production") {
    if (-not $OctopusParameters["Security.ProductionApproval"]) {
        throw "Production deployment requires approval"
    }
}
```

#### 2. Container Image Preparation
```bash
# Tag images with environment-specific tags
docker tag taskflow-api:latest $CONTAINER_REGISTRY/taskflow-api:$OCTOPUS_RELEASE_NUMBER
docker tag taskflow-web:latest $CONTAINER_REGISTRY/taskflow-web:$OCTOPUS_RELEASE_NUMBER
```

#### 3. Kubernetes Deployment
```bash
# Deploy using parameterized manifests
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f postgres.yaml
kubectl apply -f api.yaml
kubectl apply -f frontend.yaml
kubectl apply -f ingress.yaml
```

#### 4. Post-deployment Validation
```bash
# Health checks and smoke tests
curl -f "https://#{Ingress.Hostname}/health"
kubectl wait --for=condition=available deployment/taskflow-api -n #{Kubernetes.Namespace}
```

#### 5. Rollback Process
```bash
# Automated rollback on failure
if [ $DEPLOYMENT_FAILED ]; then
    kubectl rollout undo deployment/taskflow-api -n #{Kubernetes.Namespace}
    kubectl rollout undo deployment/taskflow-frontend -n #{Kubernetes.Namespace}
fi
```

---

## 🏗️ Infrastructure as Code

### Terraform Environment Management

```hcl
# environments/development/main.tf
module "taskflow_dev" {
  source = "../../modules/taskflow"
  
  environment = "development"
  namespace   = "taskflow-dev"
  replicas = {
    api      = 1
    frontend = 1
    database = 1
  }
  resources = {
    api_cpu_request      = "100m"
    api_memory_request   = "128Mi"
    api_cpu_limit        = "500m"
    api_memory_limit     = "512Mi"
  }
}
```

### Helm Chart Alternative

```yaml
# values-development.yaml
environment: development
namespace: taskflow-dev

api:
  replicaCount: 1
  image:
    tag: "#{Octopus.Release.Number}-dev"
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi

database:
  persistence:
    enabled: false
    size: 1Gi
```

---

## 📈 Monitoring and Observability Strategy

### Logging Configuration by Environment

| Environment | Log Level | Destinations | Retention |
|-------------|-----------|--------------|-----------|
| **Development** | Debug | Console, File | 7 days |
| **Staging** | Information | Console, ELK Stack | 30 days |
| **Production** | Warning | ELK Stack, SIEM | 90 days |

### Metrics and Alerting

#### Development
- Basic application metrics
- No alerting
- Manual monitoring

#### Staging
- Full application metrics
- Performance metrics
- Non-critical alerting

#### Production
- Application metrics
- Infrastructure metrics
- Business metrics
- Critical alerting with PagerDuty

---

## 🔒 Security Considerations

### Environment-Specific Security

#### Development
- Relaxed CORS policies
- Swagger UI enabled
- Detailed error messages
- No network policies
- Self-signed certificates

#### Staging
- Production-like security
- Limited CORS origins
- Swagger UI enabled
- Network policies enforced
- Let's Encrypt staging certificates

#### Production
- Strict security policies
- Single origin CORS
- Swagger UI disabled
- Comprehensive network policies
- Production TLS certificates
- Security scanning enabled
- Audit logging enabled

### Compliance and Governance

- **Data Classification**: Environment-specific data handling
- **Access Control**: Role-based access per environment
- **Audit Trail**: All changes tracked and logged
- **Backup Strategy**: Environment-appropriate backup policies

---

## 🎯 Success Metrics

### Development Environment
- **Deployment Frequency**: Multiple times per day
- **Lead Time**: < 1 hour from commit to deployment
- **Recovery Time**: < 15 minutes
- **Success Rate**: > 95%

### Staging Environment
- **Deployment Frequency**: Daily
- **Lead Time**: < 2 hours from development
- **Recovery Time**: < 30 minutes
- **Success Rate**: > 98%

### Production Environment
- **Deployment Frequency**: Weekly/Bi-weekly
- **Lead Time**: < 4 hours from staging approval
- **Recovery Time**: < 5 minutes (rollback)
- **Success Rate**: > 99.9%

---

## 📋 Implementation Checklist

### Phase 1: Foundation (Week 1)
- [ ] Define Octopus Deploy variable sets
- [ ] Create environment-specific configurations
- [ ] Implement sensitive variable management
- [ ] Set up basic deployment processes

### Phase 2: Security and Compliance (Week 2)
- [ ] Implement external secret management
- [ ] Configure network policies
- [ ] Set up TLS certificates
- [ ] Establish audit logging

### Phase 3: Monitoring and Observability (Week 3)
- [ ] Deploy monitoring stack
- [ ] Configure alerting rules
- [ ] Set up log aggregation
- [ ] Implement health checks

### Phase 4: Advanced Features (Week 4)
- [ ] Implement blue-green deployment
- [ ] Set up automated rollbacks
- [ ] Configure performance monitoring
- [ ] Establish disaster recovery procedures

---

**Document Version**: 1.0  
**Last Updated**: $(date)  
**Next Review**: $(date -d '+3 months')  
**Owner**: Platform Engineering Team