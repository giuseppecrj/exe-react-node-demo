# exe.dev Setup Guide

This guide takes a new project from zero to a production deployment on exe.dev using this repo's Bun monorepo pattern.

## Product model

- `ssh exe.dev ...` is the exe.dev control plane: account checks, VM lifecycle, integrations, sharing, proxy ports.
- `ssh <vm>.exe.xyz ...` is the Linux VM shell.
- `https://<vm>.exe.xyz/` proxies to one selected port on the VM.
- `https://<vm>.exe.xyz:<port>/` can reach additional private dev ports in the 3000-9999 range.
- HTTP access is private by default. Make it public only when explicitly requested.

## 1. Verify local exe.dev access

```bash
ssh exe.dev whoami
ssh exe.dev ls
```

If either command fails, finish exe.dev login and SSH key registration first. Do not create API tokens unless SSH is impossible.

## 2. Create a VM

Use a lowercase name with numbers and hyphens.

```bash
VM=exe-demo
ssh exe.dev "new --name=$VM --tag=app,prod,bun,agent"
ssh exe.dev ls
```

Verify shell and Docker access:

```bash
ssh -o StrictHostKeyChecking=accept-new $VM.exe.xyz 'docker version && docker compose version && docker run --rm alpine:latest echo hello'
```

Do not install JavaScript tooling with `sudo apt install npm`. This repo uses Docker images for Bun.

## 3. Add exe.dev GitHub integration

Use the exe.dev GitHub integration when the VM needs to clone or pull the repo. This avoids storing GitHub PATs on the VM.

First link GitHub in the exe.dev UI. Then create and attach a repo integration:

```bash
OWNER_REPO=giuseppecrj/exe-react-node-demo
INTEGRATION=demo-repo
VM=exe-demo

ssh exe.dev "integrations add github --name=$INTEGRATION --repository=$OWNER_REPO --attach=vm:$VM"
```

If the integration already exists:

```bash
ssh exe.dev "integrations attach $INTEGRATION vm:$VM"
```

Verify it:

```bash
ssh exe.dev "integrations list"
```

## 4. Clone the repo on the VM

The CI/CD workflow expects a git checkout at `/home/exedev/exe-react-node-demo` by default.

```bash
VM=exe-demo
INTEGRATION=demo-repo
OWNER_REPO=giuseppecrj/exe-react-node-demo
APP_DIR=/home/exedev/exe-react-node-demo

ssh $VM.exe.xyz "git clone https://$INTEGRATION.int.exe.xyz/$OWNER_REPO.git $APP_DIR"
ssh $VM.exe.xyz "cd $APP_DIR && git fetch origin && git status --short"
```

If the clone already exists, confirm its remote:

```bash
ssh $VM.exe.xyz "cd $APP_DIR && git remote -v"
```

## 5. Run dev mode on exe.dev

```bash
ssh exe-demo.exe.xyz
cd /home/exedev/exe-react-node-demo
docker compose -f docker-compose.dev.yml up
```

Open the Vite port directly:

```text
https://exe-demo.exe.xyz:5173/
```

Or point the main proxy at Vite while developing:

```bash
ssh exe.dev "share port exe-demo 5173"
```

Switch back to production later:

```bash
ssh exe.dev "share port exe-demo 3000"
```

## 6. Run production manually

```bash
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && PORT=3000 scripts/exe-deploy-on-vm.sh"
ssh exe.dev "share port exe-demo 3000"
```

Verify:

```bash
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && docker compose ps && curl --fail http://127.0.0.1:3000/health"
```

Open:

```text
https://exe-demo.exe.xyz/
```

## 7. Configure GitHub Actions deployment

Generate a dedicated deploy SSH key locally:

```bash
ssh-keygen -t ed25519 -C exe-demo-github-actions-deploy -f ~/.ssh/exe_demo_github_actions_deploy
cat ~/.ssh/exe_demo_github_actions_deploy.pub | ssh exe.dev ssh-key add
ssh -i ~/.ssh/exe_demo_github_actions_deploy exedev@exe-demo.exe.xyz whoami
```

Add GitHub Actions secrets:

| Secret | Value |
| --- | --- |
| `EXE_VM_HOST` | `exe-demo.exe.xyz` |
| `EXE_SSH_PRIVATE_KEY` | contents of `~/.ssh/exe_demo_github_actions_deploy` |

Add GitHub Actions variables:

| Variable | Value |
| --- | --- |
| `EXE_VM_USER` | `exedev` |
| `EXE_APP_DIR` | `/home/exedev/exe-react-node-demo` |
| `EXE_APP_PORT` | `3000` |

Then push to `main` or run **Deploy to exe.dev** manually from GitHub Actions.

The workflow verifies the ref with Bun and Docker, SSHes into the VM, fetches through the exe.dev GitHub integration, checks out the exact commit, runs the VM-local deploy script, and points the exe.dev proxy at port `3000`.

## 8. Make the app public only if requested

Private is the default.

```bash
ssh exe.dev "share show exe-demo"
ssh exe.dev "share set-public exe-demo"
ssh exe.dev "share set-private exe-demo"
```

## 9. First deployment verification checklist

Before calling the deployment complete, verify:

```bash
ssh exe.dev ls
ssh exe.dev "share show exe-demo"
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && cat .deployed-sha && git rev-parse HEAD && docker compose ps && curl --fail http://127.0.0.1:3000/health"
```

Expected:

- VM exists and is running.
- GitHub integration fetch works.
- `.deployed-sha` matches the intended commit.
- Compose service is running and healthy.
- `/health` returns `{ "ok": true }`.
- exe.dev proxy is set to port `3000`.
