import { useEffect, useRef, useState } from "react"
import { useLocation } from "react-router"
import { useTranslation } from "react-i18next"
import { Loader2, RefreshCw, Search } from "lucide-react"
import { postService } from "@/services/postService"
import type { PostDto } from "@/types"
import { usePostFeed } from "@/components/post/PostFeed"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Skeleton } from "@/components/ui/skeleton"
import type { FeedListState } from "./ListContext"
import { CompactPostRow } from "./CompactPostRow"

function selectedPostId(pathname: string) {
  if (!pathname.startsWith("/post/")) return ""
  const id = pathname.slice("/post/".length)
  if (!id || id.includes("/")) return ""
  return decodeURIComponent(id)
}

function ListSkeleton() {
  return (
    <div className="divide-y divide-border/30">
      {Array.from({ length: 6 }).map((_, i) => (
        <div key={i} className="space-y-2 px-4 py-3">
          <div className="flex items-center gap-2">
            <Skeleton className="h-5 w-5 rounded-full" />
            <Skeleton className="h-3 w-24" />
            <Skeleton className="ml-auto h-3 w-10" />
          </div>
          <Skeleton className="h-4 w-4/5" />
          <Skeleton className="h-3 w-3/5" />
        </div>
      ))}
    </div>
  )
}

function ListEmpty({ label }: { label: string }) {
  return (
    <div className="flex flex-col items-center gap-3 px-6 py-16 text-center">
      <div className="rounded-2xl bg-muted/50 p-3">
        <RefreshCw size={20} className="text-muted-foreground/50" />
      </div>
      <p className="text-sm text-muted-foreground">{label}</p>
    </div>
  )
}

/** latest / tag：复用 PostFeed 导出的 usePostFeed（含分页与哨兵逻辑） */
function FeedPane({ tagId }: { tagId?: string }) {
  const { t } = useTranslation()
  const location = useLocation()
  const {
    posts,
    loading,
    hasMore,
    feedError,
    observerTarget,
    isRefreshingFeed,
    searchInput,
    setSearchInput,
    handleSearch,
    isSearching,
  } = usePostFeed(tagId)
  const activeId = selectedPostId(location.pathname)
  const scrollRef = useRef<HTMLDivElement>(null)

  const handleSubmit = (event: React.FormEvent) => {
    handleSearch(event)
    scrollRef.current?.scrollTo({ top: 0 })
  }

  return (
    <div className="flex h-full flex-col">
      {/* 固定搜索头：latest / tag 上下文可用；清空输入并回车恢复全量 */}
      <form onSubmit={handleSubmit} className="shrink-0 border-b border-border/40 px-3 py-2.5">
        <div className="relative">
          <Search
            size={15}
            aria-hidden
            className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground"
          />
          <Input
            type="text"
            value={searchInput}
            onChange={(event) => setSearchInput(event.target.value)}
            placeholder={t("common.search_placeholder")}
            aria-label={t("common.search")}
            className="h-9 rounded-xl border-border/50 bg-background/60 pl-9 pr-9 text-[13px]"
          />
          {isSearching && (
            <Loader2
              size={14}
              aria-hidden
              className="absolute right-3 top-1/2 -translate-y-1/2 animate-spin text-primary"
            />
          )}
        </div>
      </form>

      <div ref={scrollRef} className="min-h-0 flex-1 overflow-y-auto overscroll-contain">
        {isRefreshingFeed && <ListSkeleton />}

        {feedError && posts.length === 0 && (
          <p className="px-4 py-6 text-center text-xs font-medium text-destructive">{feedError}</p>
        )}

        {!isRefreshingFeed && posts.map((post) => (
          <CompactPostRow key={post.id} post={post} selected={post.id === activeId} />
        ))}

        {!loading && !feedError && posts.length === 0 && <ListEmpty label={t("shell.list_empty")} />}

        {loading && posts.length > 0 && (
          <div className="flex justify-center py-4">
            <Loader2 className="animate-spin text-primary" size={20} />
          </div>
        )}

        {!hasMore && posts.length > 0 && (
          <p className="py-4 text-center text-xs text-muted-foreground/70">
            {t("common.no_more_posts")}
          </p>
        )}

        {/* 1px 哨兵：进入滚动容器可视区时，usePostFeed 内部的 IntersectionObserver 会触发 loadMore */}
        <div ref={observerTarget} aria-hidden className="h-px w-full" />
      </div>
    </div>
  )
}

/** hot：复用 postService.getHotPosts(10)，非虚拟化紧凑行 */
function HotListPane() {
  const { t } = useTranslation()
  const location = useLocation()
  const [posts, setPosts] = useState<PostDto[]>([])
  const [loading, setLoading] = useState(true)
  const [failed, setFailed] = useState(false)
  const [reloadKey, setReloadKey] = useState(0)
  const activeId = selectedPostId(location.pathname)

  useEffect(() => {
    let cancelled = false

    const load = async () => {
      setLoading(true)
      setFailed(false)
      try {
        const response = await postService.getHotPosts(10)
        if (!cancelled) setPosts(response.data ?? [])
      } catch (error) {
        console.error(error)
        if (!cancelled) setFailed(true)
      } finally {
        if (!cancelled) setLoading(false)
      }
    }

    void load()

    return () => {
      cancelled = true
    }
  }, [reloadKey])

  if (loading && posts.length === 0) {
    return (
      <div className="h-full overflow-y-auto overscroll-contain">
        <ListSkeleton />
      </div>
    )
  }

  if (failed && posts.length === 0) {
    return (
      <div className="flex flex-col items-center gap-3 px-6 py-16 text-center">
        <p className="text-sm text-muted-foreground">{t("shell.list_error")}</p>
        <Button
          variant="outline"
          size="sm"
          className="rounded-full gap-2"
          onClick={() => setReloadKey((value) => value + 1)}
        >
          <RefreshCw size={14} />
          {t("shell.list_retry")}
        </Button>
      </div>
    )
  }

  if (posts.length === 0) {
    return <ListEmpty label={t("shell.list_empty")} />
  }

  return (
    <div className="h-full overflow-y-auto overscroll-contain">
      {posts.map((post, index) => (
        <CompactPostRow
          key={post.id}
          post={post}
          rank={index + 1}
          selected={post.id === activeId}
          trailing={t("shell.list_heat", { heat: post.heat ?? 0 })}
        />
      ))}
    </div>
  )
}

export function FeedListPane({ list }: { list: FeedListState }) {
  if (list.kind === "hot") return <HotListPane />
  return <FeedPane tagId={list.kind === "tag" ? list.tagId : undefined} />
}
