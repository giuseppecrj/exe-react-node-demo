# Operations Runbook

Use this runbook when maintaining the exe.dev deployment.

## Known production values

| Item | Value |
| --- | --- |
| App port | `3000` |
| Dev frontend port | `5173` |
| Default VM user | `exedev` |
| Default VM app dir | `/home/exedev/exe-react-node-demo` |
| Health endpoint | `/health` |

## Inspect the VM

```bash
ssh exe.dev ls
ssh exe.dev "share show exe-demo"
ssh exe-demo.exe.xyz "docker version && docker compose version"
```

## Inspect the app

```bash
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && git status --short && git rev-parse HEAD && cat .deployed-sha 2>/dev/null || true"
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && docker compose ps"
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && docker compose logs web --tail=100"
ssh exe-demo.exe.xyz "curl --fail --silent --show-error http://127.0.0.1:3000/health"
```

## Start production manually

```bash
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && PORT=3000 scripts/exe-deploy-on-vm.sh"
ssh exe.dev "share port exe-demo 3000"
```

## Stop production

```bash
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && docker compose down"
```

## Run development on the VM

```bash
ssh exe-demo.exe.xyz
cd /home/exedev/exe-react-node-demo
docker compose -f docker-compose.dev.yml up
```

Open the extra port directly:

```text
https://exe-demo.exe.xyz:5173/
```

Or point the main proxy at Vite while developing:

```bash
ssh exe.dev "share port exe-demo 5173"
```

Switch the main proxy back to production:

```bash
ssh exe.dev "share port exe-demo 3000"
```

## Make access public/private

Private is the default. Only make public when explicitly requested.

```bash
ssh exe.dev "share set-public exe-demo"
ssh exe.dev "share set-private exe-demo"
```

Share with a specific user:

```bash
ssh exe.dev "share add exe-demo user@example.com"
```

## Common failures

### GitHub Actions cannot SSH to the VM

Check:

- `EXE_VM_HOST` is correct, e.g. `exe-demo.exe.xyz`.
- `EXE_SSH_PRIVATE_KEY` is the full private key.
- Matching public key is registered with exe.dev.
- The key can connect locally:

```bash
ssh -i ~/.ssh/exe_demo_github_actions_deploy exedev@exe-demo.exe.xyz whoami
```

### VM cannot fetch from GitHub integration

Symptom:

```text
integration not found or not attached to this VM
403
```

Check:

```bash
ssh exe.dev "integrations list"
ssh exe.dev "integrations attach <integration> vm:exe-demo"
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && git remote -v && git fetch origin"
```

If the remote hostname is stale, update it:

```bash
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && git remote set-url origin https://<integration>.int.exe.xyz/OWNER/REPO.git"
```

### Vite blocks exe.dev hostname

Symptom:

```text
Blocked request. This host is not allowed.
```

Fix: ensure Vite allows `.exe.xyz` hosts. This repo does so in `apps/web/client/vite.config.js`.

### Healthcheck fails immediately after deploy

The deploy script retries `/health` because containers may briefly reset connections while starting. If it still fails after retries:

```bash
ssh exe-demo.exe.xyz "cd /home/exedev/exe-react-node-demo && docker compose ps && docker compose logs web --tail=100"
```

### Wrong JavaScript runtime on the VM

Do not use:

```bash
sudo apt install npm
```

Use Docker Compose. The dev and production Compose paths use official Bun images.

### Main URL shows dev server instead of production

The exe.dev proxy is probably pointed at port `5173`. Switch back:

```bash
ssh exe.dev "share port exe-demo 3000"
```
