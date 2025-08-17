# TaskFlow - Full-Stack Task Management

A modern, containerized task management application built with .NET 9, React, and PostgreSQL. Designed to showcase enterprise CI/CD patterns with complete frontend and backend integration.

## 🏗️ Project Structure

```
TaskFlow/
├── src/
│   ├── TaskFlow.Api/           # Web API project (.NET 9)
│   ├── TaskFlow.Core/          # Domain models, interfaces, business logic
│   ├── TaskFlow.Infrastructure/ # EF DbContext, repositories, data access
│   ├── TaskFlow.Tests/         # Unit and integration tests
│   └── TaskFlow.Web/           # React frontend application
│       ├── src/
│       │   ├── components/     # React components
│       │   ├── services/       # API client services
│       │   ├── types/          # TypeScript type definitions
│       │   └── styles/         # CSS styling
│       ├── public/
│       └── package.json
├── deploy/
│   ├── docker/                 # Docker containerization
│   │   ├── Dockerfile.api      # API container definition
│   │   ├── Dockerfile.web      # Frontend container definition
│   │   ├── nginx.conf          # Nginx configuration
│   │   └── *.sh               # Docker deployment scripts
│   └── k8s/                   # Kubernetes deployment manifests
│       ├── namespace.yaml      # Kubernetes namespace
│       ├── configmap.yaml      # Application configuration
│       ├── secret.yaml         # Database credentials
│       ├── postgres-*.yaml     # PostgreSQL manifests
│       ├── api-*.yaml          # API deployment & service
│       ├── frontend-*.yaml     # Frontend deployment & service
│       ├── ingress.yaml        # External access routing
│       ├── deploy.sh          # Kubernetes deployment script
│       └── cleanup.sh         # Resource cleanup script
├── README.md
└── TaskFlow.sln
```

## 🚀 Features

### Core Functionality
- **Complete Task Management Interface** - Create, read, update, delete tasks
- **Task Status Workflow** - Todo → In Progress → Done progression
- **Priority Management** - Low, Medium, High priority levels
- **Due Date Tracking** - Optional due date assignment and monitoring
- **Task Filtering** - Filter tasks by status (All, Todo, In Progress, Done)
- **Real-time Updates** - Immediate UI updates with API synchronization

### Frontend Features (React/TypeScript)
- **Modern React SPA** with TypeScript for type safety
- **Responsive Design** - Works seamlessly on desktop and mobile
- **Component-Based Architecture** - Reusable, maintainable components
- **Real-time API Integration** - Efficient REST API communication
- **Error Handling** - Graceful error states and user feedback
- **Loading States** - Visual feedback during API operations
- **Form Validation** - Client-side and server-side validation

### Backend Features (. 9)
- **Clean Architecture** with proper separation of concerns
- **Domain-Driven Design** with rich domain models
- **Repository Pattern** for data access abstraction
- **Entity Framework Core** with PostgreSQL support
- **Serilog** for structured logging
- **Swagger/OpenAPI** documentation
- **CORS** configuration for frontend integration
- **Health checks** for monitoring
- **Input validation** with data annotations
- **Async/await** patterns throughout

### Containerization & Orchestration Features
- **Multi-stage Docker builds** for optimized image sizes
- **Production-ready containers** with security best practices
- **Container orchestration** with custom networking
- **Kubernetes deployment** with complete manifest suite
- **Persistent data storage** with Docker volumes and PVCs
- **Health monitoring** for all services
- **Environment-based configuration** for different deployment scenarios
- **Service discovery** and load balancing with Kubernetes

## 📋 API Endpoints

### Tasks
- `GET /api/tasks` - List all tasks (with optional status filter)
- `GET /api/tasks/{id}` - Get specific task
- `POST /api/tasks` - Create new task
- `PUT /api/tasks/{id}` - Update existing task
- `DELETE /api/tasks/{id}` - Delete task

### Health
- `GET /health` - Health check endpoint

### Documentation
- `GET /swagger` - Swagger UI (in development mode)

## 🛠️ Technology Stack

### Frontend
- **React 18** - Modern UI library with hooks
- **TypeScript** - Type-safe JavaScript development
- **CSS Modules** - Scoped styling with responsive design
- **Fetch API** - HTTP client for API communication

