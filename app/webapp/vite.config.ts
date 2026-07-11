import { defineConfig } from 'vite'
import react, { reactCompilerPreset } from '@vitejs/plugin-react'
import babel from '@rolldown/plugin-babel'
import tailwindcss from '@tailwindcss/vite'
import { VitePWA } from 'vite-plugin-pwa'
import path from 'path'

// https://vite.dev/config/
export default defineConfig({
  build: {
    outDir: 'build',
  },
  plugins: [
    react(),
    babel({ presets: [reactCompilerPreset()] }),
    tailwindcss(),
    VitePWA({
      strategies: 'injectManifest',
      srcDir: 'src',
      filename: 'sw.ts',
      injectRegister: 'auto',
      registerType: 'autoUpdate',
      injectManifest: {
        // Let Vite build the TS service worker; Workbox injects the precache manifest
        injectionPoint: undefined,
      },
      manifest: {
        name: '光汇 - Lumalis',
        short_name: 'Lumalis',
        description: 'Campus marketplace — 我们的集市，不属于任何人',
        theme_color: '#0f172a',
        background_color: '#ffffff',
        display: 'standalone',
        orientation: 'portrait-primary',
        start_url: '/',
        scope: '/',
        lang: 'zh-CN',
        dir: 'ltr',
        categories: ['social', 'marketplace', 'education'],
        icons: [
          { src: '/pwa-icons/icon-192x192.png', sizes: '192x192', type: 'image/png' },
          { src: '/pwa-icons/icon-512x512.png', sizes: '512x512', type: 'image/png' },
          { src: '/pwa-icons/icon-512x512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
        ],
        screenshots: [],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
        globIgnores: ['**/vapid_*'],
      },
      devOptions: {
        enabled: false, // Disable SW in dev to avoid caching issues; enable for testing
      },
    }),
  ],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
})
