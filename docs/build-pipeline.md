# Build and deployment pipeline

GitHub Actions builds and versions TaskFlow, then hands each version to Octopus Deploy, which
deploys it to Kubernetes and promotes it through the environments.

```
pull request ──► build 1.1.47-pr21.3 ──► Octopus release (Ephemeral Environments channel)
                                          └─► provisions pr-21, deploys, smoke tests
merge to main ─► build 1.1.47 ─────────► Octopus release (Release channel)
                                          └─► Dev (automatic) ──► Test ──► Production
```

## GitHub Actions (`.github/workflows/build.yml`)

Runs on pull requests to `main` and pushes to `main` that change `src/`, `deploy/k8s/`,
`deploy/octopus/`, `GitVersion.yml`, `README.md` or the workflow itself.

| Job | What it does |
|---|---|
| Calculate Version | GitVersion 6 works out the version (see below) |
| Security Scan | Trivy scans the repository and uploads SARIF to the GitHub Security tab |
| Test | `dotnet test` for the API and `npm test` (Vitest) for the web app |
| Build | Builds each image natively on amd64 and arm64 runners and pushes it by digest |
| Create Multi-Arch Manifests | Tags one multi-arch image per app from the two digests |
| Deploy to Octopus | Creates the GitHub release, pushes build information and creates the Octopus release |

### Versions

| Build | Version | Example |
|---|---|---|
| `main` | The next patch after the latest `v*` tag | `1.1.47` |
| Pull request | A pre-release of that patch, numbered by commits since the tag | `1.1.47-pr21.3` |

Every `main` build creates a GitHub release and tag (`v1.1.47`) so the next build moves on to
`1.1.48`. Put `+semver: minor` or `+semver: major` in a commit message to bump further.

The version is used everywhere: the image tags, the Octopus release number, `APP_VERSION` in
both images (`/health` reports it and the web app shows it in the footer), and the build
information pushed to Octopus.

### Images

`mattallford/taskflow-api` and `mattallford/taskflow-web` on Docker Hub, one multi-arch tag per
version (linux/amd64 and linux/arm64). `latest` only moves on `main` builds.

- **API**: built on `mcr.microsoft.com/dotnet/sdk:10.0`, runs on `aspnet:10.0` as a non-root user
- **Web**: built on `node:24-alpine` with Vite, served by `nginx:1.30-alpine` on port 3000

## Octopus Deploy

### Channels

The version's pre-release tag decides where a release can go:

| Channel | Accepts | Lifecycle |
|---|---|---|
| Release (default) | Versions without a pre-release tag, from `refs/heads/main` | Dev (automatic) → Test → Production |
| Ephemeral Environments | Versions with a pre-release tag | The PR's ephemeral environment |

This keeps branch builds out of Test and Production.

### Deployment process

1. **Kustomize deployment** applies `deploy/k8s/overlays/<environment>` (`#{OverlayPath}`) on
   the `k8s-macos` Kubernetes agent. The overlays pin both images to the release's package
   versions with `#{Octopus.Action.Package[taskflow-api].PackageVersion}`.
2. **Smoke test** runs [`deploy/octopus/scripts/Invoke-SmokeTest.ps1`](../deploy/octopus/scripts/Invoke-SmokeTest.ps1)
   from Git on the same agent. It checks that `/health` is Healthy and reports the release's
   version, and that `/` and `/api/tasks` respond. `*.localhost` only resolves on the Mac, so the
   script calls Traefik's in-cluster Service with the app's `Host` header instead.

PR releases point both steps' Git resources at the PR branch, so a PR deploys its own
manifests and smoke test.

### Project variables

| Variable | Value |
|---|---|
| `environmentName` | `#{Octopus.Environment.Name \| ToLower}` |
| `Kubernetes.Namespace` | `taskflow-#{environmentName}` |
| `OverlayPath` | `deploy/k8s/overlays/#{Octopus.Environment.Name \| ToLower}`, or `deploy/k8s/overlays/ephemeralenvironments` for ephemeral environments |
| `AppHost` | `taskflow-#{environmentName}.localhost`, or `taskflow.localhost` in Production |
| `Swagger.Enabled` | `true` or `false`; becomes `Swagger__Enabled` in each overlay's ConfigMap and turns Swagger UI at `/swagger` on or off |

### Ephemeral environments

Each pull request gets an environment named `pr-<number>`:

- The **provision-environment** runbook creates the namespace and sets the environment URLs
  shown in Octopus. Octopus runs it once, when the environment is created.
- Each new commit on the PR creates a release and deploys it.
- Closing the PR runs `.github/workflows/deprovision-ephemeral-environment.yml`, which calls the
  **delete-environment** runbook to remove the namespace and the environment.

### Feature flags

TaskFlow's flags live in the TaskFlow project (Project ➜ Feature Flags) and are read through
OpenFeature with the Octopus providers: `Octopus.OpenFeature` in the API and
`@octopusdeploy/openfeature` in the web app.

- Octopus substitutes `#{Octopus.FeatureFlags.ClientIdentifier}` into each overlay's
  ConfigMap as `FeatureFlags__ClientIdentifier`. The identifier is a JWT naming the project,
  environment and release.
- The API reads it at startup and checks for flag changes every 15 seconds. The web app is the
  same image everywhere, so it fetches the identifier from `GET /api/config` and downloads the
  flags once per page load.
- Both download flags from `features.octopus.com`, which Octopus publishes to whenever a flag
  changes. Without an identifier (local development), every flag uses its default in code.
- `GET /api/features` shows how the API evaluates each flag, and why.

| Flag | Effect |
|---|---|
| `dark-mode` | Switches the web app to a dark theme |

### Build information and release notes

The workflow pushes build information for both images, so each release links to its build,
branch and commits, and the release notes template lists them. Commits are only included for
`main` builds; GitHub doesn't send them for pull request builds.

## Kubernetes

`deploy/k8s/base` holds the shared manifests, and each overlay sets the namespace, Ingress host,
database name and image tags for one environment.

- **Rollouts**: surge-only, with a `preStop` delay, so Traefik stops routing to a pod before it
  shuts down
- **API probes**: a startup probe waits up to 2 minutes for PostgreSQL; readiness uses `/health`;
  liveness uses `/health/live`, so a database outage removes the pod from service instead of
  restarting it
- **PostgreSQL** uses `emptyDir` storage, so its data doesn't survive a pod restart
