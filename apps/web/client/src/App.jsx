import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

function App() {
  const [hello, setHello] = useState(null);

  useEffect(() => {
    fetch("/api/hello")
      .then(async (res) => {
        if (!res.ok) {
          throw new Error(`API request failed with ${res.status}`);
        }
        return res.json();
      })
      .then((response) => setHello(response))
      .catch((error) => setHello({ error: error.message }));
  }, []);

  return (
    <main className="shell">
      <section className="hero">
        <p className="eyebrow">exe.dev deployment demo</p>
        <h1>Production-shaped Bun monorepo, deployed to one persistent VM.</h1>
        <p className="lede">
          This reference app uses a Bun workspace, Vite React frontend, Express API, Docker Compose,
          exe.dev GitHub integration, and GitHub Actions SSH deployment.
        </p>
        <div className="card">
          <span>API response</span>
          <pre>{JSON.stringify(hello ?? { loading: true }, null, 2)}</pre>
        </div>
      </section>
    </main>
  );
}

createRoot(document.getElementById("root")).render(<App />);
