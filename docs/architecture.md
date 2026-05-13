# Architecture

This repository is structured as a small but production-shaped Bun monorepo. The goal is not to demonstrate every possible framework choice; the goal is to give agents and humans a stable reference for deploying web apps to exe.dev with the fewest hidden assumptions.

## Design goals

1. **One deployable app, clear room to grow.** The first app lives in `apps/web`, and shared packages can be added under `packages/` without changing the deployment model.
2. **Bun-first workspace tooling.** The root owns workspace scripts, lockfile, Biome, and TypeScript baseline configuration.
3. **Docker-first runtime reproducibility.** Development and production can run without host-level Node/npm/Bun installs.
4. **One production HTTP port.** exe.dev's main HTTPS proxy points to a single port, currently `3000`.
5. **Agent-readable conventions.** `AGENTS.md` and `docs/agent-exe-dev-playbook.md` explain exactly what future agents should do.

## Directory map

```text
apps/web/
  client/                 Vite React frontend
  server/                 Bun/Express API and static frontend server
  dist/                   Generated production frontend build; ignored by git
  package.json            App-specific scripts and dependencies
packages/
  .gitkeep                Placeholder for shared packages
Dockerfile                Multi-stage Bun production image
docker-compose.yml        Production Compose service
docker-compose.dev.yml    Development Compose service
biome.json                Formatting/linting policy
tsconfig.base.json        Shared TypeScript defaults
.github/workflows/        CI and deployment workflows
scripts/                  VM/dev/deployment helper scripts
docs/                     Architecture, setup, CI/CD, runbooks
```

## Runtime topology

### Development

```text
browser
  → http://localhost:5173 or https://<vm>.exe.xyz:5173
  → Vite dev server
  → /api proxy
  → Bun/Express API on port 3000
```

The dev Compose file runs both Vite and Bun/Express in one container for simplicity. Dependencies live in Docker volumes, not on the host.

### Production

```text
browser
  → https://<vm>.exe.xyz/
  → exe.dev HTTPS proxy
  → VM port 3000
  → Docker Compose service
  → Bun/Express server
  → static files from apps/web/dist/public + /api routes
```

The production image builds the frontend first, then copies only the server, built assets, lockfile, and production dependencies into the runtime stage.

## Why Bun monorepo?

Bun gives the reference app a single tool for package management and script execution while still allowing common frontend/backend tooling such as Vite and Express. The workspace layout mirrors what a real production repo will eventually need:

- `apps/` for deployable surfaces.
- `packages/` for shared libraries.
- root scripts for repo-wide checks.
- package scripts for app-local build/dev/start behavior.

## Deployment model

The production deployment is intentionally Git-based on the VM:

1. The VM owns a git checkout of the repo.
2. The checkout uses the exe.dev GitHub integration remote.
3. GitHub Actions SSHes into the VM only to trigger deployment.
4. The VM fetches and checks out the exact commit SHA.
5. Docker Compose builds and restarts the app.
6. A healthcheck gates success.

This avoids rsync drift and keeps the deployed artifact tied to a real git commit.

## Non-goals

- Kubernetes, serverless, or platform adapters.
- Host-level runtime installs on exe.dev VMs.
- Multiple production services behind multiple public ports.
- Public-by-default demos.
- Storing GitHub PATs on VMs.
