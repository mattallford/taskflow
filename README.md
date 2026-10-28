# TaskFlow

A small task management app used to demo Octopus Deploy: a .NET API and a React frontend,
built by GitHub Actions and deployed by Octopus to a local Kubernetes cluster.

## Tech stack

- **API**: .NET 10 Web API, Entity Framework Core, PostgreSQL
- **Web**: React 19, TypeScript, Vite, served by nginx
- **Delivery**: GitHub Actions builds multi-arch images to Docker Hub; Octopus Deploy deploys
  them with Kustomize to Kubernetes (Rancher Desktop k3s, Traefik ingress)

## Environments

| Environment | URL | How it gets a release |
|---|---|---|
| Dev | http://taskflow-dev.localhost | Automatically, from every merge to `main` |
| Test | http://taskflow-test.localhost | Promoted in Octopus |
| Production | http://taskflow.localhost | Promoted in Octopus |
| Pull requests | http://taskflow-pr-N.localhost | An ephemeral environment per PR, removed when the PR closes |

`*.localhost` names resolve to your own machine in browsers, so no `/etc/hosts` entries are
needed. Every environment serves the web app at `/`, the API at `/api` and health at
`/health`, which also reports the running version.

See [docs/build-pipeline.md](docs/build-pipeline.md) for how versions, channels, ephemeral
environments and smoke tests fit together.

## Local development

**API** (uses an in-memory database when no connection string is set):

```bash
cd src/TaskFlow.Api
dotnet run --urls http://localhost:8080
```

**Web** (serves on http://localhost:3000 and forwards `/api` and `/health` to the API on 8080):

```bash
cd src/TaskFlow.Web
npm install
npm run dev
```

**Tests:**

```bash
dotnet test TaskFlow.sln
cd src/TaskFlow.Web && npm test
```

## API endpoints

- `GET /api/tasks` - List all tasks
- `POST /api/tasks` - Create a task
- `PUT /api/tasks/{id}` - Update a task
- `DELETE /api/tasks/{id}` - Delete a task
- `GET /health` - Health, database status and version (503 when the database is unreachable)
- `GET /health/live` - Liveness only; doesn't check the database
