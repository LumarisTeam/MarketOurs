import { Heart, Share2, MoreHorizontal, Search, Loader2, Eye, ArrowLeft } from "lucide-react"
import { useNavigate } from "react-router"
import { useState, useEffect, useRef, useEffectEvent } from "react"
import { useTranslation } from "react-i18next"
import { useSelector } from "react-redux"
import type { RootState } from "../../stores"
import { postService } from "../../services/postService"
import { extractUserMessage } from "../../services/errorCodes"
import type { PostDto } from "../../types"
import { formatPostRelativeDate, getPostAuthorName, getPostExcerpt } from "../../lib/postDisplay"
import { sharePost } from "../../lib/postShare"
import { PostTagBadge } from "./PostTagBadge"

export function PostCard({ post, onDelete }: { post: PostDto; onDelete?: (id: string) => void }) {
  const navigate = useNavigate()
  const { t, i18n } = useTranslation()
  const { user } = useSelector((state: RootState) => state.auth)
  const [shareFeedback, setShareFeedback] = useState<string | null>(null)

  const isMe = user && post.userId.toLowerCase() === user.id.toLowerCase()
  const isAdmin = user && user.role === "Admin"
  const authorName = getPostAuthorName(post, t("common.user"))
  const displayName = isMe ? `${authorName} (${t("common.me", { defaultValue: "我" })})` : authorName
  const authorAvatar = post.author?.avatar || `https://api.dicebear.com/7.x/avataaars/svg?seed=${post.userId}`

  const handleDelete = async (e: React.MouseEvent) => {
    e.stopPropagation()
    if (window.confirm(t("post.confirm_delete"))) {
      try {
        await postService.deletePost(post.id)
        onDelete?.(post.id)
      } catch (err) {
        console.error(err)
      }
    }
  }

  const handleAuthorClick = (e: React.MouseEvent) => {
    e.stopPropagation()
    navigate(`/user/${post.userId}`)
  }

  const handleShare = async (e: React.MouseEvent) => {
    e.stopPropagation()
    try {
      const outcome = await sharePost(post)
      if (outcome === "shared") {
        setShareFeedback("已打开分享面板")
      } else if (outcome === "copied") {
        setShareFeedback("链接已复制")
      }
    } catch (error) {
      console.error(error)
      setShareFeedback(extractUserMessage(error, "分享失败，请稍后重试"))
    } finally {
      window.setTimeout(() => setShareFeedback(null), 2500)
    }
  }

  return (
    <article
      onClick={() => navigate(`/post/${post.id}`)}
      className="group relative cursor-pointer rounded-[2rem] border border-border/50 bg-card p-6 transition-all duration-300 hover:border-primary/30 hover:shadow-xl hover:shadow-primary/5"
    >
      <div className="mb-4 flex items-center gap-3">
        <button
          type="button"
          onClick={handleAuthorClick}
          className="flex flex-1 items-center gap-3 rounded-2xl text-left transition-colors hover:text-primary"
        >
          <img src={authorAvatar} alt={authorName} className="h-10 w-10 rounded-full bg-muted" />
          <div className="flex-1">
            <p className="text-sm font-semibold">{displayName}</p>
            <p className="text-xs text-muted-foreground">{formatPostRelativeDate(post.createdAt, i18n, post.updatedAt, t("post.edited"))}</p>
          </div>
        </button>
        {(isMe || isAdmin) && (
          <button
            onClick={handleDelete}
            className="rounded-full p-2 text-muted-foreground transition-colors hover:bg-destructive/10 hover:text-destructive"
            title={t("post.delete")}
          >
            <span className="sr-only">{t("post.delete")}</span>
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
          </button>
        )}
        <button
          onClick={(e) => {
            e.stopPropagation()
          }}
          className="rounded-full p-2 text-muted-foreground transition-colors hover:bg-muted"
        >
          <MoreHorizontal size={18} />
        </button>
      </div>

      <div className="mb-6 space-y-2">
        <PostTagBadge tag={post.tag} />
        <h2 className="text-2xl font-bold tracking-tight transition-colors group-hover:text-primary">
          {post.title}
        </h2>
        <p className="line-clamp-3 whitespace-pre-wrap leading-relaxed text-muted-foreground">
          {getPostExcerpt(post.content)}
        </p>
        {post.images && post.images.length > 0 && (
          <div className="mt-4 flex h-32 gap-2 overflow-hidden rounded-xl">
            {post.images.slice(0, 3).map((img, i) => (
              <img key={i} src={img} className="h-full w-1/3 bg-muted object-cover" alt="" />
            ))}
          </div>
        )}
      </div>

      <div className="flex items-center gap-6 border-t border-border/30 pt-4">
        <button
          onClick={(e) => {
            e.stopPropagation()
          }}
          className="flex items-center gap-2 text-sm font-medium text-muted-foreground transition-colors hover:text-primary"
        >
          <Heart size={18} />
          <span>{post.likes}</span>
        </button>
        <button
          onClick={(e) => {
            e.stopPropagation()
          }}
          className="flex items-center gap-2 text-sm font-medium text-muted-foreground transition-colors hover:text-primary"
        >
          <Eye size={18} />
          <span>{post.watch}</span>
        </button>
        <button
          onClick={handleShare}
          className="ml-auto flex items-center gap-2 text-sm font-medium text-muted-foreground transition-colors hover:text-primary"
          title={t("post.share")}
        >
          <Share2 size={18} />
          <span>{t("post.share")}</span>
        </button>
      </div>
      {shareFeedback ? (
        <p className="mt-3 text-right text-xs font-medium text-primary">{shareFeedback}</p>
      ) : null}
    </article>
  )
}

