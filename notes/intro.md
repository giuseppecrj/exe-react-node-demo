# exe.dev is the AI-native deployment primitive I wanted

## 1. The problem: AI projects hit cloud friction fast

AI tinkering has a weird shape.

You start with a prompt, a sketch, maybe a half-working agent loop in a local repo. Twenty minutes later you have a small app that needs a real URL, a database, a webhook endpoint, a background worker, maybe Redis, maybe a cron job, maybe a browser session. The idea is moving quickly. The infrastructure is not.

Most cloud platforms were not built for this style of work. They were built around packaging, deployment artifacts, immutable containers, preview environments, cold starts, and dashboards full of knobs. That is fine when you know exactly what you are shipping. It is less fun when you are vibecoding with an agent and the shape of the thing changes every ten minutes.

Serverless sounds frictionless until your agent needs a mutable filesystem. Containers sound clean until every change becomes a build-push-deploy cycle. PaaS platforms are great until you need to run a weird daemon, inspect a local SQLite file, install a package, or leave a half-finished experiment running overnight. Then you are back to fighting the platform instead of building the thing.

AI developers need something different. Not more abstraction. Less.

They need a real machine.

## 2. Why exe.dev matters

exe.dev is refreshingly simple: persistent Linux VMs, on the internet, with HTTPS and auth handled for you.

You do not design your app around exe.dev. You do not learn a new deployment model. You SSH into a computer:

```bash
ssh exe.dev
```

That is the control plane. From there you can create VMs, list them, share them, resize them, and manage access. Each VM is just Linux. You can SSH into it, clone a repo, run Docker Compose, start Postgres, tail logs, edit files, or let an agent work inside it.

That is the whole point. exe.dev feels less like a cloud product and more like someone took the parts of a VPS that developers actually like, then removed the tedious parts.

You get persistent disk, so your app state does not disappear between deploys. You get automatic HTTPS, so you are not thinking about certbot at 1am. You get built-in private access, so a prototype can be online without becoming public by accident. And when you do want to share it, you can hand someone a link.

For AI tinkering, that is a big deal. The fastest path from idea to usable app is often not a perfect platform abstraction. It is a box you can mutate.

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

Now you are on a Linux machine. Clone your repo. Run your app. Start Docker Compose. Keep a database on disk. Leave a worker running. Try the ugly version before you clean it up.

A typical app deploy can be as boring as this:

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

That workflow is hard to overstate. You are not creating a Kubernetes cluster. You are not writing Terraform for a weekend experiment. You are just using a computer.

If you like where the experiment is going, clone the VM and keep moving.

## 4. Core features that make the difference

Persistent disk is the first thing that clicks.

A lot of AI apps are stateful in annoying ways. They have embeddings, local caches, SQLite files, Postgres databases, Redis queues, uploaded files, model artifacts, browser profiles, generated assets, and logs you actually want to inspect. On exe.dev, those things can just live on disk. Postgres works. Redis works. SQLite works. Docker volumes work. You do not have to externalize every piece of state just to survive a deploy.

Automatic HTTPS and IAM are the second click.

Every VM gets an HTTPS endpoint like:

```text
https://my-ai-app.exe.xyz/
```

exe.dev handles certificates and proxying. Access is private by default, which is exactly what you want for half-baked AI tools. You can share with specific people, keep it to yourself, or make it public when the thing is ready. That turns prototypes into real demos without turning every demo into a security chore.

Instant VM cloning is the third click.

This is perfect for agent iteration. You can snapshot a working environment, clone it, and let an agent try something risky in the copy. Or keep one VM stable while another becomes the chaos branch. For AI-assisted development, where exploration is cheap but cleanup is expensive, cloneable machines are a surprisingly powerful primitive.

Then there is Shelley.

Shelley is exe.dev's coding agent. The important part is not that there is another AI coding UI. The important part is where it runs. Shelley runs on the VM, next to your code, your dependencies, your logs, your database, and your actual deployment environment. It can inspect the same machine your app runs on. It can edit and test in place. It can deploy without translating its work through three layers of CI ceremony.

The pricing model also fits the way tinkerers think: $20/month flat rate for up to 50 VMs. That matters because marginal cost changes behavior. If every idea means another bill, you become more conservative. If spinning up another machine is basically free inside your plan, you try more things.

That is the energy exe.dev gets right.

## 5. Why it is perfect for AI development

Agents are not normal build tools.

