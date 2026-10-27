import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // Keep the output folder the Dockerfile and nginx expect
  build: {
    outDir: 'build',
  },
  // Local development: serve on 3000 and send API calls to the API on 8080
  server: {
    port: 3000,
    proxy: {
      '/api': 'http://localhost:8080',
      '/health': 'http://localhost:8080',
    },
  },
  test: {
    environment: 'jsdom',
    passWithNoTests: true,
  },
});