### Backend
- **.NET 9** - Web API framework
- **Entity Framework Core** - ORM with PostgreSQL
- **Serilog** - Structured logging
- **Swagger/OpenAPI** - API documentation
- **xUnit** - Unit and integration testing

### Database & Infrastructure
- **PostgreSQL 15** - Primary production database
- **Docker** - Containerization platform
- **Nginx** - Static file serving and reverse proxy
- **Multi-stage builds** - Optimized container images

## 🏃‍♂️ Getting Started

Choose your preferred method to run TaskFlow:

### 🚀 Quick Start - Kubernetes Deployment (Recommended for Production)

**Prerequisites:**
- [Rancher Desktop](https://rancherdesktop.io/) or [Docker Desktop](https://www.docker.com/get-started) with Kubernetes enabled
- kubectl configured to access your cluster

**Deploy to Kubernetes:**

1. **Prepare container images**
   ```bash
   # Build containers
   docker build -f deploy/docker/Dockerfile.api -t taskflow-api:latest .
   docker build -f deploy/docker/Dockerfile.web -t taskflow-web:latest .
   
   # For Rancher Desktop, import to k8s.io namespace
   nerdctl save taskflow-api:latest -o /tmp/taskflow-api.tar
   nerdctl --namespace k8s.io load -i /tmp/taskflow-api.tar
   nerdctl save taskflow-web:latest -o /tmp/taskflow-web.tar
   nerdctl --namespace k8s.io load -i /tmp/taskflow-web.tar
   ```

2. **Deploy to Kubernetes**
   ```bash
   # Deploy complete application
   ./deploy/k8s/deploy.sh
   ```

3. **Access the application**
   ```bash
   # Add to /etc/hosts for ingress access
   echo "127.0.0.1 taskflow.local" | sudo tee -a /etc/hosts
   ```
   
   - 🎨 **Web App**: http://taskflow.local
   - 🌐 **API**: http://taskflow.local/api  
   - 📚 **API Docs**: http://taskflow.local/swagger
   - 🏥 **Health Check**: http://taskflow.local/health

4. **Verify deployment**
   ```bash
   # Check pod status
   kubectl get pods -n taskflow
   
   # View logs
   kubectl logs -f deployment/taskflow-api -n taskflow
   ```

5. **Clean up when done**
   ```bash
   ./deploy/k8s/cleanup.sh
   ```

### 🐳 Quick Start - Full-Stack Containers

**Prerequisites:**
- [Docker](https://www.docker.com/get-started) or [Rancher Desktop](https://rancherdesktop.io/) with nerdctl

**Run the complete application:**

1. **Build all containers**
   ```bash
   # Build API container
   docker build -f deploy/docker/Dockerfile.api -t taskflow-api:latest .
   
   # Build Web frontend container  
   docker build -f deploy/docker/Dockerfile.web -t taskflow-web:latest .
   ```

2. **Start the full-stack environment**
   ```bash
   # Using Docker
   ./deploy/docker/run-fullstack.sh
   
   # Using nerdctl (Rancher Desktop)
   ./deploy/docker/run-fullstack-local.sh
   ```

3. **Access the application**
   - 🎨 **Web App**: http://localhost:3000
   - 🌐 **API**: http://localhost:8080  
   - 📚 **API Docs**: http://localhost:8080/swagger
   - 🏥 **Health Check**: http://localhost:8080/health

4. **Clean up when done**
   ```bash
   # Using Docker
   ./deploy/docker/cleanup.sh
   
   # Using nerdctl
   ./deploy/docker/cleanup-local.sh
   ```

### 🔧 Development Mode - Local Development

**Prerequisites:**
- [.NET 9 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Node.js 18+](https://nodejs.org/) 
- [PostgreSQL](https://www.postgresql.org/download/) (optional - uses in-memory DB by default)

**Setup:**

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd taskflow
   ```

2. **Backend setup**
   ```bash
   # Restore .NET dependencies
   dotnet restore
   
   # Build the solution
   dotnet build
   
   # Run the API (starts on http://localhost:5055)
   cd src/TaskFlow.Api
   dotnet run
   ```

3. **Frontend setup** (in a new terminal)
   ```bash
   # Navigate to frontend directory
   cd src/TaskFlow.Web
   
   # Install Node.js dependencies
   npm install
   
   # Start development server (starts on http://localhost:3000)
   npm start
   ```

4. **Access the application**
   - 🎨 **Web App**: http://localhost:3000 (with hot reload)
   - 🌐 **API**: http://localhost:5055 (or 8080 if containerized)
   - 📚 **API Docs**: http://localhost:5055/swagger

The frontend will automatically proxy API requests to the backend during development.

### Database Configuration

#### Development Mode
The application automatically uses an in-memory database in development mode for easy testing without requiring PostgreSQL setup.

#### Production Mode
For production deployment, configure the PostgreSQL connection string:

**Via appsettings.json:**
```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=taskflowdb;Username=postgres;Password=yourpassword"
  }
}
```

**Via Environment Variables:**
```bash
export ConnectionStrings__DefaultConnection="Host=localhost;Database=taskflowdb;Username=postgres;Password=yourpassword"
```

## 🧪 Testing

### Run Unit Tests
```bash
dotnet test
```

### Run Specific Test Project
```bash
dotnet test src/TaskFlow.Tests/TaskFlow.Tests.csproj
```

### Manual API Testing

With the API running, you can test endpoints using curl:

```bash
# Health check
curl http://localhost:5055/health

# Get all tasks
curl http://localhost:5055/api/tasks

# Create a new task
curl -X POST http://localhost:5055/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"New Task","description":"Task description","status":0,"priority":1}'

# Get specific task
curl http://localhost:5055/api/tasks/{task-id}

# Update task
curl -X PUT http://localhost:5055/api/tasks/{task-id} \
  -H "Content-Type: application/json" \
  -d '{"title":"Updated Task","description":"Updated description","status":1,"priority":2}'

# Delete task
curl -X DELETE http://localhost:5055/api/tasks/{task-id}
```

## 📊 Data Models

### TaskItem
```csharp
public class TaskItem
{
    public Guid Id { get; set; }
    public string Title { get; set; }              // Required, max 200 chars
    public string? Description { get; set; }       // Optional, max 1000 chars
    public TaskItemStatus Status { get; set; }     // Todo, InProgress, Done
    public TaskPriority Priority { get; set; }     // Low, Medium, High
    public DateTime CreatedDate { get; set; }
    public DateTime? DueDate { get; set; }
    public DateTime UpdatedDate { get; set; }
}
```

### Enums
- **TaskItemStatus**: `Todo (0)`, `InProgress (1)`, `Done (2)`
- **TaskPriority**: `Low (0)`, `Medium (1)`, `High (2)`

## 📝 Configuration

### Logging
The application uses Serilog with console output. Configure logging levels in `appsettings.json`:

```json
{
  "Serilog": {
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "Microsoft.EntityFrameworkCore": "Warning"
      }
    }
  }
}
```

### CORS
CORS is configured to allow all origins in development. Customize in `Program.cs` for production:

```csharp
services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins("https://your-frontend-domain.com")
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});
```

## 🏗️ Architecture

This project follows **Clean Architecture** principles:

- **TaskFlow.Core**: Contains domain models, interfaces, and business logic
- **TaskFlow.Infrastructure**: Implements data access using Entity Framework
- **TaskFlow.Api**: Web API controllers and configuration
- **TaskFlow.Tests**: Unit and integration tests

### Dependencies
- Core has no dependencies on other projects
- Infrastructure depends on Core
- API depends on both Core and Infrastructure
- Tests can depend on all projects

## ☸️ Kubernetes Deployment

TaskFlow now includes production-ready Kubernetes manifests for container orchestration! Deploy to any Kubernetes cluster including Rancher Desktop, Docker Desktop, or cloud providers.

### 🎯 Kubernetes Features

- **Complete manifest suite** with namespace, ConfigMap, Secret, PVC, Deployments, Services, and Ingress
- **Multi-tier architecture** deployment (Frontend, API, Database)
- **Service discovery** and load balancing
- **Persistent data storage** with PostgreSQL PVC
- **Health checks** and readiness probes
- **Resource limits** and requests for production workloads
- **Rolling updates** deployment strategy
- **Environment configuration** ready for Octopus Deploy
- **Security context** with non-root containers

### 📋 Kubernetes Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Ingress       │    │   Frontend      │    │   API           │
│   (External)    │───▶│   (React/Nginx) │───▶│   (.NET 9)      │
│   taskflow.local│    │   Port 3000     │    │   Port 8080     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
                                               ┌─────────────────┐
                                               │   PostgreSQL    │
                                               │   Port 5432     │
                                               │   Persistent    │
                                               └─────────────────┘
```

