import { defineConfig } from 'vite'
import { resolve } from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [],
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        monitor: resolve(__dirname, 'monitor.html'),
        agents: resolve(__dirname, 'agents.html'),
        cortex: resolve(__dirname, 'cortex.html'),
        login: resolve(__dirname, 'login.html'),
      },
    },
  },
})
