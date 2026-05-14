# exe.dev is the AI-native deployment primitive I wanted

## 1. AI projects run into cloud friction fast

AI tinkering has a weird shape.

You start with a prompt, a sketch, maybe a half-working agent loop in a local repo. Twenty minutes later the little thing needs a real URL, a database, a webhook endpoint, a worker, Redis, cron, maybe even a browser session. The idea is moving. The infrastructure is not.

Most cloud platforms were built for a cleaner world than this. They assume packaging, deployment artifacts, immutable containers, preview environments, cold starts, dashboards, knobs. That works when you know what you're shipping. It feels absurd when you're vibecoding with an agent and the app changes shape every ten minutes.

Serverless is great until the agent needs a mutable filesystem. Containers are great until every tiny change turns into build, push, deploy, wait. PaaS is great until you need a weird daemon, a local SQLite file, an extra package, or a half-finished experiment still running tomorrow morning. Suddenly you're negotiating with the platform instead of building the thing.

AI developers don't need more abstraction here. They need less.

They need a real machine.

## 2. Why exe.dev matters

exe.dev is simple in the way I want more tools to be simple: persistent Linux VMs, already on the internet, with HTTPS and access control handled for you.

You don't design your app around exe.dev. You don't learn a new deployment model. You SSH into a computer:

```bash
ssh exe.dev
```

That's the control plane. From there you can create VMs, list them, share them, resize them, and manage access. Each VM is just Linux. SSH in, clone a repo, run Docker Compose, start Postgres, tail logs, edit files, or let an agent work inside it.

That's the whole trick. exe.dev feels less like a cloud product and more like someone took the parts of a VPS that developers actually like, then removed the boring chores.

You get persistent disk, so app state doesn't vanish between deploys. You get automatic HTTPS, so you're not thinking about certbot at 1am. You get private access by default, so a prototype can be online without accidentally becoming public. When you do want to share it, you hand someone a link.

For AI tinkering, that matters. The fastest path from idea to usable app is often not a perfect platform abstraction. It's a box you can mutate.

## 3. How to start

The first move is almost comically direct:

```bash
ssh exe.dev
```

Create a VM:

```bash
ssh exe.dev "new --name=my-ai-app"
```

SSH into it:

```bash
ssh my-ai-app.exe.xyz
```

Now you're on a Linux machine. Clone your repo. Run the app. Start Docker Compose. Keep a database on disk. Leave a worker running. Try the ugly version before you clean it up.

A typical app deploy can be this boring:

```bash
git clone https://github.com/you/my-ai-app.git
cd my-ai-app
docker compose up -d --build
curl http://127.0.0.1:3000/health
```

Then point exe.dev's HTTPS proxy at the app port:

```bash
ssh exe.dev "share port my-ai-app 3000"
```

Open:

```text
https://my-ai-app.exe.xyz/
```

By default, access is private. If you want to make the app public:

```bash
ssh exe.dev "share set-public my-ai-app"
```

That workflow is hard to overstate. No Kubernetes cluster. No Terraform for a weekend experiment. Just a computer.

If the experiment starts to look real, clone the VM and keep moving.

## 4. The features that make it click

Persistent disk is the first one.

A lot of AI apps are stateful in annoying ways. Embeddings, local caches, SQLite files, Postgres databases, Redis queues, uploaded files, model artifacts, browser profiles, generated assets, logs you actually want to inspect. On exe.dev, those can just live on disk. Postgres works. Redis works. SQLite works. Docker volumes work. You don't have to externalize every bit of state just to survive a deploy.

HTTPS and access control are the second one.

Every VM gets an HTTPS endpoint like:

```text
https://my-ai-app.exe.xyz/
```

exe.dev handles certificates and proxying. Access is private by default, which is exactly what you want for half-baked AI tools. Share it with specific people, keep it to yourself, or make it public when it's ready. That turns prototypes into real demos without turning every demo into a security errand.

VM cloning is the third.

This is perfect for agent iteration. Snapshot a working environment, clone it, and let an agent try the risky thing in the copy. Keep one VM stable while another becomes the chaos branch. For AI-assisted development, where exploration is cheap and cleanup is expensive, cloneable machines are a surprisingly good primitive.

Then there's Shelley.

Shelley is exe.dev's coding agent. The interesting part is not that there's another AI coding UI. The interesting part is where it runs. Shelley runs on the VM, next to your code, dependencies, logs, database, and actual deployment environment. It can inspect the same machine your app runs on. It can edit and test in place. It can deploy without translating its work through three layers of CI ceremony.

The pricing fits the way tinkerers think too: $20/month flat rate for up to 50 VMs. That matters because marginal cost changes behavior. If every idea creates another bill, you become more conservative. If another machine is basically free inside the plan, you try more things.