### 🚀 Quick Kubernetes Deployment

**Prerequisites:**
- Kubernetes cluster (Rancher Desktop, Docker Desktop, or cloud)
- kubectl configured and connected
- Container images built and available

**Automatic deployment with environment detection:**
```bash
./deploy/k8s/deploy.sh
```

**Alternative - NodePort for guaranteed local access:**
```bash
./deploy/k8s/deploy-nodeport.sh
```

**Access points (auto-detected):**

*Ingress mode (default):*
- **Web App**: http://taskflow.local (hosts file managed automatically)
- **API**: http://taskflow.local/api
- **Health**: http://taskflow.local/health  
- **Swagger**: http://taskflow.local/swagger

*NodePort mode (fallback):*
- **Web App**: http://localhost:30300
- **API**: http://localhost:30080
- **Health**: http://localhost:30080/health
- **Swagger**: http://localhost:30080/swagger

### 📦 Kubernetes Manifests

| Manifest | Purpose | Features |
|----------|---------|----------|
| `namespace.yaml` | Resource isolation | Dedicated taskflow namespace |
| `configmap.yaml` | App configuration | API URLs, timeouts, logging, environment variables |
| `secret.yaml` | Sensitive data | Database credentials (base64) |
| `postgres-pvc.yaml` | Persistent storage | 1Gi database volume |
| `postgres-deployment.yaml` | Database workload | Health checks, security context |
| `postgres-service.yaml` | Database access | ClusterIP service discovery |
| `api-deployment.yaml` | API workload | 2 replicas, environment config |
| `api-service.yaml` | API access | ClusterIP load balancing |
| `frontend-deployment.yaml` | Frontend workload | 2 replicas, nginx config |
| `frontend-service.yaml` | Frontend access | ClusterIP service |
| `ingress.yaml` | External routing | Clean Traefik routing (fixed middleware) |
| `ingress-localhost.yaml` | Local development | Localhost/127.0.0.1 routing |
| `services-nodeport.yaml` | Alternative networking | NodePort services for direct access |
| `deploy.sh` | Smart deployment | Environment detection, validation |
| `deploy-nodeport.sh` | Simple deployment | NodePort-only deployment |
| `cleanup.sh` | Resource cleanup | Safe removal with confirmation |

