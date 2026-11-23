import { defineConfig } from 'vitest/config';

// base: on GitHub Pages the game lives under /<repo>/play/, locally at the root.
export default defineConfig({
  base: process.env.BASE_PATH ?? './',
  build: { target: 'es2022', chunkSizeWarningLimit: 2000 },
  server: { host: true },
  test: { include: ['test/**/*.test.ts'] },
});
