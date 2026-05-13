# exe.dev setup for this repo

This document captures the repeatable setup for deploying this React + Node app to an [exe.dev](https://exe.dev) VM from GitHub Actions.

The intended deployment model is deliberately simple:

1. Create an exe.dev VM.
2. Ensure Docker works on the VM.
3. Store SSH deployment credentials in GitHub Secrets.
4. Let GitHub Actions copy the repo to the VM and run `docker compose up -d --build`.
5. Point exe.dev's HTTPS proxy at the app port.

No custom platform adapter is required because exe.dev is just a persistent Linux VM with built-in HTTPS proxying.

## Prerequisites

You need:

- An exe.dev account.
- An SSH public key added to exe.dev.
- Local SSH access to the exe.dev control plane.
- A GitHub repository containing this app.
- GitHub Actions enabled for the repo.

Before continuing, verify local access:

```bash
ssh exe.dev whoami
ssh exe.dev ls
```

On first connection, verify the exe.dev host fingerprint before accepting it:

```text
SHA256:JJOP/lwiBGOMilfONPWZCXUrfK154cnJFXcqlsi6lPo.
```

## 1. Create the VM

From this repo:

```bash
chmod +x scripts/exe-create-vm.sh
./scripts/exe-create-vm.sh exe-react-node-demo
```

Or manually:

```bash
ssh exe.dev 'new --name=exe-react-node-demo --comment="React + Node demo deployed from GitHub Actions" --tag=demo,react,node'
```

Use `--flag=value` for exe.dev value flags, and keep the outer quotes when a value contains spaces. Without that, exe.dev can see values like the VM name or words in `--comment` as unsupported positional arguments.

Verify the VM appears:

```bash
ssh exe.dev ls
```

SSH into the VM:

```bash
ssh exe-react-node-demo.exe.xyz
```

## 2. Verify Docker on the VM

Inside the VM, run:

```bash
docker run --rm alpine:latest echo hello
```

If that prints `hello`, Docker is ready.

This repo deploys with Docker Compose, so also check:

```bash
docker compose version
```

You do **not** need host-level Node/npm. Avoid `sudo apt install npm`; Ubuntu's `npm` package can install an old Node/npm toolchain. This repo uses Docker Compose for both dev and production so Node 22 comes from the container image.

For development on the VM, clone the repo, then run:

```bash
cd exe-react-node-demo
EXE_DEV_HOST=exe-react-node-demo.exe.xyz docker compose -f docker-compose.dev.yml up
```

This starts:

- Vite React dev server on port `5173`
- Express API server on port `3000`

Open the Vite dev server through exe.dev's extra port proxy:

```text
https://exe-react-node-demo.exe.xyz:5173/
```

Or point the main exe.dev HTTPS proxy at Vite while developing:

```bash
ssh exe.dev share port exe-react-node-demo 5173
```

Switch the main proxy back to production Express before/after deploying production:

```bash
ssh exe.dev share port exe-react-node-demo 3000
```

If you explicitly want to run the app directly on the VM without Docker, install Node 22 with a user-level version manager such as `fnm`, not `apt`.

## 3. Create or choose a deployment SSH key

GitHub Actions needs an SSH private key that can connect to the exe.dev VM.

Recommended: use a dedicated deploy key rather than your personal day-to-day SSH key.

Create one locally:

```bash
ssh-keygen -t ed25519 -C exe-react-node-demo-deploy -f ~/.ssh/exe_react_node_demo_deploy
```

Add the public key to exe.dev:

```bash
cat ~/.ssh/exe_react_node_demo_deploy.pub | ssh exe.dev ssh-key add
```

Test the key:

```bash
ssh -i ~/.ssh/exe_react_node_demo_deploy exedev@exe-react-node-demo.exe.xyz whoami
```

Expected output:

```text
exedev
```

## 4. Add GitHub repository secrets

In GitHub:

```text
Repo → Settings → Secrets and variables → Actions → New repository secret
```

Add:

| Secret | Value |
| --- | --- |
| `EXE_VM_HOST` | `exe-react-node-demo.exe.xyz` |
| `EXE_SSH_PRIVATE_KEY` | Contents of `~/.ssh/exe_react_node_demo_deploy` |

To copy the private key safely on macOS:

```bash
pbcopy < ~/.ssh/exe_react_node_demo_deploy
```

Then paste into the GitHub secret value.

Do **not** commit this private key to the repository.

## 5. Optional GitHub repository variables

The deploy workflow has sensible defaults, but you can override them with repo variables:

```text
Repo → Settings → Secrets and variables → Actions → Variables
```

| Variable | Default | Purpose |
| --- | --- | --- |
| `EXE_VM_USER` | `exedev` | SSH user on the VM. |
| `EXE_APP_DIR` | `/home/exedev/apps/exe-react-node-demo` | Directory where the app is copied on the VM. |

Most setups do not need to set these.

## 6. Run deployment

The deploy workflow lives at:

```text
.github/workflows/deploy-exe.yml
```

It runs on:

- Pushes to `main`.
- Manual `workflow_dispatch` runs.

To deploy manually:

```text
GitHub → Actions → Deploy to exe.dev → Run workflow
```

The workflow does this:

1. Checks out the repo.
2. Configures SSH using `EXE_SSH_PRIVATE_KEY`.
3. Creates the app directory on the VM.
4. Uses `rsync` to copy the repo to the VM.
5. Runs `docker compose up -d --build` on the VM.
6. Verifies `http://127.0.0.1:3000/health`.

## 7. Configure exe.dev HTTPS proxy

The app listens on port `3000` in production.

The `Dockerfile` contains:

```dockerfile
EXPOSE 3000
```

exe.dev may auto-detect this, but you can force the proxy target:

```bash
ssh exe.dev share port exe-react-node-demo 3000
```

By default, exe.dev web access is private/authenticated.

Open the protected URL:

```text
https://exe-react-node-demo.exe.xyz/
```

To make it public:

```bash
ssh exe.dev share set-public exe-react-node-demo
```

To make it private again:

```bash
ssh exe.dev share set-private exe-react-node-demo
```

## 8. Verify the deployed app

After GitHub Actions completes, check:

```bash
curl https://exe-react-node-demo.exe.xyz/health
```

Expected shape:

```json
{"ok":true,"service":"exe-react-node-demo"}
```

Check the API route:

```bash
curl https://exe-react-node-demo.exe.xyz/api/hello
```

If the site is private, you may need to open it in a browser and authenticate through exe.dev instead of using unauthenticated `curl`.

## 9. Troubleshooting

### `Host key verification failed`

Run this locally once and accept the key only after verifying the fingerprint:

```bash
ssh exe.dev whoami
```

Expected fingerprint:

```text
SHA256:JJOP/lwiBGOMilfONPWZCXUrfK154cnJFXcqlsi6lPo.
```

### GitHub Actions cannot SSH into the VM

Check:

- `EXE_VM_HOST` is exactly the VM hostname, for example `exe-react-node-demo.exe.xyz`.
- `EXE_SSH_PRIVATE_KEY` contains the full private key, including header/footer lines.
- The matching public key has been added to exe.dev.
- The workflow is using the correct user, usually `exedev`.

Test locally with the same key:

```bash
ssh -i ~/.ssh/exe_react_node_demo_deploy exedev@exe-react-node-demo.exe.xyz whoami
```

### Wrong Node/npm version after `sudo apt install npm`

You do not need host Node/npm for this repo. Remove the distro packages and use Docker Compose instead:

```bash
sudo apt-get remove -y npm nodejs || true
sudo apt-get autoremove -y || true
EXE_DEV_HOST=exe-react-node-demo.exe.xyz docker compose -f docker-compose.dev.yml up
```

The dev Compose file uses the official Node 22 container image and keeps `node_modules` in a Docker volume.

If you still want host-level Node, install Node 22 with `fnm` rather than `apt`.

### Docker is missing or not running

SSH into the VM and run:

```bash
docker version
docker compose version
docker run --rm alpine:latest echo hello
```

exe.dev docs say Docker works on the default `exeuntu` image. If Docker is unavailable, confirm the VM image and recreate the VM with the default image if needed.

### Site loads privately but not publicly

Make the proxy public:

```bash
ssh exe.dev share set-public exe-react-node-demo
```

Confirm the target port:

```bash
ssh exe.dev share port exe-react-node-demo 3000
```

### App container is unhealthy

SSH into the VM:

```bash
ssh exe-react-node-demo.exe.xyz
cd /home/exedev/apps/exe-react-node-demo
docker compose ps
docker compose logs web --tail=100
curl http://127.0.0.1:3000/health
```

## 10. Optional: exe.dev HTTPS API token for Hermes

Hermes does **not** need an exe.dev API token for this repo if local SSH works. Hermes can run the same `ssh exe.dev ...` commands as you.

Only create an HTTPS API token if you want Hermes or scripts to call exe.dev with `curl` instead of SSH.

Generate a short-lived token:

```bash
ssh exe.dev ssh-key generate-api-key --exp=30d
```

Store it in Hermes' env file, usually `~/.hermes/.env`:

```bash
EXE_DEV_API_TOKEN=...
```

Then restart the Hermes gateway/session before relying on it.

Prefer SSH for normal VM setup and deployment because it is simpler and avoids introducing another secret.

## 11. Repurposing this for another repo

For a new app:

1. Copy `.github/workflows/deploy-exe.yml`.
2. Copy or adapt `Dockerfile` and `docker-compose.yml`.
3. Change app name references:
   - VM name
   - `EXE_APP_DIR`
   - Docker image/container names if desired
4. Ensure the app listens on `0.0.0.0` inside the container.
5. Ensure the Dockerfile has the correct `EXPOSE <port>`.
6. Run:

```bash
ssh exe.dev 'new --name=your-new-vm'
ssh exe.dev share port your-new-vm <port>
```

7. Add GitHub secrets:

```text
EXE_VM_HOST=your-new-vm.exe.xyz
EXE_SSH_PRIVATE_KEY=<deploy private key>
```

8. Push to `main` or run the deploy workflow manually.
