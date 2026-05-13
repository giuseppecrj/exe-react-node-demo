# Agent playbook: create an app, deploy it to exe.dev, return a link

This document explains how an agent should use this repo as a reusable deployment pattern.

## Does this make sense as a repo?

Yes. The repo can serve as an executable reference implementation:

- It demonstrates the app shape agents should produce.
- It contains known-good Docker and Compose patterns.
- It captures exe.dev-specific gotchas such as Vite allowed hosts, proxy ports, and avoiding `apt install npm`.
- It gives agents concrete commands they can copy, adapt, run, and verify.

The repo should stay small, boring, and explicit. It is less a product app and more a deployment specimen.

## Should this become a skill?

Yes, but keep the layers separate:

1. **`AGENTS.md` in this repo** is the canonical project-local reference. Any agent that opens this repo should immediately know the exe.dev deployment pattern.
2. **A reusable skill** should be a short triggerable workflow for agents working in other repos. The skill should tell the agent to apply the pattern from this repo: Docker-first dev/prod, exe.dev SSH control plane, proxy setup, verification, and final URL.
3. **Scripts/templates** can grow later if repeated steps become deterministic enough to automate safely.

Do not put every exe.dev doc into the skill. The skill should route the agent to this repo's pattern and to exe.dev docs when it needs platform details.

## What an agent needs to deploy automatically

### Required from the user/environment

- exe.dev account already created.
- User's SSH public key registered with exe.dev.
- Local shell can run `ssh exe.dev whoami` successfully.
- Permission to create a VM.
- Desired app/VM name or permission to choose one.
- App visibility: private by default, public only if requested.

### Required from the target app

- A single HTTP entry port for production, usually `3000`.
- A deterministic build/check command.
- A health endpoint, preferably `/health`.
- A production Dockerfile.
- A production Compose file.
- For dev mode, a Compose file using official runtime images rather than host-level runtime installs.

### Required when the VM must access the repo

- exe.dev GitHub integration installed for `OWNER/REPO`.
- Integration attached to the target VM or to a tag/auto-attach rule.
- Integration clone hostname, e.g. `https://<integration>.int.exe.xyz/OWNER/REPO.git`.

This is required for private repos when the VM will clone, pull, or run agents against the repo. It is not required for a one-shot `rsync` deploy from the local workspace.

### Optional but useful

- Custom domain requirements.
- Whether the VM is temporary, dev, staging, or prod.
- Whether to install/use Shelley or other agents on the VM.

## Automation boundaries

Agents can safely automate:

- Inspecting app framework and ports.
- Adding Dockerfile/Compose files.
- Running local checks.
- Creating a VM after `ssh exe.dev whoami` works.
- Attaching an existing GitHub integration to a VM.
- Copying files with `rsync` for one-shot deploys.
- Cloning/pulling through the GitHub integration for VM-native workflows.
- Running `docker compose up -d --build`.
- Setting the exe.dev proxy port.
- Returning the verified URL.

Agents should ask before:

- Making the VM public.
- Deleting/recreating VMs.
- Creating long-lived API tokens.
- Adding GitHub deploy secrets.
- Changing DNS/custom domains.
- Installing broad system packages on the VM.

Agents cannot automate without user action:

- First-time exe.dev login/account setup.
- Browser-based GitHub integration authorization or GitHub App installation.
- SSH key registration if no key is already accepted by exe.dev.

## Repo transfer decision tree

Use the GitHub integration by default when the VM will keep working with the repo:

- Private repo cloned from the VM: **GitHub integration required**.
- Shelley/agent coding inside the VM: **GitHub integration strongly preferred**.
- Long-lived dev/prod VM that pulls updates: **GitHub integration preferred**.
- One-shot deploy from the current local workspace: `rsync` is acceptable.
- Public repo: plain `git clone` is acceptable, but integration still works.
- GitHub Actions deployment: SSH deploy key/secrets can replace VM-side GitHub integration.

Integration command shape:

```bash
ssh exe.dev "integrations add github --name=<integration> --repository=OWNER/REPO --attach=vm:<vm>"
ssh exe.dev "integrations attach <integration> vm:<vm>"
ssh <vm>.exe.xyz "git clone https://<integration>.int.exe.xyz/OWNER/REPO.git"
```

## The one-shot deployment workflow

Use this when the user asks: "create a simple app, deploy it to exe.dev, and give me the link."

1. Build or modify the app locally.
2. Add Docker/Compose using this repo's pattern.
3. Run checks locally.
4. Verify exe.dev control-plane access.
5. Create a VM.
6. Copy the workspace to the VM.
7. Build/run with Docker Compose on the VM.
8. Point the proxy at the app port.
9. Verify health locally on the VM and through the exe.dev URL if accessible.
10. Return the URL and important commands.

Command skeleton:

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

Return:

```text
Deployed: https://my-app.exe.xyz/
```

## Dev VM workflow

Use this when the user wants interactive development or agent work on exe.dev.

1. Create a `-dev` VM.
2. Attach GitHub integration if the repo is private.
3. Clone the repo inside the VM.
4. Run dev Compose.
5. Point proxy at the dev server port.
6. Open Shelley for agent work.

For this repo:

```bash
docker compose -f docker-compose.dev.yml up
ssh exe.dev "share port exe-demo 5173"
```

Open:

```text
https://exe-demo.exe.xyz/
https://exe-demo.shelley.exe.xyz/
```

## Production workflow

Use this for the stable hosted app.

```bash
docker compose -f docker-compose.dev.yml down || true
docker compose up -d --build
ssh exe.dev "share port <vm> 3000"
```

Keep production boring:

- No Vite dev server.
- No host-level Node/npm dependency.
- No direct agent mutation unless the user explicitly wants that.
- Verify with `/health` and logs.

## Recommended reusable skill shape

A skill should be named something like `deploy-app-to-exe-dev`.

Trigger description:

```text
Deploys apps to exe.dev using a Docker-first pattern inspired by exe-react-node-demo. Use when the user asks to create, prototype, host, or deploy an app on exe.dev and wants a working URL.
```

The skill should instruct the agent to:

1. Inspect the app and identify the production port.
2. Add or adapt Dockerfile/Compose.
3. Avoid host-level runtime installs on exe.dev.
4. Verify `ssh exe.dev whoami` before VM creation.
5. Use `ssh exe.dev` for lifecycle/proxy commands.
6. Use `ssh <vm>.exe.xyz` for VM shell commands.
7. Deploy with Docker Compose.
8. Set proxy port.
9. Verify health.
10. Return the URL.

Keep the skill short. Use this repo's `AGENTS.md` and docs as the deeper reference.
