import react from '@vitejs/plugin-react';
import { defineConfig } from 'vite';
import { fileURLToPath } from 'node:url';

const root = fileURLToPath(new URL('.', import.meta.url));
const apiTarget = process.env.API_PROXY_TARGET ?? 'http://127.0.0.1:3000';
const allowedHosts = (process.env.VITE_ALLOWED_HOSTS ?? process.env.EXE_DEV_HOST ?? '')
  .split(',')
  .map((host) => host.trim())
  .filter(Boolean);

export default defineConfig({
  root,
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    ...(allowedHosts.length > 0 ? { allowedHosts } : {}),
    proxy: {
      '/api': {
        target: apiTarget,
        changeOrigin: true,
      },
    },
  },
  build: {
    outDir: '../dist/public',
    emptyOutDir: true,
  },
});