A build tool wants clean inputs and repeatable outputs. An agent wants a place to poke around. It wants to read files, run commands, install dependencies, inspect logs, break something, fix it, restart it, and check whether the thing actually works.

That is why the normal cloud workflow feels awkward for AI projects. The agent writes code locally, then you push it into a remote build system, then a container restarts, then logs appear somewhere else, then you copy an error back into chat. Every boundary adds latency. Every translation step loses context.

On exe.dev, the agent can work where the app lives.

That changes the loop:

```text
ask agent → edit code → run app → inspect logs → fix bug → share URL
```

No fake environment. No "works locally" gap. No waiting on a cold start just to see if a route returns JSON. If the app needs Postgres, install Postgres. If it needs a queue, run Redis. If it needs a browser, run one. If it needs a long-running worker, leave it running.

This is the part that feels AI-native to me. Not because exe.dev hides the machine. Because it gives the machine back to the agent.

A mutable Linux VM is an incredible workspace for an AI developer. The agent can accumulate context in the filesystem. It can leave artifacts. It can use ordinary Unix tools. It can run the exact server that users will hit. And when the thing works, the demo URL is already there.

That is vibecoding at its best: you are not pretending the prototype is production, but you are also not trapped in localhost theater. You are building something real enough to click, share, and iterate on.

## 6. The future: compute for agent workflows

The next wave of AI tooling will not be only about better models. It will be about better places for models to act.

Agents need compute with memory. They need environments that survive between sessions. They need safe sharing. They need access to repos, databases, logs, browsers, and background processes. They need somewhere to make a mess, then turn the mess into a working app.

exe.dev is pointed directly at that future.

The upcoming LLM integrations make the direction pretty obvious: exe.dev is becoming a compute primitive for AI-driven development. A place where human developers and coding agents can collaborate on the same real machine, with the same files, the same services, and the same URL.

That is a different mental model from "deploy my container somewhere."

It is closer to:

```text
give me a computer for this idea
let my agent work there
show me the link when it runs
```

For AI tinkerers, that is the dream. Less platform choreography. More building. More weird experiments that actually make it onto the internet.

I do not want to design every side project around cloud infrastructure. I want to SSH into a machine, hand it to an agent, and watch the idea become real.

That is why exe.dev is interesting.

Not because it reinvents the server.

Because it remembers that the server was already pretty great.

## Thread version

1/ AI projects hit cloud friction fast. You start with a prompt and a repo. Twenty minutes later you need a real URL, a database, a webhook endpoint, a worker, maybe Redis. The idea is moving quickly. The infrastructure is not.

2/ Most platforms were built around immutable deploy artifacts, cold starts, dashboards, preview environments, and packaging rules. That is fine when you know exactly what you are shipping. It is awkward when you are vibecoding and the app shape changes every ten minutes.

3/ exe.dev has a simpler answer: persistent Linux VMs, on the internet, with HTTPS and auth handled for you. You do not design around it. You SSH into a real computer.

```bash
ssh exe.dev
```

4/ Create a VM, SSH into it, clone a repo, run Docker Compose, start Postgres, tail logs, let an agent edit files. It is just Linux, which is exactly why it works.

5/ Persistent disk matters for AI apps. Embeddings, SQLite, Postgres, Redis, uploaded files, browser profiles, generated assets, logs. On exe.dev, those things can just live on disk.

6/ HTTPS and access control are built in. Your VM gets a URL like `https://my-ai-app.exe.xyz/`. It is private by default. Share it with specific people or make it public when you are ready.

7/ VM cloning is underrated. Keep one stable environment, clone it, let an agent go wild in the copy. Perfect for the "try the risky idea without wrecking the working demo" workflow.

8/ Shelley, exe.dev's coding agent, runs directly on the VM. That means it sees the code, dependencies, logs, database, and deployment environment in context. It can edit, test, and deploy where the app actually lives.

9/ This is why exe.dev feels AI-native. Agents need mutable environments. They need to run commands, inspect logs, install packages, restart services, and leave useful artifacts behind. A real Linux VM is a great agent workspace.

10/ The loop becomes simple: ask agent → edit code → run app → inspect logs → fix bug → share URL. No fake localhost-only demo. No container restart theater. No cloud dashboard side quest.

11/ Pricing fits tinkering too: $20/month flat rate for up to 50 VMs. When the marginal cost of another idea drops, you try more ideas.

12/ The future is not just better models. It is better places for models to act. exe.dev is becoming a compute primitive for AI-driven development: give me a computer, let my agent work there, show me the link when it runs.
