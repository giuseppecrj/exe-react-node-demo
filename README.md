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
docker-compose.yml      Runs the production app on port 3000
docker-compose.dev.yml  Runs the Vite + Express dev servers on ports 5173 and 3000
.github/workflows/ci.yml
.github/workflows/deploy-exe.yml
scripts/exe-create-vm.sh
AGENTS.md               Agent-facing deployment guidance
docs/agent-exe-dev-playbook.md
                        Deeper agent workflow/playbook
skills/deploy-app-to-exe-dev/
                        Draft reusable agent skill
```

## Local development

Use Docker Compose if you want the same Node 22 toolchain locally and on exe.dev:

```bash
docker compose -f docker-compose.dev.yml up
```

Or run directly on your host if you already have Node 22 installed:

```bash
npm install
npm run dev
```

- React dev server: <http://localhost:5173>
- Node server: <http://localhost:3000>
- Local API calls from React should stay relative, e.g. `fetch('/api/hello')`; Vite proxies `/api` to the Node server in `client/vite.config.js`.
- On an exe.dev VM, run the same Docker Compose command and open `https://your-vm.exe.xyz:5173/`. Vite is configured to allow `*.exe.xyz` dev hosts.

## Local production check

```bash
npm run check
docker compose up -d --build
curl http://localhost:3000/health
```

If you do not have host Node installed, run the check in Docker:

```bash
docker compose -f docker-compose.dev.yml run --rm web sh -lc "npm ci && npm run check"
```

## Agent usage

This repo is intended to be a reference pattern for agents. If an agent is asked to create and deploy an app to exe.dev, it should read:

- [`AGENTS.md`](AGENTS.md)
- [`docs/agent-exe-dev-playbook.md`](docs/agent-exe-dev-playbook.md)
- [`docs/exe-dev-setup.md`](docs/exe-dev-setup.md)

There is also a draft reusable skill at [`skills/deploy-app-to-exe-dev/SKILL.md`](skills/deploy-app-to-exe-dev/SKILL.md).

For VM-native agent workflows, treat the exe.dev GitHub integration as part of the standard setup so the VM can clone/pull private repos without GitHub PATs.

## Create an exe.dev VM

Full setup instructions live in [`docs/exe-dev-setup.md`](docs/exe-dev-setup.md).

```bash
chmod +x scripts/exe-create-vm.sh
./scripts/exe-create-vm.sh exe-react-node-demo
```

Or manually:

```bash
ssh exe.dev 'new --name=exe-react-node-demo --comment="React + Node demo" --tag=demo,react,node'
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

This demo serves the built React app from Express in production, so it avoids Vite dev-server host allow-list issues. For dev mode on exe.dev, `client/vite.config.js` sets `server.host = '0.0.0.0'` and allows `.exe.xyz` hosts. You can override this with `VITE_ALLOWED_HOSTS=host1,host2`.
