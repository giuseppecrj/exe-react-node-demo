# exe.dev Bun Monorepo Deployment Reference

This repository is a production-shaped reference for building, developing, and deploying a small full-stack app to [exe.dev](https://exe.dev). It is intentionally more than a demo app: it is meant to outlive individual agent sessions as a canonical pattern that agents and humans can copy into real projects.

## What this repo demonstrates

- Bun workspace monorepo layout.
- Vite React frontend and Bun/Express backend in `apps/web`.
- Docker-first local and VM development; no host-level Node/npm required.
- Production Docker image that serves the built frontend from the backend on one HTTP port.
- exe.dev VM lifecycle, GitHub integration, private-by-default HTTPS proxy, and production port selection.
- GitHub Actions CI/CD where the runner SSHes into exe.dev and the VM pulls the exact git commit through the exe.dev GitHub integration.
- Agent-facing guidance for reliably creating and deploying similar apps.

## Repository layout

```text
apps/web/                       Production app package
  client/                       Vite React frontend
  server/                       Bun/Express API + static frontend server
  package.json                  App scripts and runtime dependencies
packages/                       Shared packages go here as the project grows
Dockerfile                      Production Bun image build
docker-compose.yml              Production runtime on port 3000
docker-compose.dev.yml          Dev runtime on ports 5173 and 3000
.github/workflows/ci.yml        Pull request/main checks
.github/workflows/deploy-exe.yml
                                Deploy exact git ref to exe.dev
docs/                           Human and agent deployment documentation
scripts/docker-dev.sh           Dev container dependency bootstrap
scripts/exe-create-vm.sh        Small VM creation helper
scripts/exe-deploy-on-vm.sh     VM-local production deployment script
AGENTS.md                       Agent-facing rules for this repo
```

## Local development

Use Docker Compose for the same Bun runtime locally and on exe.dev:

```bash
docker compose -f docker-compose.dev.yml up
```

Open:

```text
http://localhost:5173/
```

The Vite frontend proxies `/api` to the Bun/Express server on port `3000`.

If you already have Bun installed locally, you can run without Docker:

```bash
bun install
bun run dev
```

## Local production check

```bash
bun install
bun run check
docker compose up -d --build
curl --fail http://127.0.0.1:3000/health
docker compose down
```

## exe.dev deployment quick path

Full details are in [`docs/exe-dev-setup.md`](docs/exe-dev-setup.md) and [`docs/ci-cd.md`](docs/ci-cd.md).

Minimum shape:

1. User signs in to exe.dev and registers an SSH public key.
2. Create an exe.dev VM.
3. Attach the exe.dev GitHub integration for this repo.
4. Clone this repo on the VM at `/home/exedev/exe-react-node-demo`.
5. Add GitHub Actions secrets/variables.
6. Push to `main`.

The workflow then:

1. Checks the requested ref with Bun and Docker in GitHub Actions.
2. SSHes into the exe.dev VM.
3. Fetches the requested ref through the exe.dev GitHub integration.
4. Checks out the exact commit.
5. Runs `scripts/exe-deploy-on-vm.sh`.
6. Points exe.dev's HTTPS proxy at port `3000`.

## Required GitHub Actions configuration

Secrets:

| Secret | Meaning |
| --- | --- |
| `EXE_VM_HOST` | VM hostname, e.g. `exe-demo.exe.xyz` |
| `EXE_SSH_PRIVATE_KEY` | Private key whose public key is registered with exe.dev |

Variables:

| Variable | Default |
| --- | --- |
| `EXE_VM_USER` | `exedev` |
| `EXE_APP_DIR` | `/home/exedev/exe-react-node-demo` |
| `EXE_APP_PORT` | `3000` |

## Documentation map

- [`docs/architecture.md`](docs/architecture.md) — why the repo is structured as a Bun monorepo.
- [`docs/exe-dev-setup.md`](docs/exe-dev-setup.md) — first-time VM, GitHub integration, and deployment setup.
- [`docs/ci-cd.md`](docs/ci-cd.md) — CI/CD pipeline contract and rollback model.
- [`docs/runbook.md`](docs/runbook.md) — operational commands and failure recovery.
- [`docs/agent-exe-dev-playbook.md`](docs/agent-exe-dev-playbook.md) — agent-specific deployment playbook.

## Important exe.dev rules

- `ssh exe.dev ...` talks to the control plane.
- `ssh <vm>.exe.xyz ...` talks to the VM.
- `https://<vm>.exe.xyz/` proxies to one selected VM port.
- Use the exe.dev GitHub integration when the VM must clone or pull private repos.
- Keep sites private by default; make public only when explicitly requested.
- Do not install JavaScript runtimes with `sudo apt install npm`; use Docker or Bun-managed tooling.
