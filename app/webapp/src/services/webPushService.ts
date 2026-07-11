/**
 * Browser Web Push notification service.
 *
 * Manages Push API subscription lifecycle:
 *   - Permission request
 *   - Subscribe / unsubscribe
 *   - Sync subscription to the backend
 *
 * The VAPID public key is exposed via VITE_VAPID_PUBLIC_KEY env var.
 */

// Read from build-time env; also supports runtime override via `window.__VAPID_PUBLIC_KEY__`
const VAPID_PUBLIC_KEY: string =
  import.meta.env.VITE_VAPID_PUBLIC_KEY ||
  (typeof window !== 'undefined' && (window as any).__VAPID_PUBLIC_KEY__) ||
  'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEeaW04isWplerfD8p9AiPOf_iyEPxbhlcp_jbWCW9PtMU_JlrKKljs7dEP-NiKe8H7BiIP-46qOTr_Hy-PkxsVQ'

interface PushSubscriptionJson {
  endpoint: string
  keys: {
    p256dh: string
    auth: string
  }
  expirationTime?: number | null
}

// ── helpers ───────────────────────────────────────────────────────────

function urlBase64ToUint8Array(base64String: string): Uint8Array {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4)
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/')
  const rawData = atob(base64)
  const outputArray = new Uint8Array(rawData.length)
  for (let i = 0; i < rawData.length; i++) {
    outputArray[i] = rawData.charCodeAt(i)
  }
  return outputArray
}

// ── service ────────────────────────────────────────────────────────────

export const webPushService = {
  /** Whether the browser supports the Push API and Service Workers */
  isSupported(): boolean {
    return (
      typeof window !== 'undefined' &&
      'serviceWorker' in navigator &&
      'PushManager' in window &&
      'Notification' in window
    )
  },

  /** Returns the current Notification API permission state */
  getPermissionState(): NotificationPermission {
    if (!this.isSupported()) return 'denied'
    return Notification.permission
  },

  /** Request notification permission from the user */
  async requestPermission(): Promise<NotificationPermission> {
    if (!this.isSupported()) throw new Error('Web Push not supported')
    return Notification.requestPermission()
  },

  /** Get the current push subscription if any */
  async getCurrentSubscription(): Promise<PushSubscription | null> {
    if (!this.isSupported()) return null
    try {
      const registration = await navigator.serviceWorker.ready
      return registration.pushManager.getSubscription()
    } catch {
      return null
    }
  },

  /**
   * Subscribe to push notifications.
   * Returns the subscription or null if denied / unsupported.
   */
  async subscribe(): Promise<PushSubscription | null> {
    if (!this.isSupported()) {
      console.warn('[WebPush] Push API not supported in this browser.')
      return null
    }

    const permission = Notification.permission
    if (permission === 'denied') {
      console.warn('[WebPush] Notification permission was denied.')
      return null
    }

    if (permission === 'default') {
      const result = await this.requestPermission()
      if (result !== 'granted') return null
    }

    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(VAPID_PUBLIC_KEY) as unknown as BufferSource,
      })
      console.log('[WebPush] Subscribed:', subscription.endpoint)
      return subscription
    } catch (error) {
      console.error('[WebPush] Subscribe failed:', error)
      return null
    }
  },

  /** Unsubscribe from push notifications */
  async unsubscribe(): Promise<boolean> {
    try {
      const subscription = await this.getCurrentSubscription()
      if (subscription) {
        await subscription.unsubscribe()
        console.log('[WebPush] Unsubscribed.')
        return true
      }
      return false
    } catch (error) {
      console.error('[WebPush] Unsubscribe failed:', error)
      return false
    }
  },

  /** Serialize a PushSubscription to a JSON-friendly object for the backend */
  serializeSubscription(sub: PushSubscription): PushSubscriptionJson {
    const raw = sub.toJSON() as any
    return {
      endpoint: raw.endpoint,
      keys: { p256dh: raw.keys.p256dh, auth: raw.keys.auth },
      expirationTime: raw.expirationTime ?? null,
    }
  },

  /** Check if the user is currently subscribed */
  async isSubscribed(): Promise<boolean> {
    const sub = await this.getCurrentSubscription()
    return sub !== null
  },
}
