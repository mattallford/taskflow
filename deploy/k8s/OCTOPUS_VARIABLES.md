# Octopus Deploy Variables - Simplified

This document describes the essential variables required for Octopus Deploy to correctly substitute values in the Kubernetes manifests.

## Required Variables (Only 6!)

| Variable | Description | Example Values |
|----------|-------------|----------------|
| `#{Namespace}` | Kubernetes namespace for deployment | `taskflow-dev`, `taskflow-test`, `taskflow-prod` |
| `#{Environment}` | ASP.NET Core environment setting | `Development`, `Staging`, `Production` |
| `#{ImageTag}` | Container image tag for both API and Web images | `latest`, `v1.0.0`, `#{Octopus.Release.Number}` |
| `#{DatabaseName}` | PostgreSQL database name | `taskflowdb-dev`, `taskflowdb-test`, `taskflowdb-prod` |
| `#{ReplicaCount}` | Number of replicas for API and Frontend | `1` (dev/test), `2` (prod) |
| `#{IngressHost}` | Ingress hostname | `taskflow-dev.local`, `taskflow-test.local`, `taskflow.local` |
| `#{ConnectionString}` | Database connection string (Base64 encoded) | See examples below |

## Static Values (No Variables Needed)
- **Resource Limits**: Fixed at reasonable defaults
- **Application Name/Version**: Static "TaskFlow" and "1.0.0"
- **Database Timeout**: Fixed at 30 seconds
- **PostgreSQL Credentials**: Fixed username/password (taskflow/taskflow123)

## Environment-Specific Examples

### Development Environment
```
Namespace = taskflow-dev
Environment = Development
ImageTag = latest
DatabaseName = taskflowdb-dev
ReplicaCount = 1
IngressHost = taskflow-dev.local
ConnectionString = SG9zdD10YXNrZmxvdy1wb3N0Z3Jlcy1zZXJ2aWNlO0RhdGFiYXNlPXRhc2tmbG93ZGItZGV2O1VzZXJuYW1lPXRhc2tmbG93O1Bhc3N3b3JkPXRhc2tmbG93MTIz
```

### Test Environment
```
Namespace = taskflow-test
Environment = Staging
ImageTag = #{Octopus.Release.Number}
DatabaseName = taskflowdb-test
ReplicaCount = 1
IngressHost = taskflow-test.local
ConnectionString = SG9zdD10YXNrZmxvdy1wb3N0Z3Jlcy1zZXJ2aWNlO0RhdGFiYXNlPXRhc2tmbG93ZGItdGVzdDtVc2VybmFtZT10YXNrZmxvdztQYXNzd29yZD10YXNrZmxvdzEyMw==
```

### Production Environment
```
Namespace = taskflow-prod
Environment = Production
ImageTag = #{Octopus.Release.Number}
DatabaseName = taskflowdb-prod
ReplicaCount = 2
IngressHost = taskflow.local
ConnectionString = SG9zdD10YXNrZmxvdy1wb3N0Z3Jlcy1zZXJ2aWNlO0RhdGFiYXNlPXRhc2tmbG93ZGItcHJvZDtVc2VybmFtZT10YXNrZmxvdztQYXNzd29yZD10YXNrZmxvdzEyMw==
```

## Connection String Examples (Base64 Encoded)

### Development
```
Raw: Host=taskflow-postgres-service;Database=taskflowdb-dev;Username=taskflow;Password=taskflow123
Base64: SG9zdD10YXNrZmxvdy1wb3N0Z3Jlcy1zZXJ2aWNlO0RhdGFiYXNlPXRhc2tmbG93ZGItZGV2O1VzZXJuYW1lPXRhc2tmbG93O1Bhc3N3b3JkPXRhc2tmbG93MTIz
```

### Test
```
Raw: Host=taskflow-postgres-service;Database=taskflowdb-test;Username=taskflow;Password=taskflow123
Base64: SG9zdD10YXNrZmxvdy1wb3N0Z3Jlcy1zZXJ2aWNlO0RhdGFiYXNlPXRhc2tmbG93ZGItdGVzdDtVc2VybmFtZT10YXNrZmxvdztQYXNzd29yZD10YXNrZmxvdzEyMw==
```

### Production
```
Raw: Host=taskflow-postgres-service;Database=taskflowdb-prod;Username=taskflow;Password=taskflow123
Base64: SG9zdD10YXNrZmxvdy1wb3N0Z3Jlcy1zZXJ2aWNlO0RhdGFiYXNlPXRhc2tmbG93ZGItcHJvZDtVc2VybmFtZT10YXNrZmxvdztQYXNzd29yZD10YXNrZmxvdzEyMw==
```

## Octopus Deploy Setup

### Variable Sets
Use scoped variables for each environment:

| Variable | Dev | Test | Prod |
|----------|-----|------|------|
| Namespace | taskflow-dev | taskflow-test | taskflow-prod |
| Environment | Development | Staging | Production |
| ImageTag | latest | #{Octopus.Release.Number} | #{Octopus.Release.Number} |
| DatabaseName | taskflowdb-dev | taskflowdb-test | taskflowdb-prod |
| ReplicaCount | 1 | 1 | 2 |
| IngressHost | taskflow-dev.local | taskflow-test.local | taskflow.local |

### Deployment Process
1. Use "Deploy Kubernetes containers" step
2. Configure variable substitution in YAML files
3. Set package feed to Docker Hub (mattallford)
4. Ensure environment scoping for all variables

This simplified approach reduces complexity while maintaining environment flexibility.