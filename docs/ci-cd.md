# CI/CD Pipeline

This document describes the production deployment pipeline for this repo.

## Pipeline summary

```text
push to main or manual workflow_dispatch
  → GitHub Actions verify job
      → bun install --frozen-lockfile
      → bun run check
      → docker build
  → GitHub Actions deploy job
      → SSH into exe.dev VM
      → git fetch through exe.dev GitHub integration
      → checkout exact commit SHA
      → scripts/exe-deploy-on-vm.sh
      → docker compose up -d --build
      → wait for /health
      → set exe.dev proxy port
```

## Why this shape?

There are two separate trust/access paths:

1. **GitHub Actions → exe.dev VM** uses a dedicated SSH private key stored in GitHub Actions secrets. The matching public key is registered with exe.dev.
2. **exe.dev VM → GitHub repo** uses the exe.dev GitHub integration. No GitHub PAT is stored on the VM.

This lets GitHub Actions trigger deployments while the VM remains responsible for pulling the exact git ref it is deploying.

## Required GitHub Actions secrets

| Name | Value |
| --- | --- |
| `EXE_VM_HOST` | VM hostname, e.g. `exe-demo.exe.xyz` |
| `EXE_SSH_PRIVATE_KEY` | Private deploy key whose public key is registered with exe.dev |

Generate the deploy key locally:

```bash
ssh-keygen -t ed25519 -C exe-demo-github-actions-deploy -f ~/.ssh/exe_demo_github_actions_deploy
cat ~/.ssh/exe_demo_github_actions_deploy.pub | ssh exe.dev ssh-key add
ssh -i ~/.ssh/exe_demo_github_actions_deploy exedev@exe-demo.exe.xyz whoami
```

Copy the private key into the GitHub secret:

```bash
pbcopy < ~/.ssh/exe_demo_github_actions_deploy
```

Never paste private keys into chat or commit them to the repo.

## Required GitHub Actions variables

| Name | Default | Meaning |
| --- | --- | --- |
| `EXE_VM_USER` | `exedev` | SSH user on the VM |
| `EXE_APP_DIR` | `/home/exedev/exe-react-node-demo` | Git checkout on the VM |
| `EXE_APP_PORT` | `3000` | Production app port |

## VM checkout requirement

Before the first deployment, the VM app directory must be a git checkout with a working exe.dev integration remote:

```bash
ssh exe-demo.exe.xyz
cd /home/exedev
git clone https://demo-repo.int.exe.xyz/giuseppecrj/exe-react-node-demo.git exe-react-node-demo
cd exe-react-node-demo
git remote -v
git fetch origin
```

If the integration remote returns `403`, inspect and attach the integration:

```bash
ssh exe.dev "integrations list"
ssh exe.dev "integrations attach <integration> vm:<vm>"
```

## Deployment script contract

`scripts/exe-deploy-on-vm.sh` runs on the VM from the repo root. It expects the workflow to have already checked out the target commit.

It does:

1. Saves the previous deployed SHA if present.
2. Runs `docker compose up -d --build`.
3. Shows `docker compose ps`.
4. Retries `http://127.0.0.1:$PORT/health` until healthy or timeout.
5. Writes `.deployed-sha`.
6. Prints the deployed commit.

Environment knobs:

| Name | Default |
| --- | --- |
| `PORT` | `3000` |
| `HEALTHCHECK_RETRIES` | `30` |
| `HEALTHCHECK_INTERVAL_SECONDS` | `2` |
| `DEPLOYED_SHA_FILE` | `.deployed-sha` |
| `PREVIOUS_SHA_FILE` | `.previous-deployed-sha` |

## Manual deploy

To deploy the current local commit after pushing it:

```bash
SHA=$(git rev-parse HEAD)
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && git fetch origin && git checkout --detach $SHA && PORT=3000 scripts/exe-deploy-on-vm.sh"
ssh exe.dev "share port exe-demo 3000"
```

## Rollback

Deploy any previous commit:

```bash
OLD_SHA=<commit-sha>
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && git fetch origin && git checkout --detach $OLD_SHA && PORT=3000 scripts/exe-deploy-on-vm.sh"
```

Or run the GitHub workflow manually with `ref=<commit-sha>`.

## Verification

After a deployment:

```bash
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && cat .deployed-sha && docker compose ps && curl --fail http://127.0.0.1:3000/health"
ssh exe.dev "share show exe-demo"
```

Expected:

- `.deployed-sha` matches the intended commit.
- Compose service is running and eventually healthy.
- `/health` returns JSON with `ok: true`.
- exe.dev proxy points at port `3000`.