### 🔧 Kubernetes Management

**View deployment status:**
```bash
kubectl get pods -n taskflow
kubectl get services -n taskflow
kubectl get ingress -n taskflow
```

**View logs:**
```bash
kubectl logs -f deployment/taskflow-api -n taskflow
kubectl logs -f deployment/taskflow-frontend -n taskflow
kubectl logs -f deployment/taskflow-postgres -n taskflow
```

**Scale deployments:**
```bash
kubectl scale deployment taskflow-api --replicas=3 -n taskflow
kubectl scale deployment taskflow-frontend --replicas=3 -n taskflow
```

**Complete cleanup:**
```bash
./deploy/k8s/cleanup.sh
```

### 🌐 Networking Options

TaskFlow provides multiple networking approaches to ensure reliable deployment:

**Option 1: Smart Ingress (Recommended)**
- Automatic environment detection (Rancher Desktop, Docker Desktop, cloud)
- Automatic hosts file management
- Falls back to NodePort if ingress fails
- Production-ready with proper routing

**Option 2: NodePort (Guaranteed Local Access)**
- Direct port access (30080 for API, 30300 for frontend)
- No DNS configuration required
- Works in all environments
- Perfect for development and testing

**Option 3: Manual Ingress Configuration**
- Use `ingress-localhost.yaml` for localhost routing
- Use `services-nodeport.yaml` for NodePort access
- Custom configurations for specific requirements

### 🔍 Environment Detection

The deployment script automatically detects:
- **Rancher Desktop**: Uses localhost ingress with 127.0.0.1
- **Docker Desktop**: Uses localhost ingress with 127.0.0.1  
- **Minikube**: Uses minikube IP for ingress
- **Cloud Providers** (AWS/GCP/Azure): Waits for LoadBalancer IP
- **Generic Kubernetes**: Falls back to NodePort if needed

### 🚨 Troubleshooting

