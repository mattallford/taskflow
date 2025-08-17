# TaskFlow API Dockerfile
# Multi-stage build for production-ready .NET 9.0 application

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy solution and project files for dependency restoration
COPY TaskFlow.sln ./
COPY src/TaskFlow.Api/TaskFlow.Api.csproj src/TaskFlow.Api/
COPY src/TaskFlow.Core/TaskFlow.Core.csproj src/TaskFlow.Core/
COPY src/TaskFlow.Infrastructure/TaskFlow.Infrastructure.csproj src/TaskFlow.Infrastructure/
COPY src/TaskFlow.Tests/TaskFlow.Tests.csproj src/TaskFlow.Tests/

# Restore dependencies for all projects
RUN dotnet restore TaskFlow.sln

# Copy source code
COPY src/ src/

# Build and publish the API project
WORKDIR /src/src/TaskFlow.Api
RUN dotnet publish TaskFlow.Api.csproj \
    -c Release \
    -o /app/publish \
    --no-restore \
    --self-contained false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final

# Install curl for health checks
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r taskflow && useradd -r -g taskflow taskflow

# Set working directory
WORKDIR /app

# Copy published application
COPY --from=build /app/publish .

# Change ownership to non-root user
RUN chown -R taskflow:taskflow /app

# Switch to non-root user
USER taskflow

# Expose port 8080 (container standard for non-root)
EXPOSE 8080

# Configure ASP.NET Core to listen on port 8080
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
ENV DOTNET_RUNNING_IN_CONTAINER=true
ENV DOTNET_EnableDiagnostics=0

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Entry point
ENTRYPOINT ["dotnet", "TaskFlow.Api.dll"]