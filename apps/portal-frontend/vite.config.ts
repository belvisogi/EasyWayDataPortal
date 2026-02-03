import { defineConfig } from 'vite'


// https://vite.dev/config/
export default defineConfig({
  plugins: [],
  build: {
    rollupOptions: {
      input: {
        main: 'index.html',
        demo: 'demo.html',
        memory: 'memory.html',
        'test-datepicker': 'test-datepicker.html',
        'test-select': 'test-select.html',
        'test-grid': 'test-grid.html',
        'test-toaster': 'test-toaster.html',
        'test-cookie': 'test-cookie.html',
      },
    },
  },
})