**Ingress not working?**
```bash
# Switch to NodePort mode
kubectl apply -f deploy/k8s/services-nodeport.yaml

# Access via NodePort
curl http://localhost:30080/health
```

**Pods not starting?**
```bash
# Check pod status
kubectl get pods -n taskflow

# View logs
kubectl logs -f deployment/taskflow-api -n taskflow
kubectl describe pod <pod-name> -n taskflow
```

**Container images not found?**
```bash
# For Rancher Desktop, import images to k8s.io namespace
nerdctl save taskflow-api:latest -o /tmp/taskflow-api.tar
nerdctl --namespace k8s.io load -i /tmp/taskflow-api.tar
nerdctl save taskflow-web:latest -o /tmp/taskflow-web.tar
nerdctl --namespace k8s.io load -i /tmp/taskflow-web.tar
```

### 🐳 Docker Containerization

TaskFlow also supports Docker containerization for development and single-host deployments.

**Quick Docker deployment:**
```bash
# Build all containers
./deploy/docker/build.sh

# Start full-stack environment
./deploy/docker/run-fullstack.sh

# Access: http://localhost:3000
# Clean up: ./deploy/docker/cleanup.sh
```

**Container features:**
- Multi-stage Docker builds for optimized images
- Non-root security with dedicated users
- Persistent data storage with volumes
- Health monitoring and automated restarts
- Container networking for secure communication

## 🔄 Future Roadmap

This is a multi-chunk project. **Chunk 3: Frontend Development** is now complete! Future iterations will include:

- **✅ Chunk 1**: Core API development (.NET 9, PostgreSQL, Clean Architecture)
- **✅ Chunk 2**: Docker containerization (Multi-stage builds, container orchestration)
- **✅ Chunk 3**: Frontend development (React, TypeScript, full-stack integration)
- **✅ Chunk 4**: Kubernetes deployment (K8s manifests, container orchestration)
- **Chunk 5**: CI/CD pipeline setup (GitHub Actions, automated testing)
- **Future**: Microservices architecture evolution

## 🎨 User Interface

TaskFlow features a modern, responsive web interface built with React and TypeScript:

### 🖥️ Main Features
- **Task Dashboard**: Clean overview of all tasks with status filtering
- **Quick Actions**: Inline task status updates (Todo → In Progress → Done)
- **Task Creation**: Intuitive form for adding new tasks with validation
- **Task Editing**: Inline editing capabilities for all task properties
- **Responsive Design**: Optimized for desktop, tablet, and mobile devices
- **Real-time Feedback**: Loading states, error handling, and success messages

### 📱 User Experience
- **Status Filters**: Filter tasks by All, Todo, In Progress, or Done
- **Priority Indicators**: Color-coded visual priority indicators (Low/Medium/High)
- **Due Date Tracking**: Optional due date assignment and visual indicators
- **Task Workflow**: Guided progression through task lifecycle
- **Form Validation**: Client-side validation with helpful error messages
- **Keyboard Navigation**: Accessible design with keyboard support

### 🎯 Task Management Workflow
1. **Create**: Add new tasks with title, description, priority, and due date
2. **Organize**: Filter and view tasks by status to focus on what matters
3. **Progress**: Move tasks through workflow with single-click status updates
4. **Edit**: Modify any task details inline without page navigation
5. **Complete**: Mark tasks as done and track your productivity

## 🚀 Sample Data

The application includes seed data with 6 sample tasks covering different statuses and priorities for demonstration purposes.

## 🛡️ Security Notes

- Input validation is implemented using Data Annotations
- Proper error handling prevents information leakage
- HTTPS redirection is enabled
- Ready for authentication/authorization implementation

## 📞 API Response Examples

### Successful Task Creation
```json
{
  "id": "9debd27f-40b3-4194-bf76-1d54a8727ec6",
  "title": "New Task",
  "description": "Task description",
  "status": 0,
  "priority": 1,
  "createdDate": "2025-08-16T01:12:14.781662Z",
  "dueDate": null,
  "updatedDate": "2025-08-16T01:12:14.781662Z"
}
```

### Health Check Response
```json
{
  "status": "Healthy",
  "timestamp": "2025-08-16T01:11:56.887657Z",
  "database": "Connected"
}
```

---

🌟 **Built with ❤️ using .NET 9 for enterprise-grade task management**