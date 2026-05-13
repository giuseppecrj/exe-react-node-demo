import React, { useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import './styles.css';

function App() {
  const [hello, setHello] = useState(null);

  useEffect(() => {
    fetch('/api/hello')
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
        <p className="eyebrow">React + Node on exe.dev</p>
        <h1>One tiny full-stack app, one persistent VM.</h1>
        <p className="lede">
          This demo builds a Vite React frontend, serves it from Express, and deploys with Docker
          to an exe.dev VM over SSH from GitHub Actions.
        </p>
        <div className="card">
          <span>API response</span>
          <pre>{JSON.stringify(hello ?? { loading: true }, null, 2)}</pre>
        </div>
      </section>
    </main>
  );
}

createRoot(document.getElementById('root')).render(<App />);
