# Agent guidance for exe.dev app deployment

This repo is the canonical reference for agents that need to create, adapt, and deploy small web apps to exe.dev VMs.

Use this repo as the pattern when the user asks for work like: "create a simple app, deploy it to exe.dev, and give me the link" or "look at exe-react-node-demo for how to deploy this".

## Goal state

A successful agent run produces:

1. A working app with deterministic build/check commands.
2. A Docker-based dev path that does not require host-level Node/npm.
3. A production `Dockerfile` and `docker-compose.yml` exposing one HTTP port.
4. An exe.dev VM created after the user has authenticated locally.
5. The exe.dev GitHub integration attached when the VM must clone/pull a private repo.
6. The app deployed to the VM with `docker compose up -d --build`.
7. exe.dev's HTTPS proxy pointed at the app port.
8. A verified URL returned to the user.

## exe.dev mental model

- `ssh exe.dev ...` talks to the exe.dev control plane. Use it for VM lifecycle, sharing, proxy port selection, integrations, and account checks.
- `ssh <vm>.exe.xyz ...` talks to the actual Linux VM. Use it for shell commands, Docker, logs, files, and app deployment.
- `https://<vm>.exe.xyz/` is the HTTPS proxy to one selected port on the VM.
- `https://<vm>.exe.xyz:<port>/` can reach additional proxied ports in the 3000-9999 range for private dev access.
- exe.dev HTTP access is private by default. Only make it public when the user explicitly asks.

## Authentication and user gates

Agents can automate after the user has completed exe.dev login/key setup, but should not invent credentials.

Before creating or deploying a VM, verify:

```bash
ssh exe.dev whoami
ssh exe.dev ls
```

If these fail, ask the user to sign in to exe.dev and register their SSH public key. Do not ask the user to paste private keys into chat.

Prefer SSH commands over exe.dev HTTPS API tokens. Use HTTPS API tokens only when SSH is impossible and the user explicitly wants token-based automation.

## Safe defaults

- Use lowercase VM names with numbers and hyphens: `my-app`, `my-app-dev`, `my-app-prod`.
- Use `--flag=value` for exe.dev value flags: `ssh exe.dev "new --name=$VM --tag=dev,agent"`.
- Never run `ssh exe.dev rm <vm>` without explicit user confirmation.
- Do not run `sudo apt install npm` on exe.dev VMs for JavaScript projects. Use Docker Compose or a user-level Node manager.
- Bind app servers to `0.0.0.0` inside containers/VMs, not only `localhost`.
- Add a health endpoint such as `/health` and verify it from inside the VM.

## Golden app pattern from this repo

For React/Vite + Node/Express apps, mirror this structure:

```text
client/                 frontend app
server/                 API/static server
Dockerfile              production image build
compose.yaml or docker-compose.yml
                        production runtime on one exposed HTTP port
docker-compose.dev.yml  dev runtime using official language image
```

Production:

- Build frontend assets into `dist/public`.
- Serve the built frontend from the backend in production.
- Expose one main port, usually `3000`.
- Include `EXPOSE 3000` in `Dockerfile`.
- Include a Compose healthcheck that calls `http://127.0.0.1:<port>/health`.

Development:

- Use Docker Compose with official runtime images, e.g. `node:22-bookworm-slim`.
- Mount the repo into the dev container.
- Keep dependency folders in Docker volumes.
- For Vite on exe.dev, set `server.host = '0.0.0.0'` and allow `.exe.xyz` hosts.
- Proxy frontend `/api` calls to the backend to avoid cross-origin issues.

## Standard deploy flow

Use this flow for a local workspace that should be pushed to a new exe.dev VM.

```bash
VM=my-app
APP_DIR=/home/exedev/apps/$VM

# 1. Verify control-plane access.
ssh exe.dev whoami

# 2. Create the VM.
ssh exe.dev "new --name=$VM --tag=app,agent"

# 3. Verify VM shell/Docker.
ssh -o StrictHostKeyChecking=accept-new $VM.exe.xyz 'docker version && docker compose version'

# 4. Copy the app workspace to the VM.
ssh $VM.exe.xyz "mkdir -p '$APP_DIR'"
rsync -az --delete \
  --exclude .git --exclude node_modules --exclude dist --exclude .env \
  ./ "$VM.exe.xyz:$APP_DIR/"

# 5. Build and run production.
ssh $VM.exe.xyz "cd '$APP_DIR' && docker compose up -d --build && docker compose ps"

# 6. Point exe.dev HTTPS proxy at the app port.
ssh exe.dev "share port $VM 3000"

# 7. Verify.
ssh $VM.exe.xyz "curl --fail --silent --show-error http://127.0.0.1:3000/health"
```

Then return:

```text
https://my-app.exe.xyz/
```

If the app should be public:

```bash
ssh exe.dev "share set-public $VM"
```

## GitHub integration usage

Treat the exe.dev GitHub integration as first-class for agent/dev VM workflows. If the VM needs to clone or pull a private repo, this is the preferred path; it avoids GitHub PATs and deploy keys on the VM.

There are still valid non-integration paths:

- `rsync` from the agent's current workspace for one-shot deployments.
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

Use this for long-lived dev VMs, production VMs that pull from Git, and Shelley/agent workflows.

## When to ask the user

Ask before continuing if any of these are unknown or blocked:

- Desired VM name.
- Public vs private visibility.
- Domain/custom domain needs.
- Missing exe.dev login or SSH key setup.
- Missing GitHub integration for private repos that must be cloned or pulled from the VM.
- Destructive operations such as deleting/recreating VMs.

## Verification checklist before saying "deployed"

- `ssh exe.dev ls` shows the VM.
- `ssh <vm>.exe.xyz 'docker compose ps'` shows the app running.
- VM-local healthcheck succeeds: `curl http://127.0.0.1:<port>/health`.
- exe.dev proxy port is set: `ssh exe.dev "share port <vm> <port>"`.
- Public/private status matches the user's request.
- The returned URL is the exact exe.dev URL, e.g. `https://<vm>.exe.xyz/`.
