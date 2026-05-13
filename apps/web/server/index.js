import path from "node:path";
import { fileURLToPath } from "node:url";
import express from "express";
import morgan from "morgan";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const app = express();
const port = Number(process.env.PORT || 3000);
const publicDir = path.resolve(__dirname, "../dist/public");

app.set("trust proxy", true);
app.use(morgan("tiny"));
app.use(express.json());

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "exe-react-node-demo" });
});

app.get("/api/hello", (req, res) => {
  res.json({
    message: "Hello from the Bun + Express server on exe.dev!",
    host: req.get("host"),
    forwardedHost: req.get("x-forwarded-host") ?? null,
    forwardedProto: req.get("x-forwarded-proto") ?? null,
    timestamp: new Date().toISOString(),
  });
});

if (process.env.NODE_ENV === "production") {
  app.use(express.static(publicDir));
  app.use((_req, res) => res.sendFile(path.join(publicDir, "index.html")));
} else {
  app.get("/", (_req, res) => {
    res.type("text/plain").send("API server is running. Start Vite with `bun run dev:client`.");
  });
}

app.listen(port, "0.0.0.0", () => {
  console.log(`Server listening on http://0.0.0.0:${port}`);
});
