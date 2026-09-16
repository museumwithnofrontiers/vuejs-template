import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    vueDevTools(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    // See compose.yml: only needed for hot reload inside Docker on hosts
    // where filesystem change events don't reach the container reliably.
    watch: {
      usePolling: process.env.VITE_USE_POLLING === 'true',
    },
  },
})
