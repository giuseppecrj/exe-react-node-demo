# Agent guidance for exe.dev Bun monorepo deployments

This repo is the canonical reference for agents that need to create, adapt, and deploy production-shaped web apps to exe.dev VMs.

Use this repo as the pattern when the user asks for work like: "create a simple app, deploy it to exe.dev, and give me the link" or "look at exe-react-node-demo for how to deploy this".

## Goal state for a successful agent run

1. A working app with deterministic `bun run check` and Docker build commands.
2. A Bun workspace monorepo shape with apps under `apps/` and shared libraries under `packages/`.
3. A Docker-based dev path that does not require host-level Node/npm.
4. A production `Dockerfile` and `docker-compose.yml` exposing one HTTP port.
5. An exe.dev VM created after the user has authenticated locally.
6. The exe.dev GitHub integration attached when the VM must clone/pull a private repo.
7. The app deployed to the VM with `docker compose up -d --build`.
8. exe.dev's HTTPS proxy pointed at the app port.
9. A verified URL returned to the user.

## exe.dev mental model

- `ssh exe.dev ...` talks to the exe.dev control plane. Use it for VM lifecycle, sharing, proxy port selection, integrations, and account checks.
- `ssh <vm>.exe.xyz ...` talks to the actual Linux VM. Use it for shell commands, Docker, logs, files, and app deployment.
- `https://<vm>.exe.xyz/` is the HTTPS proxy to one selected port on the VM.
- `https://<vm>.exe.xyz:<port>/` can reach additional proxied ports in the 3000-9999 range for private dev access.
- exe.dev HTTP access is private by default. Only make it public when the user explicitly asks.

## Authentication and user gates

Before creating or deploying a VM, verify:

```bash
ssh exe.dev whoami
ssh exe.dev ls
```

If these fail, ask the user to sign in to exe.dev and register their SSH public key. Do not ask the user to paste private keys into chat.

Prefer SSH commands over exe.dev HTTPS API tokens. Use HTTPS API tokens only when SSH is impossible and the user explicitly wants token-based automation.

## Safe defaults

- Use lowercase VM names with numbers and hyphens: `my-app`, `my-app-dev`, `my-app-prod`.
- Use `--flag=value` for exe.dev value flags: `ssh exe.dev "new --name=$VM --tag=app,agent"`.
- Never run `ssh exe.dev rm <vm>` without explicit user confirmation.
- Do not run `sudo apt install npm` on exe.dev VMs for JavaScript projects. Use Docker Compose or Bun-managed tooling.
- Bind app servers to `0.0.0.0` inside containers/VMs, not only `localhost`.
- Add a health endpoint such as `/health` and verify it from inside the VM.

## Golden app pattern from this repo

```text
apps/web/                       web app package
  client/                       frontend app
  server/                       API/static server
packages/                       shared packages, when needed
Dockerfile                      production image build
docker-compose.yml              production runtime on one exposed HTTP port
docker-compose.dev.yml          dev runtime using official Bun image
```

Production:

- Build frontend assets into `apps/web/dist/public`.
- Serve the built frontend from the backend in production.
- Expose one main port, usually `3000`.
- Include `EXPOSE 3000` in `Dockerfile`.
- Include a Compose healthcheck that calls `http://127.0.0.1:<port>/health`.

Development:

- Use Docker Compose with the official Bun image, e.g. `oven/bun:1.3.3-debian`.
- Mount the repo into the dev container.
- Keep dependency folders and Bun cache in Docker volumes.
- For Vite on exe.dev, set `server.host = '0.0.0.0'` and allow `.exe.xyz` hosts.
- Proxy frontend `/api` calls to the backend to avoid cross-origin issues.

## GitHub integration usage

Treat the exe.dev GitHub integration as first-class for agent/dev VM workflows. If the VM needs to clone or pull a private repo, this is the preferred path; it avoids GitHub PATs and deploy keys on the VM.

There are still valid non-integration paths:

- `rsync` from the agent's current workspace for a one-shot deployment.
- GitHub Actions SSH deployment for conventional CI/CD.
- Plain `git clone` for public repos.

But for "agent on exe.dev works on this repo" or "VM pulls updates itself", require the GitHub integration unless the user explicitly chooses another path.

After the user links GitHub in exe.dev, create/attach a per-repo integration:

```bash
ssh exe.dev "integrations add github --name=<integration> --repository=OWNER/REPO --attach=vm:<vm>"
# or, if it already exists:
ssh exe.dev "integrations attach <integration> vm:<vm>"
```

Clone from inside the VM with the integration hostname exe.dev reports:

```bash
git clone https://<integration>.int.exe.xyz/OWNER/REPO.git
```

## Standard CI/CD deployment flow

Use this flow for a long-lived production VM:

1. VM has a git checkout at `/home/exedev/<repo>` cloned through exe.dev GitHub integration.
2. GitHub Actions validates the requested ref with `bun run check` and `docker build`.
3. GitHub Actions SSHes into the VM using a dedicated deploy key stored as `EXE_SSH_PRIVATE_KEY`.
4. The VM runs `git fetch`, checks out the exact SHA, and runs `scripts/exe-deploy-on-vm.sh`.
5. The deploy script builds/restarts Compose and waits for `/health`.
6. The workflow sets `ssh exe.dev "share port <vm> 3000"`.

## When to ask the user

Ask before continuing if any of these are unknown or blocked:

- Desired VM name.
- Public vs private visibility.
- Domain/custom domain needs.
- Missing exe.dev login or SSH key setup.
- Missing GitHub integration for private repos that must be cloned or pulled from the VM.
- Destructive operations such as deleting/recreating VMs.

## Verification checklist before saying "deployed"

- `bun run check` passes.
- `docker build` or `docker compose up -d --build` succeeds.
- `ssh exe.dev ls` shows the VM.
- `ssh <vm>.exe.xyz 'docker compose ps'` shows the app running.
- VM-local healthcheck succeeds: `curl http://127.0.0.1:<port>/health`.
- exe.dev proxy port is set: `ssh exe.dev "share port <vm> <port>"`.
- Public/private status matches the user's request.
- The returned URL is the exact exe.dev URL, e.g. `https://<vm>.exe.xyz/`.
