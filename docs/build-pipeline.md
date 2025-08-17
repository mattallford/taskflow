# TaskFlow Container Build Pipeline

## Overview

This document describes the containerized build pipeline for TaskFlow, including Docker configuration, GitHub Actions workflows, and container registry integration.

## Architecture

```
TaskFlow Build Pipeline
├── API Container (taskflow-api)
│   ├── Multi-stage .NET 9.0 build
│   ├── Security hardening
│   └── Health checks
├── Web Container (taskflow-web)  
│   ├── Multi-stage React build
│   ├── Nginx production server
│   └── Static asset optimization
└── CI/CD Pipeline
    ├── Automated testing
    ├── Container builds
    ├── Security scanning
    └── Registry publishing
```

## Container Images

### API Container (`taskflow-api`)

**Base Images:**
- Build: `mcr.microsoft.com/dotnet/sdk:9.0`
- Runtime: `mcr.microsoft.com/dotnet/aspnet:9.0`

**Features:**
- Multi-stage build for optimized image size
- Non-root user execution (security)
- Health check endpoint integration
- Ready-to-run compilation for faster startup
- Proper .dockerignore for efficient builds

**Build Context:** Repository root (for solution-wide dependencies)
**Dockerfile Location:** `src/TaskFlow.Api/Dockerfile`

### Web Container (`taskflow-web`)

**Base Images:**
- Build: `node:20-alpine`
- Runtime: `nginx:1.25-alpine`

**Features:**
- Multi-stage build separating build and runtime
- Production-optimized React build
- Nginx with security headers and gzip compression
- Non-root nginx execution
- Asset caching and compression

**Build Context:** `src/TaskFlow.Web/`
**Dockerfile Location:** `src/TaskFlow.Web/Dockerfile`

## Docker Configuration

### File Structure
```
src/
├── TaskFlow.Api/
│   ├── Dockerfile
│   └── .dockerignore
└── TaskFlow.Web/
    ├── Dockerfile
    ├── .dockerignore
    └── nginx.conf
```

### Security Features

1. **Non-root Execution**
   - API runs as `taskflow` user (UID 1001)
   - Web runs as `nginx` user (UID 101)

2. **Minimal Attack Surface**
   - Alpine Linux where possible
   - No unnecessary packages
   - Proper file permissions

3. **Health Checks**
   - API: HTTP health endpoint
   - Web: Static content availability

## GitHub Actions Workflow

### Simplified Build Workflow (`.github/workflows/build.yml`)

**Triggers:**
- Push to `main` and `develop` branches
- Pull requests to `main`

**Single Job: `test-and-build`**

**Steps:**
1. **Testing Phase**
   - .NET 9.0 setup and dependency restoration
   - .NET solution build and unit tests
   - Node.js 20 setup and React frontend tests

2. **Container Build Phase**
   - Docker Buildx setup with caching
   - Docker Hub authentication (push events only)
   - API container build and push (AMD64)
   - Web container build and push (AMD64)
   - Build summary generation

## Container Registry Integration

### Docker Hub Configuration

**Registry:** `docker.io`
**Images:**
- `[username]/taskflow-api`
- `[username]/taskflow-web`

**Required Secrets:**
```yaml
DOCKER_USERNAME: Docker Hub username
DOCKER_PASSWORD: Docker Hub access token
```

### Image Tagging Strategy

**Tags Generated:**
- `latest` (all pushes to main/develop)
- `[commit-sha]` (specific commit identifier)

**Example:**
```
taskflow-api:latest
taskflow-api:abc1234567890abcdef1234567890abcdef1234
taskflow-web:latest
taskflow-web:abc1234567890abcdef1234567890abcdef1234
```

## Local Development

### Building Containers Locally

**API Container:**
```bash
# From repository root
docker build -f src/TaskFlow.Api/Dockerfile -t taskflow-api:local .
```

**Web Container:**
```bash
# From web directory
cd src/TaskFlow.Web
docker build -t taskflow-web:local .
```

### Running Containers

**API Container:**
```bash
docker run -p 8080:8080 taskflow-api:local
```

**Web Container:**
```bash
docker run -p 3000:3000 taskflow-web:local
```

## Configuration

### Environment Variables

**API Container:**
```bash
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:8080
DOTNET_RUNNING_IN_CONTAINER=true
DOTNET_EnableDiagnostics=0
```

**Web Container:**
- No runtime environment variables (static build)
- Configuration embedded during build process

### Ports

| Service | Container Port | Description |
|---------|----------------|-------------|
| API | 8080 | HTTP API endpoint |
| Web | 3000 | Nginx static server |

### Health Checks

**API Health Check:**
- Endpoint: `http://localhost:8080/health`
- Interval: 30s
- Timeout: 10s
- Start period: 30s
- Retries: 3

**Web Health Check:**
- Endpoint: `http://localhost:3000/`
- Interval: 30s
- Timeout: 10s
- Start period: 10s
- Retries: 3

## Security Considerations

### Container Security

1. **Non-root Execution**
   - All containers run as non-root users
   - Proper file ownership and permissions

2. **Minimal Base Images**
   - Alpine Linux for reduced attack surface
   - Only necessary packages installed

3. **Basic Security**
   - Health checks for container monitoring
   - Secure base image selection

### Network Security

1. **Port Configuration**
   - Non-privileged ports (8080, 3000)
   - No unnecessary port exposure

2. **Communication**
   - HTTP within container network
   - TLS termination at ingress layer

## Monitoring and Observability

### Build Metrics

1. **GitHub Actions**
   - Build success/failure rates
   - Build duration tracking
   - Test execution results

2. **Container Metrics**
   - Image build times
   - Image size tracking
   - Push success rates

### Logging

1. **Build Logs**
   - GitHub Actions workflow logs
   - Container build output
   - Test execution results

2. **Runtime Logs**
   - Application logs via stdout/stderr
   - Nginx access/error logs
   - Health check monitoring

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check dependency compatibility
   - Verify base image availability
   - Review .dockerignore patterns

2. **Size Optimization**
   - Review multi-stage build efficiency
   - Check for unnecessary files
   - Optimize layer caching

3. **Security Scan Failures**
   - Update base images regularly
   - Review vulnerability reports
   - Implement security patches

### Debug Commands

**Check container layers:**
```bash
docker history taskflow-api:latest
```

**Inspect container:**
```bash
docker inspect taskflow-api:latest
```

**Test health checks:**
```bash
docker run --rm taskflow-api:latest curl -f http://localhost:8080/health
```

## Future Enhancements

### Potential Improvements

1. **Advanced Security**
   - Container vulnerability scanning
   - Supply chain security (SBOM)
   - Image signing and verification

2. **Build Optimization**
   - Multi-architecture builds (ARM64)
   - Advanced layer caching
   - Build parallelization

3. **Enhanced CI/CD**
   - Integration testing with containers
   - Automated deployment pipelines
   - Blue-green deployment support

---

**Document Version:** 1.0  
**Last Updated:** $(date)  
**Next Review:** $(date -d '+1 month')  
**Owner:** Platform Engineering Team