export function usePostFeed(tagId?: string) {
  const { t } = useTranslation()
  const [posts, setPosts] = useState<PostDto[]>([])
  const [keyword, setKeyword] = useState("")
  const [searchInput, setSearchInput] = useState("")
  const [loading, setLoading] = useState(false)
  const [hasMore, setHasMore] = useState(true)
  const [feedError, setFeedError] = useState<string | null>(null)
  const observerTarget = useRef<HTMLDivElement | null>(null)
  const loadingRef = useRef(false)
  const hasMoreRef = useRef(true)
  const currentPageRef = useRef(0)
  const currentKeywordRef = useRef("")
  const observerInViewRef = useRef(false)
  const requestPhaseRef = useRef<"idle" | "loading" | "cooldown">("idle")
  const feedVersionRef = useRef(0)
  const normalizedTagId = tagId?.trim() || undefined
  const isRefreshingFeed = loading && posts.length === 0
  const isSearching = isRefreshingFeed && keyword.trim().length > 0

  useEffect(() => {
    loadingRef.current = loading
  }, [loading])

  useEffect(() => {
    hasMoreRef.current = hasMore
  }, [hasMore])

  useEffect(() => {
    currentKeywordRef.current = keyword
  }, [keyword])

  const fetchPosts = useEffectEvent(async (pageNum: number, append = true, version = feedVersionRef.current) => {
    if (requestPhaseRef.current === "loading") return

    requestPhaseRef.current = "loading"
    setLoading(true)
    setFeedError(null)
    let nextHasMore = hasMoreRef.current

    try {
      const trimmedKeyword = currentKeywordRef.current.trim()
      const res = trimmedKeyword
        ? await postService.searchPosts(pageNum, 10, trimmedKeyword, normalizedTagId)
        : await postService.getPosts(pageNum, 10, undefined, normalizedTagId)

      if (version !== feedVersionRef.current) {
        return
      }

      const data = res.data
      if (data && data.items) {
        currentPageRef.current = pageNum
        nextHasMore = data.hasNextPage
        setPosts((prev) => (append ? [...prev, ...data.items] : data.items))
        setHasMore(data.hasNextPage)
      } else {
        currentPageRef.current = pageNum
        nextHasMore = false
        if (!append) {
          setPosts([])
        }
        setHasMore(false)
      }
    } catch (err) {
      nextHasMore = hasMoreRef.current
      if (version !== feedVersionRef.current) {
        return
      }
      console.error(err)
      setFeedError(extractUserMessage(err, t("common.error")))
    }

    if (version !== feedVersionRef.current) {
      return
    }

    setLoading(false)
    hasMoreRef.current = nextHasMore
    requestPhaseRef.current = observerInViewRef.current && nextHasMore ? "cooldown" : "idle"
  })

  useEffect(() => {
    const version = feedVersionRef.current + 1
    feedVersionRef.current = version
    currentPageRef.current = 0
    currentKeywordRef.current = keyword
    observerInViewRef.current = false
    requestPhaseRef.current = "idle"
    hasMoreRef.current = true
    setPosts([])
    setHasMore(true)
    void fetchPosts(1, false, version)
  }, [keyword, normalizedTagId])

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0]
        if (!entry) return

        observerInViewRef.current = entry.isIntersecting

        if (!entry.isIntersecting) {
          if (requestPhaseRef.current === "cooldown") {
            requestPhaseRef.current = "idle"
          }
          return
        }

        if (requestPhaseRef.current !== "idle" || !hasMoreRef.current || loadingRef.current) {
          return
        }

        void fetchPosts(currentPageRef.current + 1, true, feedVersionRef.current)
      },
      {
        rootMargin: "0px 0px 320px 0px",
        threshold: 0,
      },
    )

    const target = observerTarget.current
    if (target) {
      observer.observe(target)
    }

    return () => observer.disconnect()
  }, [])

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault()
    setKeyword(searchInput.trim())
  }

  return {
    posts,
    setPosts,
    searchInput,
    setSearchInput,
    loading,
    hasMore,
    feedError,
    observerTarget,
    isRefreshingFeed,
    isSearching,
    keyword,
    handleSearch,
  }
}

