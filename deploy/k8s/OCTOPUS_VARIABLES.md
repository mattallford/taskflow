# Octopus Deploy Structured Variables

This document describes the structured variable paths required for Octopus Deploy to replace values in the Kubernetes manifests using the structured variable replacement feature.

## Overview

The manifests in `/deploy/k8s/` contain valid YAML with default values that can be replaced by Octopus Deploy using structured variable replacement. This approach is preferred over template syntax as it maintains valid YAML that can be deployed independently.

Reference: [Structured Variables in Raw Kubernetes YAML](https://octopus.com/blog/structured-variables-raw-kubernetes-yaml)

## Required Structured Variables

### Namespace Configuration
**File**: `namespace.yaml`
| Variable Path | Default Value | Description |
|---------------|---------------|-------------|
| `metadata.name` | `taskflow-dev` | Kubernetes namespace name |
| `metadata.labels.environment` | `dev` | Environment label |

### Secret Configuration
**File**: `secret.yaml`
| Variable Path | Default Value | Description |
|---------------|---------------|-------------|
| `metadata.namespace` | `taskflow-dev` | Target namespace |
| `data.connection-string` | Base64 dev connection | Database connection string (Base64) |

### ConfigMap Configuration
**File**: `configmap.yaml`
| Variable Path | Default Value | Description |
|---------------|---------------|-------------|
| `metadata.namespace` | `taskflow-dev` | Target namespace |
| `data.ASPNETCORE_ENVIRONMENT` | `Development` | ASP.NET Core environment |

### PostgreSQL Deployment
**File**: `postgres.yaml`
| Variable Path | Default Value | Description |
|---------------|---------------|-------------|
| `metadata.namespace` | `taskflow-dev` | Target namespace |
| `spec.template.spec.containers[0].env[0].value` | `taskflowdb-dev` | PostgreSQL database name |
| `spec.template.spec.containers[0].livenessProbe.exec.command[3]` | `taskflowdb-dev` | Liveness probe database name |
| `spec.template.spec.containers[0].readinessProbe.exec.command[3]` | `taskflowdb-dev` | Readiness probe database name |

### API Deployment
**File**: `api.yaml`
| Variable Path | Default Value | Description |
|---------------|---------------|-------------|
| `metadata.namespace` | `taskflow-dev` | Target namespace |
| `spec.replicas` | `1` | Number of API replicas |
| `spec.template.spec.containers[0].image` | `mattallford/taskflow-api:latest` | Container image with tag |

### Frontend Deployment
**File**: `frontend.yaml`
| Variable Path | Default Value | Description |
|---------------|---------------|-------------|
| `metadata.namespace` | `taskflow-dev` | Target namespace |
| `spec.replicas` | `1` | Number of frontend replicas |
| `spec.template.spec.containers[0].image` | `mattallford/taskflow-web:latest` | Container image with tag |

### Ingress Configuration
**File**: `ingress.yaml`
| Variable Path | Default Value | Description |
|---------------|---------------|-------------|
| `metadata.namespace` | `taskflow-dev` | Target namespace |
| `spec.rules[0].host` | `taskflow-dev.local` | Ingress hostname |

## Environment-Specific Variable Examples

### Development Environment
```json
{
  "metadata.name": "taskflow-dev",
  "metadata.labels.environment": "dev",
  "metadata.namespace": "taskflow-dev",
  "data.ASPNETCORE_ENVIRONMENT": "Development",
  "data.connection-string": "SG9zdD10YXNrZmxvdy1wb3N0Z3Jlcy1zZXJ2aWNlO0RhdGFiYXNlPXRhc2tmbG93ZGItZGV2O1VzZXJuYW1lPXRhc2tmbG93O1Bhc3N3b3JkPXRhc2tmbG93MTIz",
  "spec.template.spec.containers[0].env[0].value": "taskflowdb-dev",
  "spec.template.spec.containers[0].livenessProbe.exec.command[3]": "taskflowdb-dev",
  "spec.template.spec.containers[0].readinessProbe.exec.command[3]": "taskflowdb-dev",
  "spec.replicas": 1,
  "spec.template.spec.containers[0].image": "mattallford/taskflow-api:latest",
  "spec.rules[0].host": "taskflow-dev.local"
}
```

### Test Environment
```json
{
  "metadata.name": "taskflow-test",
  "metadata.labels.environment": "test",
  "metadata.namespace": "taskflow-test",
  "data.ASPNETCORE_ENVIRONMENT": "Staging",
  "data.connection-string": "SG9zdD10YXNrZmxvdy1wb3N0Z3Jlcy1zZXJ2aWNlO0RhdGFiYXNlPXRhc2tmbG93ZGItdGVzdDtVc2VybmFtZT10YXNrZmxvdztQYXNzd29yZD10YXNrZmxvdzEyMw==",
  "spec.template.spec.containers[0].env[0].value": "taskflowdb-test",
  "spec.template.spec.containers[0].livenessProbe.exec.command[3]": "taskflowdb-test",
  "spec.template.spec.containers[0].readinessProbe.exec.command[3]": "taskflowdb-test",
  "spec.replicas": 1,
  "spec.template.spec.containers[0].image": "mattallford/taskflow-api:#{Octopus.Release.Number}",
  "spec.rules[0].host": "taskflow-test.local"
}
```

### Production Environment
```json
{
  "metadata.name": "taskflow-prod",
  "metadata.labels.environment": "prod",
  "metadata.namespace": "taskflow-prod",
  "data.ASPNETCORE_ENVIRONMENT": "Production",
  "data.connection-string": "SG9zdD10YXNrZmxvdy1wb3N0Z3Jlcy1zZXJ2aWNlO0RhdGFiYXNlPXRhc2tmbG93ZGItcHJvZDtVc2VybmFtZT10YXNrZmxvdztQYXNzd29yZD10YXNrZmxvdzEyMw==",
  "spec.template.spec.containers[0].env[0].value": "taskflowdb-prod",
  "spec.template.spec.containers[0].livenessProbe.exec.command[3]": "taskflowdb-prod",
  "spec.template.spec.containers[0].readinessProbe.exec.command[3]": "taskflowdb-prod",
  "spec.replicas": 2,
  "spec.template.spec.containers[0].image": "mattallford/taskflow-api:#{Octopus.Release.Number}",
  "spec.rules[0].host": "taskflow.local"
}
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

## Octopus Deploy Configuration

### 1. Enable Structured Configuration Variables
In your deployment step:
1. Go to **Features** tab
2. Enable "**Structured Configuration Variables**"
3. Set target files to: `*.yaml`

### 2. Define Variables
Create project variables with the exact paths shown above. Use environment scoping for environment-specific values.

### 3. Variable Naming Convention
- Use dot notation for nested JSON paths
- Array indices use square brackets: `[0]`, `[1]`, etc.
- Scope variables to appropriate environments

### 4. Deployment Process
1. Package your Kubernetes manifests
2. Use "Deploy Kubernetes containers" step  
3. Configure structured variable replacement
4. Deploy to target environment

## Benefits of This Approach

1. **Valid YAML**: Manifests are always syntactically correct
2. **Testable**: Can be deployed without Octopus for testing
3. **Maintainable**: Clear separation between defaults and overrides
4. **Flexible**: Full JSON path access to any YAML property
5. **Debuggable**: Easy to verify variable replacements

## Testing Variable Replacement

Use Octopus variable preview feature to verify that variables are being replaced correctly before deployment.