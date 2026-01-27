import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [],
  build: {
    rollupOptions: {
      input: {
        main: 'index.html',
        monitor: 'monitor.html',
      },
    },
  },
})
