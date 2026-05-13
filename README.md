# exe.dev React + Node demo

A minimal full-stack demo showing how to run a React website plus Node.js server on an [exe.dev](https://exe.dev) VM and deploy it from GitHub Actions.

## What I pulled from the linked video + exe.dev docs

- exe.dev is VM-first: persistent Linux VMs, reachable over HTTPS, with sane secure defaults.
- It is good for quick idea deployment because you can create many small VMs without paying per tiny project.
- The public/private web proxy is built in. `https://<vm>.exe.xyz/` proxies to a port on the VM and is private by default.
- Docker works on the default `exeuntu` image (`docker run --rm alpine:latest echo hello`).
- The proxy chooses a port from a Dockerfile `EXPOSE`; this demo exposes `3000`. You can force it with `ssh exe.dev share port <vmname> 3000`.
- GitHub Actions can deploy by SSHing into the VM, copying the repo, and running `docker compose up -d --build`.

## App structure

```text
client/                 Vite React app
server/                 Express API + static file server
Dockerfile              Builds React, then runs Express in production
docker-compose.yml      Runs the app on port 3000
.github/workflows/ci.yml
.github/workflows/deploy-exe.yml
scripts/exe-create-vm.sh
```

## Local development

```bash
npm install
npm run dev
```

- React dev server: <http://localhost:5173>
- Node server: <http://localhost:3000>

## Local production check

```bash
npm run check
docker compose up -d --build
curl http://localhost:3000/health
```

## Create an exe.dev VM

```bash
chmod +x scripts/exe-create-vm.sh
./scripts/exe-create-vm.sh exe-react-node-demo
```

Or manually:

```bash
ssh exe.dev new --name exe-react-node-demo --comment "React + Node demo" --tag demo,react,node
ssh exe-react-node-demo.exe.xyz
```

Inside the VM, verify Docker:

```bash
docker run --rm alpine:latest echo hello
```

## GitHub Actions deployment

Add these repository secrets:

| Secret | Example | Notes |
| --- | --- | --- |
| `EXE_VM_HOST` | `exe-react-node-demo.exe.xyz` | The exe.dev VM host. |
| `EXE_SSH_PRIVATE_KEY` | `-----BEGIN OPENSSH PRIVATE KEY-----...` | A private key whose public key is registered with exe.dev. |

Optional repository variables:

| Variable | Default |
| --- | --- |
| `EXE_VM_USER` | `exedev` |
| `EXE_APP_DIR` | `/home/exedev/apps/exe-react-node-demo` |

Then push to `main` or run **Deploy to exe.dev** manually.

The workflow:

1. Checks out the repo.
2. SSHes into the exe.dev VM.
3. Rsyncs the app to `/home/exedev/apps/exe-react-node-demo`.
4. Runs `docker compose up -d --build` on the VM.
5. Verifies `http://127.0.0.1:3000/health`.

## Configure exe.dev proxy

The Dockerfile has `EXPOSE 3000`, which exe.dev may auto-detect. To force the HTTPS proxy to the app port:

```bash
ssh exe.dev share port exe-react-node-demo 3000
```

By default, exe.dev web access is private/authenticated. To make the site public:

```bash
ssh exe.dev share set-public exe-react-node-demo
```

To make it private again:

```bash
ssh exe.dev share set-private exe-react-node-demo
```

## Notes for Vite/Next dev servers

This demo serves the built React app from Express in production, so it avoids Vite dev-server host allow-list issues. If you run a Vite dev server directly on exe.dev, configure `server.host = '0.0.0.0'` and `server.allowedHosts = ['<vm>.exe.xyz']`.
