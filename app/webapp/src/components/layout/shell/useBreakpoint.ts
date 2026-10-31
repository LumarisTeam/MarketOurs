import { useSyncExternalStore } from "react"

export type Breakpoint = "phone" | "tablet" | "desktop"

const TABLET_QUERY = "(min-width: 768px)"
const DESKTOP_QUERY = "(min-width: 1024px)"

function getSnapshot(): Breakpoint {
  if (typeof window === "undefined") return "phone"
  if (window.matchMedia(DESKTOP_QUERY).matches) return "desktop"
  if (window.matchMedia(TABLET_QUERY).matches) return "tablet"
  return "phone"
}

function subscribe(onChange: () => void) {
  const tablet = window.matchMedia(TABLET_QUERY)
  const desktop = window.matchMedia(DESKTOP_QUERY)
  tablet.addEventListener("change", onChange)
  desktop.addEventListener("change", onChange)
  return () => {
    tablet.removeEventListener("change", onChange)
    desktop.removeEventListener("change", onChange)
  }
}

/**
 * 微信式分栏断点：
 * - phone: <768px，保持原单栏 + Navbar + footer
 * - tablet: 768–1023px，左图标栏 + 内容区
 * - desktop: >=1024px，左图标栏 + 列表栏 + 内容区
 * SSR 安全默认 phone（本应用为纯客户端 SPA，客户端首帧直接读到真实宽度，无闪动）。
 */
export function useBreakpoint(): Breakpoint {
  return useSyncExternalStore(subscribe, getSnapshot, () => "phone" as Breakpoint)
}
