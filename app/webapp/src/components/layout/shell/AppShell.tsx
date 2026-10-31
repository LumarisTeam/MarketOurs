import { useCallback, useEffect, useMemo, useState } from "react"
import { useLocation } from "react-router"
import { cn } from "@/lib/utils"
import { PageTransition } from "@/components/layout/PageTransition"
import { AppRail } from "./AppRail"
import { ListColumn } from "./ListColumn"
import { ListContext, type FeedListState } from "./ListContext"
import type { Breakpoint } from "./useBreakpoint"

interface AppShellProps {
  breakpoint: Exclude<Breakpoint, "phone">
  children: React.ReactNode
}

/**
 * 微信式分栏外壳（>=768px）。
 * 左图标栏 + （desktop）中间列表栏固定定位；右侧内容区使用文档滚动，
 * 这样页面里基于 window 的虚拟列表（PostFeed / 公开主页）依然正常工作。
 */
export function AppShell({ breakpoint, children }: AppShellProps) {
  const location = useLocation()
  const [list, setList] = useState<FeedListState>({ kind: "latest" })

  // 依据路由决定列表栏数据源；/post/:id 等其它路径保持上一次的值，列表栏不消失。
  const applyPath = useCallback((path: string) => {
    if (path === "/") {
      setList((prev) => (prev.kind === "latest" ? prev : { kind: "latest" }))
      return
    }
    if (path === "/hot") {
      setList((prev) => (prev.kind === "hot" ? prev : { kind: "hot" }))
      return
    }
    const tagMatch = /^\/tag\/([^/]+)\/?$/.exec(path)
    if (tagMatch) {
      const tagId = decodeURIComponent(tagMatch[1])
      setList((prev) =>
        prev.kind === "tag" && prev.tagId === tagId ? prev : { kind: "tag", tagId },
      )
    }
  }, [])

  useEffect(() => {
    // React Router 不对外提供 location 的 subscribe，这里只能通过 effect 把路由同步进列表栏状态。
    // eslint-disable-next-line react-hooks/set-state-in-effect
    applyPath(location.pathname)
  }, [applyPath, location.pathname])

  // 标签页加载到标签名后回填，列表栏标题从「标签」变成真实名称。
  const setTagName = useCallback((tagId: string, name: string) => {
    setList((prev) =>
      prev.kind === "tag" && prev.tagId === tagId && prev.tagName !== name
        ? { ...prev, tagName: name }
        : prev,
    )
  }, [])

  const value = useMemo(() => ({ list, setTagName }), [list, setTagName])

  return (
    <ListContext.Provider value={value}>
      <div className="relative min-h-dvh bg-background">
        <AppRail />
        {breakpoint === "desktop" && <ListColumn />}
        <div
          className={cn(
            "min-w-0",
            breakpoint === "desktop"
              ? "pl-[392px] xl:pl-[412px]"
              : "pl-[72px]",
          )}
        >
          <PageTransition>
            <div className="mx-auto w-full max-w-4xl px-4 py-8 sm:px-6 lg:px-8">
              {children}
            </div>
          </PageTransition>
        </div>
      </div>
    </ListContext.Provider>
  )
}