That's the part exe.dev gets right.

## 5. Why this works for AI development

Agents are not normal build tools.

A build tool wants clean inputs and repeatable outputs. An agent wants a place to poke around. It wants to read files, run commands, install dependencies, inspect logs, break something, fix it, restart it, and check whether the thing actually works.

That's why the normal cloud workflow feels awkward for AI projects. The agent writes code locally, you push it into a remote build system, a container restarts, logs show up somewhere else, and then you copy an error back into chat. Every boundary adds latency. Every translation step loses context.

On exe.dev, the agent can work where the app lives.

The loop gets much smaller:

```text
ask agent → edit code → run app → inspect logs → fix bug → share URL
```

No fake environment. No "works locally" gap. No waiting on a cold start just to find out whether a route returns JSON. If the app needs Postgres, install Postgres. If it needs a queue, run Redis. If it needs a browser, run one. If it needs a long-running worker, leave it running.

This is the part that feels AI-native to me. Not because exe.dev hides the machine. Because it gives the machine back to the agent.

A mutable Linux VM is a great workspace for an AI developer. The agent can build context in the filesystem. It can leave artifacts. It can use ordinary Unix tools. It can run the exact server users will hit. And when the thing works, the demo URL is already there.

That's vibecoding at its best. You're not pretending the prototype is production, but you're also not trapped in localhost theater. You're building something real enough to click, share, and iterate on.

## 6. Compute for agent workflows

The next wave of AI tooling won't just be better models. It will be better places for models to act.

Agents need compute with memory. They need environments that survive between sessions. They need safe sharing. They need access to repos, databases, logs, browsers, and background processes. They need somewhere to make a mess, then turn the mess into a working app.

exe.dev is aimed at that future.

The upcoming LLM integrations make the direction pretty clear: exe.dev is becoming a compute primitive for AI-driven development. Human developers and coding agents can work on the same real machine, with the same files, the same services, and the same URL.

That's a different mental model from "deploy my container somewhere."

It's closer to:

```text
give me a computer for this idea
let my agent work there
show me the link when it runs
```

For AI tinkerers, that's the dream. Less platform choreography. More building. More weird experiments that actually make it onto the internet.

I don't want to design every side project around cloud infrastructure. I want to SSH into a machine, hand it to an agent, and watch the idea become real.

That's why exe.dev is interesting.

Not because it reinvents the server.

Because it remembers that the server was already pretty great.

## Thread version

1/ AI projects hit cloud friction fast. You start with a prompt and a repo. Twenty minutes later you need a real URL, a database, a webhook endpoint, a worker, maybe Redis. The idea is moving. The infrastructure is not.

2/ Most platforms assume immutable deploy artifacts, cold starts, dashboards, preview environments, and packaging rules. Fine when you know what you're shipping. Awkward when you're vibecoding and the app changes shape every ten minutes.

3/ exe.dev has a simpler answer: persistent Linux VMs, on the internet, with HTTPS and access control handled for you. You don't design around it. You SSH into a real computer.

```bash
ssh exe.dev
```

4/ Create a VM, SSH into it, clone a repo, run Docker Compose, start Postgres, tail logs, let an agent edit files. It's just Linux, which is exactly why it works.

5/ Persistent disk matters for AI apps. Embeddings, SQLite, Postgres, Redis, uploads, browser profiles, generated assets, logs. On exe.dev, those things can just live on disk.

6/ HTTPS and access control are built in. Your VM gets a URL like `https://my-ai-app.exe.xyz/`. It's private by default. Share it with specific people or make it public when you're ready.

7/ VM cloning is underrated. Keep one stable environment, clone it, let an agent go wild in the copy. Perfect for trying the risky idea without wrecking the working demo.

8/ Shelley, exe.dev's coding agent, runs directly on the VM. It sees the code, dependencies, logs, database, and deployment environment in context. It can edit, test, and deploy where the app actually lives.

9/ This is why exe.dev feels AI-native. Agents need mutable environments. They need to run commands, inspect logs, install packages, restart services, and leave useful artifacts behind. A real Linux VM is a great agent workspace.

10/ The loop becomes simple: ask agent → edit code → run app → inspect logs → fix bug → share URL. No fake localhost-only demo. No container restart theater. No cloud dashboard side quest.

11/ Pricing fits tinkering too: $20/month flat rate for up to 50 VMs. When another idea doesn't mean another bill, you try more ideas.

12/ The future is not just better models. It's better places for models to act. exe.dev is becoming a compute primitive for AI-driven development: give me a computer, let my agent work there, show me the link when it runs.