export function PostFeed({
  tagId,
  searchPlaceholder,
  emptyMessage,
  header,
}: {
  tagId?: string
  searchPlaceholder?: string
  emptyMessage?: string
  header?: React.ReactNode
}) {
  const { t } = useTranslation()
  const {
    posts,
    setPosts,
    searchInput,
    setSearchInput,
    loading,
    hasMore,
    feedError,
    observerTarget,
    isRefreshingFeed,
    isSearching,
    handleSearch,
  } = usePostFeed(tagId)

  return (
    <div className="mx-auto max-w-3xl space-y-10 pb-20">
      {header}
      <form onSubmit={handleSearch} className="relative">
        <input
          type="text"
          value={searchInput}
          onChange={(e) => setSearchInput(e.target.value)}
          placeholder={searchPlaceholder ?? t("common.search_placeholder")}
          className="w-full rounded-2xl border border-border/50 bg-card py-4 pl-12 pr-12 shadow-sm outline-none transition-all focus:border-primary focus:ring-2 focus:ring-primary/20"
          aria-busy={isSearching}
        />
        <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground" size={20} />
        {isSearching ? (
          <Loader2
            className="absolute right-4 top-1/2 -translate-y-1/2 animate-spin text-primary"
            size={20}
            aria-hidden="true"
          />
        ) : null}
        <button type="submit" className="hidden">{t("common.search")}</button>
      </form>

      <div className="space-y-6">
        {feedError && (
          <div className="animate-in rounded-2xl bg-destructive/10 p-4 text-center text-sm font-medium text-destructive fade-in duration-300">
            {feedError}
          </div>
        )}
        {isRefreshingFeed ? (
          <div className="flex items-center justify-center gap-3 rounded-2xl border border-border/50 bg-card/70 px-4 py-5 text-sm font-medium text-muted-foreground">
            <Loader2 className="animate-spin text-primary" size={20} />
            <span>{isSearching ? t("common.search") : t("common.loading", { defaultValue: "Loading..." })}</span>
          </div>
        ) : null}
        {posts.map((post) => (
          <PostCard
            key={post.id}
            post={post}
            onDelete={(id) => setPosts((prev) => prev.filter((p) => p.id !== id))}
          />
        ))}
      </div>

      <div ref={observerTarget} className="flex justify-center py-8">
        {loading && posts.length > 0 ? <Loader2 className="animate-spin text-primary" size={32} /> : null}
        {!hasMore && posts.length > 0 ? <p className="text-muted-foreground">{t("common.no_more_posts")}</p> : null}
        {!hasMore && posts.length === 0 && !loading ? <p className="text-muted-foreground">{emptyMessage ?? t("common.no_posts_found")}</p> : null}
      </div>
    </div>
  )
}

export function BackLink({ to, label }: { to: string; label: string }) {
  const navigate = useNavigate()

  return (
    <button
      type="button"
      onClick={() => navigate(to)}
      className="inline-flex items-center gap-2 rounded-full border border-border/60 bg-card px-4 py-2 text-sm font-semibold text-muted-foreground transition hover:border-primary/20 hover:text-primary"
    >
      <ArrowLeft size={16} />
      {label}
    </button>
  )
}
