# Octopus Deploy Configuration

## Overview

The Kubernetes manifests in `/deploy/k8s/` are configured for development environment deployment and can be deployed directly using Octopus Deploy.

## File Pattern

Configure Octopus Deploy to target: `deploy/k8s/*.yaml`

## Static Configuration

All manifests are hard-coded for the development environment:
- **Namespace**: `taskflow-dev`
- **Hostname**: `taskflow-dev.local`
- **Database**: `taskflowdb-dev`
- **Image Tags**: `latest`
- **Resource Limits**: Development-appropriate sizes

## Deployment Process

1. Use "Deploy Kubernetes containers" step
2. Set file pattern to `deploy/k8s/*.yaml`
3. Deploy directly without variable substitution
4. No additional configuration required

## Files Included

- `namespace.yaml` - Creates taskflow-dev namespace
- `secret.yaml` - Database credentials and connection string
- `configmap.yaml` - Application configuration
- `postgres.yaml` - PostgreSQL database deployment
- `api.yaml` - TaskFlow API deployment
- `frontend.yaml` - TaskFlow Web frontend deployment
- `ingress.yaml` - Nginx ingress routing

## Access URLs

After deployment:
- **Frontend**: http://taskflow-dev.local
- **API**: http://taskflow-dev.local/api
- **Health**: http://taskflow-dev.local/health
- **Swagger**: http://taskflow-dev.local/swagger

## Resource Allocation

Optimized for development environment:
- **PostgreSQL**: 100m CPU, 128Mi RAM (limit: 300m CPU, 256Mi RAM)
- **API**: 100m CPU, 128Mi RAM (limit: 500m CPU, 256Mi RAM)
- **Frontend**: 50m CPU, 64Mi RAM (limit: 200m CPU, 128Mi RAM)