# TaskFlow

A simple task management application built with .NET 9, React, and PostgreSQL. Containerized and ready for Kubernetes deployment.
vrv
## Tech Stack

- **Backend**: .NET 9 Web API, Entity Framework Core, PostgreSQL
- **Frontend**: React 18, TypeScript
- **Infrastructure**: Docker, Kubernetes, GitHub Actions

## Quick Start

### Using Kubernetes (Recommended)

```bash
# Deploy to dev environment
kubectl apply -k deploy/k8s/overlays/dev

# Deploy to test environment  
kubectl apply -k deploy/k8s/overlays/test
```

Access the application:
- **Web App**: http://taskflow-dev.local or http://taskflow-test.local
- **API**: http://taskflow-dev.local/api
- **Health Check**: http://taskflow-dev.local/health

### Local Development

**Backend:**
```bash
cd src/TaskFlow.Api
dotnet run
```

**Frontend:**
```bash
cd src/TaskFlow.Web
npm install
npm start
```

## API Endpoints

- `GET /api/tasks` - List all tasks
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/{id}` - Update task
- `DELETE /api/tasks/{id}` - Delete task
- `GET /health` - Health check

## Features

- Create, read, update, delete tasks
- Task status workflow (Todo → In Progress → Done)
- Priority levels (Low, Medium, High)
- Due date tracking
- Multi-environment Kubernetes deployments
- CI/CD with GitHub Actions

---

*Demo project for learning .NET 9, React, and Kubernetes*