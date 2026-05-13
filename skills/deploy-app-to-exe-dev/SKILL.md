---
name: deploy-app-to-exe-dev
description: Deploys apps to exe.dev using a Docker-first pattern inspired by exe-react-node-demo. Use when the user asks to create, prototype, host, or deploy an app on exe.dev, especially when they want a working exe.dev URL or mention exe-react-node-demo as the reference.
---

# Deploy App to exe.dev

## Core model

- `ssh exe.dev ...` is the exe.dev control plane for VM lifecycle, integrations, sharing, and proxy ports.
- `ssh <vm>.exe.xyz ...` is the actual VM shell.
- `https://<vm>.exe.xyz/` proxies to one selected VM port.
- exe.dev sites are private by default; make public only when the user asks.

## Before creating a VM

Verify user auth works:

```bash
ssh exe.dev whoami
ssh exe.dev ls
```

If this fails, stop and ask the user to finish exe.dev login/SSH key setup. Do not ask for private keys in chat.

Ask only for missing essentials:

- VM/app name, if not inferable.
- Public vs private visibility.
- Whether an existing VM should be reused.
- GitHub repo/integration name when the VM must clone or pull a private repo.
- Permission before destructive operations.

## App preparation checklist

- Add deterministic check/build commands.
- Add production `Dockerfile`.
- Add production `docker-compose.yml` exposing one HTTP port, usually `3000`.
- Add `/health` endpoint when possible.
- Ensure servers bind `0.0.0.0` in containers/VMs.
- Avoid `sudo apt install npm`; prefer Docker Compose or official runtime images.
- For Vite dev servers on exe.dev, allow `.exe.xyz` hosts.

## GitHub integration

Use exe.dev GitHub integration by default when the VM will clone/pull a private repo or Shelley/agents will work inside the VM. Alternatives exist (`rsync`, GitHub Actions SSH deploy, public clone), but integration is the safest VM-native path.

```bash
ssh exe.dev "integrations add github --name=<integration> --repository=OWNER/REPO --attach=vm:<vm>"
# if already created:
ssh exe.dev "integrations attach <integration> vm:<vm>"
ssh <vm>.exe.xyz "git clone https://<integration>.int.exe.xyz/OWNER/REPO.git"
```

## Standard deployment

```bash
VM=my-app
APP_DIR=/home/exedev/apps/$VM
PORT=3000

ssh exe.dev "new --name=$VM --tag=app,agent"
ssh -o StrictHostKeyChecking=accept-new $VM.exe.xyz 'docker version && docker compose version'
ssh $VM.exe.xyz "mkdir -p '$APP_DIR'"
rsync -az --delete \
  --exclude .git --exclude node_modules --exclude dist --exclude .env \
  ./ "$VM.exe.xyz:$APP_DIR/"
ssh $VM.exe.xyz "cd '$APP_DIR' && docker compose up -d --build && docker compose ps"
ssh $VM.exe.xyz "curl --fail --silent --show-error http://127.0.0.1:$PORT/health"
ssh exe.dev "share port $VM $PORT"
```

If public access was requested:

```bash
ssh exe.dev "share set-public $VM"
```

Return:

```text
https://my-app.exe.xyz/
```

## Verification before declaring success

- VM exists in `ssh exe.dev ls`.
- GitHub integration is attached if the VM must clone/pull the repo.
- `docker compose ps` shows the service running.
- VM-local healthcheck succeeds.
- exe.dev proxy is pointed at the right port.
- Public/private visibility matches the user's request.
- Final answer includes the URL and the key commands used.

## Reference pattern

When available, read the `exe-react-node-demo` reference repo:

- `AGENTS.md`
- `docs/agent-exe-dev-playbook.md`
- `docs/exe-dev-setup.md`
- `Dockerfile`
- `docker-compose.yml`
- `docker-compose.dev.yml`
