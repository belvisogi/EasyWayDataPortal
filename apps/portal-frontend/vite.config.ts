import { defineConfig } from 'vite'
import { resolve } from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [],
  build: {
    rollupOptions: {
      input: {
        input: {
          main: 'index.html',
          demo: 'demo.html',
          memory: 'memory.html',
        },
      },
    },
  },
})
