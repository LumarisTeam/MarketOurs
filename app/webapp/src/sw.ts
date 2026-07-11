/// <reference lib="webworker" />

import { precacheAndRoute, type PrecacheEntry } from 'workbox-precaching'
import { clientsClaim } from 'workbox-core'
import { registerRoute } from 'workbox-routing'
import { StaleWhileRevalidate, CacheFirst } from 'workbox-strategies'

declare let self: ServiceWorkerGlobalScope & {
  __WB_MANIFEST: Array<PrecacheEntry | string>
}

// Immediately claim any active clients so the new SW takes control without reload
clientsClaim()

// Precache all static assets (injected by Workbox at build time)
precacheAndRoute(self.__WB_MANIFEST)

// Cache API responses (stale-while-revalidate) for common GET data endpoints
registerRoute(
  ({ url }) => url.pathname.startsWith('/api/'),
  new StaleWhileRevalidate({
    cacheName: 'api-cache',
    matchOptions: { ignoreSearch: false },
  }),
  'GET',
)

// Cache images with a cache-first strategy
registerRoute(
  ({ request }) => request.destination === 'image',
  new CacheFirst({
    cacheName: 'image-cache',
    matchOptions: { ignoreSearch: true },
  }),
)

// ── Push Notification Handling ────────────────────────────────────────

interface PushPayload {
  title: string
  body?: string
  icon?: string
  badge?: string
  image?: string
  url?: string
  tag?: string
  requireInteraction?: boolean
  actions?: Array<{ action: string; title: string }>
}

self.addEventListener('push', (event: PushEvent) => {
  if (!event.data) return

  let payload: PushPayload
  try {
    payload = event.data.json()
  } catch {
    // Fallback: treat the text as the title
    payload = { title: event.data.text() }
  }

  const {
    title,
    body = '',
    icon = '/pwa-icons/icon-192x192.png',
    badge = '/pwa-icons/icon-192x192.png',
    image: notifImage,
    url = '/',
    tag,
    requireInteraction = false,
    actions,
  } = payload

  // Build notification options — cast at call site to avoid TS DOM type limitations
  const options = {
    body,
    icon,
    badge,
    data: { url },
    tag: tag ?? `lumalis-notif-${Date.now()}`,
    requireInteraction,
    vibrate: [200, 100, 200],
    actions: actions ?? [
      { action: 'open', title: 'View' },
      { action: 'close', title: 'Dismiss' },
    ],
    ...(notifImage ? { image: notifImage } : {}),
  }

  event.waitUntil(
    (async () => {
      // Ensure all windows are focused before showing notification
      const allClients = await self.clients.matchAll({ type: 'window' })
      const hasFocusedClient = allClients.some((c) => c.focused)

      if (!hasFocusedClient || requireInteraction) {
        await self.registration.showNotification(title, options as NotificationOptions)
      }
    })(),
  )
})

self.addEventListener('notificationclick', (event: NotificationEvent) => {
  event.notification.close()

  const url = event.notification.data?.url as string | undefined
  const action = event.action

  if (action === 'close') return

  const targetUrl = url || '/'

  event.waitUntil(
    (async () => {
      const clientList = await self.clients.matchAll({ type: 'window', includeUnreserved: true })

      // Try to focus an existing window on the target URL
      for (const client of clientList) {
        if (client.url.includes(targetUrl) && 'focus' in client) {
          return client.focus()
        }
      }

      // If there's any open window, navigate it to the target
      const anyClient = clientList[0]
      if (anyClient && 'navigate' in anyClient) {
        await (anyClient as WindowClient).navigate(targetUrl)
        return anyClient.focus()
      }

      // Open a new window as last resort
      if (self.clients.openWindow) {
        return self.clients.openWindow(targetUrl)
      }
    })(),
  )
})

// Optional: Handle push subscription change (e.g., expiration)
self.addEventListener('pushsubscriptionchange', (_event: Event) => {
  // The subscription expired or changed — the main thread should re-subscribe.
  // We post a message so the webPushService can handle it.
  self.clients.matchAll({ type: 'window' }).then((clients) => {
    for (const client of clients) {
      client.postMessage({ type: 'PUSH_SUBSCRIPTION_CHANGED' })
    }
  })
})

// Handle messages from the main thread (e.g., skip waiting)
self.addEventListener('message', (event: ExtendableMessageEvent) => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting()
  }
})

// Force this file to be treated as a module by TypeScript
export {}
