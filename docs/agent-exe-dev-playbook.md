# Agent playbook: deploy apps to exe.dev

This document explains how agents should use this repo as a reusable production deployment pattern.

## What this repo is

This repo is an executable reference implementation for exe.dev deployments:

- Bun workspace monorepo.
- Docker-first local, dev VM, and production VM flows.
- exe.dev GitHub integration for VM-side repo access.
- GitHub Actions SSH trigger for CI/CD.
- One public/proxied production port.
- Health-gated deployment script.

Agents should copy the pattern, not blindly copy app-specific names.

## Required user/environment state

Agents can automate only after these are true:

- User has an exe.dev account.
- User's SSH public key is registered with exe.dev.
- `ssh exe.dev whoami` succeeds locally.
- User has authorized/installed exe.dev GitHub integration when private repo access from the VM is needed.
- User has approved any public sharing or destructive VM operation.

Do not ask users to paste private keys into chat.

## Required app shape

A production-ready app for this pattern has:

- Root `bun run check` command.
- Production `Dockerfile`.
- Production `docker-compose.yml` with one HTTP port.
- `/health` endpoint.
- App server binding `0.0.0.0`.
- Docker-based dev path.
- No dependency on host-level Node/npm installs.

For Vite or similar dev servers on exe.dev:

- bind `0.0.0.0`
- allow `.exe.xyz` hosts
- proxy frontend `/api` to the backend

## exe.dev command split

```bash
ssh exe.dev ...         # control plane
ssh <vm>.exe.xyz ...    # VM shell
```

Use `ssh exe.dev` for:

- `whoami`
- `ls`
- `new`
- `share port`
- `share set-public` / `set-private`
- `integrations add/attach/list`

Use `ssh <vm>.exe.xyz` for:

- `git fetch`
- `docker compose up`
- logs
- healthchecks
- file inspection

## GitHub integration decision tree

Use the exe.dev GitHub integration by default when the VM keeps working with the repo:

- Private repo cloned from VM: **required**.
- Shelley/agent coding inside VM: **strongly preferred**.
- Long-lived production VM that pulls updates: **preferred**.
- One-shot local deploy: `rsync` is acceptable, but not the production CI/CD pattern in this repo.
- Public repo: plain `git clone` is acceptable, but integration still works.

Command shape:

```bash
ssh exe.dev "integrations add github --name=<integration> --repository=OWNER/REPO --attach=vm:<vm>"
ssh exe.dev "integrations attach <integration> vm:<vm>"
ssh <vm>.exe.xyz "git clone https://<integration>.int.exe.xyz/OWNER/REPO.git /home/exedev/<repo>"
```

## Production CI/CD pattern

1. GitHub Actions verifies the requested ref with Bun and Docker.
2. GitHub Actions SSHes into the exe.dev VM with a dedicated deploy key.
3. VM fetches through exe.dev GitHub integration.
4. VM checks out the exact SHA.
5. VM runs `scripts/exe-deploy-on-vm.sh`.
6. Script builds/restarts Docker Compose and waits for `/health`.
7. Workflow points exe.dev proxy at the production port.
8. Agent returns the verified URL.

## One-shot deployment skeleton

Use this only when the user wants a quick deploy from the current workspace and does not need VM-side repo lifecycle:

```bash
VM=my-app
APP_DIR=/home/exedev/apps/$VM
PORT=3000

ssh exe.dev whoami
ssh exe.dev "new --name=$VM --tag=app,agent"
ssh -o StrictHostKeyChecking=accept-new $VM.exe.xyz 'docker version && docker compose version'
ssh $VM.exe.xyz "mkdir -p '$APP_DIR'"
rsync -az --delete --exclude .git --exclude node_modules --exclude dist --exclude .env ./ "$VM.exe.xyz:$APP_DIR/"
ssh $VM.exe.xyz "cd '$APP_DIR' && docker compose up -d --build && curl --fail http://127.0.0.1:$PORT/health"
ssh exe.dev "share port $VM $PORT"
```

## Production VM bootstrap skeleton

Use this for long-lived deployments:

```bash
VM=my-app
REPO=OWNER/REPO
INTEGRATION=my-app-repo
APP_DIR=/home/exedev/my-app

ssh exe.dev "new --name=$VM --tag=app,prod,agent"
ssh exe.dev "integrations add github --name=$INTEGRATION --repository=$REPO --attach=vm:$VM"
ssh $VM.exe.xyz "git clone https://$INTEGRATION.int.exe.xyz/$REPO.git $APP_DIR"
ssh $VM.exe.xyz "cd $APP_DIR && PORT=3000 scripts/exe-deploy-on-vm.sh"
ssh exe.dev "share port $VM 3000"
```

## Verification before saying done

Do not rely on a green build alone. Verify the actual deployed state:

```bash
ssh exe.dev "share show <vm>"
ssh <vm>.exe.xyz "cd <app-dir> && cat .deployed-sha && git rev-parse HEAD && docker compose ps && curl --fail http://127.0.0.1:<port>/health"
```

Only then return:

```text
https://<vm>.exe.xyz/
```

## What to ask the user

Ask when missing:

- VM name.
- Public/private visibility.
- GitHub repo path and integration name.
- Whether to reuse or create a VM.
- Permission before destructive operations.
- Custom domain requirements.

Never make the site public by default.
